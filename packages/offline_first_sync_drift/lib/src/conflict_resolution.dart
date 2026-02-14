import 'package:offline_first_sync_drift/src/constants.dart';

/// Strategies and types for sync conflict resolution.

/// Conflict resolution strategy.
enum ConflictStrategy {
  /// Server version always wins.
  serverWins,

  /// Client version always wins (retry with force).
  clientWins,

  /// Version with a newer timestamp wins.
  lastWriteWins,

  /// Try to merge changes.
  merge,

  /// Manual resolution via callback.
  manual,

  /// Automatic smart merge without data loss.
  autoPreserve,
}

/// Conflict resolution result.
sealed class ConflictResolution {
  const ConflictResolution();
}

/// Accept server version.
class AcceptServer extends ConflictResolution {
  const AcceptServer();
}

/// Accept client version (retry push with force).
class AcceptClient extends ConflictResolution {
  const AcceptClient();
}

/// Use merged data.
class AcceptMerged extends ConflictResolution {
  const AcceptMerged(this.mergedData, {this.mergeInfo});

  final Map<String, Object?> mergedData;

  /// Information about field source selection.
  final MergeInfo? mergeInfo;
}

/// Data merge metadata.
class MergeInfo {
  const MergeInfo({required this.localFields, required this.serverFields});

  /// Fields taken from local data.
  final Set<String> localFields;

  /// Fields taken from server data.
  final Set<String> serverFields;
}

/// Defer resolution (keep operation in outbox).
class DeferResolution extends ConflictResolution {
  const DeferResolution();
}

/// Discard operation (remove from outbox).
class DiscardOperation extends ConflictResolution {
  const DiscardOperation();
}

/// Conflict details.
class Conflict {
  const Conflict({
    required this.kind,
    required this.entityId,
    required this.opId,
    required this.localData,
    required this.serverData,
    required this.localTimestamp,
    required this.serverTimestamp,
    this.serverVersion,
    this.changedFields,
  });

  /// Entity kind.
  final String kind;

  /// Entity ID.
  final String entityId;

  /// Operation ID.
  final String opId;

  /// Local client data.
  final Map<String, Object?> localData;

  /// Server data.
  final Map<String, Object?> serverData;

  /// Local change timestamp.
  final DateTime localTimestamp;

  /// Server change timestamp.
  final DateTime serverTimestamp;

  /// Server version (ETag, version number).
  final String? serverVersion;

  /// Fields changed by the client.
  final Set<String>? changedFields;

  @override
  String toString() =>
      'Conflict(kind: $kind, id: $entityId, '
      'local: ${localTimestamp.toIso8601String()}, '
      'server: ${serverTimestamp.toIso8601String()})';
}

/// Callback for manual conflict resolution.
typedef ConflictResolver =
    Future<ConflictResolution> Function(Conflict conflict);

/// Callback for data merging.
typedef MergeFunction =
    Map<String, Object?> Function(
      Map<String, Object?> local,
      Map<String, Object?> server,
    );

/// Push operation result.
sealed class PushResult {
  const PushResult();
}

/// Operation pushed successfully.
class PushSuccess extends PushResult {
  const PushSuccess({this.serverData, this.serverVersion});

  /// Data returned by server (if any).
  final Map<String, Object?>? serverData;

  /// Server version after the operation.
  final String? serverVersion;
}

/// Conflict during push.
class PushConflict extends PushResult {
  const PushConflict({
    required this.serverData,
    required this.serverTimestamp,
    this.serverVersion,
  });

  /// Current server data.
  final Map<String, Object?> serverData;

  /// Server data timestamp.
  final DateTime serverTimestamp;

  /// Server version.
  final String? serverVersion;
}

/// Entity not found on server (for update/delete).
class PushNotFound extends PushResult {
  const PushNotFound();
}

/// Push error (not a conflict).
class PushError extends PushResult {
  const PushError(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;
}

/// Conflict utility functions.
abstract final class ConflictUtils {
  /// System fields that should not be merged.
  static const systemFields = {
    SyncFields.id,
    SyncFields.idUpper,
    SyncFields.uuid,
    SyncFields.updatedAt,
    SyncFields.updatedAtSnake,
    SyncFields.createdAt,
    SyncFields.createdAtSnake,
    SyncFields.deletedAt,
    SyncFields.deletedAtSnake,
  };

  /// Default merge: server fields + changed client fields.
  /// Keeps server values for fields not changed by client.
  static Map<String, Object?> defaultMerge(
    Map<String, Object?> local,
    Map<String, Object?> server,
  ) {
    final merged = Map<String, Object?>.from(server);
    for (final entry in local.entries) {
      if (entry.value != null) {
        merged[entry.key] = entry.value;
      }
    }
    return merged;
  }

  /// Deep merge for nested objects.
  static Map<String, Object?> deepMerge(
    Map<String, Object?> local,
    Map<String, Object?> server,
  ) {
    final merged = <String, Object?>{};

    final allKeys = {...local.keys, ...server.keys};

    for (final key in allKeys) {
      final localValue = local[key];
      final serverValue = server[key];

      if (localValue is Map<String, Object?> &&
          serverValue is Map<String, Object?>) {
        merged[key] = deepMerge(localValue, serverValue);
      } else if (local.containsKey(key)) {
        merged[key] = localValue;
      } else {
        merged[key] = serverValue;
      }
    }

    return merged;
  }

  /// Smart merge that preserves ALL data without loss.
  ///
  /// Rules:
  /// - System fields always come from server
  /// - If [changedFields] is provided, only those local fields are applied
  /// - If local value is non-null and server value is null, use local
  /// - Lists are merged as union
  /// - Nested objects are merged recursively
  static PreservingMergeResult preservingMerge(
    Map<String, Object?> local,
    Map<String, Object?> server, {
    Set<String>? changedFields,
  }) {
    final result = Map<String, Object?>.from(server);
    final localFieldsUsed = <String>{};
    final serverFieldsUsed = <String>{};

    // All server fields are used by default
    for (final key in server.keys) {
      if (!systemFields.contains(key)) {
        serverFieldsUsed.add(key);
      }
    }

    for (final key in local.keys) {
      // System fields always come from server
      if (systemFields.contains(key)) continue;

      final localVal = local[key];
      final serverVal = server[key];

      // If changedFields is provided, apply only those fields
      if (changedFields != null && !changedFields.contains(key)) {
        continue;
      }

      // Both null: skip
      if (localVal == null && serverVal == null) continue;

      // Local is present and server is missing: use local
      if (localVal != null && serverVal == null) {
        result[key] = localVal;
        localFieldsUsed.add(key);
        serverFieldsUsed.remove(key);
        continue;
      }

      // Local is null and server is present: keep server
      if (localVal == null && serverVal != null) {
        continue;
      }

      // Both present: smart merge by value type
      if (localVal is List && serverVal is List) {
        result[key] = _mergeLists(localVal, serverVal);
        localFieldsUsed.add(key);
        // Lists were merged; both sources were used
      } else if (localVal is Map<String, Object?> &&
          serverVal is Map<String, Object?>) {
        final nestedResult = preservingMerge(localVal, serverVal);
        result[key] = nestedResult.data;
        if (nestedResult.localFields.isNotEmpty) {
          localFieldsUsed.add(key);
        }
      } else {
        // Primitive values: use local (user changed it)
        result[key] = localVal;
        localFieldsUsed.add(key);
        serverFieldsUsed.remove(key);
      }
    }

    return PreservingMergeResult(
      data: result,
      localFields: localFieldsUsed,
      serverFields: serverFieldsUsed,
    );
  }

  /// Merge lists.
  static List<Object?> _mergeLists(List<Object?> local, List<Object?> server) {
    final result = List<Object?>.from(server);

    for (final item in local) {
      if (item is Map && item.containsKey(SyncFields.id)) {
        final itemId = item[SyncFields.id];
        final exists = server.any(
          (s) => s is Map && s[SyncFields.id] == itemId,
        );
        if (!exists) {
          result.add(item);
        }
      } else {
        if (!server.contains(item)) {
          result.add(item);
        }
      }
    }

    return result;
  }

  /// Extract timestamp from JSON data.
  static DateTime? extractTimestamp(Map<String, Object?> data) {
    final ts = data[SyncFields.updatedAt] ?? data[SyncFields.updatedAtSnake];
    if (ts == null) return null;
    if (ts is DateTime) return ts;
    return DateTime.tryParse(ts.toString())?.toUtc();
  }
}

/// `preservingMerge` result with field source information.
class PreservingMergeResult {
  const PreservingMergeResult({
    required this.data,
    required this.localFields,
    required this.serverFields,
  });

  /// Merged data.
  final Map<String, Object?> data;

  /// Fields taken from local data.
  final Set<String> localFields;

  /// Fields taken from server data.
  final Set<String> serverFields;
}
