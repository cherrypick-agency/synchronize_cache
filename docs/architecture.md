# Architecture and Internals

## Architecture Overview

`offline_first_sync_drift` is built on the **orchestrator + specialized services** principle. The central `SyncEngine` class coordinates the entire sync process, delegating specific tasks to five internal services:

```
SyncEngine (orchestrator)
├── PushService       → sends local changes to the server
│   ├── OutboxService → manages the operation queue
│   └── ConflictService → resolves conflicts
├── PullService       → receives server changes
│   └── CursorService → manages pagination cursors
└── TransportAdapter  → network transport abstraction (implemented by the user)
```

Each service performs a single task and receives dependencies via its constructor. `SyncEngine` creates all services in the `_initServices()` method and manages the order of their invocation.

### Sync Order

Each `sync()` call follows a **push-first** strategy:

1. **Push** -- send all local changes from the outbox
2. **Pull** -- receive all server changes since the last cursor

This ensures the server receives local changes before the client starts downloading new data, minimizing the number of conflicts.

---

## Outbox Pattern

### Why an Outbox Is Needed

The outbox (outgoing operation queue) solves three key problems:

- **Reliability**: operations are not lost on network interruption or app crash
- **Idempotency**: each operation has a unique `opId`, allowing the server to deduplicate repeated sends
- **Ordering**: operations are stored with a timestamp (`ts`) and sent in creation order

### How Operations Are Stored

Operations are written to the `sync_outbox` table with the following columns:

| Column | Description |
|---------|----------|
| `op_id` | Operation UUID (primary key, idempotency) |
| `kind` | Entity type (`'todos'`, `'notes'`, etc.) |
| `entity_id` | Entity ID |
| `op` | Operation type: `'upsert'` or `'delete'` |
| `payload` | JSON data for upsert (null for delete) |
| `ts` | Creation timestamp (milliseconds UTC) |
| `try_count` | Send attempt counter |
| `base_updated_at` | Server timestamp at read time (for conflict detection) |
| `changed_fields` | JSON list of changed fields (for autoPreserve strategy) |

### Operation Types

Operations are represented as a sealed class `Op` with two subtypes:

```dart
sealed class Op {
  final String opId;          // UUID for idempotency
  final String kind;          // Entity type
  final String id;            // Entity ID
  final DateTime localTimestamp; // Creation time
}

class UpsertOp extends Op {
  final Map<String, Object?> payloadJson;  // Data to send
  final DateTime? baseUpdatedAt;           // null = new record
  final Set<String>? changedFields;        // For smart merge
}

class DeleteOp extends Op {
  final DateTime? baseUpdatedAt;           // For conflict detection
}
```

### Operation Lifecycle

```
User modifies data
        │
        ▼
   OutboxService.enqueue(op)
   ┌──────────────────────┐
   │   sync_outbox (DB)   │  ← operation saved, survives restart
   └──────────────────────┘
        │
        ▼ (on sync)
   OutboxService.take(limit: pageSize)
   ┌──────────────────────┐
   │   Batch of operations│  ← read from DB, ORDER BY ts
   └──────────────────────┘
        │
        ▼
   TransportAdapter.push(ops)
        │
   ┌────┼────────────┐
   │    │             │
   ▼    ▼             ▼
Success Conflict    Error
   │    │             │
   ▼    ▼             ▼
  ack  resolve     emit event
(delete) │      (keep in outbox)
        │
   ┌────┼────────┐
   │    │        │
   ▼    ▼        ▼
  ack  defer   skip/retry
```

---

## Push Flow (Detailed)

### Source Code: `PushService.pushAll()`

Push operates in a loop, processing operations in batches:

**Step 1: Read batch from outbox**

```dart
final ops = await _outbox.take(limit: _config.pageSize); // default 500
if (ops.isEmpty) break; // all operations sent
```

**Step 2: Send batch with retry**

The `_pushBatch()` method sends the entire batch via `TransportAdapter.push(ops)` with exponential backoff:

```dart
Future<BatchPushResult> _pushBatch(List<Op> ops) async {
  int attempt = 0;
  while (true) {
    try {
      attempt++;
      return await _transport.push(ops);
    } catch (e, st) {
      if (attempt >= _config.maxPushRetries) {
        throw MaxRetriesExceededException(...);
      }
      // Exponential backoff: min * multiplier^(attempt-1)
      // Capped at backoffMax
      final backoff = _config.backoffMin * pow(_config.backoffMultiplier, attempt - 1);
      final delay = backoff > _config.backoffMax ? _config.backoffMax : backoff;
      await Future.delayed(delay);
    }
  }
}
```

Backoff parameters (from `SyncConfig`):
- `backoffMin`: 1 second
- `backoffMax`: 2 minutes
- `backoffMultiplier`: 2.0
- `maxPushRetries`: 5 attempts

**Step 3: Process results for each operation**

The server returns `BatchPushResult` with an individual result for each operation:

```dart
for (final opResult in result.results) {
  switch (opResult.result) {
    case PushSuccess():
      // Operation accepted by server
      successOpIds.add(opResult.opId);
      counters.pushed++;
      _events.add(OperationPushedEvent(...));

    case PushConflict():
      // Version conflict -- delegate to ConflictService
      counters.conflicts++;
      conflictOps[op] = conflict;

    case PushNotFound():
      // Entity not found on server (deleted?) -- treat as success
      successOpIds.add(opResult.opId);

    case PushError():
      // Error -- keep in outbox for next attempt
      counters.errors++;
      _events.add(OperationFailedEvent(...));
  }
}
```

**Step 4: Acknowledge successful operations**

```dart
await _outbox.ack(successOpIds); // DELETE FROM sync_outbox WHERE op_id IN (...)
```

**Step 5: Resolve conflicts**

```dart
for (final entry in conflictOps.entries) {
  final result = await _conflictService.resolve(entry.key, entry.value);
  if (result.resolved) {
    counters.conflictsResolved++;
    successOpIds.add(entry.key.opId);
  } else if (_config.skipConflictingOps) {
    successOpIds.add(entry.key.opId); // Remove even unresolved conflict
  }
}
```

If `skipConflictingOps = true`, unresolved conflicts are removed from the outbox. If `false` -- they remain for the next sync.

---

## Pull Flow (Detailed)

### Source Code: `PullService.pullKind()`

Pull retrieves data from the server page by page, using a cursor to track progress.

**Step 1: Get current cursor**

```dart
final cursor = await _cursorService.get(kind);
var since = cursor?.ts ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
var afterId = cursor?.lastId;
```

If the cursor is absent (first sync), `since` is set to epoch (1970-01-01), meaning all data will be loaded.

**Step 2: Page-by-page loading loop**

```dart
while (true) {
  final page = await _transport.pull(
    kind: kind,
    updatedSince: since,      // Filter by update time
    pageSize: _config.pageSize, // 500 by default
    pageToken: token,          // Next page token (from server)
    afterId: afterId,          // ID for timestamp collision resolution
    includeDeleted: true,      // Include soft-deleted records
  );

  if (page.items.isEmpty) break;
  // ... processing ...
}
```

**Step 3: Write data to local DB**

```dart
await _db.batch((batch) {
  for (final json in page.items) {
    final entity = tableConfig.fromJson(json);
    batch.insert(
      tableConfig.table,
      tableConfig.getInsertable(entity),
      mode: InsertMode.insertOrReplace, // Upsert semantics
    );
  }
});
```

All records (including soft-deleted) are inserted via `insertOrReplace`. This means deleted records are also stored in the local DB with the `deletedAt` field populated.

**Step 4: Update cursor**

```dart
final last = page.items.last;
final ts = last['updatedAt'] ?? last['updated_at'];
final id = (last['id'] ?? last['ID'] ?? last['uuid']).toString();

since = ts is DateTime ? ts : DateTime.parse(ts.toString()).toUtc();
afterId = id;
await _cursorService.set(kind, Cursor(ts: since, lastId: afterId));
```

The cursor is updated **after each page**, which provides fault tolerance: on a connection drop, the next sync will continue from the last successful page.

**Step 5: Determine end of data**

```dart
token = page.nextPageToken;
if (token == null && page.items.length < _config.pageSize) {
  break; // Last page
}
```

Pagination ends when:
- The server did not return a `nextPageToken` **AND** the item count is less than `pageSize`
- Or the server returned an empty page

---

## Conflict Resolution Flow

### Conflict Detection

A conflict occurs when the server returns `PushConflict` instead of `PushSuccess`. This means the data on the server changed after the client read it (optimistic locking via `baseUpdatedAt`).

`PushConflict` contains:
- `serverData` -- current data on the server
- `serverTimestamp` -- time of last server update
- `serverVersion` -- version/ETag (optional)

### Resolution Strategies

The strategy is determined in priority order:
1. `TableConflictConfig.strategy` -- for a specific table
2. `SyncConfig.conflictStrategy` -- global (default `autoPreserve`)

```dart
Future<ConflictResolution> _determineResolution(...) async {
  switch (strategy) {
    case ConflictStrategy.serverWins:
      return const AcceptServer();

    case ConflictStrategy.clientWins:
      return const AcceptClient();

    case ConflictStrategy.lastWriteWins:
      if (conflict.localTimestamp.isAfter(conflict.serverTimestamp)) {
        return const AcceptClient();
      }
      return const AcceptServer();

    case ConflictStrategy.merge:
      final mergeFunc = tableConfig?.mergeFunction
          ?? _config.mergeFunction
          ?? ConflictUtils.defaultMerge;
      final merged = mergeFunc(conflict.localData, conflict.serverData);
      return AcceptMerged(merged);

    case ConflictStrategy.manual:
      final resolver = tableConfig?.resolver ?? _config.conflictResolver;
      if (resolver == null) return const DeferResolution();
      return resolver(conflict);

    case ConflictStrategy.autoPreserve:
      // Smart merge without data loss
      final mergeResult = ConflictUtils.preservingMerge(
        conflict.localData,
        conflict.serverData,
        changedFields: conflict.changedFields,
      );
      return AcceptMerged(mergeResult.data, mergeInfo: ...);
  }
}
```

### Applying the Resolution

After determining the strategy, `_applyResolution()` performs the specific action:

| Resolution | Action |
|-----------|----------|
| `AcceptServer` | Write server data to local DB via `insertOnConflictUpdate` |
| `AcceptClient` | Resend the operation via `TransportAdapter.forcePush()` with retry |
| `AcceptMerged` | Create a new `UpsertOp` with merged data, `forcePush()`, update local DB |
| `DeferResolution` | Do nothing, operation stays in outbox |
| `DiscardOperation` | Remove operation from outbox (data loss by user decision) |

### forcePush with Retry

Both `AcceptClient` and `AcceptMerged` use `forcePush` with a limited number of attempts:

```dart
Future<bool> _forcePushOp(Op op) async {
  var retries = 0;
  while (retries < _config.maxConflictRetries) { // default 3
    final result = await _transport.forcePush(op);
    if (result is PushSuccess) return true;
    if (result is PushConflict) {
      retries++;
      if (retries < _config.maxConflictRetries) {
        await Future.delayed(_config.conflictRetryDelay); // 500ms
      }
      continue;
    }
    return false; // PushError or PushNotFound
  }
  return false;
}
```

### autoPreserve: Smart Lossless Merge

The `autoPreserve` strategy (default) uses `ConflictUtils.preservingMerge()`:

1. System fields (`id`, `updatedAt`, `createdAt`, `deletedAt`) are taken from the server
2. If `changedFields` is specified -- only changed fields are taken from local data
3. Local value != null, server value == null -> local value is used
4. Lists are merged (union by `id` for objects, by value for primitives)
5. Nested Maps are merged recursively
6. Primitives: local data takes priority (user made the change)

---

## Cursor-based Pagination

### Why Cursor Is Better Than Offset

Offset-based pagination is unreliable for sync:
- Inserting/deleting records during pagination shifts the offset
- Records can be skipped or duplicated

Cursor `(ts, lastId)` provides stable pagination:
- `ts` (DateTime) -- timestamp of the last processed item
- `lastId` (String) -- ID of the last processed item

### How the Cursor Works

```dart
class Cursor {
  final DateTime ts;      // Last item timestamp
  final String lastId;    // Last item ID
}
```

Request to server: "give me records updated after `ts`, and if `ts` is the same -- with ID after `lastId`".

**First sync**: cursor = null, `since` = epoch (1970-01-01). All data is loaded.

**Subsequent syncs**: pull starts from the last cursor position, loading only changes.

### Why lastId Is Needed

Multiple records can have the same `updatedAt` (e.g., during bulk updates). Without `lastId`, records with the same timestamp would be loaded repeatedly. `lastId` serves as an additional discriminator for precise cursor positioning.

### Cursor Storage

Cursors are stored in the `sync_cursors` table:

| Column | Description |
|---------|----------|
| `kind` | Entity type (primary key) |
| `ts` | Timestamp in milliseconds UTC |
| `last_id` | Last item ID |

A special cursor `__full_resync__` stores the time of the last full resync.

---

## Soft Delete

### Two Fields for Deletion

Synced tables have two fields for deletion (defined in `SyncColumns`):

```dart
mixin SyncColumns on Table implements SynchronizableTable {
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get deletedAtLocal => dateTime().nullable()();
}
```

| Field | Set By | Purpose |
|------|-------------------|------------|
| `deletedAt` | Server | Server deletion marker, received during pull |
| `deletedAtLocal` | Client | Local deletion marker before syncing with server |

### Why Two Fields

Local deletions must be sent to the server. With a single field, it would be impossible to distinguish "deleted on server" from "deleted locally but not yet synced".

### Deletion Flow

```
User deletes a record locally
        │
        ▼
Set deletedAtLocal = DateTime.now()
        │
        ▼
OutboxService.enqueue(DeleteOp(...))
        │
        ▼ (on sync)
PushService → TransportAdapter.push()
        │
        ▼
Server sets deletedAt
        │
        ▼ (on pull)
PullService receives record with deletedAt != null
        │
        ▼
insertOrReplace into local DB
(now deletedAt is populated)
```

### During Pull

During pull, all records (including deleted) are written to the local DB:

```dart
// pull_service.dart
final deletedAt = json['deletedAt'] ?? json['deleted_at'];
if (deletedAt != null) {
  deletes++;  // For statistics
} else {
  upserts++;
}
// In both cases -- insertOrReplace
batch.insert(tableConfig.table, ..., mode: InsertMode.insertOrReplace);
```

The app must filter records with `deletedAt != null` when displaying data to the user.

---

## Race Condition Protection

### Concurrent Sync

`SyncEngine` uses a shared Future pattern to prevent parallel syncs:

```dart
Future<SyncStats>? _syncFuture;

Future<SyncStats> sync({Set<String>? kinds}) {
  // If sync is already running -- return the same Future
  if (_syncFuture != null) {
    return _syncFuture!;
  }

  _syncFuture = _doSync(kinds: kinds);
  return _syncFuture!.whenComplete(() => _syncFuture = null);
}
```

This means:
- The first `sync()` call starts the actual synchronization
- All subsequent `sync()` calls during execution **receive the same Future** and the same result
- After completion, `_syncFuture` is cleared, and the next call starts a new sync

An analogous safeguard exists for `fullResync()`:

```dart
Future<SyncStats>? _fullResyncFuture;

Future<SyncStats> fullResync({bool clearData = false}) {
  if (_fullResyncFuture != null) {
    return _fullResyncFuture!;
  }
  _fullResyncFuture = _doFullResync(...);
  return _fullResyncFuture!.whenComplete(() => _fullResyncFuture = null);
}
```

### Full Resync

A full resync is periodically performed (default every 7 days):

```dart
final lastFullResync = await _cursorService.getLastFullResync();
final needsFullResync = lastFullResync == null ||
    started.difference(lastFullResync) >= _config.fullResyncInterval;
```

Full resync performs:
1. Push all local changes (like a regular sync)
2. Reset all cursors (`resetAll`)
3. Optionally: clear local data (`clearData = true`)
4. Pull all data from the server (from zero cursors)
5. Save the full resync timestamp

---

## Data Flows

### Local Data Write

```
┌─────────────┐
│ Application  │
│ modifies     │
│ data         │
└──────┬──────┘
       │
       ▼
┌──────────────┐     ┌──────────────────┐
│ Drift ORM    │────▶│ Local table       │
│ insert/update│     │ (todos, notes...) │
└──────────────┘     └──────────────────┘
       │
       ▼
┌──────────────────┐
│ OutboxService    │
│ .enqueue(Op)     │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ sync_outbox      │
│ (awaiting sync)  │
└──────────────────┘
```

### Sync Push

```
┌──────────────────┐
│ SyncEngine.sync()│
│ Phase: PUSH      │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐     ┌──────────────────┐
│ PushService      │────▶│ OutboxService     │
│ .pushAll()       │     │ .take(limit: 500) │
└──────┬───────────┘     └──────────────────┘
       │
       ▼
┌──────────────────┐
│ TransportAdapter │
│ .push(ops)       │
└──────┬───────────┘
       │
  ┌────┼──────────┐
  │    │          │
  ▼    ▼          ▼
 OK  Conflict   Error
  │    │          │
  ▼    ▼          ▼
 ack  Conflict  event
      Service   (keep
  │    │        in outbox)
  │    ▼
  │  resolve()
  │    │
  │  ┌─┼───────────────────┐
  │  │ │                   │
  │  ▼ ▼                   ▼
  │ AcceptServer       AcceptClient
  │ (apply local)      (forcePush)
  │                        │
  │                    AcceptMerged
  │                    (forcePush merged)
  │                        │
  └────────────────────────┘
             │
             ▼
       OutboxService.ack()
       (remove from queue)
```

### Sync Pull

```
┌──────────────────┐
│ SyncEngine.sync()│
│ Phase: PULL      │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐     ┌──────────────────┐
│ PullService      │────▶│ CursorService    │
│ .pullKinds()     │     │ .get(kind)       │
└──────┬───────────┘     └──────────────────┘
       │                  Cursor(ts, lastId)
       │                  or null (first sync)
       ▼
┌──────────────────────────────────────┐
│ Loop over pages:                     │
│                                      │
│  TransportAdapter.pull(              │
│    kind, updatedSince, pageSize,     │
│    pageToken, afterId, includeDeleted│
│  )                                   │
│           │                          │
│           ▼                          │
│  db.batch(insertOrReplace)           │
│           │                          │
│           ▼                          │
│  CursorService.set(kind, newCursor)  │
│           │                          │
│           ▼                          │
│  More pages? ──── Yes ─── ▲         │
│           │                          │
│          No                          │
└──────────┬───────────────────────────┘
           │
           ▼
     return totalPulled
```

### Conflict Resolution

```
┌──────────────────┐
│ PushConflict     │
│ (from server)    │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ ConflictService  │
│ .resolve(op,     │
│  serverConflict) │
└──────┬───────────┘
       │
       ▼
  Create Conflict {
    localData, serverData,
    localTimestamp, serverTimestamp,
    changedFields, serverVersion
  }
       │
       ▼
  emit ConflictDetectedEvent
       │
       ▼
  _determineResolution()
       │
  ┌────┴────────────────────────────────┐
  │                                     │
  ▼                                     ▼
serverWins/clientWins/           merge/autoPreserve/
lastWriteWins                    manual
  │                                     │
  ▼                                     ▼
AcceptServer/                    AcceptMerged/
AcceptClient                     DeferResolution/
                                 DiscardOperation
       │
       ▼
  _applyResolution()
       │
  ┌────┼────────────────┬──────────────┐
  │    │                │              │
  ▼    ▼                ▼              ▼
Accept  Accept        Accept         Defer/
Server  Client        Merged         Discard
  │      │              │              │
  ▼      ▼              ▼              ▼
apply  forcePush    forcePush       keep/
server  (retry)     merged          remove
data     │         (retry)          from outbox
(local   │            │
 DB)     │            ▼
  │      │         update
  │      │         local DB
  │      │            │
  ▼      ▼            ▼
  emit ConflictResolvedEvent
```

---

## Service Dependencies

### Dependency Graph

```
SyncEngine
  │
  ├─── OutboxService(db: SyncDatabaseMixin)
  │
  ├─── CursorService(db: SyncDatabaseMixin)
  │
  ├─── ConflictService(
  │        db, transport, tables,
  │        config, tableConflictConfigs, events
  │    )
  │
  ├─── PushService(
  │        outbox: OutboxService,
  │        transport, conflictService,
  │        config, events
  │    )
  │
  └─── PullService(
           db, transport, tables,
           cursorService: CursorService,
           config, events
       )
```

### Initialization Order

The order of service creation in `_initServices()` is critical due to dependencies:

```dart
void _initServices() {
  // 1. Base services (depend only on DB)
  _outboxService = OutboxService(_syncDb);
  _cursorService = CursorService(_syncDb);

  // 2. ConflictService (depends on DB, transport, tables)
  _conflictService = ConflictService<DB>(
    db: _db, transport: _transport, tables: _tables,
    config: _config, tableConflictConfigs: _tableConflictConfigs,
    events: _events,
  );

  // 3. PushService (depends on OutboxService and ConflictService)
  _pushService = PushService(
    outbox: _outboxService, transport: _transport,
    conflictService: _conflictService,
    config: _config, events: _events,
  );

  // 4. PullService (depends on CursorService)
  _pullService = PullService<DB>(
    db: _db, transport: _transport, tables: _tables,
    cursorService: _cursorService,
    config: _config, events: _events,
  );
}
```

### Shared Dependencies

All services share:
- `StreamController<SyncEvent> _events` -- a single event stream
- `SyncConfig _config` -- configuration
- `TransportAdapter _transport` -- network transport

### Lifecycle

```dart
// Creation
final engine = SyncEngine(db: database, transport: transport, tables: [...]);

// Usage
await engine.sync();
engine.startAuto(interval: Duration(minutes: 5));

// Resource cleanup
engine.dispose(); // stopAuto() + _events.close()
```

`dispose()` stops auto-sync and closes the StreamController. Always call `dispose()` when done with the engine.
