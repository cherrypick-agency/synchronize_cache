import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/src/tables/sync_data_classes.dart';

/// Additional metadata for outbox operations.
///
/// This is used for debugging and for "dead-letter/quarantine" UX:
/// it records the last attempt time and last error for each operation.
@UseRowClass(SyncOutboxMetaData)
class SyncOutboxMeta extends Table {
  /// Operation identifier.
  TextColumn get opId => text()();

  /// Last attempt timestamp (UTC milliseconds).
  IntColumn get lastTriedAt => integer().nullable()();

  /// Last error message for this operation.
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {opId};

  @override
  String get tableName => 'sync_outbox_meta';
}
