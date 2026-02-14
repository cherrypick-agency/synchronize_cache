import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/src/tables/sync_data_classes.dart';

/// Outbox table for synchronization operations.
/// Stores local changes until they are sent to the server.
@UseRowClass(SyncOutboxData)
class SyncOutbox extends Table {
  /// Unique operation identifier.
  TextColumn get opId => text()();

  /// Entity kind (for example, `daily_feeling`).
  TextColumn get kind => text()();

  /// Entity ID.
  TextColumn get entityId => text()();

  /// Operation type: `upsert` or `delete`.
  TextColumn get op => text()();

  /// JSON payload for upsert operations.
  TextColumn get payload => text().nullable()();

  /// Operation timestamp (UTC milliseconds).
  IntColumn get ts => integer()();

  /// Number of send attempts.
  IntColumn get tryCount => integer().withDefault(const Constant(0))();

  /// Timestamp when data was last fetched from server (UTC milliseconds).
  IntColumn get baseUpdatedAt => integer().nullable()();

  /// JSON array with changed field names.
  TextColumn get changedFields => text().nullable()();

  @override
  Set<Column> get primaryKey => {opId};

  @override
  String get tableName => 'sync_outbox';
}
