import 'package:offline_first_sync_drift/src/conflict_resolution.dart';
import 'package:offline_first_sync_drift/src/exceptions.dart';
import 'package:offline_first_sync_drift/src/sync_error.dart';
import 'package:offline_first_sync_drift/src/sync_events.dart';
import 'package:test/test.dart';

void main() {
  group('SyncPhase', () {
    test('has push and pull values', () {
      expect(SyncPhase.values, hasLength(2));
      expect(SyncPhase.values, contains(SyncPhase.push));
      expect(SyncPhase.values, contains(SyncPhase.pull));
    });
  });

  group('FullResyncReason', () {
    test('has scheduled and manual values', () {
      expect(FullResyncReason.values, hasLength(2));
      expect(FullResyncReason.values, contains(FullResyncReason.scheduled));
      expect(FullResyncReason.values, contains(FullResyncReason.manual));
    });
  });

  group('FullResyncStarted', () {
    test('creates with reason', () {
      final event = FullResyncStarted(FullResyncReason.scheduled);

      expect(event, isA<SyncEvent>());
      expect(event.reason, equals(FullResyncReason.scheduled));
    });

    test('toString includes reason', () {
      final event = FullResyncStarted(FullResyncReason.manual);

      expect(
        event.toString(),
        equals('FullResyncStarted(FullResyncReason.manual)'),
      );
    });
  });

  group('SyncStarted', () {
    test('creates with push phase', () {
      final event = SyncStarted(SyncPhase.push);

      expect(event, isA<SyncEvent>());
      expect(event.phase, equals(SyncPhase.push));
    });

    test('creates with pull phase', () {
      final event = SyncStarted(SyncPhase.pull);

      expect(event.phase, equals(SyncPhase.pull));
    });

    test('toString includes phase', () {
      final event = SyncStarted(SyncPhase.push);

      expect(event.toString(), equals('SyncStarted(SyncPhase.push)'));
    });
  });

  group('SyncProgress', () {
    test('creates with phase, done and total', () {
      final event = SyncProgress(SyncPhase.pull, 50, 100);

      expect(event, isA<SyncEvent>());
      expect(event.phase, equals(SyncPhase.pull));
      expect(event.done, equals(50));
      expect(event.total, equals(100));
    });

    test('progress returns correct ratio', () {
      final event = SyncProgress(SyncPhase.push, 25, 100);

      expect(event.progress, equals(0.25));
    });

    test('progress returns 0 when total is 0', () {
      final event = SyncProgress(SyncPhase.push, 0, 0);

      expect(event.progress, equals(0));
    });

    test('progress returns 1.0 when done equals total', () {
      final event = SyncProgress(SyncPhase.pull, 50, 50);

      expect(event.progress, equals(1.0));
    });

    test('toString includes phase and progress', () {
      final event = SyncProgress(SyncPhase.push, 30, 60);

      expect(event.toString(), equals('SyncProgress(SyncPhase.push, 30/60)'));
    });
  });

  group('SyncCompleted', () {
    test('creates with took and at', () {
      const duration = Duration(milliseconds: 1500);
      final time = DateTime.utc(2024, 1, 15, 10, 30);
      final event = SyncCompleted(duration, time);

      expect(event, isA<SyncEvent>());
      expect(event.took, equals(duration));
      expect(event.at, equals(time));
      expect(event.stats, isNull);
    });

    test('creates with stats', () {
      const stats = SyncStats(pushed: 10, pulled: 20, conflicts: 2);
      final event = SyncCompleted(
        const Duration(seconds: 2),
        DateTime.utc(2024, 1, 1),
        stats: stats,
      );

      expect(event.stats, equals(stats));
    });

    test('toString includes duration', () {
      final event = SyncCompleted(
        const Duration(milliseconds: 500),
        DateTime.utc(2024, 1, 1),
      );

      expect(event.toString(), equals('SyncCompleted(took: 500ms)'));
    });
  });

  group('SyncStats', () {
    test('creates with default values', () {
      const stats = SyncStats();

      expect(stats.pushed, equals(0));
      expect(stats.pulled, equals(0));
      expect(stats.conflicts, equals(0));
      expect(stats.conflictsResolved, equals(0));
      expect(stats.errors, equals(0));
    });

    test('creates with custom values', () {
      const stats = SyncStats(
        pushed: 5,
        pulled: 10,
        conflicts: 2,
        conflictsResolved: 1,
        errors: 1,
      );

      expect(stats.pushed, equals(5));
      expect(stats.pulled, equals(10));
      expect(stats.conflicts, equals(2));
      expect(stats.conflictsResolved, equals(1));
      expect(stats.errors, equals(1));
    });

    test('copyWith preserves values when null passed', () {
      const original = SyncStats(pushed: 5, pulled: 10);

      final copied = original.copyWith();

      expect(copied.pushed, equals(5));
      expect(copied.pulled, equals(10));
      expect(copied.conflicts, equals(0));
    });

    test('copyWith updates specified values', () {
      const original = SyncStats(pushed: 5);

      final copied = original.copyWith(pulled: 20, conflicts: 3);

      expect(copied.pushed, equals(5));
      expect(copied.pulled, equals(20));
      expect(copied.conflicts, equals(3));
    });

    test('toString includes all values', () {
      const stats = SyncStats(
        pushed: 10,
        pulled: 20,
        conflicts: 3,
        conflictsResolved: 2,
        errors: 1,
      );

      expect(
        stats.toString(),
        equals(
          'SyncStats(pushed: 10, pulled: 20, '
          'conflicts: 3, resolved: 2, errors: 1)',
        ),
      );
    });
  });

  group('SyncErrorEvent', () {
    test('creates with phase and error', () {
      final event = SyncErrorEvent(SyncPhase.push, 'Network error');

      expect(event, isA<SyncEvent>());
      expect(event.phase, equals(SyncPhase.push));
      expect(event.error, equals('Network error'));
      expect(event.stackTrace, isNull);
    });

    test('creates with stack trace', () {
      final stackTrace = StackTrace.current;
      final event = SyncErrorEvent(
        SyncPhase.pull,
        Exception('Failed'),
        stackTrace,
      );

      expect(event.stackTrace, equals(stackTrace));
    });

    test('toString includes phase and error', () {
      final event = SyncErrorEvent(SyncPhase.push, 'Timeout');

      expect(event.toString(), equals('SyncError(SyncPhase.push): Timeout'));
    });

    test('maps errorInfo for transport auth error', () {
      final event = SyncErrorEvent(
        SyncPhase.push,
        TransportException.httpError(401),
      );

      expect(event.errorInfo.category, SyncErrorCategory.auth);
      expect(event.errorInfo.retryable, isFalse);
      expect(event.errorInfo.statusCode, 401);
    });
  });

  group('ConflictDetectedEvent', () {
    test('creates with conflict and strategy', () {
      final conflict = Conflict(
        kind: 'users',
        entityId: 'user-1',
        opId: 'op-1',
        localData: {'name': 'Local'},
        serverData: {'name': 'Server'},
        localTimestamp: DateTime.utc(2024, 1, 1),
        serverTimestamp: DateTime.utc(2024, 1, 2),
      );

      final event = ConflictDetectedEvent(
        conflict: conflict,
        strategy: ConflictStrategy.autoPreserve,
      );

      expect(event, isA<SyncEvent>());
      expect(event.conflict, equals(conflict));
      expect(event.strategy, equals(ConflictStrategy.autoPreserve));
    });

    test('toString includes kind, entityId and strategy', () {
      final conflict = Conflict(
        kind: 'tasks',
        entityId: 'task-123',
        opId: 'op-1',
        localData: {},
        serverData: {},
        localTimestamp: DateTime.utc(2024, 1, 1),
        serverTimestamp: DateTime.utc(2024, 1, 2),
      );

      final event = ConflictDetectedEvent(
        conflict: conflict,
        strategy: ConflictStrategy.serverWins,
      );

      expect(
        event.toString(),
        equals(
          'ConflictDetected(tasks/task-123, strategy: ConflictStrategy.serverWins)',
        ),
      );
    });
  });

  group('ConflictResolvedEvent', () {
    test('creates with conflict and resolution', () {
      final conflict = Conflict(
        kind: 'items',
        entityId: 'item-1',
        opId: 'op-1',
        localData: {},
        serverData: {},
        localTimestamp: DateTime.utc(2024, 1, 1),
        serverTimestamp: DateTime.utc(2024, 1, 2),
      );

      final event = ConflictResolvedEvent(
        conflict: conflict,
        resolution: const AcceptServer(),
      );

      expect(event, isA<SyncEvent>());
      expect(event.conflict, equals(conflict));
      expect(event.resolution, isA<AcceptServer>());
      expect(event.resultData, isNull);
    });

    test('creates with result data', () {
      final conflict = Conflict(
        kind: 'docs',
        entityId: 'doc-1',
        opId: 'op-1',
        localData: {},
        serverData: {},
        localTimestamp: DateTime.utc(2024, 1, 1),
        serverTimestamp: DateTime.utc(2024, 1, 2),
      );

      final event = ConflictResolvedEvent(
        conflict: conflict,
        resolution: const AcceptMerged({'merged': true}),
        resultData: {'merged': true, 'from': 'both'},
      );

      expect(event.resultData, equals({'merged': true, 'from': 'both'}));
    });

    test('toString includes kind, entityId and resolution type', () {
      final conflict = Conflict(
        kind: 'users',
        entityId: 'user-5',
        opId: 'op-1',
        localData: {},
        serverData: {},
        localTimestamp: DateTime.utc(2024, 1, 1),
        serverTimestamp: DateTime.utc(2024, 1, 2),
      );

      final event = ConflictResolvedEvent(
        conflict: conflict,
        resolution: const AcceptClient(),
      );

      expect(
        event.toString(),
        equals('ConflictResolved(users/user-5, AcceptClient)'),
      );
    });
  });

  group('ConflictUnresolvedEvent', () {
    test('creates with conflict and reason', () {
      final conflict = Conflict(
        kind: 'orders',
        entityId: 'order-1',
        opId: 'op-1',
        localData: {},
        serverData: {},
        localTimestamp: DateTime.utc(2024, 1, 1),
        serverTimestamp: DateTime.utc(2024, 1, 2),
      );

      final event = ConflictUnresolvedEvent(
        conflict: conflict,
        reason: 'Manual resolution required',
      );

      expect(event, isA<SyncEvent>());
      expect(event.conflict, equals(conflict));
      expect(event.reason, equals('Manual resolution required'));
    });

    test('toString includes kind, entityId and reason', () {
      final conflict = Conflict(
        kind: 'products',
        entityId: 'prod-99',
        opId: 'op-1',
        localData: {},
        serverData: {},
        localTimestamp: DateTime.utc(2024, 1, 1),
        serverTimestamp: DateTime.utc(2024, 1, 2),
      );

      final event = ConflictUnresolvedEvent(
        conflict: conflict,
        reason: 'Max retries exceeded',
      );

      expect(
        event.toString(),
        equals(
          'ConflictUnresolved(products/prod-99, reason: Max retries exceeded)',
        ),
      );
    });
  });

  group('DataMergedEvent', () {
    test('creates with all parameters', () {
      final event = DataMergedEvent(
        kind: 'users',
        entityId: 'user-1',
        localFields: {'name', 'email'},
        serverFields: {'updatedAt', 'version'},
        mergedData: {'name': 'Local', 'updatedAt': '2024-01-01'},
      );

      expect(event, isA<SyncEvent>());
      expect(event.kind, equals('users'));
      expect(event.entityId, equals('user-1'));
      expect(event.localFields, equals({'name', 'email'}));
      expect(event.serverFields, equals({'updatedAt', 'version'}));
      expect(event.mergedData, isNotEmpty);
    });

    test('toString includes kind, entityId and field counts', () {
      final event = DataMergedEvent(
        kind: 'tasks',
        entityId: 'task-5',
        localFields: {'title', 'description', 'status'},
        serverFields: {'createdAt', 'updatedAt'},
        mergedData: {},
      );

      expect(
        event.toString(),
        equals('DataMerged(tasks/task-5, local: 3 fields, server: 2 fields)'),
      );
    });
  });

  group('CacheUpdateEvent', () {
    test('creates with kind only', () {
      final event = CacheUpdateEvent('users');

      expect(event, isA<SyncEvent>());
      expect(event.kind, equals('users'));
      expect(event.upserts, equals(0));
      expect(event.deletes, equals(0));
    });

    test('creates with upserts and deletes', () {
      final event = CacheUpdateEvent('tasks', upserts: 10, deletes: 3);

      expect(event.upserts, equals(10));
      expect(event.deletes, equals(3));
    });

    test('toString includes kind, upserts and deletes', () {
      final event = CacheUpdateEvent('items', upserts: 5, deletes: 2);

      expect(
        event.toString(),
        equals('CacheUpdate(items, upserts: 5, deletes: 2)'),
      );
    });
  });

  group('OperationPushedEvent', () {
    test('creates with all parameters', () {
      final event = OperationPushedEvent(
        opId: 'op-123',
        kind: 'users',
        entityId: 'user-1',
        operationType: 'upsert',
      );

      expect(event, isA<SyncEvent>());
      expect(event.opId, equals('op-123'));
      expect(event.kind, equals('users'));
      expect(event.entityId, equals('user-1'));
      expect(event.operationType, equals('upsert'));
    });

    test('toString includes operation type, kind and entityId', () {
      final event = OperationPushedEvent(
        opId: 'op-456',
        kind: 'tasks',
        entityId: 'task-99',
        operationType: 'delete',
      );

      expect(event.toString(), equals('OperationPushed(delete tasks/task-99)'));
    });
  });

  group('OperationFailedEvent', () {
    test('creates with required parameters', () {
      final event = OperationFailedEvent(
        opId: 'op-err',
        kind: 'users',
        entityId: 'user-1',
        error: 'Network timeout',
      );

      expect(event, isA<SyncEvent>());
      expect(event.opId, equals('op-err'));
      expect(event.kind, equals('users'));
      expect(event.entityId, equals('user-1'));
      expect(event.error, equals('Network timeout'));
      expect(event.willRetry, isFalse);
    });

    test('creates with willRetry true', () {
      final event = OperationFailedEvent(
        opId: 'op-retry',
        kind: 'tasks',
        entityId: 'task-1',
        error: Exception('Server error'),
        willRetry: true,
      );

      expect(event.willRetry, isTrue);
    });

    test('toString includes kind, entityId and retry status', () {
      final event = OperationFailedEvent(
        opId: 'op-1',
        kind: 'items',
        entityId: 'item-5',
        error: 'Error',
        willRetry: true,
      );

      expect(
        event.toString(),
        equals('OperationFailed(items/item-5, retry: true)'),
      );
    });

    test('maps errorInfo for network exception', () {
      final event = OperationFailedEvent(
        opId: 'op-net',
        kind: 'items',
        entityId: 'item-9',
        error: const NetworkException('timeout'),
      );

      expect(event.errorInfo.category, SyncErrorCategory.network);
      expect(event.errorInfo.retryable, isTrue);
    });
  });

  group('New progress events', () {
    test('PullPageProcessedEvent stores values', () {
      final event = PullPageProcessedEvent(
        kind: 'users',
        pageSize: 20,
        totalDone: 60,
      );

      expect(event.kind, 'users');
      expect(event.pageSize, 20);
      expect(event.totalDone, 60);
    });

    test('PushBatchProcessedEvent stores values', () {
      final event = PushBatchProcessedEvent(
        batchSize: 10,
        successCount: 7,
        errorCount: 2,
        conflictCount: 1,
      );

      expect(event.batchSize, 10);
      expect(event.successCount, 7);
      expect(event.errorCount, 2);
      expect(event.conflictCount, 1);
    });
  });

  group('SyncEvent sealed class', () {
    test('all events are SyncEvent subtypes', () {
      final conflict = Conflict(
        kind: 'test',
        entityId: 'id',
        opId: 'op',
        localData: {},
        serverData: {},
        localTimestamp: DateTime.utc(2024, 1, 1),
        serverTimestamp: DateTime.utc(2024, 1, 2),
      );

      final events = <SyncEvent>[
        FullResyncStarted(FullResyncReason.manual),
        SyncStarted(SyncPhase.push),
        SyncProgress(SyncPhase.pull, 1, 10),
        SyncCompleted(const Duration(seconds: 1), DateTime.now()),
        SyncErrorEvent(SyncPhase.push, 'error'),
        ConflictDetectedEvent(
          conflict: conflict,
          strategy: ConflictStrategy.serverWins,
        ),
        ConflictResolvedEvent(
          conflict: conflict,
          resolution: const AcceptServer(),
        ),
        ConflictUnresolvedEvent(conflict: conflict, reason: 'reason'),
        DataMergedEvent(
          kind: 'k',
          entityId: 'id',
          localFields: {},
          serverFields: {},
          mergedData: {},
        ),
        CacheUpdateEvent('kind'),
        OperationPushedEvent(
          opId: 'op',
          kind: 'k',
          entityId: 'id',
          operationType: 'upsert',
        ),
        OperationFailedEvent(
          opId: 'op',
          kind: 'k',
          entityId: 'id',
          error: 'err',
        ),
      ];

      for (final event in events) {
        expect(event, isA<SyncEvent>());
      }
    });
  });
}
