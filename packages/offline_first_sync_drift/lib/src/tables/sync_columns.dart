import 'package:drift/drift.dart';

/// Marker interface for syncable tables.
/// Allows type-safe checks that a table includes
/// required system fields.
abstract interface class SynchronizableTable {
  DateTimeColumn get updatedAt;
  DateTimeColumn get deletedAt;
  DateTimeColumn get deletedAtLocal;
}

/// Mixin for synchronized tables.
/// Adds standard fields: updatedAt, deletedAt, deletedAtLocal.
mixin SyncColumns on Table implements SynchronizableTable {
  /// Last update time (UTC).
  @override
  DateTimeColumn get updatedAt => dateTime()();

  /// Server-side deletion time (UTC), null if not deleted.
  @override
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Local deletion time (UTC), used for deferred cleanup.
  @override
  DateTimeColumn get deletedAtLocal => dateTime().nullable()();
}
