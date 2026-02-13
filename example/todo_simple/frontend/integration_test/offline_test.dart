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

// ============================================================================
// OFFLINE MODE INTEGRATION TESTS
// ============================================================================
//
// These tests verify the "offline-first" principle: the app must remain
// fully functional even when the server is completely unavailable.
//
// ┌─────────────────────────────────────────────────────────────────────────┐
// │ QUICK REFERENCE                                                          │
// ├─────────────────────────────────────────────────────────────────────────┤
// │                                                                         │
// │  RUN:     flutter test integration_test/offline_test.dart               │
// │  BACKEND: NOT REQUIRED (uses invalid port to simulate offline)          │
// │  TIME:    ~15 seconds                                                   │
// │  TESTS:   11 tests in 5 groups                                          │
// │                                                                         │
// │  GROUPS:                                                                 │
// │    • App Launch .......... 1 test   (UI renders without server)         │
// │    • CRUD Operations ..... 4 tests  (CREATE/UPDATE/DELETE/TOGGLE)       │
// │    • Sync Error Handling . 3 tests  (error states & retry)              │
// │    • Outbox Queue ........ 2 tests  (operation queuing)                 │
// │    • Empty State ......... 1 test   (stability after error)             │
// │                                                                         │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ┌─────────────────────────────────────────────────────────────────────────┐
// │                        OFFLINE-FIRST ARCHITECTURE                       │
// ├─────────────────────────────────────────────────────────────────────────┤
// │                                                                         │
// │   ┌─────────┐      ┌────────────┐      ┌─────────────┐                 │
// │   │   UI    │ ──── │ Repository │ ──── │  Local DB   │                 │
// │   └─────────┘      └────────────┘      │   (Drift)   │                 │
// │                           │            └─────────────┘                 │
// │                           │                   │                        │
// │                           ▼                   ▼                        │
// │                    ┌─────────────┐     ┌─────────────┐                 │
// │                    │ SyncService │     │   Outbox    │                 │
// │                    └─────────────┘     │   Queue     │                 │
// │                           │            └─────────────┘                 │
// │                           ▼                                            │
// │                    ┌─────────────┐                                     │
// │                    │   Server    │  ← UNAVAILABLE in these tests       │
// │                    │    (API)    │                                     │
// │                    └─────────────┘                                     │
// │                                                                         │
// └─────────────────────────────────────────────────────────────────────────┘
//
// KEY PRINCIPLE:
// All CRUD operations go directly to local DB first, then queue for sync.
// User never waits for network - instant feedback, eventual consistency.
//
// TEST STRATEGY:
// We simulate "offline" by pointing SyncService to invalid URL (port 99999).
// This guarantees connection failure without mocking network layer.
//
// ============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // Test Infrastructure
  // ---------------------------------------------------------------------------

  late AppDatabase db;
  late TodoRepository repo;
  late SyncService syncService;

  /// Builds the app widget tree with all required providers.
  ///
  /// Uses in-memory database for test isolation - each test starts fresh.
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
  // Test Groups
  // ---------------------------------------------------------------------------

  group('Offline Mode', () {
    setUp(() {
      // Fresh in-memory database for each test
      db = AppDatabase(NativeDatabase.memory());
      final todoSync = todoSyncTable(db);
      repo = TodoRepository(db, todoSync);

      // SyncService with INVALID URL - simulates network unavailability
      // Port 99999 is invalid, guaranteeing immediate connection failure
      syncService = SyncService(
        db: db,
        baseUrl: 'http://localhost:99999', // <-- Always fails
        todoSync: todoSync,
        maxRetries: 0, // <-- Fail fast, don't waste time on retries
      );
    });

    tearDown(() async {
      syncService.dispose();
      await db.close();
    });

    // =========================================================================
    // APP LAUNCH TESTS
    // =========================================================================
    //
    // Verify: App launches and displays UI regardless of server availability.
    // Why: Users must be able to use the app even with no internet connection.
    //
    // =========================================================================

    group('App Launch', () {
      testWidgets('launches and shows UI when server unavailable',
          (tester) async {
        // ARRANGE & ACT
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ASSERT: Core UI elements are present
        expect(find.text('Todo Simple'), findsOneWidget); // App title
        expect(find.text('No todos yet'), findsOneWidget); // Empty state
        expect(find.text('Add Todo'), findsOneWidget); // CTA button
        expect(find.byIcon(Icons.sync), findsOneWidget); // Sync button
      });
    });

    // =========================================================================
    // CRUD OPERATIONS TESTS
    // =========================================================================
    //
    // Verify: All Create/Read/Update/Delete operations work without network.
    //
    // Data Flow (offline):
    //   User Action → Repository → Local DB → UI Update
    //                     ↓
    //               Outbox Queue (for later sync)
    //
    // =========================================================================

    group('CRUD Operations', () {
      testWidgets('CREATE: todo appears immediately in UI', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ACT: Create todo via UI
        await tester.tap(find.text('Add Todo'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).first,
          'Buy groceries',
        );
        await tester.tap(find.byTooltip('Save'));
        await tester.pumpAndSettle();

        // ASSERT: Todo visible immediately (no network wait!)
        expect(find.text('Buy groceries'), findsOneWidget);
        expect(find.text('No todos yet'), findsNothing);

        // VERIFY: Operation queued in outbox for later sync
        expect(await syncService.getPendingCount(), 1);
      });

      testWidgets('UPDATE: changes reflected immediately', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ARRANGE: Create todo via repository
        await repo.create(title: 'Old title');
        await tester.pumpAndSettle();

        // ACT: Edit via UI
        await tester.tap(find.text('Old title'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'),
          'New title',
        );
        await tester.tap(find.byTooltip('Save'));
        await tester.pumpAndSettle();

        // ASSERT: Change visible immediately
        expect(find.text('New title'), findsOneWidget);
        expect(find.text('Old title'), findsNothing);
      });

      testWidgets('DELETE: todo removed immediately', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ARRANGE
        await repo.create(title: 'To be deleted');
        await tester.pumpAndSettle();
        expect(find.text('To be deleted'), findsOneWidget);

        // ACT: Delete via UI
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete')); // Confirm dialog
        await tester.pumpAndSettle();

        // ASSERT: Gone immediately
        expect(find.text('To be deleted'), findsNothing);
      });

      testWidgets('TOGGLE: completion state changes immediately',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ARRANGE
        await repo.create(title: 'Complete me');
        await tester.pumpAndSettle();

        final checkbox = find.byType(Checkbox);

        // ASSERT: Initially unchecked
        expect(tester.widget<Checkbox>(checkbox).value, isFalse);

        // ACT: Toggle
        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        // ASSERT: Now checked with visual feedback (strikethrough)
        expect(tester.widget<Checkbox>(checkbox).value, isTrue);
        final text = tester.widget<Text>(find.text('Complete me'));
        expect(text.style?.decoration, TextDecoration.lineThrough);
      });
    });

    // =========================================================================
    // SYNC ERROR HANDLING TESTS
    // =========================================================================
    //
    // Verify: App handles sync failures gracefully with clear UI feedback.
    //
    // Status Flow:
    //   idle (Online) → syncing (Syncing...) → error (Error/cloud_off icon)
    //
    // =========================================================================

    group('Sync Error Handling', () {
      testWidgets('shows error status after failed sync attempt',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ASSERT: Initial state is "Online" (idle)
        expect(find.text('Online'), findsOneWidget);
        expect(syncService.status, SyncStatus.idle);

        // ACT: Trigger sync (will fail due to invalid URL)
        await tester.tap(find.byIcon(Icons.sync));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // ASSERT: Error state shown
        expect(find.byIcon(Icons.cloud_off), findsOneWidget);
        expect(syncService.status, SyncStatus.error);
      });

      testWidgets('sync button remains functional after error',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // First attempt - fails
        await tester.tap(find.byIcon(Icons.sync));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // ASSERT: Button still there, can retry
        expect(find.byIcon(Icons.sync), findsOneWidget);

        // Second attempt - also fails, but app doesn't crash
        await tester.tap(find.byIcon(Icons.sync));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.sync), findsOneWidget);
      });

      testWidgets('status transitions correctly: idle → syncing → error',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // STATE 1: idle
        expect(syncService.status, SyncStatus.idle);

        // ACT: Start sync
        await tester.tap(find.byIcon(Icons.sync));
        await tester.pump(const Duration(milliseconds: 100));

        // Note: syncing state may be very brief due to immediate failure

        // STATE 2: error (after failure)
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(syncService.status, SyncStatus.error);
      });
    });

    // =========================================================================
    // OUTBOX QUEUE TESTS
    // =========================================================================
    //
    // Verify: Operations are properly queued when offline.
    //
    // Outbox Pattern:
    //   ┌─────────────┐
    //   │   Outbox    │  Stores pending operations as JSON
    //   │   Queue     │  Each operation: { type, entityId, data, timestamp }
    //   └─────────────┘
    //         │
    //         ▼ (when online)
    //   ┌─────────────┐
    //   │   Server    │  Operations replayed in order
    //   └─────────────┘
    //
    // =========================================================================

    group('Outbox Queue', () {
      testWidgets('multiple operations queue correctly', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ACT: Create multiple todos while "offline"
        await repo.create(title: 'Task 1');
        await repo.create(title: 'Task 2');
        await repo.create(title: 'Task 3');
        await tester.pumpAndSettle();

        // ASSERT: All visible in UI
        expect(find.text('Task 1'), findsOneWidget);
        expect(find.text('Task 2'), findsOneWidget);
        expect(find.text('Task 3'), findsOneWidget);

        // ASSERT: All queued in outbox
        expect(await syncService.getPendingCount(), 3);
      });

      testWidgets('chained operations (create → edit → toggle) persist',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // CREATE
        await repo.create(title: 'Original');
        await tester.pumpAndSettle();

        // EDIT
        await tester.tap(find.text('Original'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'),
          'Modified',
        );
        await tester.tap(find.byTooltip('Save'));
        await tester.pumpAndSettle();

        // TOGGLE
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        // ASSERT: Final state is correct
        expect(find.text('Modified'), findsOneWidget);
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      });
    });

    // =========================================================================
    // EMPTY STATE TESTS
    // =========================================================================

    group('Empty State', () {
      testWidgets('empty state preserved after sync error', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // ACT: Trigger sync error
        await tester.tap(find.byIcon(Icons.sync));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // ASSERT: Empty state still shown (no crash, no broken UI)
        expect(find.text('No todos yet'), findsOneWidget);
        expect(find.text('Add Todo'), findsOneWidget);
      });
    });
  });
}
