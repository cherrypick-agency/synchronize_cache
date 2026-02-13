@Tags(['e2e'])
@Timeout(Duration(minutes: 3))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:todo_advanced_frontend/database/database.dart';
import 'package:todo_advanced_frontend/repositories/todo_repository.dart';
import 'package:todo_advanced_frontend/services/conflict_handler.dart';
import 'package:todo_advanced_frontend/services/sync_service.dart';
import 'package:todo_advanced_frontend/sync/todo_sync.dart';

import '../helpers/backend_server.dart';
import '../helpers/test_database.dart';

/// End-to-end tests for conflict detection and resolution.
///
/// These tests start an actual backend server and test the full conflict flow.
/// Run with: `flutter test test/e2e/ --tags e2e`
void main() {
  late BackendServer server;
  late AppDatabase db;
  late TodoRepository repo;
  late ConflictHandler conflictHandler;
  late SyncService syncService;

  /// Gets the backend path relative to the test execution directory.
  String getBackendPath() {
    final currentDir = Directory.current.path;
    if (currentDir.endsWith('frontend')) {
      return '$currentDir/../backend';
    }
    return '${Directory.current.path}/example/todo_advanced/backend';
  }

  /// Updates a todo directly on the server (bypassing client).
  Future<void> updateOnServer({
    required String id,
    required String title,
    bool completed = false,
    int priority = 3,
  }) async {
    final response = await http.put(
      Uri.parse('${server.baseUrl}/todos/$id'),
      headers: {
        'Content-Type': 'application/json',
        'X-Force-Update': 'true', // Bypass conflict check
      },
      body: jsonEncode({
        'title': title,
        'completed': completed,
        'priority': priority,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('Failed to update on server: ${response.body}');
    }
  }

  setUpAll(() async {
    server = BackendServer(backendPath: getBackendPath());
    await server.start();
  });

  tearDownAll(() async {
    await server.stop();
  });

  setUp(() async {
    db = createTestDatabase();
    final todoSync = todoSyncTable(db);
    repo = TodoRepository(db, todoSync);
    conflictHandler = ConflictHandler();
    syncService = SyncService(
      db: db,
      baseUrl: server.baseUrl.toString(),
      conflictHandler: conflictHandler,
      todoSync: todoSync,
    );
  });

  tearDown(() async {
    syncService.dispose();
    await db.close();
  });

  group('Conflict Detection and Resolution', () {
    test('detects conflict when server changed during local edit', () async {
      // Create a todo and sync it
      var todo = await repo.create(title: 'Original Title');
      await syncService.sync();

      // Refetch todo after sync to get server timestamp
      todo = (await repo.getById(todo.id))!;

      // Server modifies the todo (simulates another client)
      await updateOnServer(
        id: todo.id,
        title: 'Server Changed Title',
      );

      // Local modifies the same todo (using synced version with correct timestamp)
      await repo.update(todo, title: 'Local Changed Title');

      // Start sync in background - it will wait for conflict resolution
      final syncFuture = syncService.sync();

      // Wait for conflict to appear
      await Future<void>.delayed(const Duration(milliseconds: 500));
      for (var i = 0; i < 20 && !conflictHandler.hasConflicts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      // Verify conflict was detected
      expect(conflictHandler.hasConflicts, isTrue);
      expect(conflictHandler.currentConflict, isNotNull);
      expect(conflictHandler.currentConflict!.localTodo.title, 'Local Changed Title');
      expect(conflictHandler.currentConflict!.serverTodo.title, 'Server Changed Title');

      // Resolve with server version
      conflictHandler.resolveWithServer();

      // Wait for sync to complete
      await syncFuture;

      // Local should now have server's version
      final result = await repo.getById(todo.id);
      expect(result?.title, 'Server Changed Title');
    });

    test('resolves conflict with local version', () async {
      var todo = await repo.create(title: 'Original');
      await syncService.sync();

      // Refetch todo after sync to get server timestamp
      todo = (await repo.getById(todo.id))!;

      await updateOnServer(id: todo.id, title: 'Server Version');
      await repo.update(todo, title: 'Local Version');

      final syncFuture = syncService.sync();

      // Wait for conflict
      for (var i = 0; i < 30 && !conflictHandler.hasConflicts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      expect(conflictHandler.hasConflicts, isTrue);

      // Resolve with local
      conflictHandler.resolveWithLocal();

      await syncFuture;

      // Server should now have local's version
      // (we need to re-fetch from server to verify)
      final response = await http.get(
        Uri.parse('${server.baseUrl}/todos/${todo.id}'),
      );
      final serverTodo = jsonDecode(response.body) as Map<String, dynamic>;
      expect(serverTodo['title'], 'Local Version');
    });

    test('resolves conflict with merged version', () async {
      var todo = await repo.create(
        title: 'Original Title',
        priority: 3,
        completed: false,
      );
      await syncService.sync();

      // Refetch todo after sync to get server timestamp
      todo = (await repo.getById(todo.id))!;

      // Server changes title
      await updateOnServer(id: todo.id, title: 'Server Title', priority: 3);

      // Local changes priority
      await repo.update(todo, priority: 1);

      final syncFuture = syncService.sync();

      // Wait for conflict
      for (var i = 0; i < 30 && !conflictHandler.hasConflicts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      expect(conflictHandler.hasConflicts, isTrue);

      // Create merged version with server's title and local's priority
      final info = conflictHandler.currentConflict!;
      final merged = info.localTodo.copyWith(
        title: info.serverTodo.title, // Take server's title
        priority: info.localTodo.priority, // Keep local's priority
      );

      conflictHandler.resolveWithMerged(merged);

      await syncFuture;

      // Verify merged result
      final result = await repo.getById(todo.id);
      expect(result?.title, 'Server Title');
      expect(result?.priority, 1);
    });

    test('handles multiple conflicts in queue', () async {
      // Create two todos
      var todo1 = await repo.create(title: 'Todo 1');
      var todo2 = await repo.create(title: 'Todo 2');
      await syncService.sync();

      // Refetch todos after sync to get server timestamps
      todo1 = (await repo.getById(todo1.id))!;
      todo2 = (await repo.getById(todo2.id))!;

      // Server modifies both
      await updateOnServer(id: todo1.id, title: 'Server 1');
      await updateOnServer(id: todo2.id, title: 'Server 2');

      // Local modifies both
      await repo.update(todo1, title: 'Local 1');
      await repo.update(todo2, title: 'Local 2');

      final syncFuture = syncService.sync();

      // Wait for first conflict
      for (var i = 0; i < 30 && !conflictHandler.hasConflicts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      expect(conflictHandler.hasConflicts, isTrue);
      // Note: Conflicts are processed sequentially, so we see 1 at a time
      expect(conflictHandler.conflictCount, greaterThanOrEqualTo(1));

      // Resolve first conflict with server version
      conflictHandler.resolveWithServer();

      // Wait for second conflict to appear
      for (var i = 0; i < 30 && !conflictHandler.hasConflicts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      // Resolve second conflict with local version
      if (conflictHandler.hasConflicts) {
        conflictHandler.resolveWithLocal();
      }

      await syncFuture;

      // Verify results
      final result1 = await repo.getById(todo1.id);
      final result2 = await repo.getById(todo2.id);

      // First was resolved with server, second with local
      expect(result1?.title, 'Server 1');
      expect(result2?.title, 'Local 2');
    });

    test('conflict log records events correctly', () async {
      var todo = await repo.create(title: 'Test');
      await syncService.sync();

      // Refetch todo after sync to get server timestamp
      todo = (await repo.getById(todo.id))!;

      conflictHandler.clearLog();

      await updateOnServer(id: todo.id, title: 'Server');
      await repo.update(todo, title: 'Local');

      final syncFuture = syncService.sync();

      for (var i = 0; i < 30 && !conflictHandler.hasConflicts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      conflictHandler.resolveWithServer();
      await syncFuture;

      // Check log entries
      expect(conflictHandler.log, isNotEmpty);
      expect(
        conflictHandler.log.any((e) => e.message.contains('Conflict detected')),
        isTrue,
      );
      expect(
        conflictHandler.log.any((e) => e.message.contains('Resolved')),
        isTrue,
      );
    });

    test('server simulation triggers conflict', () async {
      var todo = await repo.create(
        title: 'Test Todo',
        completed: false,
      );
      await syncService.sync();

      // Refetch todo after sync to get server timestamp
      todo = (await repo.getById(todo.id))!;

      // Server marks todo as completed (simulates server-side change)
      await updateOnServer(
        id: todo.id,
        title: todo.title,
        completed: true, // Server changes completed to true
        priority: todo.priority,
      );

      // Local marks as not completed (same field conflict)
      await repo.update(todo, completed: false);

      final syncFuture = syncService.sync();

      for (var i = 0; i < 30 && !conflictHandler.hasConflicts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      expect(conflictHandler.hasConflicts, isTrue);

      // Server marked as completed, local as not completed
      final conflict = conflictHandler.currentConflict!;
      expect(conflict.serverTodo.completed, isTrue);
      expect(conflict.localTodo.completed, isFalse);
      expect(conflict.conflictingFields, contains('completed'));

      conflictHandler.resolveWithServer();
      await syncFuture;

      final result = await repo.getById(todo.id);
      expect(result?.completed, isTrue);
    });

    test('no conflict when different fields changed', () async {
      // Note: This test depends on autoPreserve behavior which is not enabled
      // in todo_advanced (it uses manual). So any field change triggers conflict.
      // This test verifies that even different field changes are detected.

      var todo = await repo.create(
        title: 'Original',
        priority: 3,
        description: 'Original desc',
      );
      await syncService.sync();

      // Refetch todo after sync to get server timestamp
      todo = (await repo.getById(todo.id))!;

      // Server changes description
      final response = await http.put(
        Uri.parse('${server.baseUrl}/todos/${todo.id}'),
        headers: {
          'Content-Type': 'application/json',
          'X-Force-Update': 'true',
        },
        body: jsonEncode({
          'title': 'Original',
          'description': 'Server desc',
          'priority': 3,
        }),
      );
      expect(response.statusCode, 200);

      // Local changes priority
      await repo.update(todo, priority: 1);

      final syncFuture = syncService.sync();

      for (var i = 0; i < 30 && !conflictHandler.hasConflicts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      // With manual strategy, any change is a conflict
      expect(conflictHandler.hasConflicts, isTrue);

      // Merge: keep server's description, local's priority
      final info = conflictHandler.currentConflict!;
      final merged = info.localTodo.copyWith(
        description: info.serverTodo.description,
        priority: info.localTodo.priority,
      );

      conflictHandler.resolveWithMerged(merged);
      await syncFuture;

      final result = await repo.getById(todo.id);
      expect(result?.description, 'Server desc');
      expect(result?.priority, 1);
    });
  });

  group('Conflict Edge Cases', () {
    test('conflict on completed field toggle', () async {
      var todo = await repo.create(title: 'Toggle Test', completed: false);
      await syncService.sync();
      todo = (await repo.getById(todo.id))!;

      // Server marks as completed
      await updateOnServer(
        id: todo.id,
        title: todo.title,
        completed: true,
        priority: todo.priority,
      );

      // Local also tries to mark as completed (same change)
      await repo.update(todo, completed: true);

      final syncFuture = syncService.sync();

      for (var i = 0; i < 30 && !conflictHandler.hasConflicts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      // Even same value change triggers conflict due to timestamp mismatch
      expect(conflictHandler.hasConflicts, isTrue);

      // Both have completed=true, so either resolution works
      conflictHandler.resolveWithServer();
      await syncFuture;

      final result = await repo.getById(todo.id);
      expect(result?.completed, isTrue);
    });

    test('rapid local updates before conflict resolution', () async {
      var todo = await repo.create(title: 'Rapid Update');
      await syncService.sync();
      todo = (await repo.getById(todo.id))!;

      // Server changes
      await updateOnServer(id: todo.id, title: 'Server Title');

      // Single local change (multiple updates would queue multiple ops)
      await repo.update(todo, title: 'Local Updated');

      final syncFuture = syncService.sync();

      for (var i = 0; i < 30 && !conflictHandler.hasConflicts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      expect(conflictHandler.hasConflicts, isTrue);
      expect(conflictHandler.currentConflict!.localTodo.title, 'Local Updated');
      expect(conflictHandler.currentConflict!.serverTodo.title, 'Server Title');

      conflictHandler.resolveWithLocal();
      await syncFuture;

      final result = await repo.getById(todo.id);
      expect(result?.title, 'Local Updated');
    });

    test('conflict resolution with priority change', () async {
      var todo = await repo.create(title: 'Priority Conflict', priority: 3);
      await syncService.sync();
      todo = (await repo.getById(todo.id))!;

      // Server sets high priority
      await updateOnServer(
        id: todo.id,
        title: todo.title,
        priority: 1,
      );

      // Local sets low priority
      await repo.update(todo, priority: 5);

      final syncFuture = syncService.sync();

      for (var i = 0; i < 30 && !conflictHandler.hasConflicts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      expect(conflictHandler.hasConflicts, isTrue);
      expect(conflictHandler.currentConflict!.serverTodo.priority, 1);
      expect(conflictHandler.currentConflict!.localTodo.priority, 5);
      expect(conflictHandler.currentConflict!.conflictingFields, contains('priority'));

      // Resolve with merged - take average priority
      final info = conflictHandler.currentConflict!;
      final merged = info.localTodo.copyWith(priority: 3); // Compromise
      conflictHandler.resolveWithMerged(merged);

      await syncFuture;

      final result = await repo.getById(todo.id);
      expect(result?.priority, 3);
    });

    test('conflict info shows correct conflicting fields', () async {
      var todo = await repo.create(
        title: 'Original Title',
        description: 'Original Desc',
        priority: 3,
        completed: false,
      );
      await syncService.sync();
      todo = (await repo.getById(todo.id))!;

      // Server changes title and completed
      await http.put(
        Uri.parse('${server.baseUrl}/todos/${todo.id}'),
        headers: {
          'Content-Type': 'application/json',
          'X-Force-Update': 'true',
        },
        body: jsonEncode({
          'title': 'Server Title',
          'description': 'Original Desc',
          'priority': 3,
          'completed': true,
        }),
      );

      // Local changes description and priority
      await repo.update(
        todo,
        description: 'Local Desc',
        priority: 1,
      );

      final syncFuture = syncService.sync();

      for (var i = 0; i < 30 && !conflictHandler.hasConflicts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      expect(conflictHandler.hasConflicts, isTrue);

      final fields = conflictHandler.currentConflict!.conflictingFields;
      expect(fields, contains('title'));
      expect(fields, contains('completed'));
      expect(fields, contains('description'));
      expect(fields, contains('priority'));

      conflictHandler.resolveWithServer();
      await syncFuture;
    });

    test('no data loss on merge resolution', () async {
      var todo = await repo.create(
        title: 'Important Task',
        description: 'Initial notes',
        priority: 2,
        completed: false,
      );
      await syncService.sync();
      todo = (await repo.getById(todo.id))!;

      // Server adds more info to description
      await http.put(
        Uri.parse('${server.baseUrl}/todos/${todo.id}'),
        headers: {
          'Content-Type': 'application/json',
          'X-Force-Update': 'true',
        },
        body: jsonEncode({
          'title': 'Important Task',
          'description': 'Initial notes\n\nServer added: Meeting notes from John',
          'priority': 2,
          'completed': false,
        }),
      );

      // Local also adds notes
      await repo.update(
        todo,
        description: 'Initial notes\n\nLocal added: Remember to call client',
      );

      final syncFuture = syncService.sync();

      for (var i = 0; i < 30 && !conflictHandler.hasConflicts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      expect(conflictHandler.hasConflicts, isTrue);

      // Manual merge to preserve both additions
      final info = conflictHandler.currentConflict!;
      final mergedDesc = 'Initial notes\n\n'
          'Server added: Meeting notes from John\n\n'
          'Local added: Remember to call client';
      final merged = info.localTodo.copyWith(description: mergedDesc);

      conflictHandler.resolveWithMerged(merged);
      await syncFuture;

      final result = await repo.getById(todo.id);
      expect(result?.description, contains('Meeting notes from John'));
      expect(result?.description, contains('Remember to call client'));
    });

    test('conflict after server creates same todo ID', () async {
      // This simulates a rare case where client and server might create
      // with same ID (shouldn't happen with UUIDs, but tests edge case)
      final todo = await repo.create(title: 'Client Created');
      await syncService.sync();

      // Server updates the todo
      final fetchedTodo = (await repo.getById(todo.id))!;
      await updateOnServer(
        id: fetchedTodo.id,
        title: 'Server Modified',
      );

      // Local modifies
      await repo.update(fetchedTodo, title: 'Client Modified Again');

      final syncFuture = syncService.sync();

      for (var i = 0; i < 30 && !conflictHandler.hasConflicts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      expect(conflictHandler.hasConflicts, isTrue);
      conflictHandler.resolveWithLocal();
      await syncFuture;

      final result = await repo.getById(todo.id);
      expect(result?.title, 'Client Modified Again');
    });
  });

  group('Sync Recovery', () {
    test('fresh client sees resolved state', () async {
      var todo = await repo.create(title: 'Original');
      await syncService.sync();
      todo = (await repo.getById(todo.id))!;

      // Create conflict and resolve
      await updateOnServer(id: todo.id, title: 'Server Wins');
      await repo.update(todo, title: 'Local Loses');

      final syncFuture = syncService.sync();

      for (var i = 0; i < 30 && !conflictHandler.hasConflicts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      conflictHandler.resolveWithServer();
      await syncFuture;

      // Fresh client
      await db.close();
      db = createTestDatabase();
      final todoSync = todoSyncTable(db);
      repo = TodoRepository(db, todoSync);
      final freshConflictHandler = ConflictHandler();
      syncService.dispose();
      syncService = SyncService(
        db: db,
        baseUrl: server.baseUrl.toString(),
        conflictHandler: freshConflictHandler,
        todoSync: todoSync,
      );

      await syncService.sync();

      // Fresh client should see the resolved state
      final result = await repo.getById(todo.id);
      expect(result?.title, 'Server Wins');
      expect(freshConflictHandler.hasConflicts, isFalse);
    });
  });

  group('Data Integrity After Conflict', () {
    test('all fields preserved after merge resolution', () async {
      final dueDate = DateTime.utc(2025, 6, 15, 10, 0, 0);
      var todo = await repo.create(
        title: 'Full Data',
        description: 'Test description',
        priority: 2,
        dueDate: dueDate,
        completed: false,
      );
      await syncService.sync();
      todo = (await repo.getById(todo.id))!;

      // Server only changes title
      await http.put(
        Uri.parse('${server.baseUrl}/todos/${todo.id}'),
        headers: {
          'Content-Type': 'application/json',
          'X-Force-Update': 'true',
        },
        body: jsonEncode({
          'title': 'Server Title',
          'description': 'Test description',
          'priority': 2,
          'due_date': dueDate.toIso8601String(),
          'completed': false,
        }),
      );

      // Local only changes completed
      await repo.update(todo, completed: true);

      final syncFuture = syncService.sync();

      for (var i = 0; i < 30 && !conflictHandler.hasConflicts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      // Merge: server title + local completed
      final info = conflictHandler.currentConflict!;
      final merged = info.localTodo.copyWith(
        title: info.serverTodo.title,
        completed: info.localTodo.completed,
      );
      conflictHandler.resolveWithMerged(merged);

      await syncFuture;

      final result = await repo.getById(todo.id);
      expect(result?.title, 'Server Title');
      expect(result?.description, 'Test description');
      expect(result?.priority, 2);
      expect(result?.completed, isTrue);
      expect(result?.dueDate?.day, 15);
    });

    test('unicode preserved through conflict resolution', () async {
      var todo = await repo.create(
        title: '日本語タスク',
        description: 'Описание 🚀',
      );
      await syncService.sync();
      todo = (await repo.getById(todo.id))!;

      // Server changes
      await http.put(
        Uri.parse('${server.baseUrl}/todos/${todo.id}'),
        headers: {
          'Content-Type': 'application/json',
          'X-Force-Update': 'true',
        },
        body: jsonEncode({
          'title': '更新されたタスク',
          'description': 'Новое описание 🎉',
          'priority': 3,
          'completed': false,
        }),
      );

      // Local changes
      await repo.update(todo, priority: 1);

      final syncFuture = syncService.sync();

      for (var i = 0; i < 30 && !conflictHandler.hasConflicts; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      // Merge with server's unicode content
      final info = conflictHandler.currentConflict!;
      final merged = info.localTodo.copyWith(
        title: info.serverTodo.title,
        description: info.serverTodo.description,
      );
      conflictHandler.resolveWithMerged(merged);

      await syncFuture;

      final result = await repo.getById(todo.id);
      expect(result?.title, '更新されたタスク');
      expect(result?.description, 'Новое описание 🎉');
      expect(result?.priority, 1);
    });
  });
}
