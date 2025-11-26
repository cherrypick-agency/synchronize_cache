// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:synchronize_cache/src/tables/cursors.drift.dart' as i1;
import 'package:synchronize_cache/src/tables/outbox.drift.dart' as i2;
import 'sync_engine_test.drift.dart' as i3;
import 'sync_engine_test.dart' as i4;

typedef $$TestItemsTableCreateCompanionBuilder =
    i3.TestItemsCompanion Function({
      required DateTime updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<DateTime?> deletedAtLocal,
      required String id,
      required String name,
      i0.Value<int> rowid,
    });
typedef $$TestItemsTableUpdateCompanionBuilder =
    i3.TestItemsCompanion Function({
      i0.Value<DateTime> updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<DateTime?> deletedAtLocal,
      i0.Value<String> id,
      i0.Value<String> name,
      i0.Value<int> rowid,
    });

class $$TestItemsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i3.$TestItemsTable> {
  $$TestItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get deletedAtLocal => $composableBuilder(
    column: $table.deletedAtLocal,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$TestItemsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i3.$TestItemsTable> {
  $$TestItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get deletedAtLocal => $composableBuilder(
    column: $table.deletedAtLocal,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$TestItemsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i3.$TestItemsTable> {
  $$TestItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get deletedAtLocal => $composableBuilder(
    column: $table.deletedAtLocal,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$TestItemsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i3.$TestItemsTable,
          i4.TestItem,
          i3.$$TestItemsTableFilterComposer,
          i3.$$TestItemsTableOrderingComposer,
          i3.$$TestItemsTableAnnotationComposer,
          $$TestItemsTableCreateCompanionBuilder,
          $$TestItemsTableUpdateCompanionBuilder,
          (
            i4.TestItem,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i3.$TestItemsTable,
              i4.TestItem
            >,
          ),
          i4.TestItem,
          i0.PrefetchHooks Function()
        > {
  $$TestItemsTableTableManager(
    i0.GeneratedDatabase db,
    i3.$TestItemsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => i3.$$TestItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => i3.$$TestItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  i3.$$TestItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<DateTime> updatedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAtLocal = const i0.Value.absent(),
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> name = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i3.TestItemsCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deletedAtLocal: deletedAtLocal,
                id: id,
                name: name,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime updatedAt,
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAtLocal = const i0.Value.absent(),
                required String id,
                required String name,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i3.TestItemsCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deletedAtLocal: deletedAtLocal,
                id: id,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          i0.BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TestItemsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i3.$TestItemsTable,
      i4.TestItem,
      i3.$$TestItemsTableFilterComposer,
      i3.$$TestItemsTableOrderingComposer,
      i3.$$TestItemsTableAnnotationComposer,
      $$TestItemsTableCreateCompanionBuilder,
      $$TestItemsTableUpdateCompanionBuilder,
      (
        i4.TestItem,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i3.$TestItemsTable,
          i4.TestItem
        >,
      ),
      i4.TestItem,
      i0.PrefetchHooks Function()
    >;

abstract class $TestDatabase extends i0.GeneratedDatabase {
  $TestDatabase(i0.QueryExecutor e) : super(e);
  $TestDatabaseManager get managers => $TestDatabaseManager(this);
  late final i1.$SyncCursorsTable syncCursors = i1.$SyncCursorsTable(this);
  late final i2.$SyncOutboxTable syncOutbox = i2.$SyncOutboxTable(this);
  late final i3.$TestItemsTable testItems = i3.$TestItemsTable(this);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [
    syncCursors,
    syncOutbox,
    testItems,
  ];
  @override
  i0.DriftDatabaseOptions get options =>
      const i0.DriftDatabaseOptions(storeDateTimeAsText: true);
}

class $TestDatabaseManager {
  final $TestDatabase _db;
  $TestDatabaseManager(this._db);
  i1.$$SyncCursorsTableTableManager get syncCursors =>
      i1.$$SyncCursorsTableTableManager(_db, _db.syncCursors);
  i2.$$SyncOutboxTableTableManager get syncOutbox =>
      i2.$$SyncOutboxTableTableManager(_db, _db.syncOutbox);
  i3.$$TestItemsTableTableManager get testItems =>
      i3.$$TestItemsTableTableManager(_db, _db.testItems);
}

class $TestItemsTable extends i4.TestItems
    with i0.TableInfo<$TestItemsTable, i4.TestItem> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TestItemsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _updatedAtMeta = const i0.VerificationMeta(
    'updatedAt',
  );
  @override
  late final i0.GeneratedColumn<DateTime> updatedAt =
      i0.GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _deletedAtMeta = const i0.VerificationMeta(
    'deletedAt',
  );
  @override
  late final i0.GeneratedColumn<DateTime> deletedAt =
      i0.GeneratedColumn<DateTime>(
        'deleted_at',
        aliasedName,
        true,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _deletedAtLocalMeta =
      const i0.VerificationMeta('deletedAtLocal');
  @override
  late final i0.GeneratedColumn<DateTime> deletedAtLocal =
      i0.GeneratedColumn<DateTime>(
        'deleted_at_local',
        aliasedName,
        true,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<String> id = i0.GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _nameMeta = const i0.VerificationMeta(
    'name',
  );
  @override
  late final i0.GeneratedColumn<String> name = i0.GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    deletedAtLocal,
    id,
    name,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'test_items';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i4.TestItem> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('deleted_at_local')) {
      context.handle(
        _deletedAtLocalMeta,
        deletedAtLocal.isAcceptableOrUnknown(
          data['deleted_at_local']!,
          _deletedAtLocalMeta,
        ),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i4.TestItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i4.TestItem(
      id:
          attachedDatabase.typeMapping.read(
            i0.DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            i0.DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
      deletedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      deletedAtLocal: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at_local'],
      ),
      name:
          attachedDatabase.typeMapping.read(
            i0.DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
    );
  }

  @override
  $TestItemsTable createAlias(String alias) {
    return $TestItemsTable(attachedDatabase, alias);
  }
}

class TestItemsCompanion extends i0.UpdateCompanion<i4.TestItem> {
  final i0.Value<DateTime> updatedAt;
  final i0.Value<DateTime?> deletedAt;
  final i0.Value<DateTime?> deletedAtLocal;
  final i0.Value<String> id;
  final i0.Value<String> name;
  final i0.Value<int> rowid;
  const TestItemsCompanion({
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
    this.deletedAtLocal = const i0.Value.absent(),
    this.id = const i0.Value.absent(),
    this.name = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  TestItemsCompanion.insert({
    required DateTime updatedAt,
    this.deletedAt = const i0.Value.absent(),
    this.deletedAtLocal = const i0.Value.absent(),
    required String id,
    required String name,
    this.rowid = const i0.Value.absent(),
  }) : updatedAt = i0.Value(updatedAt),
       id = i0.Value(id),
       name = i0.Value(name);
  static i0.Insertable<i4.TestItem> custom({
    i0.Expression<DateTime>? updatedAt,
    i0.Expression<DateTime>? deletedAt,
    i0.Expression<DateTime>? deletedAtLocal,
    i0.Expression<String>? id,
    i0.Expression<String>? name,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deletedAtLocal != null) 'deleted_at_local': deletedAtLocal,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i3.TestItemsCompanion copyWith({
    i0.Value<DateTime>? updatedAt,
    i0.Value<DateTime?>? deletedAt,
    i0.Value<DateTime?>? deletedAtLocal,
    i0.Value<String>? id,
    i0.Value<String>? name,
    i0.Value<int>? rowid,
  }) {
    return i3.TestItemsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedAtLocal: deletedAtLocal ?? this.deletedAtLocal,
      id: id ?? this.id,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = i0.Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = i0.Variable<DateTime>(deletedAt.value);
    }
    if (deletedAtLocal.present) {
      map['deleted_at_local'] = i0.Variable<DateTime>(deletedAtLocal.value);
    }
    if (id.present) {
      map['id'] = i0.Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = i0.Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TestItemsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deletedAtLocal: $deletedAtLocal, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class _$TestItemInsertable implements i0.Insertable<i4.TestItem> {
  i4.TestItem _object;
  _$TestItemInsertable(this._object);
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    return i3.TestItemsCompanion(
      updatedAt: i0.Value(_object.updatedAt),
      deletedAt: i0.Value(_object.deletedAt),
      deletedAtLocal: i0.Value(_object.deletedAtLocal),
      id: i0.Value(_object.id),
      name: i0.Value(_object.name),
    ).toColumns(false);
  }
}

extension TestItemToInsertable on i4.TestItem {
  _$TestItemInsertable toInsertable() {
    return _$TestItemInsertable(this);
  }
}
