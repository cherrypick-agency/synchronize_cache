# Quick Start

## Installation

```yaml
# pubspec.yaml
dependencies:
  drift: ^2.26.1
  offline_first_sync_drift: ^0.1.1
  offline_first_sync_drift_rest: ^0.1.1
  http: ^1.4.0

dev_dependencies:
  drift_dev: ^2.26.1
  build_runner: ^2.4.15
```

Run:

```bash
dart pub get
```

## Table Definition

Create a Drift table and apply the `SyncColumns` mixin, which adds the `updatedAt`, `deletedAt`, and `deletedAtLocal` fields:

```dart
import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

class Todos extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get title => text()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

`SyncColumns` adds:
- `updatedAt` -- `DateTimeColumn`, last update timestamp (UTC)
- `deletedAt` -- `DateTimeColumn?`, server-side deletion timestamp
- `deletedAtLocal` -- `DateTimeColumn?`, local deletion timestamp

## Database Setup

Apply `SyncDatabaseMixin` and include the sync tables via `include`:

```dart
import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Todos],
  include: {'package:offline_first_sync_drift/src/sync_tables.drift'},
)
class AppDatabase extends _$AppDatabase with SyncDatabaseMixin {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}
```

`include` adds the system tables `sync_outbox` and `sync_cursors`. `SyncDatabaseMixin` provides the `enqueue(Op)` method for queuing operations.

Generate code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Registering Tables for Sync

`SyncableTable` binds a Drift table to server serialization:

```dart
final todoSync = SyncableTable<Todo>(
  kind: 'todos',
  table: db.todos,
  fromJson: (json) => Todo.fromJson(json),
  toJson: (todo) => todo.toJson(),
  toInsertable: (todo) => todo.toInsertable(),
);
```

`SyncableTable` parameters:

| Parameter | Type | Required | Description |
|---|---|---|---|
| `kind` | `String` | yes | Entity name on the server |
| `table` | `TableInfo<Table, T>` | yes | Drift table |
| `fromJson` | `T Function(Map<String, dynamic>)` | yes | Deserialization from server JSON |
| `toJson` | `Map<String, dynamic> Function(T)` | yes | Serialization to JSON for the server |
| `toInsertable` | `Insertable<T> Function(T)?` | no | Conversion to `Insertable` for DB writes |
| `getId` | `String Function(T)?` | no | Get entity ID (defaults to `id` field) |
| `getUpdatedAt` | `DateTime Function(T)?` | no | Get `updatedAt` (defaults to `updatedAt` field) |

## Creating a SyncEngine

```dart
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';
import 'package:offline_first_sync_drift_rest/offline_first_sync_drift_rest.dart';

final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer ${await getAuthToken()}',
);

final engine = SyncEngine(
  db: db,
  transport: transport,
  tables: [todoSync],
);
```

### SyncEngine Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `db` | `GeneratedDatabase` | -- | Database with `SyncDatabaseMixin` |
| `transport` | `TransportAdapter` | -- | Transport (e.g., `RestTransport`) |
| `tables` | `List<SyncableTable>` | -- | List of tables to sync |
| `config` | `SyncConfig` | `SyncConfig()` | Sync configuration |
| `tableConflictConfigs` | `Map<String, TableConflictConfig>?` | `null` | Per-table conflict strategies |

### RestTransport Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `base` | `Uri` | -- | Base API URL |
| `token` | `Future<String> Function()` | -- | Auth token provider |
| `client` | `http.Client?` | `http.Client()` | HTTP client |
| `pushConcurrency` | `int` | `1` | Push request concurrency |
| `enableBatch` | `bool` | `false` | Enable batch API |
| `batchSize` | `int` | `100` | Max operations per batch request |
| `maxRetries` | `int` | `5` | Max retry count |

## Working with Data

### Reading

Use standard Drift queries:

```dart
// All non-deleted records
final todos = await (db.select(db.todos)
  ..where((t) => t.deletedAt.isNull()))
  .get();

// Single record by ID
final todo = await (db.select(db.todos)
  ..where((t) => t.id.equals(todoId)))
  .getSingleOrNull();

// Reactive stream
final stream = (db.select(db.todos)
  ..where((t) => t.deletedAt.isNull()))
  .watch();
```

### Creating

Insert a record into the DB and enqueue an `UpsertOp`:

```dart
import 'package:uuid/uuid.dart';

final todoId = const Uuid().v4();
final now = DateTime.now().toUtc();

await db.into(db.todos).insert(
  TodosCompanion.insert(
    id: todoId,
    title: 'Buy milk',
    updatedAt: now,
  ),
);

await db.enqueue(
  UpsertOp.create(
    kind: 'todos',
    id: todoId,
    localTimestamp: now,
    payloadJson: {
      'id': todoId,
      'title': 'Buy milk',
      'completed': false,
    },
  ),
);
```

### Updating

When updating, pass `baseUpdatedAt` -- the record's timestamp before editing. This enables conflict detection:

```dart
final now = DateTime.now().toUtc();

await (db.update(db.todos)..where((t) => t.id.equals(todoId))).write(
  TodosCompanion(
    title: const Value('Buy oat milk'),
    updatedAt: Value(now),
  ),
);

await db.enqueue(
  UpsertOp.create(
    kind: 'todos',
    id: todoId,
    localTimestamp: now,
    payloadJson: {
      'id': todoId,
      'title': 'Buy oat milk',
      'completed': false,
    },
    baseUpdatedAt: todo.updatedAt,
    changedFields: {'title'},
  ),
);
```

`changedFields` -- the set of fields the user changed. Used during merge conflicts to avoid overwriting fields that were not modified.

### Deleting

```dart
await db.enqueue(
  DeleteOp.create(
    kind: 'todos',
    id: todoId,
    baseUpdatedAt: todo.updatedAt,
  ),
);
```

Physical deletion from the local DB happens during pull -- the server returns a record with a populated `deletedAt`.

### Less boilerplate (optional)

If you already have a typed entity and a `SyncableTable<T>`, you can use the writer helpers:

```dart
final writer = db.syncWriter().forTable(todoSync);

await writer.insertAndEnqueue(todo);
await writer.replaceAndEnqueue(
  updated,
  baseUpdatedAt: todo.updatedAt,
  changedFields: {'title'},
);
```

## Synchronization

### Manual Sync

```dart
final stats = await engine.sync();
print('Pushed: ${stats.pushed}, Pulled: ${stats.pulled}');
```

`sync()` performs push (sending from outbox), then pull (fetching from server). Concurrent calls share the same `Future`.

### Sync by Type

```dart
final stats = await engine.sync(kinds: {'todos'});
```

### Automatic Sync

```dart
engine.startAuto(interval: const Duration(minutes: 5));

// Stop
engine.stopAuto();
```

### Full Resync

Resets cursors and re-fetches all data:

```dart
final stats = await engine.fullResync();

// With local data clearing
final stats = await engine.fullResync(clearData: true);
```

### Event Monitoring

```dart
engine.events.listen((event) {
  switch (event) {
    case SyncStarted():
      print('Sync started: ${event.phase}');
    case SyncCompleted():
      print('Sync done in ${event.took.inMilliseconds}ms');
    case SyncErrorEvent():
      print('Sync error: ${event.error}');
    case ConflictDetectedEvent():
      print('Conflict: ${event.conflict.kind}/${event.conflict.entityId}');
    case ConflictResolvedEvent():
      print('Resolved: ${event.resolution.runtimeType}');
    case _:
      break;
  }
});
```

Event types: `SyncStarted`, `SyncProgress`, `SyncCompleted`, `SyncErrorEvent`, `FullResyncStarted`, `ConflictDetectedEvent`, `ConflictResolvedEvent`, `ConflictUnresolvedEvent`, `DataMergedEvent`, `CacheUpdateEvent`, `OperationPushedEvent`, `OperationFailedEvent`.

### Resource Cleanup

```dart
engine.dispose();
```

Call `dispose()` on shutdown -- it stops auto-sync and closes the stream controller.

## Full Example

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';
import 'package:offline_first_sync_drift_rest/offline_first_sync_drift_rest.dart';
import 'package:uuid/uuid.dart';

part 'main.g.dart';

// 1. Table
class Todos extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get title => text()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// 2. Database
@DriftDatabase(
  tables: [Todos],
  include: {'package:offline_first_sync_drift/src/sync_tables.drift'},
)
class AppDatabase extends _$AppDatabase with SyncDatabaseMixin {
  AppDatabase() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

Future<void> main() async {
  final db = AppDatabase();

  // 3. Transport
  final transport = RestTransport(
    base: Uri.parse('https://api.example.com'),
    token: () async => 'Bearer my-token',
  );

  // 4. SyncEngine
  final engine = SyncEngine(
    db: db,
    transport: transport,
    tables: [
      SyncableTable<Todo>(
        kind: 'todos',
        table: db.todos,
        fromJson: (json) => Todo.fromJson(json),
        toJson: (t) => t.toJson(),
        toInsertable: (t) => t.toInsertable(),
      ),
    ],
  );

  // 5. Monitoring
  engine.events.listen((e) => print(e));

  // 6. Creating a record
  const uuid = Uuid();
  final todoId = uuid.v4();
  final now = DateTime.now().toUtc();

  await db.into(db.todos).insert(
    TodosCompanion.insert(
      id: todoId,
      title: 'Buy milk',
      updatedAt: now,
    ),
  );

  await db.enqueue(UpsertOp(
    opId: uuid.v4(),
    kind: 'todos',
    id: todoId,
    localTimestamp: now,
    payloadJson: {
      'id': todoId,
      'title': 'Buy milk',
      'completed': false,
    },
  ));

  // 7. Sync
  final stats = await engine.sync();
  print('Pushed: ${stats.pushed}, Pulled: ${stats.pulled}');

  // 8. Auto-sync
  engine.startAuto(interval: const Duration(minutes: 5));

  // 9. Don't forget on shutdown
  engine.dispose();
  await db.close();
}
```
