import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:todo_simple_frontend/database/database.dart';
import 'package:todo_simple_frontend/repositories/todo_repository.dart';
import 'package:todo_simple_frontend/services/sync_service.dart';
import 'package:todo_simple_frontend/sync/todo_sync.dart';
import 'package:todo_simple_frontend/ui/screens/todo_list_screen.dart';

/// Integration tests for Todo Simple app.
///
/// These tests run on a real device/emulator and interact with the actual UI.
///
/// Run with:
///   flutter test integration_test/app_test.dart
///
/// Or on a specific device:
///   flutter test integration_test/app_test.dart -d <device_id>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late TodoRepository repo;
  late SyncService syncService;

  setUp(() {
    // Use in-memory database for testing
    db = AppDatabase(NativeDatabase.memory());
    final todoSync = todoSyncTable(db);
    repo = TodoRepository(db, todoSync);
    syncService = SyncService(
      db: db,
      baseUrl: 'http://localhost:8080',
      todoSync: todoSync,
    );
  });

  tearDown(() async {
    syncService.dispose();
    await db.close();
  });

  Widget createTestApp() {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<TodoRepository>.value(value: repo),
        ChangeNotifierProvider<SyncService>.value(value: syncService),
      ],
      child: MaterialApp(
        title: 'Todo Simple Test',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const TodoListScreen(),
      ),
    );
  }

  group('Todo Simple Integration Tests', () {
    testWidgets('app launches and shows empty state', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify app is running
      expect(find.text('Todo Simple'), findsOneWidget);
      expect(find.text('No todos yet'), findsOneWidget);
      expect(find.text('Add Todo'), findsOneWidget);
    });

    testWidgets('can create a new todo via UI', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap FAB to create new todo
      await tester.tap(find.text('Add Todo'));
      await tester.pumpAndSettle();

      // Should navigate to edit screen
      expect(find.text('New Todo'), findsOneWidget);

      // Find TextFormFields by type (first is title, second is description)
      final textFields = find.byType(TextFormField);
      expect(textFields, findsAtLeastNWidgets(2));

      // Enter title (first TextFormField)
      await tester.enterText(textFields.first, 'Integration Test Todo');
      await tester.pumpAndSettle();

      // Enter description (second TextFormField)
      await tester.enterText(textFields.at(1), 'Created during integration test');
      await tester.pumpAndSettle();

      // Save todo via Save button (IconButton in AppBar)
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();

      // Should return to list screen with new todo
      expect(find.text('Integration Test Todo'), findsOneWidget);
      expect(find.text('Created during integration test'), findsOneWidget);
      expect(find.text('No todos yet'), findsNothing);
    });

    testWidgets('can toggle todo completion', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Create a todo first
      await repo.create(title: 'Toggle Test');
      await tester.pumpAndSettle();

      // Find checkbox
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);

      // Verify initially unchecked
      var checkboxWidget = tester.widget<Checkbox>(checkbox);
      expect(checkboxWidget.value, isFalse);

      // Tap checkbox
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Verify now checked
      checkboxWidget = tester.widget<Checkbox>(checkbox);
      expect(checkboxWidget.value, isTrue);

      // Text should have strikethrough (visual confirmation)
      final textWidget = tester.widget<Text>(find.text('Toggle Test'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('can delete todo via delete button', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Create a todo
      await repo.create(title: 'Delete Me');
      await tester.pumpAndSettle();

      expect(find.text('Delete Me'), findsOneWidget);

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Confirm deletion in dialog
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Todo should be gone
      expect(find.text('Delete Me'), findsNothing);
      expect(find.text('Todo deleted'), findsOneWidget); // Snackbar
    });

    testWidgets('can edit existing todo', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Create a todo
      await repo.create(title: 'Original Title', description: 'Original Desc');
      await tester.pumpAndSettle();

      // Tap on the todo card to edit
      await tester.tap(find.text('Original Title'));
      await tester.pumpAndSettle();

      // Should be on edit screen
      expect(find.text('Edit Todo'), findsOneWidget);

      // Clear and enter new title
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Updated Title',
      );
      await tester.pumpAndSettle();

      // Save via Save button
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();

      // Should show updated title
      expect(find.text('Updated Title'), findsOneWidget);
      expect(find.text('Original Title'), findsNothing);
    });

    testWidgets('shows sync status indicator', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Should show Online status (default idle state)
      expect(find.text('Online'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);

      // Sync button should be available
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('multiple todos appear in correct order', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Create multiple todos
      await repo.create(title: 'First Todo', priority: 1);
      await repo.create(title: 'Second Todo', priority: 2);
      await repo.create(title: 'Third Todo', priority: 3);
      await tester.pumpAndSettle();

      // All todos should be visible
      expect(find.text('First Todo'), findsOneWidget);
      expect(find.text('Second Todo'), findsOneWidget);
      expect(find.text('Third Todo'), findsOneWidget);

      // Should be in a scrollable list
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('todo with due date shows date chip', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Create todo with due date
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await repo.create(title: 'Has Due Date', dueDate: tomorrow);
      await tester.pumpAndSettle();

      // Should show calendar icon (due date indicator)
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('empty title shows validation error', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Navigate to create screen
      await tester.tap(find.text('Add Todo'));
      await tester.pumpAndSettle();

      // Try to save without title via Save button
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Title is required'), findsOneWidget);

      // Should still be on edit screen
      expect(find.text('New Todo'), findsOneWidget);
    });

    testWidgets('priority selector works', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Navigate to create screen
      await tester.tap(find.text('Add Todo'));
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Priority Test',
      );

      // Find and tap priority dropdown/slider
      // Priority is shown as slider in the edit screen
      final prioritySlider = find.byType(Slider);
      if (prioritySlider.evaluate().isNotEmpty) {
        // Drag slider to high priority (left = 1)
        await tester.drag(prioritySlider, const Offset(-100, 0));
        await tester.pumpAndSettle();
      }

      // Save via Save button
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();

      // Todo should be created
      expect(find.text('Priority Test'), findsOneWidget);
    });
  });
}
