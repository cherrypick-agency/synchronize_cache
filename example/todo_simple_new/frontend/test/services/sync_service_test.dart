import 'package:flutter_test/flutter_test.dart';
import 'package:todo_simple_new_frontend/database/database.dart';
import 'package:todo_simple_new_frontend/repositories/todo_repository.dart';
import 'package:todo_simple_new_frontend/services/sync_service.dart';
import 'package:todo_simple_new_frontend/sync/todo_sync.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SyncService service;

  setUp(() async {
    db = createTestDatabase();
    service = SyncService(
      db: db,
      baseUrl: 'http://localhost:99999',
      todoSync: todoSyncTable(db),
      maxRetries: 0,
    );
  });

  tearDown(() async {
    service.dispose();
    await db.close();
  });

  test('initial state is idle', () {
    expect(service.status, SyncStatus.idle);
    expect(service.error, isNull);
  });

  test('checkHealth returns false when backend unavailable', () async {
    expect(await service.checkHealth(), isFalse);
  });

  test('syncRun path sets error status on network failure', () async {
    final repo = TodoRepository(db, todoSyncTable(db));
    await repo.create(title: 'Need sync');

    await expectLater(service.sync, throwsA(anything));
    expect(service.status, SyncStatus.error);
    expect(service.error, isNotNull);
  });
}
