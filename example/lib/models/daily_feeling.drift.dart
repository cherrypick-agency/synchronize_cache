// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:example/models/daily_feeling.dart' as i1;
import 'package:example/models/daily_feeling.drift.dart' as i2;

typedef $$DailyFeelingsTableCreateCompanionBuilder =
    i2.DailyFeelingsCompanion Function({
      required DateTime updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<DateTime?> deletedAtLocal,
      required String id,
      required DateTime date,
      required String feeling,
      i0.Value<String?> comment,
      required int healthRecordId,
      i0.Value<int> rowid,
    });
typedef $$DailyFeelingsTableUpdateCompanionBuilder =
    i2.DailyFeelingsCompanion Function({
      i0.Value<DateTime> updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<DateTime?> deletedAtLocal,
      i0.Value<String> id,
      i0.Value<DateTime> date,
      i0.Value<String> feeling,
      i0.Value<String?> comment,
      i0.Value<int> healthRecordId,
      i0.Value<int> rowid,
    });

class $$DailyFeelingsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$DailyFeelingsTable> {
  $$DailyFeelingsTableFilterComposer({
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

  i0.ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get feeling => $composableBuilder(
    column: $table.feeling,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get healthRecordId => $composableBuilder(
    column: $table.healthRecordId,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$DailyFeelingsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$DailyFeelingsTable> {
  $$DailyFeelingsTableOrderingComposer({
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

  i0.ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get feeling => $composableBuilder(
    column: $table.feeling,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get healthRecordId => $composableBuilder(
    column: $table.healthRecordId,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$DailyFeelingsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$DailyFeelingsTable> {
  $$DailyFeelingsTableAnnotationComposer({
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

  i0.GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  i0.GeneratedColumn<String> get feeling =>
      $composableBuilder(column: $table.feeling, builder: (column) => column);

  i0.GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  i0.GeneratedColumn<int> get healthRecordId => $composableBuilder(
    column: $table.healthRecordId,
    builder: (column) => column,
  );
}

class $$DailyFeelingsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.$DailyFeelingsTable,
          i1.DailyFeeling,
          i2.$$DailyFeelingsTableFilterComposer,
          i2.$$DailyFeelingsTableOrderingComposer,
          i2.$$DailyFeelingsTableAnnotationComposer,
          $$DailyFeelingsTableCreateCompanionBuilder,
          $$DailyFeelingsTableUpdateCompanionBuilder,
          (
            i1.DailyFeeling,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i2.$DailyFeelingsTable,
              i1.DailyFeeling
            >,
          ),
          i1.DailyFeeling,
          i0.PrefetchHooks Function()
        > {
  $$DailyFeelingsTableTableManager(
    i0.GeneratedDatabase db,
    i2.$DailyFeelingsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$$DailyFeelingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$$DailyFeelingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$$DailyFeelingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<DateTime> updatedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAtLocal = const i0.Value.absent(),
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<DateTime> date = const i0.Value.absent(),
                i0.Value<String> feeling = const i0.Value.absent(),
                i0.Value<String?> comment = const i0.Value.absent(),
                i0.Value<int> healthRecordId = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.DailyFeelingsCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deletedAtLocal: deletedAtLocal,
                id: id,
                date: date,
                feeling: feeling,
                comment: comment,
                healthRecordId: healthRecordId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime updatedAt,
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAtLocal = const i0.Value.absent(),
                required String id,
                required DateTime date,
                required String feeling,
                i0.Value<String?> comment = const i0.Value.absent(),
                required int healthRecordId,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.DailyFeelingsCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                deletedAtLocal: deletedAtLocal,
                id: id,
                date: date,
                feeling: feeling,
                comment: comment,
                healthRecordId: healthRecordId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyFeelingsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.$DailyFeelingsTable,
      i1.DailyFeeling,
      i2.$$DailyFeelingsTableFilterComposer,
      i2.$$DailyFeelingsTableOrderingComposer,
      i2.$$DailyFeelingsTableAnnotationComposer,
      $$DailyFeelingsTableCreateCompanionBuilder,
      $$DailyFeelingsTableUpdateCompanionBuilder,
      (
        i1.DailyFeeling,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i2.$DailyFeelingsTable,
          i1.DailyFeeling
        >,
      ),
      i1.DailyFeeling,
      i0.PrefetchHooks Function()
    >;

class $DailyFeelingsTable extends i1.DailyFeelings
    with i0.TableInfo<$DailyFeelingsTable, i1.DailyFeeling> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyFeelingsTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _dateMeta = const i0.VerificationMeta(
    'date',
  );
  @override
  late final i0.GeneratedColumn<DateTime> date = i0.GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: i0.DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _feelingMeta = const i0.VerificationMeta(
    'feeling',
  );
  @override
  late final i0.GeneratedColumn<String> feeling = i0.GeneratedColumn<String>(
    'feeling',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _commentMeta = const i0.VerificationMeta(
    'comment',
  );
  @override
  late final i0.GeneratedColumn<String> comment = i0.GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _healthRecordIdMeta =
      const i0.VerificationMeta('healthRecordId');
  @override
  late final i0.GeneratedColumn<int> healthRecordId = i0.GeneratedColumn<int>(
    'health_record_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    deletedAtLocal,
    id,
    date,
    feeling,
    comment,
    healthRecordId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_feelings';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.DailyFeeling> instance, {
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
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('feeling')) {
      context.handle(
        _feelingMeta,
        feeling.isAcceptableOrUnknown(data['feeling']!, _feelingMeta),
      );
    } else if (isInserting) {
      context.missing(_feelingMeta);
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('health_record_id')) {
      context.handle(
        _healthRecordIdMeta,
        healthRecordId.isAcceptableOrUnknown(
          data['health_record_id']!,
          _healthRecordIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_healthRecordIdMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.DailyFeeling map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.DailyFeeling(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
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
      date: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      feeling: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}feeling'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      healthRecordId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}health_record_id'],
      )!,
    );
  }

  @override
  $DailyFeelingsTable createAlias(String alias) {
    return $DailyFeelingsTable(attachedDatabase, alias);
  }
}

class DailyFeelingsCompanion extends i0.UpdateCompanion<i1.DailyFeeling> {
  final i0.Value<DateTime> updatedAt;
  final i0.Value<DateTime?> deletedAt;
  final i0.Value<DateTime?> deletedAtLocal;
  final i0.Value<String> id;
  final i0.Value<DateTime> date;
  final i0.Value<String> feeling;
  final i0.Value<String?> comment;
  final i0.Value<int> healthRecordId;
  final i0.Value<int> rowid;
  const DailyFeelingsCompanion({
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
    this.deletedAtLocal = const i0.Value.absent(),
    this.id = const i0.Value.absent(),
    this.date = const i0.Value.absent(),
    this.feeling = const i0.Value.absent(),
    this.comment = const i0.Value.absent(),
    this.healthRecordId = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  DailyFeelingsCompanion.insert({
    required DateTime updatedAt,
    this.deletedAt = const i0.Value.absent(),
    this.deletedAtLocal = const i0.Value.absent(),
    required String id,
    required DateTime date,
    required String feeling,
    this.comment = const i0.Value.absent(),
    required int healthRecordId,
    this.rowid = const i0.Value.absent(),
  }) : updatedAt = i0.Value(updatedAt),
       id = i0.Value(id),
       date = i0.Value(date),
       feeling = i0.Value(feeling),
       healthRecordId = i0.Value(healthRecordId);
  static i0.Insertable<i1.DailyFeeling> custom({
    i0.Expression<DateTime>? updatedAt,
    i0.Expression<DateTime>? deletedAt,
    i0.Expression<DateTime>? deletedAtLocal,
    i0.Expression<String>? id,
    i0.Expression<DateTime>? date,
    i0.Expression<String>? feeling,
    i0.Expression<String>? comment,
    i0.Expression<int>? healthRecordId,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deletedAtLocal != null) 'deleted_at_local': deletedAtLocal,
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (feeling != null) 'feeling': feeling,
      if (comment != null) 'comment': comment,
      if (healthRecordId != null) 'health_record_id': healthRecordId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.DailyFeelingsCompanion copyWith({
    i0.Value<DateTime>? updatedAt,
    i0.Value<DateTime?>? deletedAt,
    i0.Value<DateTime?>? deletedAtLocal,
    i0.Value<String>? id,
    i0.Value<DateTime>? date,
    i0.Value<String>? feeling,
    i0.Value<String?>? comment,
    i0.Value<int>? healthRecordId,
    i0.Value<int>? rowid,
  }) {
    return i2.DailyFeelingsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedAtLocal: deletedAtLocal ?? this.deletedAtLocal,
      id: id ?? this.id,
      date: date ?? this.date,
      feeling: feeling ?? this.feeling,
      comment: comment ?? this.comment,
      healthRecordId: healthRecordId ?? this.healthRecordId,
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
    if (date.present) {
      map['date'] = i0.Variable<DateTime>(date.value);
    }
    if (feeling.present) {
      map['feeling'] = i0.Variable<String>(feeling.value);
    }
    if (comment.present) {
      map['comment'] = i0.Variable<String>(comment.value);
    }
    if (healthRecordId.present) {
      map['health_record_id'] = i0.Variable<int>(healthRecordId.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyFeelingsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deletedAtLocal: $deletedAtLocal, ')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('feeling: $feeling, ')
          ..write('comment: $comment, ')
          ..write('healthRecordId: $healthRecordId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class _$DailyFeelingInsertable implements i0.Insertable<i1.DailyFeeling> {
  i1.DailyFeeling _object;
  _$DailyFeelingInsertable(this._object);
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    return i2.DailyFeelingsCompanion(
      updatedAt: i0.Value(_object.updatedAt),
      deletedAt: i0.Value(_object.deletedAt),
      deletedAtLocal: i0.Value(_object.deletedAtLocal),
      id: i0.Value(_object.id),
      date: i0.Value(_object.date),
      feeling: i0.Value(_object.feeling),
      comment: i0.Value(_object.comment),
      healthRecordId: i0.Value(_object.healthRecordId),
    ).toColumns(false);
  }
}

extension DailyFeelingToInsertable on i1.DailyFeeling {
  _$DailyFeelingInsertable toInsertable() {
    return _$DailyFeelingInsertable(this);
  }
}
