@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:todo_simple_new_frontend/repositories/todo_repository.dart';
import 'package:todo_simple_new_frontend/services/sync_service.dart';
import 'package:todo_simple_new_frontend/sync/todo_sync.dart';
import 'package:todo_simple_new_frontend/ui/screens/todo_list_screen.dart';

import '../helpers/test_database.dart';

void main() {
  testWidgets('shows empty state then created todo', (tester) async {
    final db = createTestDatabase();
    final syncTable = todoSyncTable(db);
    final repo = TodoRepository(db, syncTable);
    final syncService = SyncService(
      db: db,
      baseUrl: 'http://localhost:99999',
      todoSync: syncTable,
      maxRetries: 0,
    );
    try {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: repo),
            ChangeNotifierProvider.value(value: syncService),
          ],
          child: const MaterialApp(home: TodoListScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No todos yet'), findsOneWidget);

      await repo.create(title: 'Widget Todo');
      await tester.pumpAndSettle();
      expect(find.text('Widget Todo'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      syncService.dispose();
      await db.close();
    }
  });
}
