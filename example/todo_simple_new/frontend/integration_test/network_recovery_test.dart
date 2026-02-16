import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:todo_simple_new_frontend/repositories/todo_repository.dart';
import 'package:todo_simple_new_frontend/services/sync_service.dart';
import 'package:todo_simple_new_frontend/sync/todo_sync.dart';

import '../test/helpers/test_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );

  testWidgets('queued changes are pushed when backend is reachable', (
    tester,
  ) async {
    final healthResponse = await http.get(Uri.parse('$backendUrl/health'));
    expect(
      healthResponse.statusCode,
      200,
      reason:
          'Backend is not reachable at $backendUrl. Start backend before this test.',
    );

    await http.post(Uri.parse('$backendUrl/reset'));

    final db = createTestDatabase();
    final syncTable = todoSyncTable(db);
    final repository = TodoRepository(db, syncTable);
    final syncService = SyncService(
      db: db,
      baseUrl: backendUrl,
      todoSync: syncTable,
      maxRetries: 0,
    );

    addTearDown(() async {
      syncService.dispose();
      await db.close();
    });

    await repository.create(title: 'Recovery todo');
    expect(await syncService.getPendingCount(), 1);

    final result = await syncService.sync();
    expect(result.pushed, greaterThanOrEqualTo(1));
    expect(await syncService.getPendingCount(), 0);
  });
}
