# Troubleshooting & FAQ

Diagnostics and solutions for common `offline_first_sync_drift` issues.

---

## 1. build_runner Errors / "Missing implementations"

**Symptoms:** `Missing concrete implementations of ...`, `*.g.dart` files not found.

**Solution:**

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

Check dependencies (`drift: ^2.26.1`, `drift_dev: ^2.26.1`, `build_runner: ^2.4.15`) and the DB class:

```dart
// @DriftDatabase + part '*.g.dart':
class AppDatabase extends _$AppDatabase with SyncDatabaseMixin { ... }
//                       ^ With underscore

// .drift files:
class AppDatabase extends $AppDatabase with SyncDatabaseMixin { ... }
//                       ^ Without underscore
```

---

## 2. "SyncOutbox table not found" / "SyncCursors table not found"

**Cause:** `sync_tables.drift` is not included.

**Solution:** Add `include` to `@DriftDatabase`:

```dart
@DriftDatabase(
  tables: [Todos],
  include: {'package:offline_first_sync_drift/src/sync_tables.drift'},
)
class AppDatabase extends _$AppDatabase with SyncDatabaseMixin { ... }
```

Rebuild: `dart run build_runner build --delete-conflicting-outputs`

---

## 3. Sync Works but Data Does Not Appear in UI

**Cause 1:** `deletedAt` is not filtered. The `SyncColumns` mixin adds `updatedAt`, `deletedAt`, `deletedAtLocal`. During pull, records with `deletedAt != null` are inserted into the DB but marked as deleted.

```dart
// Wrong:
select(todos).get();
// Correct:
(select(todos)..where((t) => t.deletedAt.isNull())).get();
```

**Cause 2:** Incorrect `fromJson`. It must parse all fields, including `updatedAt` and `deletedAt`.

**Cause 3:** The server returns data without `updatedAt` (or `updated_at`) and `id`. `PullService` will throw a `ParseException` if these fields are missing.

---

## 4. Conflicts Occur Constantly

**Cause 1:** Incorrect `baseUpdatedAt`. This is the record's timestamp at the last known state. The server compares it with the current `updatedAt` and returns 409 on mismatch.

```dart
final op = UpsertOp.create(
  kind: 'todos',
  id: todo.id,
  localTimestamp: DateTime.now().toUtc(),
  payloadJson: todo.toJson(),
  baseUpdatedAt: todo.updatedAt, // current updatedAt from local DB
);
```

**Cause 2:** The server updates `updatedAt` even without actual changes.

**Cause 3:** Timezone mismatch. All timestamps must be in UTC.

---

## 5. MaxRetriesExceededException

**Dual retry architecture:**

1. **RestTransport._withRetry()** -- retries HTTP requests on 429, 5xx, and network errors. `maxRetries` (5), `backoffMin` (1 sec), `backoffMax` (2 min).
2. **PushService._pushBatch()** -- retries the batch on transport exceptions. `maxPushRetries` (5) from `SyncConfig`.

In the worst case, a single operation is retried up to `maxRetries * maxPushRetries` times.

**Solution:**

```dart
final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer $token',
  maxRetries: 10,
  backoffMax: Duration(minutes: 5),
);

final engine = SyncEngine(
  db: database, transport: transport, tables: [...],
  config: SyncConfig(maxPushRetries: 10),
);
```

Check the server: `await transport.health()` (GET `/health` -> 2xx).

---

## 6. Data Gets Duplicated

**Cause 1:** No primary key defined. `PullService` uses `InsertMode.insertOrReplace` -- without a PK, each pull creates a new record.

```dart
class Todos extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get title => text()();

  @override
  Set<Column> get primaryKey => {id};  // required
}
```

**Cause 2:** `id` is regenerated on the client for each operation instead of using a stable identifier.

**Cause 3:** `opId` is not unique. Use UUID for each operation.

---

## 7. Outbox Grows Indefinitely

**Cause 1:** The server returns errors. `ackOutbox()` is only called for successful operations.

Diagnostics:

```dart
engine.events.listen((event) {
  if (event is OperationFailedEvent) {
    print('Failed: ${event.kind}/${event.entityId}, error: ${event.error}');
  }
});
```

**Cause 2:** Conflicts are not resolved, `skipConflictingOps = false` (default).

```dart
SyncConfig(
  skipConflictingOps: true,  // remove unresolved from outbox
  // or
  conflictStrategy: ConflictStrategy.serverWins,
)
```

**Manual cleanup:**

```dart
await db.purgeOutboxOlderThan(DateTime.now().subtract(Duration(days: 7)));
```

---

## 8. fullResync() Is Slow

`fullResync()` does not accept a `kinds` parameter -- all tables are synced. Sequence: push outbox -> reset cursors -> optionally clear tables -> pull all data from scratch.

**Tuning pageSize:**

```dart
SyncConfig(pageSize: 1000)  // default is 500; reduce for low-end devices
```

**Server-side optimization:**
- Index on `(updated_at, id)` for the pull endpoint
- Cursor-based pagination via `nextPageToken`
- gzip response compression

**Run frequency:** Default `fullResyncInterval: Duration(days: 7)`. When calling `sync()`, full resync is triggered automatically if the interval has elapsed.

```dart
SyncConfig(fullResyncInterval: Duration(days: 30))
```

---

## 9. Schema Migration with Sync Tables

Tables `sync_outbox` and `sync_cursors` are created by Drift via `include` during `onCreate`. On subsequent migrations they already exist.

```dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async => await m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.createTable(projects);
      // sync_outbox and sync_cursors already exist since version 1
    }
  },
);
```

After changing the structure of a synced table, it is recommended to call `fullResync(clearData: true)`.

---

## 10. Multiple Databases / Multiple SyncEngines

Each DB has its own `sync_outbox` / `sync_cursors`. They are isolated.

```dart
// Two independent DBs:
class TodoDatabase extends _$TodoDatabase with SyncDatabaseMixin { ... }
class ChatDatabase extends _$ChatDatabase with SyncDatabaseMixin { ... }

// Two engines with different transports:
final todoEngine = SyncEngine(db: todoDb, transport: todoTransport, tables: [todoTable]);
final chatEngine = SyncEngine(db: chatDb, transport: chatTransport, tables: [msgTable]);
```

For a single DB with different servers -- use one SyncEngine with a custom `TransportAdapter` that routes requests by `kind`.

---

## 11. Memory Issues

**Large pageSize:** Each pull page is loaded entirely into memory and inserted as a batch.

```dart
SyncConfig(pageSize: 50)  // for memory-constrained devices
```

**Many tables:** `pullKinds()` processes sequentially, but cumulative consumption grows. Use `sync(kinds: {'todos'})` for selective sync.

**`dispose()` leak:** `SyncEngine` contains `StreamController.broadcast()`. Always call `engine.dispose()`.

**Large outbox:** Monitor size, clean up via `purgeOutboxOlderThan()`.

---

## Diagnostics via Events

```dart
engine.events.listen((event) {
  switch (event) {
    case SyncStarted():       print('Started: ${event.phase}');
    case SyncProgress():      print('Progress: ${event.done}/${event.total}');
    case SyncCompleted():     print('Done in ${event.took.inMilliseconds}ms');
    case SyncErrorEvent():    print('Error: ${event.error}');
    case ConflictDetectedEvent(): print('Conflict: ${event.conflict}');
    case OperationFailedEvent():  print('Failed: ${event.kind}/${event.entityId}');
    default: break;
  }
});
```

---

## Exception Table

| Exception | When It Occurs |
|---|---|
| `NetworkException` | Server unreachable, timeout |
| `TransportException` | Invalid HTTP response (`statusCode`) |
| `DatabaseException` | Error writing to local DB |
| `ConflictException` | Unresolved conflict (`kind`, `entityId`) |
| `MaxRetriesExceededException` | Retry limit exceeded (`attempts`, `maxRetries`) |
| `ParseException` | JSON parsing error |
| `SyncOperationException` | General sync error (`phase`) |

```dart
try {
  await engine.sync();
} on MaxRetriesExceededException catch (e) {
  print('Server unavailable after ${e.attempts} attempts');
} on NetworkException catch (e) {
  print('Network: ${e.message}');
} on SyncException catch (e) {
  print('Sync error: $e');
}
```
