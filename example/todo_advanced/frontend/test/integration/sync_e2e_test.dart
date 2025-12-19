import 'package:flutter_test/flutter_test.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';
import 'package:todo_advanced_frontend/database/database.dart';
import 'package:todo_advanced_frontend/models/todo.dart';
import 'package:todo_advanced_frontend/repositories/todo_repository.dart';
import 'package:todo_advanced_frontend/services/conflict_handler.dart';
import 'package:todo_advanced_frontend/services/sync_service.dart';

import '../helpers/test_database.dart';

/// End-to-end tests for the sync flow.
///
/// These tests verify the complete sync cycle including:
/// - Creating todos locally and syncing
/// - Conflict detection and resolution
/// - Server simulation triggers
///
/// Note: These tests require a running backend server for full integration.
/// Without a server, they test the local components only.
void main() {
  late AppDatabase db;
  late TodoRepository repo;
  late ConflictHandler conflictHandler;
  late SyncService syncService;

  setUp(() async {
    db = createTestDatabase();
    repo = TodoRepository(db);
    conflictHandler = ConflictHandler();
    syncService = SyncService(
      db: db,
      baseUrl: 'http://localhost:8080',
      conflictHandler: conflictHandler,
    );
  });

  tearDown(() async {
    syncService.dispose();
    await db.close();
  });

  group('E2E Sync Flow', () {
    group('Local Operations', () {
      test('creates todo and queues for sync', () async {
        // Create a todo locally
        final todo = await repo.create(title: 'Test Todo');

        // Verify todo was created
        expect(todo.id, isNotEmpty);
        expect(todo.title, 'Test Todo');

        // Verify operation was queued
        final outbox = await db.takeOutbox();
        expect(outbox, hasLength(1));
        expect(outbox.first.kind, 'todos');
      });

      test('updates todo and queues for sync', () async {
        final todo = await repo.create(title: 'Original');

        // Clear create operation
        final initialOutbox = await db.takeOutbox();
        await db.ackOutbox(initialOutbox.map((o) => o.opId));

        // Update the todo
        await repo.update(todo, title: 'Updated');

        // Verify update was queued
        final outbox = await db.takeOutbox();
        expect(outbox, hasLength(1));
      });

      test('deletes todo and queues for sync', () async {
        final todo = await repo.create(title: 'To Delete');

        // Clear create operation
        final initialOutbox = await db.takeOutbox();
        await db.ackOutbox(initialOutbox.map((o) => o.opId));

        // Delete the todo
        await repo.delete(todo);

        // Verify delete was queued
        final outbox = await db.takeOutbox();
        expect(outbox, hasLength(1));
      });
    });

    group('Sync Service State', () {
      test('starts in idle state', () {
        expect(syncService.status, SyncStatus.idle);
        expect(syncService.isSyncing, false);
        expect(syncService.error, isNull);
      });

      test('provides event stream', () {
        expect(syncService.events, isA<Stream<SyncEvent>>());
      });

      test('provides conflict handler access', () {
        expect(syncService.conflictHandler, same(conflictHandler));
      });
    });

    group('Conflict Handler', () {
      test('starts with no conflicts', () {
        expect(conflictHandler.hasConflicts, false);
        expect(conflictHandler.conflictCount, 0);
        expect(conflictHandler.currentConflict, isNull);
      });

      test('can queue and resolve conflict with local', () async {
        final conflict = _createTestConflict(
          localTitle: 'Local Version',
          serverTitle: 'Server Version',
        );

        final future = conflictHandler.resolve(conflict);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(conflictHandler.hasConflicts, true);
        expect(conflictHandler.currentConflict, isNotNull);

        conflictHandler.resolveWithLocal();
        final result = await future;

        expect(result, isA<AcceptClient>());
        expect(conflictHandler.hasConflicts, false);
      });

      test('can queue and resolve conflict with server', () async {
        final conflict = _createTestConflict();

        final future = conflictHandler.resolve(conflict);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        conflictHandler.resolveWithServer();
        final result = await future;

        expect(result, isA<AcceptServer>());
      });

      test('can queue and resolve conflict with merge', () async {
        final conflict = _createTestConflict();

        final future = conflictHandler.resolve(conflict);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final mergedTodo = Todo(
          id: 'test-id',
          title: 'Merged Title',
          completed: true,
          priority: 2,
          updatedAt: DateTime.now().toUtc(),
        );

        conflictHandler.resolveWithMerged(mergedTodo);
        final result = await future;

        expect(result, isA<AcceptMerged>());
        final merged = result as AcceptMerged;
        expect(merged.mergedData['title'], 'Merged Title');
      });

      test('detects conflicting fields', () async {
        final conflict = _createTestConflict(
          localTitle: 'Local',
          serverTitle: 'Server',
        );

        final future = conflictHandler.resolve(conflict);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final info = conflictHandler.currentConflict!;
        expect(info.conflictingFields, contains('title'));
        expect(info.conflictingFields, contains('completed'));
        expect(info.conflictingFields, contains('priority'));

        conflictHandler.resolveWithServer();
        await future;
      });

      test('processes multiple conflicts in order', () async {
        final conflict1 = _createTestConflict(id: 'id-1', localTitle: 'First');
        final conflict2 = _createTestConflict(id: 'id-2', localTitle: 'Second');

        final future1 = conflictHandler.resolve(conflict1);
        final future2 = conflictHandler.resolve(conflict2);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(conflictHandler.currentConflict!.localTodo.title, 'First');
        expect(conflictHandler.conflictCount, 2);

        conflictHandler.resolveWithServer();
        await future1;

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(conflictHandler.currentConflict!.localTodo.title, 'Second');

        conflictHandler.resolveWithServer();
        await future2;

        expect(conflictHandler.hasConflicts, false);
      });
    });

    group('Sync Log', () {
      test('logs events', () {
        conflictHandler.logEvent('Test message');

        expect(conflictHandler.log, hasLength(1));
        expect(conflictHandler.log.first.message, 'Test message');
        expect(conflictHandler.log.first.level, SyncLogLevel.info);
      });

      test('logs events with custom level', () {
        conflictHandler.logEvent('Warning!', level: SyncLogLevel.warning);

        expect(conflictHandler.log.first.level, SyncLogLevel.warning);
      });

      test('can clear log', () {
        conflictHandler.logEvent('Message 1');
        conflictHandler.logEvent('Message 2');

        conflictHandler.clearLog();

        expect(conflictHandler.log, isEmpty);
      });
    });

    group('Sync Without Server', () {
      test('starts in idle state before sync attempt', () {
        expect(syncService.status, SyncStatus.idle);
        expect(syncService.isSyncing, false);
      });

      test('health check returns false without server', () async {
        final isHealthy = await syncService.checkHealth();
        expect(isHealthy, false);
      });
    });

    group('Auto Sync', () {
      test('can start and stop auto sync', () {
        expect(
          () => syncService.startAuto(interval: const Duration(minutes: 1)),
          returnsNormally,
        );

        expect(
          () => syncService.stopAuto(),
          returnsNormally,
        );
      });
    });

    group('Pending Operations', () {
      test('counts pending operations', () async {
        // Initially empty
        var count = await syncService.getPendingCount();
        expect(count, 0);

        // Create a todo (adds to outbox)
        await repo.create(title: 'Test');

        count = await syncService.getPendingCount();
        expect(count, 1);
      });
    });
  });
}

/// Creates a test conflict for testing purposes.
Conflict _createTestConflict({
  String id = 'test-id',
  String localTitle = 'Local Title',
  String serverTitle = 'Server Title',
}) {
  final now = DateTime.now().toUtc();
  return Conflict(
    kind: 'todos',
    entityId: id,
    opId: 'op-123',
    localData: {
      'id': id,
      'title': localTitle,
      'completed': false,
      'priority': 3,
      'updated_at': now.toIso8601String(),
    },
    serverData: {
      'id': id,
      'title': serverTitle,
      'completed': true,
      'priority': 1,
      'updated_at': now.toIso8601String(),
    },
    localTimestamp: now,
    serverTimestamp: now,
  );
}
