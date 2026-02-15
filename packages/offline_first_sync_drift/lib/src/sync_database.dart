import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/src/constants.dart';
import 'package:offline_first_sync_drift/src/cursor.dart';
import 'package:offline_first_sync_drift/src/op.dart';
import 'package:offline_first_sync_drift/src/tables/cursors.drift.dart';
import 'package:offline_first_sync_drift/src/tables/outbox.drift.dart';
import 'package:offline_first_sync_drift/src/tables/outbox_meta.drift.dart';
import 'package:offline_first_sync_drift/src/tables/sync_data_classes.dart';

/// Mixin for databases with synchronization support.
///
/// Usage:
/// 1. Add to `@DriftDatabase`:
///    `include: {'package:offline_first_sync_drift/src/sync_tables.drift'}`
/// 2. Add `with SyncDatabaseMixin` to your database class.
///
/// Drift will automatically include the `sync_outbox` and `sync_cursors` tables.
mixin SyncDatabaseMixin on GeneratedDatabase {
  TableInfo<Table, SyncOutboxData>? _outboxTable;
  TableInfo<Table, SyncOutboxMetaData>? _outboxMetaTable;
  TableInfo<Table, SyncCursorData>? _cursorsTable;

  /// Get outbox table.
  TableInfo<Table, SyncOutboxData> get _outbox =>
      _outboxTable ??= allTables
          .whereType<TableInfo<Table, SyncOutboxData>>()
          .firstWhere(
            (t) => t.actualTableName == 'sync_outbox',
            orElse:
                () =>
                    throw StateError(
                      'SyncOutbox table not found. Make sure to add:\n'
                      "include: {'package:offline_first_sync_drift/src/sync_tables.drift'}\n"
                      'to your @DriftDatabase annotation.',
                    ),
          );

  /// Get cursors table.
  TableInfo<Table, SyncCursorData> get _cursors =>
      _cursorsTable ??= allTables
          .whereType<TableInfo<Table, SyncCursorData>>()
          .firstWhere(
            (t) => t.actualTableName == 'sync_cursors',
            orElse:
                () =>
                    throw StateError(
                      'SyncCursors table not found. Make sure to add:\n'
                      "include: {'package:offline_first_sync_drift/src/sync_tables.drift'}\n"
                      'to your @DriftDatabase annotation.',
                    ),
          );

  /// Get outbox meta table.
  TableInfo<Table, SyncOutboxMetaData> get _outboxMeta =>
      _outboxMetaTable ??= allTables
          .whereType<TableInfo<Table, SyncOutboxMetaData>>()
          .firstWhere(
            (t) => t.actualTableName == TableNames.syncOutboxMeta,
            orElse:
                () =>
                    throw StateError(
                      'SyncOutboxMeta table not found. Make sure to add:\n'
                      "include: {'package:offline_first_sync_drift/src/sync_tables.drift'}\n"
                      'to your @DriftDatabase annotation and run migrations.',
                    ),
          );

  /// Add operation to the outbox queue.
  Future<void> enqueue(Op op) async {
    final ts = op.localTimestamp.toUtc().millisecondsSinceEpoch;

    if (op is UpsertOp) {
      final baseTs = op.baseUpdatedAt?.toUtc().millisecondsSinceEpoch;
      final changedFieldsJson =
          op.changedFields != null
              ? jsonEncode(op.changedFields!.toList())
              : null;

      await into(_outbox).insertOnConflictUpdate(
        SyncOutboxCompanion.insert(
          opId: op.opId,
          kind: op.kind,
          entityId: op.id,
          op: OpType.upsert,
          ts: ts,
          payload: Value(jsonEncode(op.payloadJson)),
          tryCount: const Value(0),
          baseUpdatedAt: Value(baseTs),
          changedFields: Value(changedFieldsJson),
        ),
      );
    } else if (op is DeleteOp) {
      final baseTs = op.baseUpdatedAt?.toUtc().millisecondsSinceEpoch;

      await into(_outbox).insertOnConflictUpdate(
        SyncOutboxCompanion.insert(
          opId: op.opId,
          kind: op.kind,
          entityId: op.id,
          op: OpType.delete,
          ts: ts,
          tryCount: const Value(0),
          baseUpdatedAt: Value(baseTs),
        ),
      );
    }
  }

  /// Get queued operations for sending.
  ///
  /// If [kinds] is provided, only operations for those entity kinds are returned.
  /// If [maxTryCountExclusive] is set, only operations with smaller tryCount
  /// are returned.
  Future<List<Op>> takeOutbox({
    int limit = 100,
    Set<String>? kinds,
    int? maxTryCountExclusive,
  }) async {
    final rows = await _selectOutboxRows(
      limit: limit,
      kinds: kinds,
      maxTryCountExclusive: maxTryCountExclusive,
    );
    return _rowsToOps(rows);
  }

  Future<List<QueryRow>> _selectOutboxRows({
    required int limit,
    Set<String>? kinds,
    int? maxTryCountExclusive,
  }) {
    final hasKindsFilter = kinds != null;
    final hasTryFilter = maxTryCountExclusive != null;
    if (hasKindsFilter && kinds.isEmpty) {
      return Future.value(const <QueryRow>[]);
    }

    final whereParts = <String>[];
    final variables = <Variable<Object>>[];

    if (hasKindsFilter) {
      final kindList = kinds.toList()..sort();
      final placeholders = List.filled(kindList.length, '?').join(', ');
      whereParts.add('${TableColumns.kind} IN ($placeholders)');
      variables.addAll(kindList.map(Variable.withString));
    }

    if (hasTryFilter) {
      whereParts.add('${TableColumns.tryCount} < ?');
      variables.add(Variable.withInt(maxTryCountExclusive));
    }

    final whereClause =
        whereParts.isEmpty ? '' : 'WHERE ${whereParts.join(' AND ')} ';
    variables.add(Variable.withInt(limit));

    return customSelect(
      'SELECT * FROM ${TableNames.syncOutbox} '
      '$whereClause'
      'ORDER BY ${TableColumns.ts} LIMIT ?',
      variables: variables,
      readsFrom: {_outbox},
    ).get();
  }

  /// Watch pending outbox count as a stream.
  Stream<int> watchOutboxCount({
    Set<String>? kinds,
    int? maxTryCountExclusive,
  }) {
    final hasKindsFilter = kinds != null;
    final hasTryFilter = maxTryCountExclusive != null;
    if (hasKindsFilter && kinds.isEmpty) {
      return Stream<int>.value(0);
    }

    final whereParts = <String>[];
    final variables = <Variable<Object>>[];

    if (hasKindsFilter) {
      final kindList = kinds.toList()..sort();
      final placeholders = List.filled(kindList.length, '?').join(', ');
      whereParts.add('${TableColumns.kind} IN ($placeholders)');
      variables.addAll(kindList.map(Variable.withString));
    }

    if (hasTryFilter) {
      whereParts.add('${TableColumns.tryCount} < ?');
      variables.add(Variable.withInt(maxTryCountExclusive));
    }

    final whereClause =
        whereParts.isEmpty ? '' : 'WHERE ${whereParts.join(' AND ')}';
    return customSelect(
      'SELECT COUNT(*) as c FROM ${TableNames.syncOutbox} $whereClause',
      variables: variables,
      readsFrom: {_outbox},
    ).watch().map((rows) => rows.first.read<int>('c'));
  }

  /// Watch stuck operations count.
  Stream<int> watchStuckOutboxCount({
    required int minTryCount,
    Set<String>? kinds,
  }) {
    final hasKindsFilter = kinds != null;
    if (hasKindsFilter && kinds.isEmpty) {
      return Stream<int>.value(0);
    }

    final whereParts = <String>['${TableColumns.tryCount} >= ?'];
    final variables = <Variable<Object>>[Variable.withInt(minTryCount)];

    if (hasKindsFilter) {
      final kindList = kinds.toList()..sort();
      final placeholders = List.filled(kindList.length, '?').join(', ');
      whereParts.add('${TableColumns.kind} IN ($placeholders)');
      variables.addAll(kindList.map(Variable.withString));
    }

    final whereClause = 'WHERE ${whereParts.join(' AND ')}';
    return customSelect(
      'SELECT COUNT(*) as c FROM ${TableNames.syncOutbox} $whereClause',
      variables: variables,
      readsFrom: {_outbox},
    ).watch().map((rows) => rows.first.read<int>('c'));
  }

  /// Increment try count for operations.
  Future<void> incrementOutboxTryCount(Iterable<String> opIds) async {
    if (opIds.isEmpty) return;
    final ids = opIds.toList();
    final placeholders = List.filled(ids.length, '?').join(', ');
    await customStatement(
      'UPDATE ${TableNames.syncOutbox} '
      'SET ${TableColumns.tryCount} = ${TableColumns.tryCount} + 1 '
      'WHERE ${TableColumns.opId} IN ($placeholders)',
      ids,
    );
  }

  /// Reset try count for operations.
  Future<void> resetOutboxTryCount(Iterable<String> opIds) async {
    if (opIds.isEmpty) return;
    final ids = opIds.toList();
    final placeholders = List.filled(ids.length, '?').join(', ');
    await customStatement(
      'UPDATE ${TableNames.syncOutbox} '
      'SET ${TableColumns.tryCount} = 0 '
      'WHERE ${TableColumns.opId} IN ($placeholders)',
      ids,
    );
  }

  /// Record outbox failures: increment tryCount and store last error metadata.
  Future<void> recordOutboxFailures(
    Map<String, String> errors, {
    DateTime? triedAt,
  }) async {
    if (errors.isEmpty) return;
    final ts = (triedAt ?? DateTime.now().toUtc()).millisecondsSinceEpoch;

    await transaction(() async {
      await incrementOutboxTryCount(errors.keys);

      try {
        for (final entry in errors.entries) {
          await into(_outboxMeta).insertOnConflictUpdate(
            SyncOutboxMetaCompanion.insert(
              opId: entry.key,
              lastTriedAt: Value(ts),
              lastError: Value(entry.value),
            ),
          );
        }
      } catch (_) {
        // Metadata is optional; ignore if table is unavailable.
      }
    });
  }

  /// Remove outbox metadata for the specified operations.
  Future<void> deleteOutboxMeta(Iterable<String> opIds) async {
    if (opIds.isEmpty) return;
    final ids = opIds.toList();
    final placeholders = List.filled(ids.length, '?').join(', ');
    await customStatement(
      'DELETE FROM ${TableNames.syncOutboxMeta} '
      'WHERE ${TableColumns.opId} IN ($placeholders)',
      ids,
    );
  }

  /// Count stuck operations by try-count threshold.
  Future<int> countStuckOutbox({
    required int minTryCount,
    Set<String>? kinds,
  }) async {
    final hasKindsFilter = kinds != null;
    if (hasKindsFilter && kinds.isEmpty) return 0;

    final whereParts = <String>['${TableColumns.tryCount} >= ?'];
    final variables = <Variable<Object>>[Variable.withInt(minTryCount)];

    if (hasKindsFilter) {
      final kindList = kinds.toList()..sort();
      final placeholders = List.filled(kindList.length, '?').join(', ');
      whereParts.add('${TableColumns.kind} IN ($placeholders)');
      variables.addAll(kindList.map(Variable.withString));
    }

    final whereClause = 'WHERE ${whereParts.join(' AND ')}';
    final rows =
        await customSelect(
          'SELECT COUNT(*) as c FROM ${TableNames.syncOutbox} $whereClause',
          variables: variables,
          readsFrom: {_outbox},
        ).get();
    return rows.first.read<int>('c');
  }

  /// Get operations considered stuck by try-count threshold.
  Future<List<Op>> getStuckOutbox({
    required int minTryCount,
    int limit = 100,
    Set<String>? kinds,
  }) async {
    if (minTryCount <= 0) {
      throw ArgumentError.value(minTryCount, 'minTryCount', 'must be > 0');
    }
    final hasKindsFilter = kinds != null;
    if (hasKindsFilter && kinds.isEmpty) return const <Op>[];

    final whereParts = <String>['${TableColumns.tryCount} >= ?'];
    final variables = <Variable<Object>>[Variable.withInt(minTryCount)];

    if (hasKindsFilter) {
      final kindList = kinds.toList()..sort();
      final placeholders = List.filled(kindList.length, '?').join(', ');
      whereParts.add('${TableColumns.kind} IN ($placeholders)');
      variables.addAll(kindList.map(Variable.withString));
    }

    final whereClause = whereParts.join(' AND ');
    variables.add(Variable.withInt(limit));
    final rows =
        await customSelect(
          'SELECT * FROM ${TableNames.syncOutbox} '
          'WHERE $whereClause '
          'ORDER BY ${TableColumns.ts} LIMIT ?',
          variables: variables,
          readsFrom: {_outbox},
        ).get();
    return _rowsToOps(rows);
  }

  List<Op> _rowsToOps(List<QueryRow> rows) {
    return rows.map((row) {
      final opId = row.read<String>(TableColumns.opId);
      final kind = row.read<String>(TableColumns.kind);
      final entityId = row.read<String>(TableColumns.entityId);
      final opType = row.read<String>(TableColumns.op);
      final tsMillis = row.read<int>(TableColumns.ts);
      final baseUpdatedAtMillis = row.readNullable<int>(
        TableColumns.baseUpdatedAt,
      );

      final ts = DateTime.fromMillisecondsSinceEpoch(tsMillis, isUtc: true);
      final baseUpdatedAt =
          baseUpdatedAtMillis != null
              ? DateTime.fromMillisecondsSinceEpoch(
                baseUpdatedAtMillis,
                isUtc: true,
              )
              : null;

      if (opType == OpType.delete) {
        return DeleteOp(
          opId: opId,
          kind: kind,
          id: entityId,
          localTimestamp: ts,
          baseUpdatedAt: baseUpdatedAt,
        );
      }

      final payloadStr = row.readNullable<String>(TableColumns.payload);
      final payload =
          payloadStr == null
              ? <String, Object?>{}
              : (jsonDecode(payloadStr) as Map<String, Object?>);
      final changedFieldsStr = row.readNullable<String>(
        TableColumns.changedFields,
      );
      Set<String>? changedFields;
      if (changedFieldsStr != null) {
        final list = jsonDecode(changedFieldsStr) as List<dynamic>;
        changedFields = list.cast<String>().toSet();
      }

      return UpsertOp(
        opId: opId,
        kind: kind,
        id: entityId,
        localTimestamp: ts,
        payloadJson: payload,
        baseUpdatedAt: baseUpdatedAt,
        changedFields: changedFields,
      );
    }).toList();
  }

  /// Acknowledge sent operations (remove from queue).
  Future<void> ackOutbox(Iterable<String> opIds) async {
    if (opIds.isEmpty) return;
    final ids = opIds.toList();
    final placeholders = List.filled(ids.length, '?').join(', ');

    await customStatement(
      'DELETE FROM ${TableNames.syncOutbox} WHERE ${TableColumns.opId} IN ($placeholders)',
      ids,
    );

    // Best-effort cleanup for metadata.
    try {
      await customStatement(
        'DELETE FROM ${TableNames.syncOutboxMeta} '
        'WHERE ${TableColumns.opId} IN ($placeholders)',
        ids,
      );
    } catch (_) {}
  }

  /// Get cursor for an entity kind.
  Future<Cursor?> getCursor(String kind) async {
    final rows =
        await customSelect(
          'SELECT ${TableColumns.ts}, ${TableColumns.lastId} '
          'FROM ${TableNames.syncCursors} WHERE ${TableColumns.kind} = ?',
          variables: [Variable.withString(kind)],
          readsFrom: {_cursors},
        ).get();

    if (rows.isEmpty) return null;

    final row = rows.first;
    return Cursor(
      ts: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>(TableColumns.ts),
        isUtc: true,
      ),
      lastId: row.read<String>(TableColumns.lastId),
    );
  }

  /// Save cursor for an entity kind.
  Future<void> setCursor(String kind, Cursor cursor) async {
    await into(_cursors).insertOnConflictUpdate(
      SyncCursorsCompanion.insert(
        kind: kind,
        ts: cursor.ts.toUtc().millisecondsSinceEpoch,
        lastId: cursor.lastId,
      ),
    );
  }

  /// Purge operations older than threshold.
  Future<int> purgeOutboxOlderThan(DateTime threshold) async {
    final th = threshold.toUtc().millisecondsSinceEpoch;
    return customUpdate(
      'DELETE FROM ${TableNames.syncOutbox} WHERE ${TableColumns.ts} <= ?',
      variables: [Variable.withInt(th)],
      updateKind: UpdateKind.delete,
    );
  }

  /// Reset all cursors for the specified kinds.
  Future<void> resetAllCursors(Set<String> kinds) async {
    if (kinds.isEmpty) return;

    final placeholders = List.filled(kinds.length, '?').join(', ');
    await customStatement(
      'DELETE FROM ${TableNames.syncCursors} WHERE ${TableColumns.kind} IN ($placeholders)',
      kinds.toList(),
    );
  }

  /// Clear data from syncable tables.
  /// [tableNames] - table names to clear.
  Future<void> clearSyncableTables(List<String> tableNames) async {
    for (final tableName in tableNames) {
      await customStatement('DELETE FROM "$tableName"');
    }
  }
}
