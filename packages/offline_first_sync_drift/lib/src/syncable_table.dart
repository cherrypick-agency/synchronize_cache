import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/src/constants.dart';

/// Configuration for a syncable table.
/// Registered in SyncEngine for automatic synchronization.
class SyncableTable<T> {
  const SyncableTable({
    required this.kind,
    required this.table,
    required this.fromJson,
    required this.toJson,
    this.toInsertable,
    this.getId,
    this.getUpdatedAt,
  });

  /// Entity kind on the server (for example, `daily_feeling`).
  final String kind;

  /// Drift table.
  final TableInfo<Table, T> table;

  /// Factory that creates an entity from server JSON.
  final T Function(Map<String, dynamic> json) fromJson;

  /// Serializes an entity to JSON sent to the server.
  final Map<String, dynamic> Function(T entity) toJson;

  /// Converts an entity to Insertable for DB writes.
  /// If you use `@UseRowClass(T, generateInsertable: true)`,
  /// pass: `toInsertable: (e) => e.toInsertable()`.
  /// If `T` already implements `Insertable<T>`, this can be omitted.
  final Insertable<T> Function(T entity)? toInsertable;

  /// Gets an entity ID. By default searches common ID field names.
  final String Function(T entity)? getId;

  /// Gets an entity updatedAt. By default searches common timestamp fields.
  final DateTime Function(T entity)? getUpdatedAt;

  /// Gets Insertable from an entity.
  Insertable<T> getInsertable(T entity) {
    if (toInsertable != null) {
      return toInsertable!(entity);
    }
    // Fallback: assume entity implements Insertable<T>
    return entity as Insertable<T>;
  }

  /// Gets an entity ID.
  ///
  /// Prefer providing [getId] for best performance and correctness.
  /// Fallback: derives id from [toJson] using [SyncFields.idFields].
  String idOf(T entity) {
    if (getId != null) return getId!(entity);
    final json = toJson(entity);
    for (final key in SyncFields.idFields) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    throw StateError(
      'Cannot determine entity id for kind "$kind". '
      'Provide getId: (e) => e.id (recommended).',
    );
  }

  /// Gets entity updatedAt.
  ///
  /// Prefer providing [getUpdatedAt] for best performance and correctness.
  /// Fallback: derives timestamp from [toJson] using [SyncFields.updatedAtFields].
  DateTime updatedAtOf(T entity) {
    if (getUpdatedAt != null) return getUpdatedAt!(entity);
    final json = toJson(entity);
    for (final key in SyncFields.updatedAtFields) {
      final value = json[key];
      if (value is DateTime) return value.toUtc();
      if (value != null) {
        final parsed = DateTime.tryParse(value.toString());
        if (parsed != null) return parsed.toUtc();
      }
    }
    throw StateError(
      'Cannot determine entity updatedAt for kind "$kind". '
      'Provide getUpdatedAt: (e) => e.updatedAt (recommended).',
    );
  }
}

/// Sugar for concise table registration.
extension SyncTableRegistrationExtension<T> on TableInfo<Table, T> {
  /// Create [SyncableTable] from a Drift table reference.
  ///
  /// Defaults [kind] to `actualTableName` when omitted.
  /// Requires explicit [getId] and [getUpdatedAt] to avoid runtime reflection
  /// fallbacks and fail fast during setup.
  SyncableTable<T> syncTable({
    String? kind,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T entity) toJson,
    Insertable<T> Function(T entity)? toInsertable,
    required String Function(T entity) getId,
    required DateTime Function(T entity) getUpdatedAt,
  }) {
    final resolvedKind = (kind ?? actualTableName).trim();
    if (resolvedKind.isEmpty) {
      throw ArgumentError.value(kind, 'kind', 'kind must not be empty');
    }

    return SyncableTable<T>(
      kind: resolvedKind,
      table: this,
      fromJson: fromJson,
      toJson: toJson,
      toInsertable: toInsertable,
      getId: getId,
      getUpdatedAt: getUpdatedAt,
    );
  }
}
