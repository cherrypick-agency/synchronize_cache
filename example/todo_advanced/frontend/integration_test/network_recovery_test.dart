import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:todo_advanced_frontend/database/database.dart';
import 'package:todo_advanced_frontend/repositories/todo_repository.dart';
import 'package:todo_advanced_frontend/services/conflict_handler.dart';
import 'package:todo_advanced_frontend/services/sync_service.dart';
import 'package:todo_advanced_frontend/sync/todo_sync.dart';
import 'package:todo_advanced_frontend/ui/screens/todo_list_screen.dart';

// ============================================================================
// NETWORK RECOVERY INTEGRATION TESTS (ADVANCED)
// ============================================================================
//
// These tests verify the complete offline-to-online sync cycle with
// advanced features: priority fields and ConflictHandler logging.
//
// ┌─────────────────────────────────────────────────────────────────────────┐
// │ QUICK REFERENCE                                                          │
// ├─────────────────────────────────────────────────────────────────────────┤
// │                                                                         │
// │  RUN:     flutter test integration_test/network_recovery_test.dart      │
// │  BACKEND: REQUIRED! (cd backend && dart_frog dev)                       │
// │  TIME:    ~25 seconds                                                   │
// │  TESTS:   10 tests in 4 groups                                          │
// │                                                                         │
// │  GROUPS:                                                                 │
// │    • Basic Operations .... 5 tests  (CREATE/UPDATE/DELETE/TOGGLE/PRIORITY)│
// │    • Complex Scenarios ... 2 tests  (multi-period, mixed + priority)    │
// │    • UI State ............ 2 tests  (status indicator, optimistic UI)  │
// │    • ConflictHandler ..... 1 test   (sync event logging)                │
// │                                                                         │
// │  ADVANCED FEATURES:                                                      │
// │    • Priority field synchronization (1-5 scale)                         │
// │    • ConflictHandler event logging                                      │
// │                                                                         │
// │  TEST PATTERN:                                                           │
// │    PHASE 1: ONLINE   - createAndSync(title, priority: N)                │
// │    PHASE 2: OFFLINE  - repo.update() WITHOUT sync()                     │
// │    PHASE 3: RECOVERY - syncAndVerify(expectedPushed: N)                 │
// │                                                                         │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ┌─────────────────────────────────────────────────────────────────────────┐
// │                 ADVANCED NETWORK RECOVERY FLOW                          │
// ├─────────────────────────────────────────────────────────────────────────┤
// │                                                                         │
// │  PHASE 1: ONLINE                                                        │
// │  ┌────────────┐     ┌────────┐     ┌────────┐     ┌────────┐          │
// │  │ Create     │ ──▶ │ Local  │ ──▶ │  Sync  │ ──▶ │ Server │          │
// │  │ (priority) │     │   DB   │     │        │     │   ✓    │          │
// │  └────────────┘     └────────┘     └────────┘     └────────┘          │
// │                                          │                             │
// │                                          ▼                             │
// │                                    ┌───────────┐                       │
// │                                    │ Conflict  │                       │
// │                                    │ Handler   │ ← Logs: "Sync OK"     │
// │                                    └───────────┘                       │
// │                                                                         │
// │  PHASE 2: OFFLINE (network down)                                        │
// │  ┌────────────┐     ┌────────┐     ┌────────┐                          │
// │  │ Create     │ ──▶ │ Local  │ ──▶ │ Outbox │                          │
// │  │ (priority) │     │   DB   │     │ Queue  │                          │
// │  └────────────┘     └────────┘     └────────┘                          │
// │                                         │                              │
// │                             [Operations with priority wait]            │
// │                                         │                              │
// │  PHASE 3: RECOVERY (network restored)                                   │
// │  ┌────────┐     ┌────────┐     ┌────────┐     ┌────────┐              │
// │  │ Outbox │ ──▶ │  Sync  │ ──▶ │ Server │ ──▶ │ Success│              │
// │  │ Replay │     │ Push   │     │   ✓    │     │  ✓✓✓   │              │
// │  └────────┘     └────────┘     └────────┘     └────────┘              │
// │                      │                                                 │
// │                      ▼                                                 │
// │                ┌───────────┐                                           │
// │                │ Conflict  │ ← Logs: "Pushed 3 todos"                  │
// │                │ Handler   │                                           │
// │                └───────────┘                                           │
// │                                                                         │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ADVANCED FEATURES:
//   - Priority field synchronization (1-5 scale)
//   - ConflictHandler event logging for sync visibility
//
// PREREQUISITES:
//   - Backend server running at localhost:8080
//   - Start with: cd backend && dart_frog dev
//
// RUN:
//   flutter test integration_test/network_recovery_test.dart
//
// ============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const baseUrl = 'http://localhost:8080';

  // ---------------------------------------------------------------------------
  // Test Infrastructure
  // ---------------------------------------------------------------------------

  late AppDatabase db;
  late TodoRepository repo;
  late ConflictHandler conflictHandler;
  late SyncService syncService;

  /// Generates unique test names to avoid collisions with persistent backend.
  String uniqueName(String base) =>
      '$base-${DateTime.now().millisecondsSinceEpoch}';

  /// Builds the complete app widget tree with all advanced dependencies.
  Widget buildTestApp() {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<TodoRepository>.value(value: repo),
        ChangeNotifierProvider<ConflictHandler>.value(value: conflictHandler),
        ChangeNotifierProvider<SyncService>.value(value: syncService),
      ],
      child: MaterialApp(
        home: const TodoListScreen(),
        theme: ThemeData(useMaterial3: true),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Test Helpers
  // ---------------------------------------------------------------------------

  /// Creates a todo with optional priority and immediately syncs.
  Future<Todo> createAndSync(String title, {int priority = 1}) async {
    final todo = await repo.create(title: title, priority: priority);
    final stats = await syncService.sync();
    expect(stats.pushed, greaterThan(0));
    expect(await syncService.getPendingCount(), 0);
    return todo;
  }

  /// Asserts that the outbox has exactly [count] pending operations.
  Future<void> expectPending(int count) async {
    expect(await syncService.getPendingCount(), count);
  }

  /// Syncs all pending operations and verifies success.
  Future<void> syncAndVerify({int expectedPushed = 0}) async {
    final stats = await syncService.sync();
    if (expectedPushed > 0) {
      expect(stats.pushed, expectedPushed);
    }
    expect(syncService.status, SyncStatus.idle);
    expect(syncService.error, isNull);
    expect(await syncService.getPendingCount(), 0);
  }

  // ---------------------------------------------------------------------------
  // Test Groups
  // ---------------------------------------------------------------------------

  group('Network Recovery (Advanced)', () {
    setUp(() async {
      // Reset server data before each test to ensure clean state
      await http.post(Uri.parse('$baseUrl/reset'));

      db = AppDatabase(NativeDatabase.memory());
      final todoSync = todoSyncTable(db);
      repo = TodoRepository(db, todoSync);
      conflictHandler = ConflictHandler();
      syncService = SyncService(
        db: db,
        baseUrl: baseUrl,
        conflictHandler: conflictHandler,
        todoSync: todoSync,
      );
    });

    tearDown(() async {
      syncService.dispose();
      conflictHandler.dispose();
      await db.close();
    });

    // =========================================================================
    // BASIC OPERATIONS RECOVERY
    // =========================================================================
    //
    // Each CRUD operation type recovers correctly after offline period.
    //
    // =========================================================================

    group('Basic Operations', () {
      testWidgets('CREATE: todos created offline sync on recovery',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ PHASE 1: ONLINE                                                  │
        // └─────────────────────────────────────────────────────────────────┘
        final onlineTodo = uniqueName('Online');
        await repo.create(title: onlineTodo);
        await syncAndVerify(expectedPushed: 1);
        await tester.pumpAndSettle();

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ PHASE 2: OFFLINE                                                 │
        // └─────────────────────────────────────────────────────────────────┘
        final offline1 = uniqueName('Offline1');
        final offline2 = uniqueName('Offline2');
        await repo.create(title: offline1);
        await repo.create(title: offline2);
        await tester.pumpAndSettle();

        // UI shows all immediately
        expect(find.text(onlineTodo), findsOneWidget);
        expect(find.text(offline1), findsOneWidget);
        expect(find.text(offline2), findsOneWidget);
        await expectPending(2);

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ PHASE 3: RECOVERY                                                │
        // └─────────────────────────────────────────────────────────────────┘
        await syncAndVerify(expectedPushed: 2);
        await tester.pumpAndSettle();

        // All synced
        expect(find.text(onlineTodo), findsOneWidget);
        expect(find.text(offline1), findsOneWidget);
        expect(find.text(offline2), findsOneWidget);
      });

      testWidgets('UPDATE: edits made offline sync on recovery',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ONLINE
        final original = uniqueName('Original');
        final todo = await createAndSync(original);
        await tester.pumpAndSettle();

        // OFFLINE
        final updated = uniqueName('Updated');
        await repo.update(todo, title: updated);
        await tester.pumpAndSettle();

        expect(find.text(updated), findsOneWidget);
        await expectPending(1);

        // RECOVERY
        await syncAndVerify(expectedPushed: 1);
      });

      testWidgets('DELETE: deletions sync on recovery', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ONLINE
        final title = uniqueName('ToDelete');
        final todo = await createAndSync(title);
        await tester.pumpAndSettle();

        // OFFLINE
        await repo.delete(todo);
        await tester.pumpAndSettle();

        expect(find.text(title), findsNothing);
        await expectPending(1);

        // RECOVERY
        await syncAndVerify(expectedPushed: 1);
      });

      testWidgets('TOGGLE: completion changes sync on recovery',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ONLINE
        final title = uniqueName('Toggle');
        final todo = await createAndSync(title);
        await tester.pumpAndSettle();

        // OFFLINE
        await repo.update(todo, completed: true);
        await tester.pumpAndSettle();

        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, isTrue);
        await expectPending(1);

        // RECOVERY
        await syncAndVerify(expectedPushed: 1);

        final syncedCheckbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(syncedCheckbox.value, isTrue);
      });

      testWidgets('PRIORITY: priority changes sync on recovery',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ Priority is an advanced field (1-5 scale)                       │
        // │ Must sync correctly along with other fields                      │
        // └─────────────────────────────────────────────────────────────────┘

        // ONLINE: Create low priority todo
        final title = uniqueName('Priority');
        final todo = await createAndSync(title, priority: 1);
        await tester.pumpAndSettle();

        // OFFLINE: Change to high priority
        await repo.update(todo, priority: 5);
        await tester.pumpAndSettle();
        await expectPending(1);

        // RECOVERY
        await syncAndVerify(expectedPushed: 1);

        // Verify priority persisted
        final updated = (await repo.getAll()).firstWhere(
          (t) => t.title == title,
        );
        expect(updated.priority, 5);
      });
    });

    // =========================================================================
    // COMPLEX SCENARIOS
    // =========================================================================

    group('Complex Scenarios', () {
      testWidgets('multiple offline periods', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ Timeline:                                                        │
        // │   [Online] → [Offline] → [Online] → [Offline] → [Online]        │
        // └─────────────────────────────────────────────────────────────────┘

        // ONLINE #1
        final todo1 = uniqueName('P1');
        await repo.create(title: todo1);
        await syncAndVerify(expectedPushed: 1);

        // OFFLINE #1
        final todo2 = uniqueName('P2');
        await repo.create(title: todo2);
        await syncAndVerify(expectedPushed: 1);

        // OFFLINE #2
        final todo3 = uniqueName('P3a');
        final todo4 = uniqueName('P3b');
        await repo.create(title: todo3);
        await repo.create(title: todo4);

        // ONLINE #2
        await syncAndVerify(expectedPushed: 2);
        await tester.pumpAndSettle();

        // All visible
        expect(find.text(todo1), findsOneWidget);
        expect(find.text(todo2), findsOneWidget);
        expect(find.text(todo3), findsOneWidget);
        expect(find.text(todo4), findsOneWidget);
      });

      testWidgets('mixed operations with priority in offline period',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ONLINE: Setup
        final original = uniqueName('Original');
        var todo = await createAndSync(original, priority: 1);
        await tester.pumpAndSettle();

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ OFFLINE: Multiple operations                                     │
        // │   1. Edit title                                                  │
        // │   2. Create new high-priority todo                              │
        // │   3. Toggle completion + change priority                        │
        // └─────────────────────────────────────────────────────────────────┘

        // Op 1: Edit
        final updated = uniqueName('Updated');
        await repo.update(todo, title: updated);

        // Op 2: Create with high priority
        final newTodo = uniqueName('HighPriority');
        await repo.create(title: newTodo, priority: 5);

        // Op 3: Toggle + priority change
        todo = (await repo.getAll()).firstWhere((t) => t.title == updated);
        await repo.update(todo, completed: true, priority: 3);
        await tester.pumpAndSettle();

        final pending = await syncService.getPendingCount();
        expect(pending, greaterThan(0));

        // RECOVERY
        final stats = await syncService.sync();
        expect(stats.pushed, greaterThan(0));
        await expectPending(0);

        // Verify
        expect(find.text(updated), findsOneWidget);
        expect(find.text(newTodo), findsOneWidget);

        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox).first);
        expect(checkbox.value, isTrue);
      });
    });

    // =========================================================================
    // UI STATE TESTS
    // =========================================================================

    group('UI State', () {
      testWidgets('status indicator shows Online after recovery',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Online'), findsOneWidget);

        final todo = uniqueName('Status');
        await repo.create(title: todo);
        await syncAndVerify(expectedPushed: 1);
        await tester.pumpAndSettle();

        expect(find.text('Online'), findsOneWidget);
      });

      testWidgets('todos with priority visible immediately (optimistic UI)',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Create without syncing - different priorities
        final low = uniqueName('Low');
        final high = uniqueName('High');
        await repo.create(title: low, priority: 1);
        await repo.create(title: high, priority: 5);
        await tester.pumpAndSettle();

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ Optimistic UI: todos visible BEFORE sync completes              │
        // └─────────────────────────────────────────────────────────────────┘
        expect(find.text(low), findsOneWidget);
        expect(find.text(high), findsOneWidget);
        await expectPending(2);

        // Recovery
        await syncAndVerify(expectedPushed: 2);
      });
    });

    // =========================================================================
    // CONFLICT HANDLER TESTS
    // =========================================================================
    //
    // ConflictHandler logs sync events for debugging and user visibility.
    //
    // =========================================================================

    group('ConflictHandler', () {
      testWidgets('logs sync events during recovery', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Clear existing logs
        conflictHandler.clearLog();

        // Create and sync
        final todo = uniqueName('LogTest');
        await repo.create(title: todo);
        await syncService.sync();
        await tester.pumpAndSettle();

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ ConflictHandler logs sync events for debugging                  │
        // │ Users can see sync history in the Sync Log screen               │
        // └─────────────────────────────────────────────────────────────────┘
        expect(conflictHandler.log, isNotEmpty);

        final hasSyncLog = conflictHandler.log.any(
          (entry) =>
              entry.message.toLowerCase().contains('sync') ||
              entry.message.toLowerCase().contains('push'),
        );
        expect(hasSyncLog, isTrue);
      });
    });
  });
}
