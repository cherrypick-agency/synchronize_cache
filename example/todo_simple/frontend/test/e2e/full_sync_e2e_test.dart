@Tags(['e2e'])
@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:todo_simple_frontend/database/database.dart';
import 'package:todo_simple_frontend/repositories/todo_repository.dart';
import 'package:todo_simple_frontend/services/sync_service.dart';
import 'package:todo_simple_frontend/sync/todo_sync.dart';

import '../helpers/backend_server.dart';
import '../helpers/test_database.dart';

/// End-to-end tests with real Dart Frog backend.
///
/// These tests start an actual backend server and test the full sync flow.
/// Run with: `flutter test test/e2e/ --tags e2e`
void main() {
  late BackendServer server;
  late AppDatabase db;
  late TodoRepository repo;
  late SyncService syncService;

  /// Gets the backend path relative to the test execution directory.
  String getBackendPath() {
    // When running tests, current directory is the frontend folder
    final currentDir = Directory.current.path;
    if (currentDir.endsWith('frontend')) {
      return '$currentDir/../backend';
    }
    // Fallback to absolute path
    return '${Directory.current.path}/example/todo_simple/backend';
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
    syncService = SyncService(
      db: db,
      baseUrl: server.baseUrl.toString(),
      todoSync: todoSync,
    );
  });

  tearDown(() async {
    syncService.dispose();
    await db.close();
  });

  group('Full Sync E2E', () {
    test('health check returns true when server is running', () async {
      final isHealthy = await syncService.checkHealth();
      expect(isHealthy, isTrue);
    });

    test('creates todo locally and syncs to server', () async {
      // Create a todo locally
      final todo = await repo.create(
        title: 'E2E Test Todo',
        description: 'Created during E2E test',
        priority: 2,
      );

      expect(todo.title, 'E2E Test Todo');

      // Verify it's in the outbox
      var pendingCount = await syncService.getPendingCount();
      expect(pendingCount, 1);

      // Sync to server
      final stats = await syncService.sync();

      // Verify sync completed
      expect(stats.pushed, greaterThanOrEqualTo(1));
      expect(syncService.status, SyncStatus.idle);

      // Outbox should be empty after sync
      pendingCount = await syncService.getPendingCount();
      expect(pendingCount, 0);
    });

    test('pulls todos from server', () async {
      // First create and sync a todo
      await repo.create(title: 'Todo to Pull');
      await syncService.sync();

      // Create a new database instance (simulates fresh app start)
      await db.close();
      db = createTestDatabase();
      final todoSync = todoSyncTable(db);
      repo = TodoRepository(db, todoSync);
      syncService.dispose();
      syncService = SyncService(
        db: db,
        baseUrl: server.baseUrl.toString(),
        todoSync: todoSync,
      );

      // Local database should be empty
      var todos = await repo.getAll();
      expect(todos, isEmpty);

      // Sync to pull from server
      final stats = await syncService.sync();

      // Should have pulled todos
      expect(stats.pulled, greaterThanOrEqualTo(1));

      // Verify todo is in local database
      todos = await repo.getAll();
      expect(todos, isNotEmpty);
      expect(todos.any((t) => t.title == 'Todo to Pull'), isTrue);
    });

    test('updates todo and syncs to server', () async {
      // Create and sync a todo
      final todo = await repo.create(title: 'Original Title');
      await syncService.sync();

      // Update the todo
      final updated = await repo.update(todo, title: 'Updated Title');
      expect(updated.title, 'Updated Title');

      // Verify update is queued
      var pendingCount = await syncService.getPendingCount();
      expect(pendingCount, 1);

      // Sync update
      final stats = await syncService.sync();
      expect(stats.pushed, greaterThanOrEqualTo(1));

      // Outbox should be empty
      pendingCount = await syncService.getPendingCount();
      expect(pendingCount, 0);
    });

    test('deletes todo and syncs to server', () async {
      // Create and sync a todo
      final todo = await repo.create(title: 'To Delete');
      await syncService.sync();

      // Delete the todo
      await repo.delete(todo);

      // Verify it's soft deleted locally
      final deletedTodo = await repo.getById(todo.id);
      expect(deletedTodo?.deletedAtLocal, isNotNull);

      // Sync delete
      final stats = await syncService.sync();
      expect(stats.pushed, greaterThanOrEqualTo(1));

      // Todo should not appear in getAll
      final todos = await repo.getAll();
      expect(todos.any((t) => t.id == todo.id), isFalse);
    });

    test('handles multiple operations in queue', () async {
      // Create multiple todos without syncing
      await repo.create(title: 'Todo 1');
      await repo.create(title: 'Todo 2');
      await repo.create(title: 'Todo 3');

      // All should be in outbox
      var pendingCount = await syncService.getPendingCount();
      expect(pendingCount, 3);

      // Sync all at once
      final stats = await syncService.sync();
      expect(stats.pushed, greaterThanOrEqualTo(3));

      // Outbox should be empty
      pendingCount = await syncService.getPendingCount();
      expect(pendingCount, 0);
    });

    test('sync status changes during sync', () async {
      // Track status changes
      final statuses = <SyncStatus>[];
      void listener() {
        statuses.add(syncService.status);
      }

      syncService.addListener(listener);

      // Create a todo and sync
      await repo.create(title: 'Status Test');
      await syncService.sync();

      syncService.removeListener(listener);

      // Should have gone through syncing and back to idle
      expect(statuses, contains(SyncStatus.syncing));
      expect(statuses.last, SyncStatus.idle);
    });

    test('sync events are emitted correctly', () async {
      final events = <dynamic>[];
      final subscription = syncService.events.listen(events.add);

      await repo.create(title: 'Events Test');
      await syncService.sync();

      await subscription.cancel();

      // Should have received sync events
      expect(events, isNotEmpty);
    });

    test('completes todo and syncs toggle', () async {
      // Create a todo
      final todo = await repo.create(title: 'Complete Me', completed: false);
      await syncService.sync();

      expect(todo.completed, isFalse);

      // Toggle completed
      final toggled = await repo.toggleCompleted(todo);
      expect(toggled.completed, isTrue);

      // Sync
      await syncService.sync();

      // Verify in database
      final fromDb = await repo.getById(todo.id);
      expect(fromDb?.completed, isTrue);
    });
  });

  group('Offline Operations', () {
    test('batches multiple creates offline then syncs all', () async {
      // Create 10 todos without syncing
      for (var i = 1; i <= 10; i++) {
        await repo.create(title: 'Offline Todo $i');
      }

      // All should be pending
      final pendingCount = await syncService.getPendingCount();
      expect(pendingCount, 10);

      // Sync all at once
      final stats = await syncService.sync();
      expect(stats.pushed, greaterThanOrEqualTo(10));

      // Verify all are on server
      final response = await http.get(Uri.parse('${server.baseUrl}/todos'));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List;

      for (var i = 1; i <= 10; i++) {
        expect(
          items.any((t) => (t as Map)['title'] == 'Offline Todo $i'),
          isTrue,
          reason: 'Offline Todo $i should be on server',
        );
      }
    });

    test('multiple updates to same todo before sync sends only final state', () async {
      // Create todo
      var todo = await repo.create(title: 'Version 1');

      // Update multiple times without syncing
      todo = await repo.update(todo, title: 'Version 2');
      todo = await repo.update(todo, title: 'Version 3');
      todo = await repo.update(todo, title: 'Final Version');

      // Sync
      await syncService.sync();

      // Verify server has final version
      final response = await http.get(
        Uri.parse('${server.baseUrl}/todos/${todo.id}'),
      );
      final serverTodo = jsonDecode(response.body) as Map<String, dynamic>;
      expect(serverTodo['title'], 'Final Version');
    });

    test('create then delete before sync results in no server data', () async {
      // Create todo
      final todo = await repo.create(title: 'Will Be Deleted');
      final todoId = todo.id;

      // Delete before sync
      await repo.delete(todo);

      // Sync
      await syncService.sync();

      // Verify todo is not on server (404 or deleted)
      final response = await http.get(
        Uri.parse('${server.baseUrl}/todos/$todoId'),
      );
      // Should be 404 or have deletedAt set
      expect(
        response.statusCode == 404 ||
            (jsonDecode(response.body) as Map)['deleted_at'] != null,
        isTrue,
      );
    });

    test('mixed operations offline: create, update, delete different todos', () async {
      // Create 3 todos
      final todo1 = await repo.create(title: 'Keep and Update');
      final todo2 = await repo.create(title: 'Keep Unchanged');
      final todo3 = await repo.create(title: 'Will Delete');

      // Sync initial state
      await syncService.sync();

      // Perform mixed operations offline
      await repo.update(todo1, title: 'Updated Title', priority: 1);
      await repo.delete(todo3);

      // Sync
      final stats = await syncService.sync();
      expect(stats.pushed, greaterThanOrEqualTo(2)); // update + delete

      // Verify final states for these specific todos
      final updatedTodo1 = await repo.getById(todo1.id);
      final unchangedTodo2 = await repo.getById(todo2.id);

      expect(updatedTodo1?.title, 'Updated Title');
      expect(unchangedTodo2?.title, 'Keep Unchanged');
      // Deleted todo should not appear in getAll
      final allTodos = await repo.getAll();
      expect(allTodos.any((t) => t.id == todo3.id), isFalse);
    });
  });

  group('Data Integrity', () {
    test('all fields sync correctly to server', () async {
      final dueDate = DateTime.now().add(const Duration(days: 7));

      final todo = await repo.create(
        title: 'Full Fields Todo',
        description: 'Test description with details',
        priority: 1,
        dueDate: dueDate,
        completed: true,
      );

      await syncService.sync();

      // Verify on server
      final response = await http.get(
        Uri.parse('${server.baseUrl}/todos/${todo.id}'),
      );
      final serverTodo = jsonDecode(response.body) as Map<String, dynamic>;

      expect(serverTodo['title'], 'Full Fields Todo');
      expect(serverTodo['description'], 'Test description with details');
      expect(serverTodo['priority'], 1);
      expect(serverTodo['completed'], true);
      expect(serverTodo['due_date'], isNotNull);
    });

    test('unicode characters in title and description', () async {
      final todo = await repo.create(
        title: '日本語タイトル 🚀 émojis',
        description: 'Описание на русском 中文描述 العربية',
      );

      await syncService.sync();

      // Verify on server
      final response = await http.get(
        Uri.parse('${server.baseUrl}/todos/${todo.id}'),
      );
      final serverTodo = jsonDecode(response.body) as Map<String, dynamic>;

      expect(serverTodo['title'], '日本語タイトル 🚀 émojis');
      expect(serverTodo['description'], 'Описание на русском 中文描述 العربية');

      // Verify round-trip back to client
      await db.close();
      db = createTestDatabase();
      final todoSync = todoSyncTable(db);
      repo = TodoRepository(db, todoSync);
      syncService.dispose();
      syncService = SyncService(
        db: db,
        baseUrl: server.baseUrl.toString(),
        todoSync: todoSync,
      );

      await syncService.sync();

      final pulled = await repo.getById(todo.id);
      expect(pulled?.title, '日本語タイトル 🚀 émojis');
      expect(pulled?.description, 'Описание на русском 中文描述 العربية');
    });

    test('long strings are handled correctly', () async {
      final longTitle = 'A' * 200;
      final longDescription = 'B' * 2000;

      final todo = await repo.create(
        title: longTitle,
        description: longDescription,
      );

      await syncService.sync();

      // Pull back
      await db.close();
      db = createTestDatabase();
      final todoSync = todoSyncTable(db);
      repo = TodoRepository(db, todoSync);
      syncService.dispose();
      syncService = SyncService(
        db: db,
        baseUrl: server.baseUrl.toString(),
        todoSync: todoSync,
      );

      await syncService.sync();

      final pulled = await repo.getById(todo.id);
      expect(pulled?.title, longTitle);
      expect(pulled?.description, longDescription);
    });

    test('null and empty values handled correctly', () async {
      // Create with null description
      final todo1 = await repo.create(title: 'No Description');

      // Create with empty description
      final todo2 = await repo.create(title: 'Empty Description', description: '');

      await syncService.sync();

      // Verify on server
      final response1 = await http.get(
        Uri.parse('${server.baseUrl}/todos/${todo1.id}'),
      );
      final serverTodo1 = jsonDecode(response1.body) as Map<String, dynamic>;
      expect(serverTodo1['description'], isNull);

      final response2 = await http.get(
        Uri.parse('${server.baseUrl}/todos/${todo2.id}'),
      );
      final serverTodo2 = jsonDecode(response2.body) as Map<String, dynamic>;
      // Empty string may be stored as null or empty
      expect(
        serverTodo2['description'] == null || serverTodo2['description'] == '',
        isTrue,
      );
    });
  });

  group('Multi-Client Simulation', () {
    test('fresh client pulls all existing data', () async {
      // First client creates todos
      await repo.create(title: 'Existing 1', priority: 1);
      await repo.create(title: 'Existing 2', priority: 2);
      await repo.create(title: 'Existing 3', priority: 3);
      await syncService.sync();

      // Simulate fresh client (new database)
      await db.close();
      db = createTestDatabase();
      final todoSync = todoSyncTable(db);
      repo = TodoRepository(db, todoSync);
      syncService.dispose();
      syncService = SyncService(
        db: db,
        baseUrl: server.baseUrl.toString(),
        todoSync: todoSync,
      );

      // Fresh database should be empty
      var todos = await repo.getAll();
      expect(todos, isEmpty);

      // Sync pulls all data
      final stats = await syncService.sync();
      expect(stats.pulled, greaterThanOrEqualTo(3));

      // All todos should be present
      todos = await repo.getAll();
      expect(todos.length, greaterThanOrEqualTo(3));
      expect(todos.any((t) => t.title == 'Existing 1'), isTrue);
      expect(todos.any((t) => t.title == 'Existing 2'), isTrue);
      expect(todos.any((t) => t.title == 'Existing 3'), isTrue);
    });

    test('server changes are pulled on sync', () async {
      // Client creates todo
      final todo = await repo.create(title: 'Original from Client');
      await syncService.sync();

      // Simulate server-side change (direct HTTP with force update)
      await http.put(
        Uri.parse('${server.baseUrl}/todos/${todo.id}'),
        headers: {
          'Content-Type': 'application/json',
          'X-Force-Update': 'true', // Bypass conflict check
        },
        body: jsonEncode({
          'title': 'Modified on Server',
          'completed': true,
          'priority': 1,
        }),
      );

      // Fresh client to pull server changes (without local state)
      await db.close();
      db = createTestDatabase();
      final todoSync = todoSyncTable(db);
      repo = TodoRepository(db, todoSync);
      syncService.dispose();
      syncService = SyncService(
        db: db,
        baseUrl: server.baseUrl.toString(),
        todoSync: todoSync,
      );

      // Sync pulls server data
      await syncService.sync();

      // Verify local has server's changes
      final updated = await repo.getById(todo.id);
      expect(updated?.title, 'Modified on Server');
      expect(updated?.completed, isTrue);
    });

    test('deleted on server is reflected locally after sync', () async {
      // Create and sync
      final todo = await repo.create(title: 'Will Delete on Server');
      await syncService.sync();

      // Verify todo is on server first
      final getResponse = await http.get(
        Uri.parse('${server.baseUrl}/todos/${todo.id}'),
      );
      expect(getResponse.statusCode, 200, reason: 'Todo should exist on server after sync');

      // Delete on server (direct HTTP)
      final deleteResponse = await http.delete(
        Uri.parse('${server.baseUrl}/todos/${todo.id}'),
      );
      // 204 No Content for successful soft-delete
      expect(deleteResponse.statusCode, 204);

      // Fresh client to see server's state
      await db.close();
      db = createTestDatabase();
      final todoSync = todoSyncTable(db);
      repo = TodoRepository(db, todoSync);
      syncService.dispose();
      syncService = SyncService(
        db: db,
        baseUrl: server.baseUrl.toString(),
        todoSync: todoSync,
      );

      // Sync pulls server data - deleted todos should not appear
      await syncService.sync();

      // Should not appear in getAll (server deleted it)
      final todos = await repo.getAll();
      expect(todos.any((t) => t.id == todo.id), isFalse);
    });
  });

  group('Edge Cases', () {
    test('rapid sequential syncs do not cause issues', () async {
      await repo.create(title: 'Rapid Sync Test');

      // Multiple rapid syncs
      await Future.wait([
        syncService.sync(),
        Future.delayed(const Duration(milliseconds: 50), syncService.sync),
        Future.delayed(const Duration(milliseconds: 100), syncService.sync),
      ]);

      // Should complete without error
      expect(syncService.status, SyncStatus.idle);
    });

    test('sync with empty outbox succeeds', () async {
      // No pending operations
      final pendingCount = await syncService.getPendingCount();
      expect(pendingCount, 0);

      // Sync should still work (just pull)
      final stats = await syncService.sync();
      expect(stats.errors, 0);
    });

    test('priority values persist correctly', () async {
      // Create todos with different priorities
      await repo.create(title: 'Priority 1', priority: 1);
      await repo.create(title: 'Priority 5', priority: 5);
      await repo.create(title: 'Priority 3', priority: 3);

      await syncService.sync();

      // Fresh client
      await db.close();
      db = createTestDatabase();
      final todoSync = todoSyncTable(db);
      repo = TodoRepository(db, todoSync);
      syncService.dispose();
      syncService = SyncService(
        db: db,
        baseUrl: server.baseUrl.toString(),
        todoSync: todoSync,
      );

      await syncService.sync();

      final todos = await repo.getAll();
      final p1 = todos.firstWhere((t) => t.title == 'Priority 1');
      final p3 = todos.firstWhere((t) => t.title == 'Priority 3');
      final p5 = todos.firstWhere((t) => t.title == 'Priority 5');

      expect(p1.priority, 1);
      expect(p3.priority, 3);
      expect(p5.priority, 5);
    });

    test('due date timezone handling', () async {
      // Create with specific UTC time
      final dueDate = DateTime.utc(2025, 12, 25, 14, 30, 0);
      final todo = await repo.create(title: 'Christmas Task', dueDate: dueDate);

      await syncService.sync();

      // Verify on server
      final response = await http.get(
        Uri.parse('${server.baseUrl}/todos/${todo.id}'),
      );
      final serverTodo = jsonDecode(response.body) as Map<String, dynamic>;
      final serverDueDate = DateTime.parse(serverTodo['due_date'] as String);

      // Should preserve the date/time
      expect(serverDueDate.year, 2025);
      expect(serverDueDate.month, 12);
      expect(serverDueDate.day, 25);
    });

    test('sync after app restart simulation', () async {
      // Create todos
      await repo.create(title: 'Before Restart 1');
      await repo.create(title: 'Before Restart 2');

      // Sync initial
      await syncService.sync();

      // Simulate app restart (close and reopen DB)
      await db.close();
      syncService.dispose();

      db = createTestDatabase();
      final todoSync = todoSyncTable(db);
      repo = TodoRepository(db, todoSync);
      syncService = SyncService(
        db: db,
        baseUrl: server.baseUrl.toString(),
        todoSync: todoSync,
      );

      // Local DB is empty after restart (in-memory)
      var todos = await repo.getAll();
      expect(todos, isEmpty);

      // Sync should restore data
      await syncService.sync();

      todos = await repo.getAll();
      expect(todos.any((t) => t.title == 'Before Restart 1'), isTrue);
      expect(todos.any((t) => t.title == 'Before Restart 2'), isTrue);
    });
  });
}
