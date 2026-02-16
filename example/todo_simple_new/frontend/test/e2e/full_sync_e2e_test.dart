@Tags(['e2e'])
@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_simple_new_frontend/database/database.dart';
import 'package:todo_simple_new_frontend/repositories/todo_repository.dart';
import 'package:todo_simple_new_frontend/services/sync_service.dart';
import 'package:todo_simple_new_frontend/sync/todo_sync.dart';

import '../helpers/backend_server.dart';
import '../helpers/test_database.dart';

void main() {
  late BackendServer server;
  late AppDatabase db;
  late TodoRepository repo;
  late SyncService syncService;

  String getBackendPath() {
    final currentDir = Directory.current.path;
    if (currentDir.endsWith('frontend')) {
      return '$currentDir/../backend';
    }
    return '${Directory.current.path}/example/todo_simple_new/backend';
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
      maxRetries: 0,
    );
  });

  tearDown(() async {
    syncService.dispose();
    await db.close();
  });

  test('pushes local todo to server and clears outbox', () async {
    await repo.create(title: 'E2E Todo');
    expect(await syncService.getPendingCount(), 1);

    final stats = await syncService.sync();
    expect(stats.pushed, greaterThanOrEqualTo(1));
    expect(await syncService.getPendingCount(), 0);
  });

  test('pulls remote data on fresh client', () async {
    await repo.create(title: 'Seed for pull');
    await syncService.sync();

    await db.close();
    db = createTestDatabase();
    final todoSync = todoSyncTable(db);
    repo = TodoRepository(db, todoSync);
    syncService.dispose();
    syncService = SyncService(
      db: db,
      baseUrl: server.baseUrl.toString(),
      todoSync: todoSync,
      maxRetries: 0,
    );

    final before = await repo.getAll();
    expect(before, isEmpty);

    final stats = await syncService.sync();
    expect(stats.pulled, greaterThanOrEqualTo(1));

    final after = await repo.getAll();
    expect(after.any((t) => t.title == 'Seed for pull'), isTrue);
  });
}
