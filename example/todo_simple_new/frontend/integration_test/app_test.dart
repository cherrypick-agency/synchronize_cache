import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:todo_simple_new_frontend/database/database.dart';
import 'package:todo_simple_new_frontend/repositories/todo_repository.dart';
import 'package:todo_simple_new_frontend/services/sync_service.dart';
import 'package:todo_simple_new_frontend/sync/todo_sync.dart';
import 'package:todo_simple_new_frontend/ui/screens/todo_list_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app opens and can create todo via UI', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final syncTable = todoSyncTable(db);
    final repo = TodoRepository(db, syncTable);
    final syncService = SyncService(
      db: db,
      baseUrl: 'http://localhost:99999',
      todoSync: syncTable,
      maxRetries: 0,
    );

    addTearDown(() async {
      syncService.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: repo),
          ChangeNotifierProvider.value(value: syncService),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const TodoListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add Todo'), findsOneWidget);

    await tester.tap(find.text('Add Todo'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Integration Todo',
    );
    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Integration Todo'), findsOneWidget);
  });
}
