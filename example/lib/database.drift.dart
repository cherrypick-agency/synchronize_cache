// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:offline_first_sync_drift/src/tables/cursors.drift.dart' as i1;
import 'package:offline_first_sync_drift/src/tables/outbox_meta.drift.dart'
    as i2;
import 'package:offline_first_sync_drift/src/tables/outbox.drift.dart' as i3;
import 'package:example/models/health_record.drift.dart' as i4;
import 'package:example/models/daily_feeling.drift.dart' as i5;

abstract class $AppDatabase extends i0.GeneratedDatabase {
  $AppDatabase(i0.QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final i1.$SyncCursorsTable syncCursors = i1.$SyncCursorsTable(this);
  late final i2.$SyncOutboxMetaTable syncOutboxMeta = i2.$SyncOutboxMetaTable(
    this,
  );
  late final i3.$SyncOutboxTable syncOutbox = i3.$SyncOutboxTable(this);
  late final i4.$HealthRecordsTable healthRecords = i4.$HealthRecordsTable(
    this,
  );
  late final i5.$DailyFeelingsTable dailyFeelings = i5.$DailyFeelingsTable(
    this,
  );
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [
    syncCursors,
    syncOutboxMeta,
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
  i2.$$SyncOutboxMetaTableTableManager get syncOutboxMeta =>
      i2.$$SyncOutboxMetaTableTableManager(_db, _db.syncOutboxMeta);
  i3.$$SyncOutboxTableTableManager get syncOutbox =>
      i3.$$SyncOutboxTableTableManager(_db, _db.syncOutbox);
  i4.$$HealthRecordsTableTableManager get healthRecords =>
      i4.$$HealthRecordsTableTableManager(_db, _db.healthRecords);
  i5.$$DailyFeelingsTableTableManager get dailyFeelings =>
      i5.$$DailyFeelingsTableTableManager(_db, _db.dailyFeelings);
}
