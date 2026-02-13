import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/src/sync_writer.dart';
import 'package:offline_first_sync_drift/src/syncable_table.dart';

/// One-liner helpers for "local write + enqueue" flows.
///
/// These are convenience wrappers over [SyncWriter] / [SyncEntityWriter].
extension SyncDatabaseDx on GeneratedDatabase {
  /// Insert [entity] and enqueue an upsert.
  Future<void> insertAndEnqueue<T>(
    SyncableTable<T> table,
    T entity, {
    OpIdFactory? opIdFactory,
    SyncClock? clock,
    String? opId,
    DateTime? localTimestamp,
  }) => syncWriter(opIdFactory: opIdFactory, clock: clock)
      .forTable(table)
      .insertAndEnqueue(entity, opId: opId, localTimestamp: localTimestamp);

  /// Replace [entity] and enqueue an upsert.
  Future<void> replaceAndEnqueue<T>(
    SyncableTable<T> table,
    T entity, {
    required DateTime baseUpdatedAt,
    Set<String>? changedFields,
    OpIdFactory? opIdFactory,
    SyncClock? clock,
    String? opId,
    DateTime? localTimestamp,
  }) => syncWriter(opIdFactory: opIdFactory, clock: clock)
      .forTable(table)
      .replaceAndEnqueue(
        entity,
        baseUpdatedAt: baseUpdatedAt,
        changedFields: changedFields,
        opId: opId,
        localTimestamp: localTimestamp,
      );

  /// Enqueue a delete (without touching local DB).
  Future<void> enqueueDelete<T>(
    SyncableTable<T> table, {
    required String id,
    DateTime? baseUpdatedAt,
    OpIdFactory? opIdFactory,
    SyncClock? clock,
    String? opId,
    DateTime? localTimestamp,
  }) => syncWriter(opIdFactory: opIdFactory, clock: clock)
      .forTable(table)
      .enqueueDelete(
        id: id,
        baseUpdatedAt: baseUpdatedAt,
        opId: opId,
        localTimestamp: localTimestamp,
      );

  /// Run [localWrite] and enqueue delete atomically.
  Future<void> writeAndEnqueueDelete<T>(
    SyncableTable<T> table, {
    required Future<void> Function() localWrite,
    required String id,
    DateTime? baseUpdatedAt,
    OpIdFactory? opIdFactory,
    SyncClock? clock,
    String? opId,
    DateTime? localTimestamp,
  }) => syncWriter(opIdFactory: opIdFactory, clock: clock)
      .forTable(table)
      .writeAndEnqueueDelete(
        localWrite: localWrite,
        id: id,
        baseUpdatedAt: baseUpdatedAt,
        opId: opId,
        localTimestamp: localTimestamp,
      );
}

