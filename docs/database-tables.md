---
sidebar_position: 2
---
# Database and Tables

Guide to configuring a Drift database for synchronization:
system tables, user tables with `SyncColumns`, `SyncableTable` configuration,
and migrations.

---

## SyncDatabaseMixin

`SyncDatabaseMixin` is a mixin that adds all methods for working with the outbox
and sync cursors to your Drift database.

### Setup

Two required steps:

1. In the `@DriftDatabase` annotation, add `include` with the system tables file.
2. Add `with SyncDatabaseMixin` to the database class.

```dart
import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

part 'app_database.g.dart';

@DriftDatabase(
  include: {'package:offline_first_sync_drift/src/sync_tables.drift'},
  tables: [Todos, Categories],
)
class AppDatabase extends _$AppDatabase with SyncDatabaseMixin {
  AppDatabase(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;
}
```

> `sync_tables.drift` imports the `SyncOutbox` and `SyncCursors` tables
> from the package. Drift will automatically create them during code generation.

### SyncDatabaseMixin Methods

| Method | Signature | Description |
|---|---|---|
| `enqueue` | `Future<void> enqueue(Op op)` | Add an operation (upsert/delete) to the send queue |
| `takeOutbox` | `Future<List<Op>> takeOutbox({int limit = 100})` | Get operations from the queue, sorted by timestamp |
| `ackOutbox` | `Future<void> ackOutbox(Iterable<String> opIds)` | Acknowledge delivery — remove operations from the queue by `opId` |
| `getCursor` | `Future<Cursor?> getCursor(String kind)` | Get the sync cursor for an entity type |
| `setCursor` | `Future<void> setCursor(String kind, Cursor cursor)` | Save a sync cursor |
| `purgeOutboxOlderThan` | `Future<int> purgeOutboxOlderThan(DateTime threshold)` | Delete old operations from the outbox |
| `resetAllCursors` | `Future<void> resetAllCursors(Set<String> kinds)` | Reset cursors for the specified entity types |
| `clearSyncableTables` | `Future<void> clearSyncableTables(List<String> tableNames)` | Clear data from syncable tables |

### Example: Adding an Operation to the Outbox

```dart
final db = AppDatabase(executor);

// Upsert operation
await db.enqueue(
  UpsertOp.create(
    kind: 'todos',
    id: 'todo-1',
    payloadJson: {'id': 'todo-1', 'title': 'Buy milk', 'completed': false},
    baseUpdatedAt: existingTodo.updatedAt, // null for a new record
    changedFields: {'title', 'completed'},
    // Optional overrides:
    opId: 'op-uuid-1',
    localTimestamp: DateTime.now().toUtc(),
  ),
);

// Delete operation
await db.enqueue(
  DeleteOp.create(
    kind: 'todos',
    id: 'todo-1',
    baseUpdatedAt: existingTodo.updatedAt,
    // Optional overrides:
    opId: 'op-uuid-2',
    localTimestamp: DateTime.now().toUtc(),
  ),
);
```

---

## SyncColumns Mixin

`SyncColumns` is a mixin for Drift tables that adds required
system synchronization fields.

### Fields

| Field | Type | Nullable | Description |
|---|---|---|---|
| `updatedAt` | `DateTimeColumn` | No | Last update time (UTC) |
| `deletedAt` | `DateTimeColumn` | Yes | Server deletion time (UTC), `null` if not deleted |
| `deletedAtLocal` | `DateTimeColumn` | Yes | Local deletion time for deferred cleanup |

### SynchronizableTable Interface

`SyncColumns` implements the `SynchronizableTable` marker interface,
which guarantees the presence of all three fields:

```dart
abstract interface class SynchronizableTable {
  DateTimeColumn get updatedAt;
  DateTimeColumn get deletedAt;
  DateTimeColumn get deletedAtLocal;
}
```

### Usage

```dart
@UseRowClass(Todo, generateInsertable: true)
class Todos extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get title => text()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

The `Todos` table will have columns: `id`, `title`, `completed`, `updated_at`,
`deleted_at`, `deleted_at_local`. You only need to define your own
business fields — the system fields are added automatically via the mixin.

### Multiple Tables with SyncColumns

```dart
@UseRowClass(Todo, generateInsertable: true)
class Todos extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get title => text()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@UseRowClass(Category, generateInsertable: true)
class Categories extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get color => text().withDefault(const Constant('#000000'))();

  @override
  Set<Column> get primaryKey => {id};
}

@UseRowClass(Tag, generateInsertable: true)
class Tags extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get label => text()();

  @override
  Set<Column> get primaryKey => {id};
}
```

---

## System Tables

The library uses two system tables, included via `sync_tables.drift`.

### SyncOutbox

Queue of local operations waiting to be sent to the server.

| Column | SQL Type | Dart Type | Description |
|---|---|---|---|
| `op_id` | TEXT PK | `String` | Unique operation UUID (for idempotency) |
| `kind` | TEXT | `String` | Entity type (e.g., `'todos'`) |
| `entity_id` | TEXT | `String` | Entity ID |
| `op` | TEXT | `String` | Operation type: `'upsert'` or `'delete'` |
| `payload` | TEXT? | `String?` | JSON payload for upsert operations |
| `ts` | INTEGER | `int` | Operation timestamp (milliseconds UTC) |
| `try_count` | INTEGER | `int` | Number of send attempts (default 0) |
| `base_updated_at` | INTEGER? | `int?` | Timestamp of data received from server (for conflict detection) |
| `changed_fields` | TEXT? | `String?` | JSON array of changed field names |

Table definition (`outbox.dart`):

```dart
@UseRowClass(SyncOutboxData)
class SyncOutbox extends Table {
  TextColumn get opId => text()();
  TextColumn get kind => text()();
  TextColumn get entityId => text()();
  TextColumn get op => text()();
  TextColumn get payload => text().nullable()();
  IntColumn get ts => integer()();
  IntColumn get tryCount => integer().withDefault(const Constant(0))();
  IntColumn get baseUpdatedAt => integer().nullable()();
  TextColumn get changedFields => text().nullable()();

  @override
  Set<Column> get primaryKey => {opId};

  @override
  String get tableName => 'sync_outbox';
}
```

### SyncCursors

Stores the last synchronization position (cursor-based pagination).

| Column | SQL Type | Dart Type | Description |
|---|---|---|---|
| `kind` | TEXT PK | `String` | Entity type |
| `ts` | INTEGER | `int` | Timestamp of the last received item (milliseconds UTC) |
| `last_id` | TEXT | `String` | ID of the last item (for resolving collisions with identical ts) |

Table definition (`cursors.dart`):

```dart
@UseRowClass(SyncCursorData)
class SyncCursors extends Table {
  TextColumn get kind => text()();
  IntColumn get ts => integer()();
  TextColumn get lastId => text()();

  @override
  Set<Column> get primaryKey => {kind};

  @override
  String get tableName => 'sync_cursors';
}
```

### Cursor — Cursor Model

```dart
class Cursor {
  const Cursor({required this.ts, required this.lastId});

  final DateTime ts;
  final String lastId;
}
```

The cursor stores a `(ts, lastId)` pair for stable pagination during pull.
This allows correct handling of situations where multiple records
have the same `updatedAt`.

---

## Op — Outbox Operations

`Op` is a sealed class describing an outbox operation. Two subtypes:

### UpsertOp

Creating or updating an entity:

```dart
class UpsertOp extends Op {
  final Map<String, Object?> payloadJson;  // JSON to send to the server
  final DateTime? baseUpdatedAt;           // null = new record
  final Set<String>? changedFields;        // null = all fields changed

  bool get isNewRecord => baseUpdatedAt == null;
}
```

### DeleteOp

Deleting an entity:

```dart
class DeleteOp extends Op {
  final DateTime? baseUpdatedAt;  // Timestamp of data from server
}
```

### Common Op Fields

| Field | Type | Description |
|---|---|---|
| `opId` | `String` | UUID for idempotency |
| `kind` | `String` | Entity type |
| `id` | `String` | Entity ID |
| `localTimestamp` | `DateTime` | Operation creation time |

---

## `SyncableTable<T>` — Syncable Table Configuration

`SyncableTable<T>` is a configuration that links a Drift table
to the server. Registered in `SyncEngine`.

### Constructor Parameters

```dart
class SyncableTable<T> {
  const SyncableTable({
    required this.kind,
    required this.table,
    required this.fromJson,
    required this.toJson,
    this.toInsertable,
    this.getId,
    this.getUpdatedAt,
  });
}
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `kind` | `String` | Yes | Entity name on the server (e.g., `'todos'`) |
| `table` | `TableInfo<Table, T>` | Yes | Drift table |
| `fromJson` | `T Function(Map<String, dynamic>)` | Yes | Create an object from server JSON |
| `toJson` | `Map<String, dynamic> Function(T)` | Yes | Serialize an object to JSON for the server |
| `toInsertable` | `Insertable<T> Function(T)?` | No | Convert entity to `Insertable` for DB writes |
| `getId` | `String Function(T)?` | No | Get entity ID (defaults to looking for `.id` field) |
| `getUpdatedAt` | `DateTime Function(T)?` | No | Get `updatedAt` (defaults to looking for `.updatedAt` field) |

### When toInsertable Is Needed

If the data model `T` does not implement `Insertable<T>`, you must provide
`toInsertable`. Typical case — using `@UseRowClass(T, generateInsertable: true)`:

```dart
SyncableTable<Todo>(
  kind: 'todos',
  table: db.todos,
  fromJson: Todo.fromJson,
  toJson: (t) => t.toJson(),
  toInsertable: (t) => t.toInsertable(), // Drift-generated method
)
```

If `T` implements `Insertable<T>` directly, `toInsertable` can be omitted —
the `getInsertable()` method will cast `entity as Insertable<T>`:

```dart
Insertable<T> getInsertable(T entity) {
  if (toInsertable != null) {
    return toInsertable!(entity);
  }
  return entity as Insertable<T>;
}
```

### Custom getId / getUpdatedAt

By default, the library expects the object `T` to have `id` and `updatedAt` fields.
If your model uses different names:

```dart
SyncableTable<Note>(
  kind: 'notes',
  table: db.notes,
  fromJson: Note.fromJson,
  toJson: (n) => n.toJson(),
  toInsertable: (n) => n.toInsertable(),
  getId: (n) => n.noteUuid,       // Custom ID field name
  getUpdatedAt: (n) => n.modifiedAt, // Custom timestamp field name
)
```

---

## Constants (constants.dart)

The library defines three groups of constants for uniform name access.

### OpType — Operation Types

```dart
abstract final class OpType {
  static const upsert = 'upsert';
  static const delete = 'delete';
}
```

### SyncFields — Field Names for JSON Serialization

```dart
abstract final class SyncFields {
  // ID fields
  static const id = 'id';
  static const idUpper = 'ID';
  static const uuid = 'uuid';

  // Timestamp fields (camelCase)
  static const updatedAt = 'updatedAt';
  static const createdAt = 'createdAt';
  static const deletedAt = 'deletedAt';

  // Timestamp fields (snake_case)
  static const updatedAtSnake = 'updated_at';
  static const createdAtSnake = 'created_at';
  static const deletedAtSnake = 'deleted_at';

  // Lookup across multiple variants
  static const idFields = [id, idUpper, uuid];
  static const updatedAtFields = [updatedAt, updatedAtSnake];
  static const deletedAtFields = [deletedAt, deletedAtSnake];
}
```

### TableColumns — SQL Column Names (snake_case)

```dart
abstract final class TableColumns {
  static const opId = 'op_id';
  static const kind = 'kind';
  static const entityId = 'entity_id';
  static const op = 'op';
  static const payload = 'payload';
  static const ts = 'ts';
  static const tryCount = 'try_count';
  static const baseUpdatedAt = 'base_updated_at';
  static const changedFields = 'changed_fields';
  static const lastId = 'last_id';
}
```

### TableNames — Table Names

```dart
abstract final class TableNames {
  static const syncOutbox = 'sync_outbox';
  static const syncCursors = 'sync_cursors';
}
```

### CursorKinds — Special Cursor Values

```dart
abstract final class CursorKinds {
  static const fullResync = '__full_resync__';
}
```

---

## Field Name Mapping

The library automatically searches for fields across multiple name variants
to support different server JSON formats.

### ID Fields

The server may send the ID in one of these formats:

| JSON Key | Dart Field | Description |
|---|---|---|
| `id` | `id` | Standard variant |
| `ID` | `id` | Upper case |
| `uuid` | `id` | UUID format |

Lookup order: `id` -> `ID` -> `uuid`.

### Timestamp Fields

| JSON Key | Dart Field | Format |
|---|---|---|
| `updatedAt` | `updatedAt` | camelCase |
| `updated_at` | `updatedAt` | snake_case |
| `createdAt` | `createdAt` | camelCase |
| `created_at` | `createdAt` | snake_case |
| `deletedAt` | `deletedAt` | camelCase |
| `deleted_at` | `deletedAt` | snake_case |

### Example fromJson with Mapping

```dart
factory Todo.fromJson(Map<String, dynamic> json) => Todo(
  id: json['id'] as String,
  title: json['title'] as String,
  completed: json['completed'] as bool,
  updatedAt: DateTime.parse(json['updated_at'] as String),
  deletedAt: json['deleted_at'] != null
      ? DateTime.parse(json['deleted_at'] as String)
      : null,
  deletedAtLocal: json['deleted_at_local'] != null
      ? DateTime.parse(json['deleted_at_local'] as String)
      : null,
);
```

---

## Multi-Table Synchronization

### Registering Multiple SyncableTables

Pass a list of `SyncableTable` to `SyncEngine`:

```dart
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
    SyncableTable<Category>(
      kind: 'categories',
      table: db.categories,
      fromJson: Category.fromJson,
      toJson: (c) => c.toJson(),
      toInsertable: (c) => c.toInsertable(),
    ),
    SyncableTable<Tag>(
      kind: 'tags',
      table: db.tags,
      fromJson: Tag.fromJson,
      toJson: (t) => t.toJson(),
      toInsertable: (t) => t.toInsertable(),
    ),
  ],
);
```

### Per-Table Conflict Strategies

The global strategy is set in `SyncConfig`, while per-table strategies
are set via `tableConflictConfigs`:

```dart
final engine = SyncEngine(
  db: db,
  transport: transport,
  tables: [...],
  config: const SyncConfig(
    conflictStrategy: ConflictStrategy.autoPreserve, // global strategy
  ),
  tableConflictConfigs: {
    'todos': const TableConflictConfig(
      strategy: ConflictStrategy.lastWriteWins,
      timestampField: 'updatedAt',
    ),
    'categories': const TableConflictConfig(
      strategy: ConflictStrategy.serverWins,
    ),
    // 'tags' — uses the global strategy (autoPreserve)
  },
);
```

Available strategies (`ConflictStrategy`):

| Strategy | Description |
|---|---|
| `serverWins` | Server version always wins |
| `clientWins` | Client version always wins (retry with force) |
| `lastWriteWins` | Version with the later timestamp wins |
| `merge` | Merge changes via `mergeFunction` |
| `manual` | Manual resolution via `conflictResolver` callback |
| `autoPreserve` | Smart merge without data loss (default) |

### Selective Synchronization

You can sync only specific entity types:

```dart
// Sync only todos and categories
await engine.sync(kinds: {'todos', 'categories'});

// Sync everything (default)
await engine.sync();
```

---

## Schema Migrations

### Adding Sync Tables to an Existing Database

If you are adding synchronization to an already existing Drift database,
you need to update `schemaVersion` and write a migration.

```dart
@DriftDatabase(
  include: {'package:offline_first_sync_drift/src/sync_tables.drift'},
  tables: [Todos, Categories],
)
class AppDatabase extends _$AppDatabase with SyncDatabaseMixin {
  AppDatabase(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 2; // was 1, increment

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      // Create all tables on first install
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Create sync system tables
        await m.createTable(allTables
            .firstWhere((t) => t.actualTableName == 'sync_outbox'));
        await m.createTable(allTables
            .firstWhere((t) => t.actualTableName == 'sync_cursors'));
      }
    },
  );
}
```

### Adding a New Sync Table

When adding a new syncable table to an already running database:

```dart
@override
int get schemaVersion => 3; // increment

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async {
    await m.createAll();
  },
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.createTable(allTables
          .firstWhere((t) => t.actualTableName == 'sync_outbox'));
      await m.createTable(allTables
          .firstWhere((t) => t.actualTableName == 'sync_cursors'));
    }
    if (from < 3) {
      // New Tags table
      await m.createTable(allTables
          .firstWhere((t) => t.actualTableName == 'tags'));
    }
  },
);
```

---

## Complete Example

Full database setup with three syncable tables.

### Data Models

```dart
// models/todo.dart
class Todo {
  final String id;
  final String title;
  final bool completed;
  final String? categoryId;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? deletedAtLocal;

  Todo({
    required this.id,
    required this.title,
    required this.completed,
    this.categoryId,
    required this.updatedAt,
    this.deletedAt,
    this.deletedAtLocal,
  });

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id'] as String,
    title: json['title'] as String,
    completed: json['completed'] as bool,
    categoryId: json['category_id'] as String?,
    updatedAt: DateTime.parse(json['updated_at'] as String),
    deletedAt: json['deleted_at'] != null
        ? DateTime.parse(json['deleted_at'] as String)
        : null,
    deletedAtLocal: json['deleted_at_local'] != null
        ? DateTime.parse(json['deleted_at_local'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'completed': completed,
    'category_id': categoryId,
    'updated_at': updatedAt.toIso8601String(),
    if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
  };

  TodosCompanion toInsertable() => TodosCompanion.insert(
    id: id,
    title: title,
    completed: completed,
    categoryId: Value(categoryId),
    updatedAt: updatedAt,
    deletedAt: Value(deletedAt),
    deletedAtLocal: Value(deletedAtLocal),
  );
}

// models/category.dart
class Category {
  final String id;
  final String name;
  final String color;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? deletedAtLocal;

  Category({
    required this.id,
    required this.name,
    required this.color,
    required this.updatedAt,
    this.deletedAt,
    this.deletedAtLocal,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    color: json['color'] as String,
    updatedAt: DateTime.parse(json['updated_at'] as String),
    deletedAt: json['deleted_at'] != null
        ? DateTime.parse(json['deleted_at'] as String)
        : null,
    deletedAtLocal: json['deleted_at_local'] != null
        ? DateTime.parse(json['deleted_at_local'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'updated_at': updatedAt.toIso8601String(),
    if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
  };

  CategoriesCompanion toInsertable() => CategoriesCompanion.insert(
    id: id,
    name: name,
    color: color,
    updatedAt: updatedAt,
    deletedAt: Value(deletedAt),
    deletedAtLocal: Value(deletedAtLocal),
  );
}
```

### Table Definitions

```dart
// tables.dart
import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

@UseRowClass(Todo, generateInsertable: true)
class Todos extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get title => text()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  TextColumn get categoryId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@UseRowClass(Category, generateInsertable: true)
class Categories extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text().withDefault(const Constant('#000000'))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Database Setup

```dart
// database.dart
import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

part 'database.g.dart';

@DriftDatabase(
  include: {'package:offline_first_sync_drift/src/sync_tables.drift'},
  tables: [Todos, Categories],
)
class AppDatabase extends _$AppDatabase with SyncDatabaseMixin {
  AppDatabase(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
  );
}
```

### Creating SyncEngine

```dart
// sync_setup.dart
final db = AppDatabase(executor);

final engine = SyncEngine(
  db: db,
  transport: myTransportAdapter,
  tables: [
    SyncableTable<Todo>(
      kind: 'todos',
      table: db.todos,
      fromJson: Todo.fromJson,
      toJson: (t) => t.toJson(),
      toInsertable: (t) => t.toInsertable(),
    ),
    SyncableTable<Category>(
      kind: 'categories',
      table: db.categories,
      fromJson: Category.fromJson,
      toJson: (c) => c.toJson(),
      toInsertable: (c) => c.toInsertable(),
    ),
  ],
  config: const SyncConfig(
    conflictStrategy: ConflictStrategy.autoPreserve,
    pageSize: 500,
    maxPushRetries: 5,
    fullResyncInterval: Duration(days: 7),
  ),
  tableConflictConfigs: {
    'categories': const TableConflictConfig(
      strategy: ConflictStrategy.serverWins,
    ),
  },
);

// Write and send changes
final todo = Todo(
  id: 'todo-1',
  title: 'Write docs',
  completed: false,
  updatedAt: DateTime.now().toUtc(),
);

await db.into(db.todos).insert(todo.toInsertable());

await db.enqueue(
  UpsertOp.create(
    kind: 'todos',
    id: todo.id,
    localTimestamp: DateTime.now().toUtc(),
    payloadJson: todo.toJson(),
    opId: 'op-1',
  ),
);

// Synchronization
final stats = await engine.sync();
print('Pushed: ${stats.pushed}, Pulled: ${stats.pulled}');

// Cleanup
engine.dispose();
await db.close();
```
