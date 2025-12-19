import 'package:flutter_test/flutter_test.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';
import 'package:todo_advanced_frontend/models/todo.dart';
import 'package:todo_advanced_frontend/services/conflict_handler.dart';

void main() {
  group('ConflictHandler', () {
    late ConflictHandler handler;

    setUp(() {
      handler = ConflictHandler();
    });

    Conflict createTestConflict({
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

    test('starts with no conflicts', () {
      expect(handler.hasConflicts, false);
      expect(handler.conflictCount, 0);
      expect(handler.currentConflict, isNull);
    });

    test('starts with empty log', () {
      expect(handler.log, isEmpty);
    });

    group('logEvent', () {
      test('adds entry to log', () {
        handler.logEvent('Test message');

        expect(handler.log, hasLength(1));
        expect(handler.log.first.message, 'Test message');
        expect(handler.log.first.level, SyncLogLevel.info);
      });

      test('adds entry with custom level', () {
        handler.logEvent('Warning!', level: SyncLogLevel.warning);

        expect(handler.log.first.level, SyncLogLevel.warning);
      });
    });

    group('clearLog', () {
      test('removes all entries', () {
        handler.logEvent('Message 1');
        handler.logEvent('Message 2');

        handler.clearLog();

        expect(handler.log, isEmpty);
      });
    });

    group('resolve', () {
      test('queues conflict and sets current', () async {
        final conflict = createTestConflict();

        // Start resolution (don't await - it waits for user input)
        final future = handler.resolve(conflict);

        // Give it time to process
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(handler.hasConflicts, true);
        expect(handler.conflictCount, 1);
        expect(handler.currentConflict, isNotNull);
        expect(handler.currentConflict!.localTodo.title, 'Local Title');
        expect(handler.currentConflict!.serverTodo.title, 'Server Title');

        // Resolve to complete the future
        handler.resolveWithServer();
        await future;
      });

      test('logs conflict detection', () async {
        final conflict = createTestConflict();

        final future = handler.resolve(conflict);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(
          handler.log.any((e) => e.message.contains('Conflict detected')),
          true,
        );

        handler.resolveWithServer();
        await future;
      });
    });

    group('resolveWithLocal', () {
      test('completes with AcceptClient', () async {
        final conflict = createTestConflict();

        final future = handler.resolve(conflict);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        handler.resolveWithLocal();
        final result = await future;

        expect(result, isA<AcceptClient>());
      });

      test('clears current conflict', () async {
        final conflict = createTestConflict();

        final future = handler.resolve(conflict);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        handler.resolveWithLocal();
        await future;

        expect(handler.currentConflict, isNull);
        expect(handler.hasConflicts, false);
      });

      test('logs resolution', () async {
        final conflict = createTestConflict();

        final future = handler.resolve(conflict);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        handler.resolveWithLocal();
        await future;

        expect(
          handler.log.any((e) => e.message.contains('Resolved with local')),
          true,
        );
      });
    });

    group('resolveWithServer', () {
      test('completes with AcceptServer', () async {
        final conflict = createTestConflict();

        final future = handler.resolve(conflict);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        handler.resolveWithServer();
        final result = await future;

        expect(result, isA<AcceptServer>());
      });

      test('logs resolution', () async {
        final conflict = createTestConflict();

        final future = handler.resolve(conflict);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        handler.resolveWithServer();
        await future;

        expect(
          handler.log.any((e) => e.message.contains('Resolved with server')),
          true,
        );
      });
    });

    group('resolveWithMerged', () {
      test('completes with AcceptMerged', () async {
        final conflict = createTestConflict();

        final future = handler.resolve(conflict);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final mergedTodo = Todo(
          id: 'test-id',
          title: 'Merged Title',
          completed: true,
          priority: 2,
          updatedAt: DateTime.now().toUtc(),
        );

        handler.resolveWithMerged(mergedTodo);
        final result = await future;

        expect(result, isA<AcceptMerged>());
        final merged = result as AcceptMerged;
        expect(merged.mergedData['title'], 'Merged Title');
      });

      test('logs resolution', () async {
        final conflict = createTestConflict();

        final future = handler.resolve(conflict);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final mergedTodo = Todo(
          id: 'test-id',
          title: 'Merged Title',
          updatedAt: DateTime.now().toUtc(),
        );

        handler.resolveWithMerged(mergedTodo);
        await future;

        expect(
          handler.log.any((e) => e.message.contains('Resolved with merge')),
          true,
        );
      });
    });

    group('skipConflict', () {
      test('is equivalent to resolveWithServer', () async {
        final conflict = createTestConflict();

        final future = handler.resolve(conflict);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        handler.skipConflict();
        final result = await future;

        expect(result, isA<AcceptServer>());
      });
    });

    group('ConflictInfo', () {
      test('detects conflicting fields', () async {
        final conflict = createTestConflict(
          localTitle: 'Local',
          serverTitle: 'Server',
        );

        final future = handler.resolve(conflict);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final info = handler.currentConflict!;
        final conflictingFields = info.conflictingFields;

        expect(conflictingFields, contains('title'));
        expect(conflictingFields, contains('completed'));
        expect(conflictingFields, contains('priority'));

        handler.resolveWithServer();
        await future;
      });
    });

    group('multiple conflicts', () {
      test('processes conflicts in order', () async {
        final conflict1 = createTestConflict(id: 'id-1', localTitle: 'First');
        final conflict2 = createTestConflict(id: 'id-2', localTitle: 'Second');

        // Queue both conflicts
        final future1 = handler.resolve(conflict1);
        final future2 = handler.resolve(conflict2);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        // First conflict should be current
        expect(handler.currentConflict!.localTodo.title, 'First');
        expect(handler.conflictCount, 2);

        // Resolve first
        handler.resolveWithServer();
        await future1;

        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Second conflict should now be current
        expect(handler.currentConflict!.localTodo.title, 'Second');
        expect(handler.conflictCount, 1);

        // Resolve second
        handler.resolveWithServer();
        await future2;

        expect(handler.hasConflicts, false);
      });
    });
  });

  group('SyncLogEntry', () {
    test('contains timestamp, message, and level', () {
      final now = DateTime.now();
      final entry = SyncLogEntry(
        timestamp: now,
        message: 'Test message',
        level: SyncLogLevel.warning,
      );

      expect(entry.timestamp, now);
      expect(entry.message, 'Test message');
      expect(entry.level, SyncLogLevel.warning);
    });
  });
}
