# SyncEngine: Lifecycle and Services

## Overview

`SyncEngine` is the central class of the library that orchestrates the entire synchronization process between a local database (Drift) and a remote server. It manages:

- Pushing local changes from the outbox to the server (push)
- Fetching remote changes with cursor-based pagination (pull)
- Conflict resolution with multiple strategies
- Automatic background synchronization
- Periodic full resynchronization

---

## Lifecycle

```
Creation ──► Service initialization ──► startAuto() ──► Sync cycles ──► dispose()
     │                                       │                │
     │                                       │      ┌────────┤────────────┐
     │                                       │      │        │            │
     ▼                                       ▼      ▼        ▼            ▼
 new SyncEngine(                      Timer.periodic   sync()  sync()   fullResync()
   db, transport,                      triggers          │        │           │
   tables, config                      sync() on         │        │           │
 )                                     interval           │        │           │
                                                          ▼        ▼           ▼
                                                     push ──► pull      reset cursors
                                                                        ──► push ──► pull
```

**State diagram:**

```
          ┌──────────┐
          │ Created  │
          └────┬─────┘
               │ constructor: _initServices()
               ▼
          ┌──────────┐    startAuto()    ┌─────────────────┐
          │  Ready   │ ───────────────► │  Auto-sync       │
          └────┬─────┘ ◄─────────────── └────────┬────────┘
               │         stopAuto()              │
               │                          Timer.periodic → sync()
               │ sync() / fullResync()           │
               ▼                                 ▼
          ┌──────────┐                   ┌──────────────┐
          │ Syncing  │                   │  Syncing     │
          │ (manual) │                   │  (auto)      │
          └────┬─────┘                   └──────┬───────┘
               │                                │
               │ dispose()                      │ dispose()
               ▼                                ▼
          ┌──────────┐
          │ Disposed │  stopAuto() + _events.close()
          └──────────┘
```

---

## Creation and Initialization

### Constructor Parameters

```dart
SyncEngine({
  required DB db,                                    // Drift database (must implement SyncDatabaseMixin)
  required TransportAdapter transport,               // Adapter for network requests
  required List<SyncableTable<dynamic>> tables,      // List of syncable tables
  SyncConfig config = const SyncConfig(),            // Sync configuration
  Map<String, TableConflictConfig>? tableConflictConfigs,  // Per-table conflict settings
})
```

When creating a `SyncEngine`, the constructor:

1. Verifies that `db` implements `SyncDatabaseMixin` (throws `ArgumentError` if not)
2. Creates a `Map<String, SyncableTable>` from the table list, keyed by `kind`
3. Calls `_initServices()`, which creates internal services:
   - `OutboxService` — manages the outgoing operations queue
   - `CursorService` — manages sync cursors
   - `ConflictService` — handles conflict resolution
   - `PushService` — pushes changes to the server
   - `PullService` — pulls changes from the server

### Initialization Order

```dart
// 1. Create the database (Drift)
final db = AppDatabase(NativeDatabase.createInBackground(dbFile));

// 2. Implement the transport
final transport = MyRestTransport(baseUrl: 'https://api.example.com');

// 3. Define syncable tables
final tables = [
  SyncableTable<Todo>(
    kind: 'todos',
    table: db.todos,
    fromJson: Todo.fromJson,
    toJson: (t) => t.toJson(),
    toInsertable: (t) => t.toInsertable(),
  ),
];

// 4. Create SyncEngine
final engine = SyncEngine(
  db: db,
  transport: transport,
  tables: tables,
  config: const SyncConfig(
    pageSize: 500,
    fullResyncInterval: Duration(days: 7),
  ),
);

// 5. Start auto-sync
engine.startAuto(interval: Duration(minutes: 5));
```

### What Happens on the First Sync

On the first call to `sync()`:

1. `CursorService.getLastFullResync()` returns `null` (no cursors exist)
2. The condition `lastFullResync == null` triggers
3. `_doFullResync(reason: FullResyncReason.scheduled, clearData: false)` is automatically launched
4. Cursors are reset (there are none anyway) via `resetAll()`
5. Pull starts with `updatedSince = DateTime(0)` — all data is downloaded from the server
6. After completion, the `lastFullResync` timestamp is saved

---

## Manual Synchronization

### `sync()` — Full push + pull Cycle

```dart
Future<SyncStats> sync({Set<String>? kinds})
```

Performs a full synchronization cycle. Returns `SyncStats` with statistics.

**Without parameters — sync all tables:**

```dart
final stats = await engine.sync();
print('Pushed: ${stats.pushed}, pulled: ${stats.pulled}');
print('Conflicts: ${stats.conflicts}, resolved: ${stats.conflictsResolved}');
```

**With `kinds` parameter — selective sync:**

```dart
// Sync only todos
final stats = await engine.sync(kinds: {'todos'});

// Sync multiple types
final stats = await engine.sync(kinds: {'todos', 'projects'});
```

> Important: the `kinds` parameter only affects the pull phase. Push always sends all operations from the outbox.

### What Happens Inside `sync()`

```
sync()
  │
  ├─ Check: is full resync needed?
  │   lastFullResync == null ──► yes ──► _doFullResync()
  │   now - lastFullResync >= fullResyncInterval ──► yes ──► _doFullResync()
  │
  ├─ PUSH phase (SyncStarted(SyncPhase.push))
  │   │
  │   ├─ outbox.take(limit: pageSize)
  │   ├─ transport.push(ops) with exponential backoff
  │   ├─ For successful: outbox.ack(opIds)
  │   ├─ For conflicting: conflictService.resolve()
  │   └─ Loop until outbox is empty
  │
  ├─ PULL phase (SyncStarted(SyncPhase.pull))
  │   │
  │   ├─ For each kind:
  │   │   ├─ cursorService.get(kind) — get current cursor
  │   │   ├─ transport.pull(kind, updatedSince, pageSize)
  │   │   ├─ batch insert/replace into local DB
  │   │   ├─ cursorService.set(kind, newCursor)
  │   │   └─ Loop while nextPageToken exists or items.length == pageSize
  │   │
  │   └─ SyncProgress events on each page
  │
  └─ SyncCompleted(took, at, stats)
```

---

## Automatic Synchronization

### `startAuto()` — Periodic Sync

```dart
void startAuto({Duration interval = const Duration(minutes: 5)})
```

Starts a `Timer.periodic` that calls `sync()` at the specified interval.

```dart
// Sync every 5 minutes (default)
engine.startAuto();

// Sync every 30 seconds
engine.startAuto(interval: Duration(seconds: 30));

// Sync once an hour
engine.startAuto(interval: Duration(hours: 1));
```

> Calling `startAuto()` automatically cancels the previous timer (calls `stopAuto()` internally).

### `stopAuto()` — Stop Periodic Sync

```dart
void stopAuto()
```

Cancels the current automatic sync timer.

```dart
// Stop auto-sync
engine.stopAuto();
```

### When to Use Auto vs Manual

| Scenario | Recommendation |
|----------|---------------|
| Background app sync | `startAuto(interval: Duration(minutes: 5))` |
| After user action | `sync()` for immediate sync |
| Only specific tables | `sync(kinds: {'todos'})` |
| On network recovery | `sync()` manual call |
| On app launch | `sync()` once + `startAuto()` for background |

---

## Full Resync

### `fullResync()` — Full Resynchronization

```dart
Future<SyncStats> fullResync({bool clearData = false})
```

Resets all cursors and reloads all data from the server.

> **Important:** `fullResync()` does **not accept** a `kinds` parameter — it always resynchronizes **all** registered tables. For selective sync, use `sync(kinds: {'todos'})`.

### The `clearData` Parameter

- **`false` (default)** — Cursors are reset, but local data remains. Pull applies data on top of existing data via `insertOrReplace`. This is the safe mode that does not lose data.

- **`true`** — First clears all syncable tables (`DELETE FROM table`), then reloads all data from scratch. Use for a "clean start".

```dart
// Soft resync: data remains, cursors are reset
final stats = await engine.fullResync();

// Hard resync: full wipe and reload
final stats = await engine.fullResync(clearData: true);
```

### What Happens Inside `fullResync()`

```
fullResync()
  │
  ├─ FullResyncStarted(reason: manual | scheduled)
  │
  ├─ PUSH: send all operations from outbox
  │   (to avoid losing local changes)
  │
  ├─ cursorService.resetAll(allKinds)
  │   (reset all cursors for tables)
  │
  ├─ If clearData == true:
  │   └─ clearSyncableTables(tableNames)
  │
  ├─ PULL: load all data with updatedSince = epoch(0)
  │
  ├─ cursorService.setLastFullResync(DateTime.now())
  │
  └─ SyncCompleted(took, at, stats)
```

### `fullResyncInterval` in SyncConfig

```dart
const SyncConfig(
  fullResyncInterval: Duration(days: 7),  // default
)
```

This interval determines how often automatic full resynchronization is performed. On each `sync()` call:

1. `getLastFullResync()` is checked
2. If `null` or more than `fullResyncInterval` has elapsed — full resync is triggered automatically
3. Event reason: `FullResyncReason.scheduled`

```dart
// Full resync once a day
const SyncConfig(fullResyncInterval: Duration(days: 1))

// Full resync once a month
const SyncConfig(fullResyncInterval: Duration(days: 30))
```

---

## OutboxService (`engine.outbox`)

Service for managing the outgoing operations queue. Each local data modification is added to the outbox as an `Op` and waits to be sent to the server.

### `enqueue(Op op)` — Add an Operation to the Queue

```dart
Future<void> enqueue(Op op)
```

Adds an operation (upsert or delete) to the `sync_outbox` table. Uses `insertOnConflictUpdate` — re-enqueuing with the same `opId` updates the existing record.

```dart
// Upsert operation
await engine.outbox.enqueue(
  UpsertOp.create(
    kind: 'todos',
    id: todo.id,
    localTimestamp: DateTime.now(),
    payloadJson: todo.toJson(),
    baseUpdatedAt: todo.updatedAt, // null for a new record
    changedFields: {'title', 'done'}, // null = all fields
  ),
);

// Delete operation
await engine.outbox.enqueue(
  DeleteOp.create(
    kind: 'todos',
    id: todo.id,
    localTimestamp: DateTime.now(),
    baseUpdatedAt: todo.updatedAt,
  ),
);
```

### `take({int limit = 100})` — Get Operations for Sending

```dart
Future<List<Op>> take({int limit = 100})
```

Returns operations from the queue, sorted by `ts` (creation time). The `limit` parameter restricts the count.

```dart
// Get up to 100 operations (default)
final ops = await engine.outbox.take();

// Get the first 10 operations
final ops = await engine.outbox.take(limit: 10);
```

> `take()` does not remove operations from the queue. Use `ack()` for removal.

### `ack(Iterable<String> opIds)` — Acknowledge Delivery

```dart
Future<void> ack(Iterable<String> opIds)
```

Removes operations from the queue by their `opId`. Called after successful delivery to the server.

```dart
final ops = await engine.outbox.take();
// ... send to server ...
await engine.outbox.ack(ops.map((op) => op.opId));
```

If an empty list is passed, the method returns immediately without accessing the DB.

### `purgeOlderThan(DateTime threshold)` — Purge Old Operations

```dart
Future<int> purgeOlderThan(DateTime threshold)
```

Deletes all operations from the outbox with `ts <= threshold`. Returns the number of deleted rows.

```dart
// Delete operations older than 30 days
final deleted = await engine.outbox.purgeOlderThan(
  DateTime.now().subtract(Duration(days: 30)),
);
print('Deleted $deleted old operations');
```

### `hasOperations()` — Check for Pending Operations

```dart
Future<bool> hasOperations()
```

Checks whether there is at least one operation in the queue. Internally calls `take(limit: 1)`.

```dart
if (await engine.outbox.hasOperations()) {
  // There are unsent changes
  await engine.sync();
}
```

---

## CursorService (`engine.cursors`)

Service for managing sync cursors. A cursor is a `(ts, lastId)` pair that stores the position of the last received item for each entity type.

### The `Cursor` Model

```dart
class Cursor {
  const Cursor({required this.ts, required this.lastId});

  final DateTime ts;   // Timestamp of the last item
  final String lastId; // ID of the last item (for resolving ts collisions)
}
```

### `get(String kind)` — Get a Cursor

```dart
Future<Cursor?> get(String kind)
```

Returns the cursor for the specified entity type. `null` if no cursor exists (first sync).

```dart
final cursor = await engine.cursors.get('todos');
if (cursor != null) {
  print('Last sync: ${cursor.ts}');
  print('Last ID: ${cursor.lastId}');
}
```

### `set(String kind, Cursor cursor)` — Save a Cursor

```dart
Future<void> set(String kind, Cursor cursor)
```

Saves the cursor for an entity type. Uses `insertOnConflictUpdate` — creates a new one or updates the existing one.

```dart
await engine.cursors.set('todos', Cursor(
  ts: DateTime.now().toUtc(),
  lastId: 'last-entity-uuid',
));
```

### `reset(String kind)` — Reset a Cursor

```dart
Future<void> reset(String kind)
```

Resets the cursor for a single entity type to `ts = epoch(0), lastId = ''`. The next pull will load all data of this type.

```dart
// Reset only the cursor for todos
await engine.cursors.reset('todos');

// The next sync() will load all todos from the server
await engine.sync(kinds: {'todos'});
```

### `resetAll(Set<String> kinds)` — Reset Multiple Cursors

```dart
Future<void> resetAll(Set<String> kinds)
```

Deletes cursors for the specified entity types from the `sync_cursors` table. Unlike `reset()`, this does not create records with zero values but completely removes the rows.

```dart
// Reset cursors for todos and projects
await engine.cursors.resetAll({'todos', 'projects'});
```

> The service cursor `__full_resync__` is not included in `kinds` and is not reset by this method.

### `getLastFullResync()` — Time of the Last Full Resync

```dart
Future<DateTime?> getLastFullResync()
```

Returns the timestamp of the last full resync. Stored as a special cursor with `kind = '__full_resync__'`. Returns `null` if full resync has never been performed.

```dart
final lastResync = await engine.cursors.getLastFullResync();
if (lastResync == null) {
  print('Full resync has never been performed');
} else {
  print('Last full resync: $lastResync');
}
```

### `setLastFullResync(DateTime timestamp)` — Update Full Resync Time

```dart
Future<void> setLastFullResync(DateTime timestamp)
```

Saves the timestamp of the last full resync. Called automatically at the end of `_doFullResync()`.

```dart
// Usually no need to call manually
await engine.cursors.setLastFullResync(DateTime.now());
```

### When to Manage Cursors Manually

- **Reset a cursor for one type** — if data becomes inconsistent and a specific type needs to be reloaded
- **After schema migration** — if the table structure changed, reset the cursor and reload the data
- **Diagnostics** — check at which position the sync stopped

---

## Race Condition Protection

`SyncEngine` prevents concurrent execution of multiple syncs through a shared Future mechanism.

### How It Works

```dart
/// Current sync Future.
Future<SyncStats>? _syncFuture;

/// Current full resync Future.
Future<SyncStats>? _fullResyncFuture;

Future<SyncStats> sync({Set<String>? kinds}) {
  // If sync is already running, return the same Future
  if (_syncFuture != null) {
    return _syncFuture!;
  }

  _syncFuture = _doSync(kinds: kinds);
  return _syncFuture!.whenComplete(() => _syncFuture = null);
}
```

### What Happens with Concurrent Calls

```
Call 1: engine.sync()  ──► creates _syncFuture ──► push → pull ──► SyncStats
                                    │
Call 2: engine.sync()  ──► sees _syncFuture != null ──► awaits the same Future
                                    │
Call 3: engine.sync()  ──► sees _syncFuture != null ──► awaits the same Future
                                    │
                          whenComplete() ──► _syncFuture = null
                                    │
Call 4: engine.sync()  ──► _syncFuture == null ──► creates a new Future
```

All concurrent callers receive the same `SyncStats` result. This prevents:
- Duplicate sending of outbox operations
- Parallel pulls with identical cursors
- Unnecessary server load

The same mechanism works for `fullResync()` via a separate `_fullResyncFuture`.

---

## Event Stream (`engine.events`)

```dart
Stream<SyncEvent> get events => _events.stream;
```

A broadcast stream you can subscribe to for progress monitoring.

```dart
engine.events.listen((event) {
  switch (event) {
    case SyncStarted(:final phase):
      print('Phase started: $phase');
    case SyncProgress(:final phase, :final done, :final total):
      print('$phase: $done/$total');
    case SyncCompleted(:final took, :final stats):
      print('Sync completed in ${took.inMilliseconds}ms');
      print('Stats: $stats');
    case SyncErrorEvent(:final phase, :final error):
      print('Error in $phase: $error');
    case FullResyncStarted(:final reason):
      print('Full resync: $reason');
    case ConflictDetectedEvent(:final conflict, :final strategy):
      print('Conflict: ${conflict.kind}/${conflict.entityId}');
    case ConflictResolvedEvent(:final conflict, :final resolution):
      print('Conflict resolved: ${conflict.entityId} -> $resolution');
    case CacheUpdateEvent(:final kind, :final upserts, :final deletes):
      print('Update $kind: +$upserts, -$deletes');
    case OperationPushedEvent(:final kind, :final entityId, :final operationType):
      print('Pushed: $operationType $kind/$entityId');
    case OperationFailedEvent(:final kind, :final entityId, :final error, :final willRetry):
      print('Error $kind/$entityId: $error (retry: $willRetry)');
    default:
      break;
  }
});
```

### Event Types

| Event | When Emitted |
|-------|-------------|
| `SyncStarted(phase)` | Start of a push or pull phase |
| `SyncProgress(phase, done, total)` | After each pull page |
| `SyncCompleted(took, at, stats)` | Successful completion of sync or fullResync |
| `SyncErrorEvent(phase, error, stackTrace)` | Error during synchronization |
| `FullResyncStarted(reason)` | Start of a full resynchronization |
| `ConflictDetectedEvent(conflict, strategy)` | Data conflict detected |
| `ConflictResolvedEvent(conflict, resolution, resultData)` | Conflict resolved |
| `ConflictUnresolvedEvent(conflict, reason)` | Conflict could not be resolved |
| `DataMergedEvent(kind, entityId, ...)` | Data was merged |
| `CacheUpdateEvent(kind, upserts, deletes)` | Local cache updated |
| `OperationPushedEvent(opId, kind, entityId, operationType)` | Operation successfully pushed |
| `OperationFailedEvent(opId, kind, entityId, error, willRetry)` | Operation failed |

---

## Dispose

### `engine.dispose()`

```dart
void dispose() {
  stopAuto();       // Cancels the auto-sync Timer
  _events.close();  // Closes the event StreamController
}
```

The `dispose()` method:

1. Calls `stopAuto()` — cancels the periodic timer
2. Closes the `_events` StreamController — all subscribers receive `done`

**When to call:**

- On application shutdown
- On user logout
- When switching to a different database
- In the `dispose()` method of the widget that owns the `SyncEngine`

```dart
@override
void dispose() {
  engine.dispose();
  super.dispose();
}
```

> `dispose()` does not close the database (`db`) and does not cancel a currently running `sync()`. If you need to wait for sync completion, do so before calling `dispose()`.

---

## SyncConfig — Configuration

```dart
const SyncConfig({
  int pageSize = 500,                                  // Page size for pull
  Duration backoffMin = Duration(seconds: 1),          // Min retry delay
  Duration backoffMax = Duration(minutes: 2),          // Max retry delay
  double backoffMultiplier = 2.0,                      // Exponential backoff multiplier
  int maxPushRetries = 5,                              // Max push attempts
  Duration fullResyncInterval = Duration(days: 7),     // Full resync interval
  bool pullOnStartup = false,                          // Pull on startup
  bool pushImmediately = true,                         // Push immediately
  Duration? reconcileInterval,                         // Data reconciliation interval
  bool lazyReconcileOnMiss = false,                    // Lazy reconciliation on miss
  ConflictStrategy conflictStrategy = ConflictStrategy.autoPreserve,  // Conflict strategy
  ConflictResolver? conflictResolver,                  // Callback for manual strategy
  MergeFunction? mergeFunction,                        // Merge function
  int maxConflictRetries = 3,                          // Max conflict resolution attempts
  Duration conflictRetryDelay = Duration(milliseconds: 500),  // Delay between attempts
  bool skipConflictingOps = false,                     // Skip unresolved conflicts
})
```

---

## Complete Lifecycle Example

```dart
import 'dart:io';
import 'package:drift/native.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

// 1. Create the database
final db = AppDatabase(
  NativeDatabase.createInBackground(File('app.db')),
);

// 2. Create the transport
final transport = MyRestTransport(
  baseUrl: 'https://api.example.com',
  authToken: userToken,
);

// 3. Create SyncEngine
final engine = SyncEngine(
  db: db,
  transport: transport,
  tables: [
    SyncableTable<Todo>(
      kind: 'todos',
      table: db.todos,
      fromJson: Todo.fromJson,
      toJson: (t) => t.toJson(),
      toInsertable: (t) => t.toInsertable(),
    ),
    SyncableTable<Project>(
      kind: 'projects',
      table: db.projects,
      fromJson: Project.fromJson,
      toJson: (p) => p.toJson(),
      toInsertable: (p) => p.toInsertable(),
    ),
  ],
  config: const SyncConfig(
    pageSize: 200,
    fullResyncInterval: Duration(days: 7),
    maxPushRetries: 3,
    conflictStrategy: ConflictStrategy.autoPreserve,
  ),
);

// 4. Subscribe to events
final subscription = engine.events.listen((event) {
  switch (event) {
    case SyncCompleted(:final stats):
      if (stats != null) {
        print('Sync: +${stats.pushed}/-${stats.pulled} '
              'conflicts: ${stats.conflicts}');
      }
    case SyncErrorEvent(:final error):
      print('Sync error: $error');
    default:
      break;
  }
});

// 5. First sync (triggers fullResync since lastFullResync == null)
await engine.sync();

// 6. Start auto-sync
engine.startAuto(interval: Duration(minutes: 5));

// 7. Application work: adding data
await engine.outbox.enqueue(
  UpsertOp.create(
    kind: 'todos',
    id: newTodo.id,
    localTimestamp: DateTime.now(),
    payloadJson: newTodo.toJson(),
  ),
);

// 8. Immediate sync after user action
await engine.sync();

// 9. If needed — full resync
await engine.fullResync(clearData: true);

// 10. Shutdown
subscription.cancel();
engine.dispose();
await db.close();
```
