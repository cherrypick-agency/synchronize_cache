# Migrations and Schema Evolution

The library uses Drift's standard migration system (`schemaVersion`, `MigrationStrategy`).

---

## 1. Adding a New Synced Table

**Step 1.** Define the table with `SyncColumns`:

```dart
@UseRowClass(Note, generateInsertable: true)
class Notes extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get content => text()();
  @override
  Set<Column> get primaryKey => {id};
}
```

**Step 2.** Add to `@DriftDatabase(tables: [Todos, Notes])`.

**Step 3.** Increment `schemaVersion` and write the migration:

```dart
@override
int get schemaVersion => 2; // was 1

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async => await m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      // Safe: the 'notes' table is guaranteed to be in allTables,
      // since it was added to @DriftDatabase(tables: [..., Notes])
      await m.createTable(
        allTables.firstWhere((t) => t.actualTableName == 'notes'),
      );
    }
  },
);
```

**Step 4.** Register `SyncableTable<Note>` in `SyncEngine.tables`.

**Step 5.** `dart run build_runner build --delete-conflicting-outputs`.

The cursor for the new table will be `null` -- pull will load all data from epoch automatically.

---

## 2. Adding Columns to an Existing Table

### Nullable Column

```dart
TextColumn get categoryId => text().nullable()(); // new
```

### Column with Default Value

```dart
IntColumn get priority => integer().withDefault(const Constant(0))();
```

### Migration

```dart
@override
int get schemaVersion => 3;

// in onUpgrade:
if (from < 3) {
  await m.addColumn(db.todos, db.todos.categoryId);
}
```

Update `fromJson`/`toJson` for the new field. After migration, call `fullResync()` to load the new field values for existing records.

---

## 3. Removing a Table from Sync

**Step 1.** Remove `SyncableTable` from `SyncEngine.tables`.

**Option A -- keep the table without sync:** data is preserved, the table remains in `@DriftDatabase.tables`.

**Option B -- delete the table:**

```dart
if (from < 5) {
  await m.deleteTable('notes');
}
```

Remove from `@DriftDatabase.tables`, regenerate code.

**Optional:** clear cursor -- `await db.resetAllCursors({'notes'})`.

---

## 4. Renaming Columns

SQLite supports `ALTER COLUMN RENAME` since version 3.25.0. Drift:

```dart
if (from < 6) {
  await m.renameColumn(db.todos, 'owner_id', db.todos.assigneeId);
}
```

### JSON Mapping

Server JSON may use the old name. Support both in `fromJson`:

```dart
assigneeId: (json['assignee_id'] ?? json['owner_id']) as String?,
```

In `toJson` -- use the name the server expects. During the transition period you can send both:

```dart
'owner_id': assigneeId,     // old name
'assignee_id': assigneeId,  // new name
```

---

## 5. Migration Structure and `schemaVersion`

Each schema change increments `schemaVersion` by 1 and adds an `if (from < N)` block in `onUpgrade`:

```dart
@override
int get schemaVersion => 6;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async => await m.createAll(),
  onUpgrade: (m, from, to) async {
    // Version 2: adding sync to an existing app.
    // sync_outbox and sync_cursors don't exist yet, because the include
    // was added along with this migration.
    // For NEW installs they will be created via m.createAll() in onCreate.
    if (from < 2) {
      await m.createTable(
        allTables.firstWhere((t) => t.actualTableName == 'sync_outbox'));
      await m.createTable(
        allTables.firstWhere((t) => t.actualTableName == 'sync_cursors'));
    }
    if (from < 3) {
      await m.createTable(
        allTables.firstWhere((t) => t.actualTableName == 'notes'));
    }
    if (from < 4) {
      await m.addColumn(db.todos, db.todos.categoryId);
    }
    if (from < 5) {
      await m.deleteTable('old_table');
    }
    if (from < 6) {
      await m.renameColumn(db.todos, 'owner_id', db.todos.assigneeId);
    }
  },
  beforeOpen: (details) async {
    await customStatement('PRAGMA journal_mode=WAL;');
  },
);
```

**Rules:**

- Never remove old `if (from < N)` blocks -- a user may upgrade from any version.
- `onCreate` always calls `m.createAll()`.
- `beforeOpen` -- for PRAGMAs and settings unrelated to migration.

---

## 6. When to Call fullResync After Migration

| Scenario | fullResync | clearData |
|---|---|---|
| Column added that is already populated on the server | yes | no |
| Changed `fromJson`/`toJson` mapping | yes | no |
| Server model changed | yes | no |
| Columns removed / significant structural change | yes | **yes** |
| New table added | no | -- |
| Nullable column added, still empty on server | no | -- |

Example invocation:

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  // ...
  beforeOpen: (details) async {
    if (details.hadUpgrade && details.versionBefore != null) {
      _needsResyncAfterMigration = true;
    }
  },
);

// After initialization:
if (_needsResyncAfterMigration) {
  await engine.fullResync(clearData: true);
}
```

---

## 7. Server Changes and Backward Compatibility

**Adding a field on the server:** a client without an update will not break -- `fromJson` ignores unknown keys. After updating the client: add column, update `fromJson`, call `fullResync()`.

**Removing a field on the server:** make the field nullable in `fromJson` **before** removing it on the server.

**Renaming a field:** transition period -- the server returns both names, the client checks both (`json['new'] ?? json['old']`).

### Deploy Order

1. **Server**: add new field / start returning both names.
2. **Client**: schema migration, update `fromJson`/`toJson`, `fullResync()`.
3. **Server**: remove old field after all clients have updated.

---

## 8. Testing Migrations

### Generating Version Schemas (Drift)

```bash
dart run drift_dev schema dump lib/database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
```

### Migration Test

```dart
import 'package:drift_dev/api/migrations.dart';

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v1 -> v2', () async {
    final conn = await verifier.startAt(1);
    await verifier.migrateAndValidate(conn, 2);
  });

  test('v1 -> v3 (skipping version)', () async {
    final conn = await verifier.startAt(1);
    await verifier.migrateAndValidate(conn, 3);
  });
}
```

### fullResync After Migration Test

```dart
test('fullResync loads new field', () async {
  final transport = MockTransport();
  transport.pullResponses.add({
    'id': 'item-1',
    'title': 'Test',
    'category_id': 'cat-1',
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  });

  final engine = SyncEngine(db: db, transport: transport, tables: [todoSync]);
  await engine.fullResync(clearData: true);

  final items = await db.select(db.todos).get();
  expect(items.first.categoryId, 'cat-1');

  engine.dispose();
});
```

---

## Migration Checklist

- [ ] Table/column added in Dart code
- [ ] `schemaVersion` incremented
- [ ] `if (from < N)` block added to `onUpgrade`
- [ ] `fromJson` / `toJson` updated
- [ ] `SyncableTable` updated (if `kind` or fields changed)
- [ ] `build_runner build --delete-conflicting-outputs` executed
- [ ] Migration test written
- [ ] `fullResync()` scheduled (if required)
- [ ] Server is backward compatible
