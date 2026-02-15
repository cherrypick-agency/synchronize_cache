// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:offline_first_sync_drift/src/tables/sync_data_classes.dart'
    as i1;
import 'package:offline_first_sync_drift/src/tables/outbox_meta.drift.dart'
    as i2;
import 'package:offline_first_sync_drift/src/tables/outbox_meta.dart' as i3;

typedef $$SyncOutboxMetaTableCreateCompanionBuilder =
    i2.SyncOutboxMetaCompanion Function({
      required String opId,
      i0.Value<int?> lastTriedAt,
      i0.Value<String?> lastError,
      i0.Value<int> rowid,
    });
typedef $$SyncOutboxMetaTableUpdateCompanionBuilder =
    i2.SyncOutboxMetaCompanion Function({
      i0.Value<String> opId,
      i0.Value<int?> lastTriedAt,
      i0.Value<String?> lastError,
      i0.Value<int> rowid,
    });

class $$SyncOutboxMetaTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$SyncOutboxMetaTable> {
  $$SyncOutboxMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get lastTriedAt => $composableBuilder(
    column: $table.lastTriedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$SyncOutboxMetaTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$SyncOutboxMetaTable> {
  $$SyncOutboxMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get lastTriedAt => $composableBuilder(
    column: $table.lastTriedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$SyncOutboxMetaTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$SyncOutboxMetaTable> {
  $$SyncOutboxMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  i0.GeneratedColumn<int> get lastTriedAt => $composableBuilder(
    column: $table.lastTriedAt,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncOutboxMetaTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.$SyncOutboxMetaTable,
          i1.SyncOutboxMetaData,
          i2.$$SyncOutboxMetaTableFilterComposer,
          i2.$$SyncOutboxMetaTableOrderingComposer,
          i2.$$SyncOutboxMetaTableAnnotationComposer,
          $$SyncOutboxMetaTableCreateCompanionBuilder,
          $$SyncOutboxMetaTableUpdateCompanionBuilder,
          (
            i1.SyncOutboxMetaData,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i2.$SyncOutboxMetaTable,
              i1.SyncOutboxMetaData
            >,
          ),
          i1.SyncOutboxMetaData,
          i0.PrefetchHooks Function()
        > {
  $$SyncOutboxMetaTableTableManager(
    i0.GeneratedDatabase db,
    i2.$SyncOutboxMetaTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => i2.$$SyncOutboxMetaTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => i2.$$SyncOutboxMetaTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => i2.$$SyncOutboxMetaTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                i0.Value<String> opId = const i0.Value.absent(),
                i0.Value<int?> lastTriedAt = const i0.Value.absent(),
                i0.Value<String?> lastError = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.SyncOutboxMetaCompanion(
                opId: opId,
                lastTriedAt: lastTriedAt,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String opId,
                i0.Value<int?> lastTriedAt = const i0.Value.absent(),
                i0.Value<String?> lastError = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.SyncOutboxMetaCompanion.insert(
                opId: opId,
                lastTriedAt: lastTriedAt,
                lastError: lastError,
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

typedef $$SyncOutboxMetaTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.$SyncOutboxMetaTable,
      i1.SyncOutboxMetaData,
      i2.$$SyncOutboxMetaTableFilterComposer,
      i2.$$SyncOutboxMetaTableOrderingComposer,
      i2.$$SyncOutboxMetaTableAnnotationComposer,
      $$SyncOutboxMetaTableCreateCompanionBuilder,
      $$SyncOutboxMetaTableUpdateCompanionBuilder,
      (
        i1.SyncOutboxMetaData,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i2.$SyncOutboxMetaTable,
          i1.SyncOutboxMetaData
        >,
      ),
      i1.SyncOutboxMetaData,
      i0.PrefetchHooks Function()
    >;

class $SyncOutboxMetaTable extends i3.SyncOutboxMeta
    with i0.TableInfo<$SyncOutboxMetaTable, i1.SyncOutboxMetaData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxMetaTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _opIdMeta = const i0.VerificationMeta(
    'opId',
  );
  @override
  late final i0.GeneratedColumn<String> opId = i0.GeneratedColumn<String>(
    'op_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _lastTriedAtMeta = const i0.VerificationMeta(
    'lastTriedAt',
  );
  @override
  late final i0.GeneratedColumn<int> lastTriedAt = i0.GeneratedColumn<int>(
    'last_tried_at',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _lastErrorMeta = const i0.VerificationMeta(
    'lastError',
  );
  @override
  late final i0.GeneratedColumn<String> lastError = i0.GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [opId, lastTriedAt, lastError];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox_meta';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.SyncOutboxMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('last_tried_at')) {
      context.handle(
        _lastTriedAtMeta,
        lastTriedAt.isAcceptableOrUnknown(
          data['last_tried_at']!,
          _lastTriedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {opId};
  @override
  i1.SyncOutboxMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.SyncOutboxMetaData(
      opId:
          attachedDatabase.typeMapping.read(
            i0.DriftSqlType.string,
            data['${effectivePrefix}op_id'],
          )!,
      lastTriedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}last_tried_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncOutboxMetaTable createAlias(String alias) {
    return $SyncOutboxMetaTable(attachedDatabase, alias);
  }
}

class SyncOutboxMetaCompanion
    extends i0.UpdateCompanion<i1.SyncOutboxMetaData> {
  final i0.Value<String> opId;
  final i0.Value<int?> lastTriedAt;
  final i0.Value<String?> lastError;
  final i0.Value<int> rowid;
  const SyncOutboxMetaCompanion({
    this.opId = const i0.Value.absent(),
    this.lastTriedAt = const i0.Value.absent(),
    this.lastError = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  SyncOutboxMetaCompanion.insert({
    required String opId,
    this.lastTriedAt = const i0.Value.absent(),
    this.lastError = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  }) : opId = i0.Value(opId);
  static i0.Insertable<i1.SyncOutboxMetaData> custom({
    i0.Expression<String>? opId,
    i0.Expression<int>? lastTriedAt,
    i0.Expression<String>? lastError,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (opId != null) 'op_id': opId,
      if (lastTriedAt != null) 'last_tried_at': lastTriedAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.SyncOutboxMetaCompanion copyWith({
    i0.Value<String>? opId,
    i0.Value<int?>? lastTriedAt,
    i0.Value<String?>? lastError,
    i0.Value<int>? rowid,
  }) {
    return i2.SyncOutboxMetaCompanion(
      opId: opId ?? this.opId,
      lastTriedAt: lastTriedAt ?? this.lastTriedAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (opId.present) {
      map['op_id'] = i0.Variable<String>(opId.value);
    }
    if (lastTriedAt.present) {
      map['last_tried_at'] = i0.Variable<int>(lastTriedAt.value);
    }
    if (lastError.present) {
      map['last_error'] = i0.Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxMetaCompanion(')
          ..write('opId: $opId, ')
          ..write('lastTriedAt: $lastTriedAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}
