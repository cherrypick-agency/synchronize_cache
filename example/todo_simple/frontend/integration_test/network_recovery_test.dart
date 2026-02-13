import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:todo_simple_frontend/database/database.dart';
import 'package:todo_simple_frontend/repositories/todo_repository.dart';
import 'package:todo_simple_frontend/services/sync_service.dart';
import 'package:todo_simple_frontend/sync/todo_sync.dart';
import 'package:todo_simple_frontend/ui/screens/todo_list_screen.dart';

// ============================================================================
// NETWORK RECOVERY INTEGRATION TESTS
// ============================================================================
//
// These tests verify the complete offline-to-online sync cycle:
// the core value proposition of offline-first architecture.
//
// ┌─────────────────────────────────────────────────────────────────────────┐
// │ QUICK REFERENCE                                                          │
// ├─────────────────────────────────────────────────────────────────────────┤
// │                                                                         │
// │  RUN:     flutter test integration_test/network_recovery_test.dart      │
// │  BACKEND: REQUIRED! (cd backend && dart_frog dev)                       │
// │  TIME:    ~20 seconds                                                   │
// │  TESTS:   8 tests in 3 groups                                           │
// │                                                                         │
// │  GROUPS:                                                                 │
// │    • Basic Operations .... 4 tests  (CREATE/UPDATE/DELETE/TOGGLE)       │
// │    • Complex Scenarios ... 2 tests  (multi-period, mixed ops)           │
// │    • UI State ............ 2 tests  (status indicator, optimistic UI)  │
// │                                                                         │
// │  TEST PATTERN:                                                           │
// │    PHASE 1: ONLINE   - Create baseline, sync to server                  │
// │    PHASE 2: OFFLINE  - Make changes WITHOUT calling sync()              │
// │    PHASE 3: RECOVERY - Call sync(), verify all changes pushed           │
// │                                                                         │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ┌─────────────────────────────────────────────────────────────────────────┐
// │                     NETWORK RECOVERY FLOW                               │
// ├─────────────────────────────────────────────────────────────────────────┤
// │                                                                         │
// │  PHASE 1: ONLINE                                                        │
// │  ┌────────┐     ┌────────┐     ┌────────┐     ┌────────┐              │
// │  │ Create │ ──▶ │ Local  │ ──▶ │  Sync  │ ──▶ │ Server │              │
// │  │  Todo  │     │   DB   │     │        │     │   ✓    │              │
// │  └────────┘     └────────┘     └────────┘     └────────┘              │
// │                                                                         │
// │  PHASE 2: OFFLINE (network down)                                        │
// │  ┌────────┐     ┌────────┐     ┌────────┐     ┌────────┐              │
// │  │ Create │ ──▶ │ Local  │ ──▶ │ Outbox │     │ Server │              │
// │  │  Todo  │     │   DB   │     │ Queue  │  ✗  │  N/A   │              │
// │  └────────┘     └────────┘     └────────┘     └────────┘              │
// │                                    │                                   │
// │                              [Operations wait]                         │
// │                                    │                                   │
// │  PHASE 3: RECOVERY (network restored)                                   │
// │  ┌────────┐     ┌────────┐     ┌────────┐     ┌────────┐              │
// │  │ Outbox │ ──▶ │  Sync  │ ──▶ │ Server │ ──▶ │ Success│              │
// │  │ Replay │     │ Push   │     │   ✓    │     │  ✓✓✓   │              │
// │  └────────┘     └────────┘     └────────┘     └────────┘              │
// │                                                                         │
// └─────────────────────────────────────────────────────────────────────────┘
//
// KEY INSIGHT:
// We simulate "offline" by simply NOT calling sync() between operations.
// This mirrors real-world behavior where sync fails due to network issues.
// When we call sync() again, it's like the network coming back online.
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
  late SyncService syncService;

  /// Generates unique test names to avoid collisions with persistent backend.
  /// Each test run creates unique data that won't conflict with previous runs.
  String uniqueName(String base) =>
      '$base-${DateTime.now().millisecondsSinceEpoch}';

  /// Builds the complete app widget tree with all dependencies.
  Widget buildTestApp() {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<TodoRepository>.value(value: repo),
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
  //
  // These helpers make tests more readable and reduce boilerplate.
  // They encapsulate common patterns in offline-first testing.
  //

  /// Creates a todo and immediately syncs it to the server.
  /// Returns the created todo for further operations.
  ///
  /// Use this to set up "online" state before going "offline".
  Future<Todo> createAndSync(String title) async {
    final todo = await repo.create(title: title);
    final stats = await syncService.sync();
    expect(stats.pushed, greaterThan(0));
    expect(await syncService.getPendingCount(), 0);
    return todo;
  }

  /// Asserts that the outbox has exactly [count] pending operations.
  ///
  /// Pending operations = changes made offline, waiting for sync.
  Future<void> expectPending(int count) async {
    expect(await syncService.getPendingCount(), count);
  }

  /// Syncs all pending operations and verifies success.
  ///
  /// This simulates "network coming back online" - all queued
  /// operations are pushed to the server.
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

  group('Network Recovery', () {
    setUp(() async {
      // Reset server data before each test to ensure clean state
      await http.post(Uri.parse('$baseUrl/reset'));

      db = AppDatabase(NativeDatabase.memory());
      final todoSync = todoSyncTable(db);
      repo = TodoRepository(db, todoSync);
      syncService = SyncService(db: db, baseUrl: baseUrl, todoSync: todoSync);
    });

    tearDown(() async {
      syncService.dispose();
      await db.close();
    });

    // =========================================================================
    // BASIC OPERATIONS RECOVERY
    // =========================================================================
    //
    // Verify: Each type of CRUD operation syncs correctly after offline period.
    //
    // Pattern for each test:
    //   1. ONLINE:   Create baseline data, sync to server
    //   2. OFFLINE:  Make changes without syncing
    //   3. RECOVERY: Sync and verify changes pushed
    //
    // =========================================================================

    group('Basic Operations', () {
      testWidgets('CREATE: todos created offline sync on recovery',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ PHASE 1: ONLINE - Create and sync first todo                    │
        // └─────────────────────────────────────────────────────────────────┘
        final onlineTodo = uniqueName('Online');
        await repo.create(title: onlineTodo);
        await syncAndVerify(expectedPushed: 1);
        await tester.pumpAndSettle();

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ PHASE 2: OFFLINE - Create more todos WITHOUT syncing            │
        // │ (Simulates: user continues working when network is down)        │
        // └─────────────────────────────────────────────────────────────────┘
        final offline1 = uniqueName('Offline1');
        final offline2 = uniqueName('Offline2');
        await repo.create(title: offline1);
        await repo.create(title: offline2);
        await tester.pumpAndSettle();

        // UI shows all todos immediately (offline-first!)
        expect(find.text(onlineTodo), findsOneWidget);
        expect(find.text(offline1), findsOneWidget);
        expect(find.text(offline2), findsOneWidget);

        // But 2 are still pending in outbox
        await expectPending(2);

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ PHASE 3: RECOVERY - Network restored, sync pushes all changes   │
        // └─────────────────────────────────────────────────────────────────┘
        await syncAndVerify(expectedPushed: 2);
        await tester.pumpAndSettle();

        // All todos still visible, now synced to server
        expect(find.text(onlineTodo), findsOneWidget);
        expect(find.text(offline1), findsOneWidget);
        expect(find.text(offline2), findsOneWidget);
      });

      testWidgets('UPDATE: edits made offline sync on recovery',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ONLINE: Create and sync baseline
        final original = uniqueName('Original');
        final todo = await createAndSync(original);
        await tester.pumpAndSettle();

        // OFFLINE: Edit without syncing
        final updated = uniqueName('Updated');
        await repo.update(todo, title: updated);
        await tester.pumpAndSettle();

        // Change visible immediately
        expect(find.text(updated), findsOneWidget);
        expect(find.text(original), findsNothing);
        await expectPending(1);

        // RECOVERY: Edit syncs to server
        await syncAndVerify(expectedPushed: 1);
      });

      testWidgets('DELETE: deletions made offline sync on recovery',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ONLINE: Create and sync
        final title = uniqueName('ToDelete');
        final todo = await createAndSync(title);
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);

        // OFFLINE: Delete without syncing
        await repo.delete(todo);
        await tester.pumpAndSettle();

        // Gone from UI immediately
        expect(find.text(title), findsNothing);
        await expectPending(1);

        // RECOVERY: Delete syncs to server
        await syncAndVerify(expectedPushed: 1);
        expect(find.text(title), findsNothing); // Still gone
      });

      testWidgets('TOGGLE: completion changes sync on recovery',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ONLINE: Create and sync
        final title = uniqueName('Toggle');
        final todo = await createAndSync(title);
        await tester.pumpAndSettle();

        // OFFLINE: Toggle completion
        await repo.update(todo, completed: true);
        await tester.pumpAndSettle();

        // UI reflects change immediately
        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, isTrue);
        await expectPending(1);

        // RECOVERY: Toggle syncs
        await syncAndVerify(expectedPushed: 1);

        // State persists after sync
        final syncedCheckbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(syncedCheckbox.value, isTrue);
      });
    });

    // =========================================================================
    // COMPLEX SCENARIOS
    // =========================================================================
    //
    // Verify: Multiple offline periods and mixed operations work correctly.
    //
    // Real-world scenario: User goes in/out of coverage multiple times,
    // making various changes each time. All must eventually sync.
    //
    // =========================================================================

    group('Complex Scenarios', () {
      testWidgets('multiple offline periods handled correctly', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ Timeline:                                                        │
        // │   [Online] → [Offline #1] → [Online] → [Offline #2] → [Online]  │
        // └─────────────────────────────────────────────────────────────────┘

        // ONLINE #1
        final todo1 = uniqueName('Period1');
        await repo.create(title: todo1);
        await syncAndVerify(expectedPushed: 1);

        // OFFLINE #1
        final todo2 = uniqueName('Period2');
        await repo.create(title: todo2);

        // ONLINE #2 (recovery from offline #1)
        await syncAndVerify(expectedPushed: 1);

        // OFFLINE #2 (multiple todos this time)
        final todo3 = uniqueName('Period3a');
        final todo4 = uniqueName('Period3b');
        await repo.create(title: todo3);
        await repo.create(title: todo4);

        // ONLINE #3 (recovery from offline #2)
        await syncAndVerify(expectedPushed: 2);
        await tester.pumpAndSettle();

        // All 4 todos visible and synced
        expect(find.text(todo1), findsOneWidget);
        expect(find.text(todo2), findsOneWidget);
        expect(find.text(todo3), findsOneWidget);
        expect(find.text(todo4), findsOneWidget);
      });

      testWidgets('mixed operations in single offline period', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ONLINE: Setup baseline
        final original = uniqueName('Original');
        var todo = await createAndSync(original);
        await tester.pumpAndSettle();

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ OFFLINE: Multiple different operations                          │
        // │   1. Edit existing todo                                         │
        // │   2. Create new todo                                            │
        // │   3. Toggle completion                                          │
        // └─────────────────────────────────────────────────────────────────┘

        // Operation 1: Edit title
        final updated = uniqueName('Updated');
        await repo.update(todo, title: updated);

        // Operation 2: Create new
        final newTodo = uniqueName('New');
        await repo.create(title: newTodo);

        // Operation 3: Toggle completion on first todo
        todo = (await repo.getAll()).firstWhere((t) => t.title == updated);
        await repo.update(todo, completed: true);
        await tester.pumpAndSettle();

        // Verify operations queued
        final pending = await syncService.getPendingCount();
        expect(pending, greaterThan(0));

        // RECOVERY: All operations sync
        final stats = await syncService.sync();
        expect(stats.pushed, greaterThan(0));
        await expectPending(0);

        // Verify final state
        expect(find.text(updated), findsOneWidget);
        expect(find.text(newTodo), findsOneWidget);

        // Find the checkbox for the completed todo (the one we toggled)
        final updatedTodo = (await repo.getAll()).firstWhere(
          (t) => t.title == updated,
        );
        expect(updatedTodo.completed, isTrue);
      });
    });

    // =========================================================================
    // UI STATE TESTS
    // =========================================================================
    //
    // Verify: UI correctly reflects sync state throughout the flow.
    //
    // =========================================================================

    group('UI State', () {
      testWidgets('status indicator shows Online after recovery',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Initial: Online
        expect(find.text('Online'), findsOneWidget);

        // Create and sync
        final todo = uniqueName('StatusTest');
        await repo.create(title: todo);
        await syncAndVerify(expectedPushed: 1);
        await tester.pumpAndSettle();

        // After sync: Still Online
        expect(find.text('Online'), findsOneWidget);
        expect(find.text(todo), findsOneWidget);
      });

      testWidgets('todos visible immediately during offline (optimistic UI)',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Create todos WITHOUT syncing
        final todo1 = uniqueName('Visible1');
        final todo2 = uniqueName('Visible2');
        await repo.create(title: todo1);
        await repo.create(title: todo2);
        await tester.pumpAndSettle();

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ KEY: Todos visible IMMEDIATELY, even though not yet synced!     │
        // │ This is the essence of offline-first / optimistic UI.           │
        // └─────────────────────────────────────────────────────────────────┘
        expect(find.text(todo1), findsOneWidget);
        expect(find.text(todo2), findsOneWidget);

        // But they're pending sync
        await expectPending(2);

        // Recovery
        await syncAndVerify(expectedPushed: 2);
      });
    });
  });
}
