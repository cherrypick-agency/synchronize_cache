import 'package:offline_first_sync_drift/src/conflict_resolution.dart';
import 'package:offline_first_sync_drift/src/sync_error.dart';

/// Synchronization events for logging, UI, and metrics.

sealed class SyncEvent {}

/// Synchronization phase.
enum SyncPhase { push, pull }

/// Reason for triggering a full resync.
enum FullResyncReason {
  /// Triggered by schedule (`fullResyncInterval`).
  scheduled,

  /// Triggered manually.
  manual,
}

/// Full resync started.
class FullResyncStarted implements SyncEvent {
  FullResyncStarted(this.reason);
  final FullResyncReason reason;

  @override
  String toString() => 'FullResyncStarted($reason)';
}

/// Synchronization started.
class SyncStarted implements SyncEvent {
  SyncStarted(this.phase);
  final SyncPhase phase;

  @override
  String toString() => 'SyncStarted($phase)';
}

/// Synchronization progress.
class SyncProgress implements SyncEvent {
  SyncProgress(this.phase, this.done, this.total);
  final SyncPhase phase;
  final int done;
  final int total;

  double get progress => total > 0 ? done / total : 0;

  @override
  String toString() => 'SyncProgress($phase, $done/$total)';
}

/// Synchronization completed.
class SyncCompleted implements SyncEvent {
  SyncCompleted(this.took, this.at, {this.stats});
  final Duration took;
  final DateTime at;
  final SyncStats? stats;

  @override
  String toString() => 'SyncCompleted(took: ${took.inMilliseconds}ms)';
}

/// Synchronization statistics.
class SyncStats {
  const SyncStats({
    this.pushed = 0,
    this.pulled = 0,
    this.conflicts = 0,
    this.conflictsResolved = 0,
    this.errors = 0,
  });

  final int pushed;
  final int pulled;
  final int conflicts;
  final int conflictsResolved;
  final int errors;

  SyncStats copyWith({
    int? pushed,
    int? pulled,
    int? conflicts,
    int? conflictsResolved,
    int? errors,
  }) => SyncStats(
    pushed: pushed ?? this.pushed,
    pulled: pulled ?? this.pulled,
    conflicts: conflicts ?? this.conflicts,
    conflictsResolved: conflictsResolved ?? this.conflictsResolved,
    errors: errors ?? this.errors,
  );

  @override
  String toString() =>
      'SyncStats(pushed: $pushed, pulled: $pulled, '
      'conflicts: $conflicts, resolved: $conflictsResolved, errors: $errors)';
}

/// Synchronization error.
class SyncErrorEvent implements SyncEvent {
  SyncErrorEvent(this.phase, this.error, [this.stackTrace])
    : errorInfo = SyncErrorInfo.fromError(error);
  final SyncPhase phase;
  final Object error;
  final StackTrace? stackTrace;
  final SyncErrorInfo errorInfo;

  @override
  String toString() => 'SyncError($phase): $error';
}

/// Data conflict detected.
class ConflictDetectedEvent implements SyncEvent {
  ConflictDetectedEvent({required this.conflict, required this.strategy});

  /// Conflict information.
  final Conflict conflict;

  /// Strategy that will be applied.
  final ConflictStrategy strategy;

  @override
  String toString() =>
      'ConflictDetected(${conflict.kind}/${conflict.entityId}, '
      'strategy: $strategy)';
}

/// Conflict resolved.
class ConflictResolvedEvent implements SyncEvent {
  ConflictResolvedEvent({
    required this.conflict,
    required this.resolution,
    this.resultData,
  });

  /// Conflict information.
  final Conflict conflict;

  /// Applied conflict resolution.
  final ConflictResolution resolution;

  /// Final data after resolution.
  final Map<String, Object?>? resultData;

  @override
  String toString() =>
      'ConflictResolved(${conflict.kind}/${conflict.entityId}, '
      '${resolution.runtimeType})';
}

/// Conflict could not be resolved automatically.
class ConflictUnresolvedEvent implements SyncEvent {
  ConflictUnresolvedEvent({required this.conflict, required this.reason});

  /// Conflict information.
  final Conflict conflict;

  /// Why resolution failed.
  final String reason;

  @override
  String toString() =>
      'ConflictUnresolved(${conflict.kind}/${conflict.entityId}, '
      'reason: $reason)';
}

/// Data was merged during conflict resolution.
class DataMergedEvent implements SyncEvent {
  DataMergedEvent({
    required this.kind,
    required this.entityId,
    required this.localFields,
    required this.serverFields,
    required this.mergedData,
  });

  /// Entity kind.
  final String kind;

  /// Entity ID.
  final String entityId;

  /// Fields taken from local data.
  final Set<String> localFields;

  /// Fields taken from server data.
  final Set<String> serverFields;

  /// Merged data.
  final Map<String, Object?> mergedData;

  @override
  String toString() =>
      'DataMerged($kind/$entityId, '
      'local: ${localFields.length} fields, server: ${serverFields.length} fields)';
}

/// Cache update.
class CacheUpdateEvent implements SyncEvent {
  CacheUpdateEvent(this.kind, {this.upserts = 0, this.deletes = 0});
  final String kind;
  final int upserts;
  final int deletes;

  @override
  String toString() =>
      'CacheUpdate($kind, upserts: $upserts, deletes: $deletes)';
}

/// Operation pushed successfully.
class OperationPushedEvent implements SyncEvent {
  OperationPushedEvent({
    required this.opId,
    required this.kind,
    required this.entityId,
    required this.operationType,
  });

  final String opId;
  final String kind;
  final String entityId;
  final String operationType;

  @override
  String toString() => 'OperationPushed($operationType $kind/$entityId)';
}

/// Operation failed.
class OperationFailedEvent implements SyncEvent {
  OperationFailedEvent({
    required this.opId,
    required this.kind,
    required this.entityId,
    required this.error,
    this.willRetry = false,
  }) : errorInfo = SyncErrorInfo.fromError(error);

  final String opId;
  final String kind;
  final String entityId;
  final Object error;
  final bool willRetry;
  final SyncErrorInfo errorInfo;

  @override
  String toString() => 'OperationFailed($kind/$entityId, retry: $willRetry)';
}

/// Pull page processed.
class PullPageProcessedEvent implements SyncEvent {
  PullPageProcessedEvent({
    required this.kind,
    required this.pageSize,
    required this.totalDone,
  });

  final String kind;
  final int pageSize;
  final int totalDone;
}

/// Push batch processed.
class PushBatchProcessedEvent implements SyncEvent {
  PushBatchProcessedEvent({
    required this.batchSize,
    required this.successCount,
    required this.errorCount,
    required this.conflictCount,
  });

  final int batchSize;
  final int successCount;
  final int errorCount;
  final int conflictCount;
}
