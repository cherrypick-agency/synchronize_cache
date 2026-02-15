import 'package:offline_first_sync_drift/src/config.dart';
import 'package:offline_first_sync_drift/src/conflict_resolution.dart';
import 'package:test/test.dart';

void main() {
  group('SyncConfig', () {
    test('creates with default values', () {
      const config = SyncConfig();

      expect(config.pageSize, equals(500));
      expect(config.backoffMin, equals(const Duration(seconds: 1)));
      expect(config.backoffMax, equals(const Duration(minutes: 2)));
      expect(config.backoffMultiplier, equals(2.0));
      expect(config.maxPushRetries, equals(5));
      expect(config.fullResyncInterval, equals(const Duration(days: 7)));
      expect(config.pullOnStartup, isFalse);
      expect(config.pushImmediately, isTrue);
      expect(config.reconcileInterval, isNull);
      expect(config.lazyReconcileOnMiss, isFalse);
      expect(config.conflictStrategy, equals(ConflictStrategy.autoPreserve));
      expect(config.conflictResolver, isNull);
      expect(config.mergeFunction, isNull);
      expect(config.maxConflictRetries, equals(3));
      expect(
        config.conflictRetryDelay,
        equals(const Duration(milliseconds: 500)),
      );
      expect(config.skipConflictingOps, isFalse);
      expect(config.maxOutboxTryCount, equals(5));
      expect(config.retryTransportErrorsInEngine, isFalse);
    });

    test('creates with custom values', () {
      Future<ConflictResolution> resolver(Conflict c) async =>
          const AcceptServer();

      Map<String, Object?> mergeFunc(
        Map<String, Object?> local,
        Map<String, Object?> server,
      ) => {...server, ...local};

      final config = SyncConfig(
        pageSize: 100,
        backoffMin: const Duration(milliseconds: 500),
        backoffMax: const Duration(minutes: 5),
        backoffMultiplier: 1.5,
        maxPushRetries: 10,
        fullResyncInterval: const Duration(days: 14),
        pullOnStartup: true,
        pushImmediately: false,
        reconcileInterval: const Duration(hours: 1),
        lazyReconcileOnMiss: true,
        conflictStrategy: ConflictStrategy.manual,
        conflictResolver: resolver,
        mergeFunction: mergeFunc,
        maxConflictRetries: 5,
        conflictRetryDelay: const Duration(seconds: 1),
        skipConflictingOps: true,
        maxOutboxTryCount: 7,
        retryTransportErrorsInEngine: true,
      );

      expect(config.pageSize, equals(100));
      expect(config.backoffMin, equals(const Duration(milliseconds: 500)));
      expect(config.backoffMax, equals(const Duration(minutes: 5)));
      expect(config.backoffMultiplier, equals(1.5));
      expect(config.maxPushRetries, equals(10));
      expect(config.fullResyncInterval, equals(const Duration(days: 14)));
      expect(config.pullOnStartup, isTrue);
      expect(config.pushImmediately, isFalse);
      expect(config.reconcileInterval, equals(const Duration(hours: 1)));
      expect(config.lazyReconcileOnMiss, isTrue);
      expect(config.conflictStrategy, equals(ConflictStrategy.manual));
      expect(config.conflictResolver, isNotNull);
      expect(config.mergeFunction, isNotNull);
      expect(config.maxConflictRetries, equals(5));
      expect(config.conflictRetryDelay, equals(const Duration(seconds: 1)));
      expect(config.skipConflictingOps, isTrue);
      expect(config.maxOutboxTryCount, equals(7));
      expect(config.retryTransportErrorsInEngine, isTrue);
    });

    test('copyWith preserves values when null passed', () {
      const original = SyncConfig(
        pageSize: 200,
        maxPushRetries: 8,
        pullOnStartup: true,
      );

      final copied = original.copyWith();

      expect(copied.pageSize, equals(200));
      expect(copied.maxPushRetries, equals(8));
      expect(copied.pullOnStartup, isTrue);
      expect(copied.backoffMin, equals(original.backoffMin));
    });

    test('copyWith updates specified values', () {
      const original = SyncConfig(pageSize: 200);

      final copied = original.copyWith(
        pageSize: 300,
        maxPushRetries: 15,
        conflictStrategy: ConflictStrategy.serverWins,
      );

      expect(copied.pageSize, equals(300));
      expect(copied.maxPushRetries, equals(15));
      expect(copied.conflictStrategy, equals(ConflictStrategy.serverWins));
      expect(copied.backoffMin, equals(original.backoffMin));
    });

    test('copyWith can update all values', () {
      Future<ConflictResolution> resolver(Conflict c) async =>
          const AcceptClient();

      Map<String, Object?> mergeFunc(
        Map<String, Object?> local,
        Map<String, Object?> server,
      ) => local;

      const original = SyncConfig();

      final copied = original.copyWith(
        pageSize: 1000,
        backoffMin: const Duration(seconds: 2),
        backoffMax: const Duration(minutes: 10),
        backoffMultiplier: 3.0,
        maxPushRetries: 20,
        fullResyncInterval: const Duration(days: 30),
        pullOnStartup: true,
        pushImmediately: false,
        reconcileInterval: const Duration(minutes: 30),
        lazyReconcileOnMiss: true,
        conflictStrategy: ConflictStrategy.clientWins,
        conflictResolver: resolver,
        mergeFunction: mergeFunc,
        maxConflictRetries: 10,
        conflictRetryDelay: const Duration(seconds: 2),
        skipConflictingOps: true,
        maxOutboxTryCount: 9,
        retryTransportErrorsInEngine: true,
      );

      expect(copied.pageSize, equals(1000));
      expect(copied.backoffMin, equals(const Duration(seconds: 2)));
      expect(copied.backoffMax, equals(const Duration(minutes: 10)));
      expect(copied.backoffMultiplier, equals(3.0));
      expect(copied.maxPushRetries, equals(20));
      expect(copied.fullResyncInterval, equals(const Duration(days: 30)));
      expect(copied.pullOnStartup, isTrue);
      expect(copied.pushImmediately, isFalse);
      expect(copied.reconcileInterval, equals(const Duration(minutes: 30)));
      expect(copied.lazyReconcileOnMiss, isTrue);
      expect(copied.conflictStrategy, equals(ConflictStrategy.clientWins));
      expect(copied.conflictResolver, equals(resolver));
      expect(copied.mergeFunction, equals(mergeFunc));
      expect(copied.maxConflictRetries, equals(10));
      expect(copied.conflictRetryDelay, equals(const Duration(seconds: 2)));
      expect(copied.skipConflictingOps, isTrue);
      expect(copied.maxOutboxTryCount, equals(9));
      expect(copied.retryTransportErrorsInEngine, isTrue);
    });
  });

  group('TableConflictConfig', () {
    test('creates with default values', () {
      const config = TableConflictConfig();

      expect(config.strategy, isNull);
      expect(config.resolver, isNull);
      expect(config.mergeFunction, isNull);
      expect(config.timestampField, equals('updatedAt'));
    });

    test('creates with custom values', () {
      Future<ConflictResolution> resolver(Conflict c) async =>
          const AcceptServer();

      Map<String, Object?> mergeFunc(
        Map<String, Object?> local,
        Map<String, Object?> server,
      ) => server;

      final config = TableConflictConfig(
        strategy: ConflictStrategy.lastWriteWins,
        resolver: resolver,
        mergeFunction: mergeFunc,
        timestampField: 'modified_at',
      );

      expect(config.strategy, equals(ConflictStrategy.lastWriteWins));
      expect(config.resolver, isNotNull);
      expect(config.mergeFunction, isNotNull);
      expect(config.timestampField, equals('modified_at'));
    });

    test('allows null strategy for global fallback', () {
      const config = TableConflictConfig(timestampField: 'lastModified');

      expect(config.strategy, isNull);
      expect(config.timestampField, equals('lastModified'));
    });
  });

  group('ConflictStrategy', () {
    test('has all expected values', () {
      expect(ConflictStrategy.values, hasLength(6));
      expect(ConflictStrategy.values, contains(ConflictStrategy.serverWins));
      expect(ConflictStrategy.values, contains(ConflictStrategy.clientWins));
      expect(ConflictStrategy.values, contains(ConflictStrategy.lastWriteWins));
      expect(ConflictStrategy.values, contains(ConflictStrategy.merge));
      expect(ConflictStrategy.values, contains(ConflictStrategy.manual));
      expect(ConflictStrategy.values, contains(ConflictStrategy.autoPreserve));
    });
  });
}
