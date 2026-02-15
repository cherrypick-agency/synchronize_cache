import 'dart:async';
import 'dart:math' as math;

import 'package:offline_first_sync_drift/src/config.dart';
import 'package:offline_first_sync_drift/src/conflict_resolution.dart';
import 'package:offline_first_sync_drift/src/constants.dart';
import 'package:offline_first_sync_drift/src/exceptions.dart';
import 'package:offline_first_sync_drift/src/op.dart';
import 'package:offline_first_sync_drift/src/services/conflict_service.dart';
import 'package:offline_first_sync_drift/src/services/outbox_service.dart';
import 'package:offline_first_sync_drift/src/sync_events.dart';
import 'package:offline_first_sync_drift/src/transport_adapter.dart';

/// Push operation statistics.
class PushStats {
  const PushStats({
    this.pushed = 0,
    this.conflicts = 0,
    this.conflictsResolved = 0,
    this.errors = 0,
  });

  final int pushed;
  final int conflicts;
  final int conflictsResolved;
  final int errors;

  PushStats copyWith({
    int? pushed,
    int? conflicts,
    int? conflictsResolved,
    int? errors,
  }) => PushStats(
    pushed: pushed ?? this.pushed,
    conflicts: conflicts ?? this.conflicts,
    conflictsResolved: conflictsResolved ?? this.conflictsResolved,
    errors: errors ?? this.errors,
  );
}

/// Service for pushing local changes to the server.
class PushService {
  PushService({
    required OutboxService outbox,
    required TransportAdapter transport,
    required ConflictService<dynamic> conflictService,
    required SyncConfig config,
    required StreamController<SyncEvent> events,
  }) : _outbox = outbox,
       _transport = transport,
       _conflictService = conflictService,
       _config = config,
       _events = events;

  final OutboxService _outbox;
  final TransportAdapter _transport;
  final ConflictService<dynamic> _conflictService;
  final SyncConfig _config;
  final StreamController<SyncEvent> _events;

  /// Push operations from outbox.
  ///
  /// If [kinds] is provided, only operations for those kinds are processed.
  Future<PushStats> pushAll({Set<String>? kinds}) async {
    final counters = _PushCounters();

    try {
      if (kinds != null && kinds.isEmpty) {
        return counters.toStats();
      }

      while (true) {
        final ops = await _outbox.take(
          limit: _config.pageSize,
          kinds: kinds,
          maxTryCountExclusive: _config.maxOutboxTryCount,
        );
        if (ops.isEmpty) break;

        final result = await _pushBatch(ops);

        final successOpIds = <String>[];
        final conflictOps = <Op, PushConflict>{};
        final failed = <String, String>{};
        var hadPushErrors = false;
        var batchSuccessCount = 0;
        var batchErrorCount = 0;
        var batchConflictCount = 0;

        for (final opResult in result.results) {
          final op = ops.firstWhere((o) => o.opId == opResult.opId);

          switch (opResult.result) {
            case PushSuccess():
              successOpIds.add(opResult.opId);
              counters.pushed++;
              batchSuccessCount++;
              _events.add(
                OperationPushedEvent(
                  opId: op.opId,
                  kind: op.kind,
                  entityId: op.id,
                  operationType: op is UpsertOp ? OpType.upsert : OpType.delete,
                ),
              );

            case final PushConflict conflict:
              counters.conflicts++;
              batchConflictCount++;
              conflictOps[op] = conflict;

            case PushNotFound():
              successOpIds.add(opResult.opId);
              batchSuccessCount++;

            case final PushError error:
              counters.errors++;
              batchErrorCount++;
              hadPushErrors = true;
              failed[op.opId] = error.error.toString();
              _events.add(
                OperationFailedEvent(
                  opId: op.opId,
                  kind: op.kind,
                  entityId: op.id,
                  error: error.error,
                  willRetry: !_config.skipConflictingOps,
                ),
              );
          }
        }

        _events.add(
          PushBatchProcessedEvent(
            batchSize: ops.length,
            successCount: batchSuccessCount,
            errorCount: batchErrorCount,
            conflictCount: batchConflictCount,
          ),
        );

        await _outbox.ack(successOpIds);
        if (failed.isNotEmpty) {
          await _outbox.recordFailures(failed);
        }

        for (final entry in conflictOps.entries) {
          final result = await _conflictService.resolve(entry.key, entry.value);
          if (result.resolved) {
            counters.conflictsResolved++;
            successOpIds.add(entry.key.opId);
          } else if (_config.skipConflictingOps) {
            successOpIds.add(entry.key.opId);
          }
        }

        if (conflictOps.isNotEmpty) {
          await _outbox.ack(
            conflictOps.keys
                .where(
                  (op) =>
                      successOpIds.contains(op.opId) ||
                      _config.skipConflictingOps,
                )
                .map((op) => op.opId),
          );
        }

        // Do not spin on the same failed operations in a single sync run.
        // Leave unresolved items in outbox for the next sync attempt.
        if (hadPushErrors) {
          break;
        }
      }
    } on SyncException {
      rethrow;
    } catch (e, st) {
      throw SyncOperationException(
        'Push failed',
        phase: 'push',
        cause: e,
        stackTrace: st,
      );
    }

    return counters.toStats();
  }

  Future<BatchPushResult> _pushBatch(List<Op> ops) async {
    if (!_config.retryTransportErrorsInEngine) {
      return _transport.push(ops);
    }

    int attempt = 0;
    while (true) {
      try {
        attempt++;
        return await _transport.push(ops);
      } catch (e, st) {
        if (attempt >= _config.maxPushRetries) {
          throw MaxRetriesExceededException(
            'Push failed after $attempt attempts',
            attempts: attempt,
            maxRetries: _config.maxPushRetries,
            cause: e,
            stackTrace: st,
          );
        }
        final backoff =
            _config.backoffMin *
            math.pow(_config.backoffMultiplier, attempt - 1);
        final delay =
            backoff > _config.backoffMax ? _config.backoffMax : backoff;

        await Future<void>.delayed(delay);
      }
    }
  }
}

class _PushCounters {
  int pushed = 0;
  int conflicts = 0;
  int conflictsResolved = 0;
  int errors = 0;

  PushStats toStats() => PushStats(
    pushed: pushed,
    conflicts: conflicts,
    conflictsResolved: conflictsResolved,
    errors: errors,
  );
}
