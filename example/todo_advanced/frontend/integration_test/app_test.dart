import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:todo_advanced_frontend/database/database.dart';
import 'package:todo_advanced_frontend/repositories/todo_repository.dart';
import 'package:todo_advanced_frontend/services/conflict_handler.dart';
import 'package:todo_advanced_frontend/services/sync_service.dart';
import 'package:todo_advanced_frontend/sync/todo_sync.dart';
import 'package:todo_advanced_frontend/ui/screens/todo_list_screen.dart';

/// Integration tests for Todo Advanced app.
///
/// These tests run on a real device/emulator and interact with the actual UI.
/// They test the full UI flow including conflict resolution dialogs.
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
  late ConflictHandler conflictHandler;
  late SyncService syncService;

  setUp(() {
    // Use in-memory database for testing
    db = AppDatabase(NativeDatabase.memory());
    final todoSync = todoSyncTable(db);
    repo = TodoRepository(db, todoSync);
    conflictHandler = ConflictHandler();
    syncService = SyncService(
      db: db,
      baseUrl: 'http://localhost:8080',
      conflictHandler: conflictHandler,
      todoSync: todoSync,
    );
  });

  tearDown(() async {
    syncService.dispose();
    conflictHandler.dispose();
    await db.close();
  });

  Widget createTestApp() {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<TodoRepository>.value(value: repo),
        ChangeNotifierProvider<ConflictHandler>.value(value: conflictHandler),
        ChangeNotifierProvider<SyncService>.value(value: syncService),
      ],
      child: MaterialApp(
        title: 'Todo Advanced Test',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const TodoListScreen(),
      ),
    );
  }

  group('Todo Advanced Integration Tests', () {
    testWidgets('app launches and shows empty state', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify app is running
      expect(find.text('Todo Advanced'), findsOneWidget);
      expect(find.text('No todos yet'), findsOneWidget);
      expect(find.text('Add Todo'), findsOneWidget);

      // Advanced version has simulation button
      expect(find.byIcon(Icons.science), findsOneWidget);
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
      await tester.enterText(textFields.first, 'Advanced Integration Test');
      await tester.pumpAndSettle();

      // Enter description (second TextFormField)
      await tester.enterText(textFields.at(1), 'Testing the advanced todo app');
      await tester.pumpAndSettle();

      // Save todo via Save button
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();

      // Should return to list screen with new todo
      expect(find.text('Advanced Integration Test'), findsOneWidget);
      expect(find.text('Testing the advanced todo app'), findsOneWidget);
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
    });

    testWidgets('can delete todo with confirmation dialog', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Create a todo
      await repo.create(title: 'Delete Me');
      await tester.pumpAndSettle();

      expect(find.text('Delete Me'), findsOneWidget);

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Delete Todo'), findsOneWidget);
      expect(find.textContaining('Are you sure'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Todo should be gone
      expect(find.text('Delete Me'), findsNothing);
    });

    testWidgets('can cancel delete in dialog', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Create a todo
      await repo.create(title: 'Keep Me');
      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Cancel deletion
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Todo should still exist
      expect(find.text('Keep Me'), findsOneWidget);
    });

    testWidgets('shows sync status indicator', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Should show Online status
      expect(find.text('Online'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);

      // Sync button should be available
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('simulation button is present', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Simulation button (science icon) should be visible
      expect(find.byIcon(Icons.science), findsOneWidget);
    });

    testWidgets('multiple todos display correctly', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Create multiple todos with different priorities
      await repo.create(title: 'High Priority', priority: 1);
      await repo.create(title: 'Medium Priority', priority: 3);
      await repo.create(title: 'Low Priority', priority: 5);
      await tester.pumpAndSettle();

      // All todos should be visible
      expect(find.text('High Priority'), findsOneWidget);
      expect(find.text('Medium Priority'), findsOneWidget);
      expect(find.text('Low Priority'), findsOneWidget);
    });

    testWidgets('todo with due date shows date chip', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Create todo with due date
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await repo.create(title: 'Has Due Date', dueDate: tomorrow);
      await tester.pumpAndSettle();

      // Should show calendar icon
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('edit screen validates empty title', (tester) async {
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
    });

    testWidgets('edit screen shows when tapping todo card', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Create a todo
      await repo.create(title: 'Tap to Edit');
      await tester.pumpAndSettle();

      // Tap on the todo
      await tester.tap(find.text('Tap to Edit'));
      await tester.pumpAndSettle();

      // Should show edit screen
      expect(find.text('Edit Todo'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Title'), findsOneWidget);
    });

    testWidgets('strikethrough appears for completed todo', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Create completed todo
      await repo.create(title: 'Already Done', completed: true);
      await tester.pumpAndSettle();

      // Text should have strikethrough
      final textWidget = tester.widget<Text>(find.text('Already Done'));
      expect(textWidget.style?.decoration, TextDecoration.lineThrough);

      // Checkbox should be checked
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('conflict handler logs events', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Log some events via conflict handler
      conflictHandler.logEvent('Test event 1');
      conflictHandler.logEvent('Test event 2');

      // Verify events are logged (internal state)
      expect(conflictHandler.log.length, 2);
      expect(conflictHandler.log[0].message, 'Test event 1');
      expect(conflictHandler.log[1].message, 'Test event 2');
    });
  });
}
