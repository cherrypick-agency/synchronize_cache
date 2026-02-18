# Migrations and Schema Evolution

The library uses Drift's standard migration system (`schemaVersion`, `MigrationStrategy`).

---

## 0. API Changes in This Release

This section summarizes user-facing API updates introduced in this release.

### Summary

- `SyncEngine.sync(kinds: ...)` is now legacy (deprecated alias).
- New explicit filters: `sync(pushKinds: ..., pullKinds: ...)`.
- App-flow flags in `SyncConfig` are now legacy:
  - `pullOnStartup`
  - `pushImmediately`
  - `reconcileInterval`
  - `lazyReconcileOnMiss`
- New orchestration layer: `SyncCoordinator`.
- New registration sugar: `db.myTable.syncTable(...)`.
- New changed-fields automation:
  - `ChangedFieldsDiff`
  - `replaceAndEnqueueDiff(...)`
- New REST one-liner:
  - `createRestSyncEngine(...)`

### Why this was changed

- Make push/pull filtering explicit and predictable.
- Move app lifecycle orchestration out of core sync config.
- Reduce boilerplate in table registration and write flows.
- Keep backward compatibility while preparing a clean next major release.

### Action required

- Existing code continues to work.
- You can migrate incrementally by replacing legacy API calls with recommended equivalents below.
- New code should use the recommended API.

### Deprecated -> Replacement (quick map)

| Deprecated API | Replacement | Impact |
|---|---|---|
| `engine.sync(kinds: {...})` | `engine.sync(pushKinds: {...}, pullKinds: {...})` | low |
| `SyncConfig(pullOnStartup: ...)` | `SyncCoordinator(pullOnStartup: ...)` | medium |
| `SyncConfig(pushImmediately: ...)` | `SyncCoordinator(pushOnOutboxChanges: ...)` | medium |
| `SyncConfig(reconcileInterval: ...)` | `SyncCoordinator(autoInterval: ...)` | medium |
| `SyncConfig(lazyReconcileOnMiss: ...)` | Reserved for future API (keep explicit app-side behavior) | low |
| `SyncCoordinator(outboxPollInterval: ...)` | Removed need: coordinator now reacts to outbox streams | low |

### Legacy -> Recommended mapping

| Legacy API | Recommended API |
|---|---|
| `engine.sync(kinds: {'todos'})` | `engine.sync(pushKinds: {'todos'}, pullKinds: {'todos'})` |
| `SyncConfig(pullOnStartup: true)` | `SyncCoordinator(pullOnStartup: true)` |
| `SyncConfig(pushImmediately: true)` | `SyncCoordinator(pushOnOutboxChanges: true)` |
| `SyncConfig(reconcileInterval: d)` | `SyncCoordinator(autoInterval: d)` |
| `SyncConfig(lazyReconcileOnMiss: ...)` | Reserved for future API (keep behavior explicit in app code) |
| Manual `SyncableTable(...)` boilerplate | `db.todos.syncTable(...)` |
| Manual `changedFields` tracking only | `replaceAndEnqueueDiff(...)` or `ChangedFieldsDiff` |

### Behavioral note: `kinds`

In earlier versions, `kinds` effectively filtered pull only.

In this release, legacy `kinds` is treated as a shared alias for both push and pull.  
If you want "filter pull, push all pending outbox kinds", use:

```dart
await engine.sync(
  pullKinds: {'todos'},
  // pushKinds omitted => push all pending kinds from outbox
);
```

### Examples

#### 1) Sync filters

```dart
// Before (legacy):
await engine.sync(kinds: {'daily_feeling'});

// After (explicit):
await engine.sync(
  pushKinds: {'daily_feeling'},
  pullKinds: {'daily_feeling'},
);
```

#### 2) Startup and periodic sync

```dart
// Before (legacy flags in SyncConfig):
final engine = SyncEngine(
  db: db,
  transport: transport,
  tables: [dailyFeelingSync],
  config: const SyncConfig(
    pullOnStartup: true,
    reconcileInterval: Duration(minutes: 5),
    pushImmediately: true,
  ),
);

// After:
final engine = SyncEngine(
  db: db,
  transport: transport,
  tables: [dailyFeelingSync],
);

final coordinator = SyncCoordinator(
  engine: engine,
  pullOnStartup: true,
  autoInterval: const Duration(minutes: 5),
  pushOnOutboxChanges: true,
);

await coordinator.start();
```

#### 3) Table registration

```dart
// Before:
final dailyFeelingSync = SyncableTable<DailyFeeling>(
  kind: 'daily_feeling',
  table: db.dailyFeelings,
  fromJson: DailyFeeling.fromJson,
  toJson: (e) => e.toJson(),
  toInsertable: (e) => e.toInsertable(),
  getId: (e) => e.id,
  getUpdatedAt: (e) => e.updatedAt,
);

// After:
final dailyFeelingSync = db.dailyFeelings.syncTable(
  kind: 'daily_feeling',
  fromJson: DailyFeeling.fromJson,
  toJson: (e) => e.toJson(),
  toInsertable: (e) => e.toInsertable(),
  getId: (e) => e.id,
  getUpdatedAt: (e) => e.updatedAt,
);
```

#### 4) changedFields automation

```dart
// Before:
await writer.replaceAndEnqueue(
  updated,
  baseUpdatedAt: old.updatedAt,
  changedFields: {'mood', 'notes'},
);

// After:
await writer.replaceAndEnqueueDiff(
  before: old,
  after: updated,
  baseUpdatedAt: old.updatedAt,
);
```

#### 5) REST setup one-liner

```dart
// Before:
final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer ${await getToken()}',
);
final engine = SyncEngine(
  db: db,
  transport: transport,
  tables: [dailyFeelingSync],
);

// After:
final engine = createRestSyncEngine(
  db: db,
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer ${await getToken()}',
  tables: [dailyFeelingSync],
);
```

### Deprecation timeline

- Current release keeps backward compatibility (deprecated API remains available).
- No immediate major bump is required for introducing these deprecations.
- Deprecated API is planned for removal together in the next major release.
- Recommended release plan:
  1. Keep deprecated API during one full minor cycle.
  2. Announce removal window in changelog and README.
  3. Remove deprecated API in the next major.

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
