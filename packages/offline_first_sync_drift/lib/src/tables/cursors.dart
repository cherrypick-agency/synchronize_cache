import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/src/tables/sync_data_classes.dart';

/// Cursor table for stable pull pagination.
/// Stores the last sync position for each kind.
@UseRowClass(SyncCursorData)
class SyncCursors extends Table {
  /// Entity kind.
  TextColumn get kind => text()();

  /// Timestamp of the last item (UTC milliseconds).
  IntColumn get ts => integer()();

  /// ID of the last item to resolve collisions for equal timestamps.
  TextColumn get lastId => text()();

  @override
  Set<Column> get primaryKey => {kind};

  @override
  String get tableName => 'sync_cursors';
}
