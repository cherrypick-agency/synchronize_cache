// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:synchronize_cache/src/tables/cursors.drift.dart' as i1;
import 'package:synchronize_cache/src/tables/outbox.drift.dart' as i2;
import 'package:example/models/health_record.drift.dart' as i3;
import 'package:example/models/daily_feeling.drift.dart' as i4;

abstract class $AppDatabase extends i0.GeneratedDatabase {
  $AppDatabase(i0.QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final i1.$SyncCursorsTable syncCursors = i1.$SyncCursorsTable(this);
  late final i2.$SyncOutboxTable syncOutbox = i2.$SyncOutboxTable(this);
  late final i3.$HealthRecordsTable healthRecords = i3.$HealthRecordsTable(
    this,
  );
  late final i4.$DailyFeelingsTable dailyFeelings = i4.$DailyFeelingsTable(
    this,
  );
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [
    syncCursors,
    syncOutbox,
    healthRecords,
    dailyFeelings,
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
  i2.$$SyncOutboxTableTableManager get syncOutbox =>
      i2.$$SyncOutboxTableTableManager(_db, _db.syncOutbox);
  i3.$$HealthRecordsTableTableManager get healthRecords =>
      i3.$$HealthRecordsTableTableManager(_db, _db.healthRecords);
  i4.$$DailyFeelingsTableTableManager get dailyFeelings =>
      i4.$$DailyFeelingsTableTableManager(_db, _db.dailyFeelings);
}
