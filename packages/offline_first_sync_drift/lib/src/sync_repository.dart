import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/src/sync_writer.dart';
import 'package:offline_first_sync_drift/src/syncable_table.dart';

/// Base repository for syncable entities.
///
/// This is an optional DX layer. It does not replace Drift, but provides
/// a consistent "local write + enqueue" API across entity types.
abstract class SyncRepository<T, DB extends GeneratedDatabase> {
  SyncRepository(
    this.db, {
    required SyncableTable<T> syncTable,
    OpIdFactory? opIdFactory,
    SyncClock? clock,
  }) : syncTable = syncTable,
       writer = SyncWriter<DB>(
         db,
         opIdFactory: opIdFactory,
         clock: clock,
       ).forTable(syncTable);

  final DB db;
  final SyncableTable<T> syncTable;
  final SyncEntityWriter<T, DB> writer;

  /// The Drift table for reading/writing.
  TableInfo<Table, T> get table => syncTable.table;

  /// Create a new entity: insert locally + enqueue upsert.
  Future<void> create(T entity) => writer.insertAndEnqueue(entity);

  /// Update an entity: replace locally + enqueue upsert.
  Future<void> update(
    T entity, {
    required DateTime baseUpdatedAt,
    Set<String>? changedFields,
  }) => writer.replaceAndEnqueue(
    entity,
    baseUpdatedAt: baseUpdatedAt,
    changedFields: changedFields,
  );

  /// Enqueue delete for an entity id (no local write).
  Future<void> enqueueDelete(
    String id, {
    DateTime? baseUpdatedAt,
  }) => writer.enqueueDelete(id: id, baseUpdatedAt: baseUpdatedAt);

  /// Apply server state locally without enqueue (used during pull).
  Future<void> upsertFromServer(T entity) async {
    await db.into(table).insertOnConflictUpdate(syncTable.getInsertable(entity));
  }
}

