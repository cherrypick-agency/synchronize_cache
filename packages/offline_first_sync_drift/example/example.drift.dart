// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:offline_first_sync_drift/src/tables/cursors.drift.dart' as i1;
import 'package:offline_first_sync_drift/src/tables/outbox_meta.drift.dart'
    as i2;
import 'package:offline_first_sync_drift/src/tables/outbox.drift.dart' as i3;
import 'example.drift.dart' as i4;
import 'example.dart' as i5;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i6;

typedef $$TodosTableCreateCompanionBuilder =
    i4.TodosCompanion Function({
      required DateTime updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<DateTime?> deletedAtLocal,
      required String id,
      required String title,
      i0.Value<bool> completed,
      i0.Value<int> rowid,
    });
typedef $$TodosTableUpdateCompanionBuilder =
    i4.TodosCompanion Function({
      i0.Value<DateTime> updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<DateTime?> deletedAtLocal,
      i0.Value<String> id,
      i0.Value<String> title,
      i0.Value<bool> completed,
      i0.Value<int> rowid,
    });

class $$TodosTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i4.$TodosTable> {
  $$TodosTableFilterComposer({
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

  i0.ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$TodosTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i4.$TodosTable> {
  $$TodosTableOrderingComposer({
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

  i0.ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$TodosTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i4.$TodosTable> {
  $$TodosTableAnnotationComposer({
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

  i0.GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  i0.GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);
}

class $$TodosTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i4.$TodosTable,
          i5.Todo,
          i4.$$TodosTableFilterComposer,
          i4.$$TodosTableOrderingComposer,
          i4.$$TodosTableAnnotationComposer,
          $$TodosTableCreateCompanionBuilder,
          $$TodosTableUpdateCompanionBuilder,
          (
            i5.Todo,
            i0.BaseReferences<i0.GeneratedDatabase, i4.$TodosTable, i5.Todo>,
          ),
          i5.Todo,
          i0.PrefetchHooks Function()
        > {
  $$TodosTableTableManager(i0.GeneratedDatabase db, i4.$TodosTable table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => i4.$$TodosTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => i4.$$TodosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => i4.$$TodosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<DateTime> updatedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAtLocal = const i0.Value.absent(),
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> title = const i0.Value.absent(),
                i0.Value<bool> completed = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i4.TodosCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deletedAtLocal: deletedAtLocal,
                id: id,
                title: title,
                completed: completed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime updatedAt,
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAtLocal = const i0.Value.absent(),
                required String id,
                required String title,
                i0.Value<bool> completed = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i4.TodosCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deletedAtLocal: deletedAtLocal,
                id: id,
                title: title,
                completed: completed,
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

typedef $$TodosTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i4.$TodosTable,
      i5.Todo,
      i4.$$TodosTableFilterComposer,
      i4.$$TodosTableOrderingComposer,
      i4.$$TodosTableAnnotationComposer,
      $$TodosTableCreateCompanionBuilder,
      $$TodosTableUpdateCompanionBuilder,
      (
        i5.Todo,
        i0.BaseReferences<i0.GeneratedDatabase, i4.$TodosTable, i5.Todo>,
      ),
      i5.Todo,
      i0.PrefetchHooks Function()
    >;

abstract class $AppDatabase extends i0.GeneratedDatabase {
  $AppDatabase(i0.QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final i1.$SyncCursorsTable syncCursors = i1.$SyncCursorsTable(this);
  late final i2.$SyncOutboxMetaTable syncOutboxMeta = i2.$SyncOutboxMetaTable(
    this,
  );
  late final i3.$SyncOutboxTable syncOutbox = i3.$SyncOutboxTable(this);
  late final i4.$TodosTable todos = i4.$TodosTable(this);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [
    syncCursors,
    syncOutboxMeta,
    syncOutbox,
    todos,
  ];
  @override
  i0.DriftDatabaseOptions get options =>
      const i0.DriftDatabaseOptions(storeDateTimeAsText: true);
}

class $AppDatabaseManager {
  final $AppDatabase _db;
  $AppDatabaseManager(this._db);
  i1.$$SyncCursorsTableTableManager get syncCursors =>
      i1.$$SyncCursorsTableTableManager(_db, _db.syncCursors);
  i2.$$SyncOutboxMetaTableTableManager get syncOutboxMeta =>
      i2.$$SyncOutboxMetaTableTableManager(_db, _db.syncOutboxMeta);
  i3.$$SyncOutboxTableTableManager get syncOutbox =>
      i3.$$SyncOutboxTableTableManager(_db, _db.syncOutbox);
  i4.$$TodosTableTableManager get todos =>
      i4.$$TodosTableTableManager(_db, _db.todos);
}

class $TodosTable extends i5.Todos with i0.TableInfo<$TodosTable, i5.Todo> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodosTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _titleMeta = const i0.VerificationMeta(
    'title',
  );
  @override
  late final i0.GeneratedColumn<String> title = i0.GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _completedMeta = const i0.VerificationMeta(
    'completed',
  );
  @override
  late final i0.GeneratedColumn<bool> completed = i0.GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: i0.DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const i6.Constant(false),
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    deletedAtLocal,
    id,
    title,
    completed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todos';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i5.Todo> instance, {
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
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i5.Todo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i5.Todo(
      id:
          attachedDatabase.typeMapping.read(
            i0.DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            i0.DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      completed:
          attachedDatabase.typeMapping.read(
            i0.DriftSqlType.bool,
            data['${effectivePrefix}completed'],
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
    );
  }

  @override
  $TodosTable createAlias(String alias) {
    return $TodosTable(attachedDatabase, alias);
  }
}

class TodosCompanion extends i0.UpdateCompanion<i5.Todo> {
  final i0.Value<DateTime> updatedAt;
  final i0.Value<DateTime?> deletedAt;
  final i0.Value<DateTime?> deletedAtLocal;
  final i0.Value<String> id;
  final i0.Value<String> title;
  final i0.Value<bool> completed;
  final i0.Value<int> rowid;
  const TodosCompanion({
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
    this.deletedAtLocal = const i0.Value.absent(),
    this.id = const i0.Value.absent(),
    this.title = const i0.Value.absent(),
    this.completed = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  TodosCompanion.insert({
    required DateTime updatedAt,
    this.deletedAt = const i0.Value.absent(),
    this.deletedAtLocal = const i0.Value.absent(),
    required String id,
    required String title,
    this.completed = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  }) : updatedAt = i0.Value(updatedAt),
       id = i0.Value(id),
       title = i0.Value(title);
  static i0.Insertable<i5.Todo> custom({
    i0.Expression<DateTime>? updatedAt,
    i0.Expression<DateTime>? deletedAt,
    i0.Expression<DateTime>? deletedAtLocal,
    i0.Expression<String>? id,
    i0.Expression<String>? title,
    i0.Expression<bool>? completed,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deletedAtLocal != null) 'deleted_at_local': deletedAtLocal,
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (completed != null) 'completed': completed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i4.TodosCompanion copyWith({
    i0.Value<DateTime>? updatedAt,
    i0.Value<DateTime?>? deletedAt,
    i0.Value<DateTime?>? deletedAtLocal,
    i0.Value<String>? id,
    i0.Value<String>? title,
    i0.Value<bool>? completed,
    i0.Value<int>? rowid,
  }) {
    return i4.TodosCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedAtLocal: deletedAtLocal ?? this.deletedAtLocal,
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
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
    if (title.present) {
      map['title'] = i0.Variable<String>(title.value);
    }
    if (completed.present) {
      map['completed'] = i0.Variable<bool>(completed.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodosCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deletedAtLocal: $deletedAtLocal, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('completed: $completed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class _$TodoInsertable implements i0.Insertable<i5.Todo> {
  i5.Todo _object;
  _$TodoInsertable(this._object);
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    return i4.TodosCompanion(
      updatedAt: i0.Value(_object.updatedAt),
      deletedAt: i0.Value(_object.deletedAt),
      deletedAtLocal: i0.Value(_object.deletedAtLocal),
      id: i0.Value(_object.id),
      title: i0.Value(_object.title),
      completed: i0.Value(_object.completed),
    ).toColumns(false);
  }
}

extension TodoToInsertable on i5.Todo {
  _$TodoInsertable toInsertable() {
    return _$TodoInsertable(this);
  }
}
