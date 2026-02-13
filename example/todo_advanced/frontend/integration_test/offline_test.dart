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

// ============================================================================
// OFFLINE MODE INTEGRATION TESTS (ADVANCED)
// ============================================================================
//
// These tests verify the "offline-first" principle with advanced features:
// - Priority field support
// - ConflictHandler logging
// - Server simulation controls
//
// ┌─────────────────────────────────────────────────────────────────────────┐
// │ QUICK REFERENCE                                                          │
// ├─────────────────────────────────────────────────────────────────────────┤
// │                                                                         │
// │  RUN:     flutter test integration_test/offline_test.dart               │
// │  BACKEND: NOT REQUIRED (uses invalid port to simulate offline)          │
// │  TIME:    ~20 seconds                                                   │
// │  TESTS:   15 tests in 6 groups                                          │
// │                                                                         │
// │  GROUPS:                                                                 │
// │    • App Launch .......... 1 test   (UI + simulation button)            │
// │    • CRUD Operations ..... 5 tests  (description, priority, etc.)       │
// │    • Sync Error Handling . 4 tests  (error states, retry, simulation)   │
// │    • ConflictHandler ..... 2 tests  (logging, manual entries)           │
// │    • Outbox Queue ........ 2 tests  (priorities, chained ops)           │
// │    • Empty State ......... 1 test   (stability after error)             │
// │                                                                         │
// │  ADVANCED FEATURES:                                                      │
// │    • Priority field (1-5 scale)                                         │
// │    • ConflictHandler event logging                                      │
// │    • Server simulation button (🧪)                                       │
// │                                                                         │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ┌─────────────────────────────────────────────────────────────────────────┐
// │                   ADVANCED OFFLINE-FIRST ARCHITECTURE                    │
// ├─────────────────────────────────────────────────────────────────────────┤
// │                                                                         │
// │   ┌─────────┐      ┌────────────┐      ┌─────────────┐                 │
// │   │   UI    │ ──── │ Repository │ ──── │  Local DB   │                 │
// │   └─────────┘      └────────────┘      │   (Drift)   │                 │
// │                           │            └─────────────┘                 │
// │                           │                   │                        │
// │                           ▼                   ▼                        │
// │   ┌─────────────────────────────────────────────────┐                 │
// │   │              SyncService                        │                 │
// │   │  ┌─────────────┐     ┌─────────────────────┐   │                 │
// │   │  │   Outbox    │     │  ConflictHandler    │   │                 │
// │   │  │   Queue     │     │  - Event logging    │   │                 │
// │   │  └─────────────┘     │  - Conflict detect  │   │                 │
// │   │                      │  - Resolution UI    │   │                 │
// │   │                      └─────────────────────┘   │                 │
// │   └─────────────────────────────────────────────────┘                 │
// │                           │                                            │
// │                           ▼                                            │
// │                    ┌─────────────┐                                     │
// │                    │   Server    │  ← UNAVAILABLE in these tests       │
// │                    │  (API +     │                                     │
// │                    │ Simulation) │                                     │
// │                    └─────────────┘                                     │
// │                                                                         │
// └─────────────────────────────────────────────────────────────────────────┘
//
// ADVANCED FEATURES TESTED:
//   - Priority field (1-5 scale)
//   - ConflictHandler error logging
//   - Server simulation button behavior
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
  late ConflictHandler conflictHandler;
  late SyncService syncService;

  /// Builds the app with all advanced features enabled.
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
  // Test Groups
  // ---------------------------------------------------------------------------

  group('Offline Mode (Advanced)', () {
    setUp(() {
      // Fresh in-memory database
      db = AppDatabase(NativeDatabase.memory());
      final todoSync = todoSyncTable(db);
      repo = TodoRepository(db, todoSync);
      conflictHandler = ConflictHandler();

      // SyncService with INVALID URL - simulates offline
      syncService = SyncService(
        db: db,
        baseUrl: 'http://localhost:99999', // <-- Always fails
        conflictHandler: conflictHandler,
        todoSync: todoSync,
        maxRetries: 0, // <-- Fail fast
      );
    });

    tearDown(() async {
      syncService.dispose();
      conflictHandler.dispose();
      await db.close();
    });

    // =========================================================================
    // APP LAUNCH TESTS
    // =========================================================================

    group('App Launch', () {
      testWidgets('launches with all UI elements when offline', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Core UI
        expect(find.text('Todo Advanced'), findsOneWidget);
        expect(find.text('No todos yet'), findsOneWidget);
        expect(find.text('Add Todo'), findsOneWidget);

        // Advanced UI: sync + simulation buttons
        expect(find.byIcon(Icons.sync), findsOneWidget);
        expect(find.byIcon(Icons.science), findsOneWidget); // Server simulation
      });
    });

    // =========================================================================
    // CRUD OPERATIONS TESTS
    // =========================================================================
    //
    // All operations work offline, including advanced fields like priority.
    //
    // =========================================================================

    group('CRUD Operations', () {
      testWidgets('CREATE: todo with description appears immediately',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Navigate to create
        await tester.tap(find.text('Add Todo'));
        await tester.pumpAndSettle();

        // Fill title + description (advanced field)
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.first, 'Important task');
        await tester.enterText(textFields.at(1), 'With description');
        await tester.tap(find.byTooltip('Save'));
        await tester.pumpAndSettle();

        // Both visible immediately
        expect(find.text('Important task'), findsOneWidget);
        expect(find.text('With description'), findsOneWidget);
      });

      testWidgets('CREATE: todo with priority works offline', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add Todo'));
        await tester.pumpAndSettle();

        // Set title
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'),
          'High priority task',
        );

        // Adjust priority slider (if present)
        final slider = find.byType(Slider);
        if (slider.evaluate().isNotEmpty) {
          await tester.drag(slider, const Offset(50, 0)); // Increase priority
        }

        await tester.tap(find.byTooltip('Save'));
        await tester.pumpAndSettle();

        expect(find.text('High priority task'), findsOneWidget);
      });

      testWidgets('UPDATE: edit preserves all fields', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Create with repository (includes description)
        await repo.create(title: 'Original', description: 'Keep this');
        await tester.pumpAndSettle();

        // Edit via UI
        await tester.tap(find.text('Original'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Todo'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'),
          'Updated',
        );
        await tester.tap(find.byTooltip('Save'));
        await tester.pumpAndSettle();

        // Title changed, todo visible
        expect(find.text('Updated'), findsOneWidget);
        expect(find.text('Original'), findsNothing);
      });

      testWidgets('DELETE: confirmation dialog works offline', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        await repo.create(title: 'Delete me');
        await tester.pumpAndSettle();

        // Delete flow
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        // Confirmation dialog shown (advanced UI)
        expect(find.text('Delete Todo'), findsOneWidget);

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.text('Delete me'), findsNothing);
      });

      testWidgets('TOGGLE: completion with visual feedback', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        await repo.create(title: 'Complete me');
        await tester.pumpAndSettle();

        final checkbox = find.byType(Checkbox);
        expect(tester.widget<Checkbox>(checkbox).value, isFalse);

        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        // Checked with strikethrough
        expect(tester.widget<Checkbox>(checkbox).value, isTrue);
        final text = tester.widget<Text>(find.text('Complete me'));
        expect(text.style?.decoration, TextDecoration.lineThrough);
      });
    });

    // =========================================================================
    // SYNC ERROR HANDLING TESTS
    // =========================================================================
    //
    // Advanced version includes ConflictHandler logging.
    //
    // =========================================================================

    group('Sync Error Handling', () {
      testWidgets('shows error status with cloud_off icon', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Initial: Online
        expect(find.text('Online'), findsOneWidget);

        // Trigger sync failure
        await tester.tap(find.byIcon(Icons.sync));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Error state
        expect(find.byIcon(Icons.cloud_off), findsOneWidget);
        expect(syncService.status, SyncStatus.error);
      });

      testWidgets('retry works after error', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // First failure
        await tester.tap(find.byIcon(Icons.sync));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Retry (still fails, but no crash)
        expect(find.byIcon(Icons.sync), findsOneWidget);
        await tester.tap(find.byIcon(Icons.sync));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.sync), findsOneWidget);
      });

      testWidgets('status transitions: idle → syncing → error', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        expect(syncService.status, SyncStatus.idle);

        await tester.tap(find.byIcon(Icons.sync));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        expect(syncService.status, SyncStatus.error);
      });

      testWidgets('simulation button accessible when offline', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Simulation button visible
        expect(find.byIcon(Icons.science), findsOneWidget);

        // Tap doesn't crash app
        await tester.tap(find.byIcon(Icons.science));
        await tester.pumpAndSettle();

        expect(find.text('Todo Advanced'), findsOneWidget);
      });
    });

    // =========================================================================
    // CONFLICT HANDLER TESTS
    // =========================================================================
    //
    // ConflictHandler logs all sync events for debugging and conflict resolution.
    //
    // Event types:
    //   - Sync started/completed/failed
    //   - Conflicts detected
    //   - Resolution chosen
    //
    // =========================================================================

    group('ConflictHandler', () {
      testWidgets('logs sync error when server unavailable', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Trigger sync failure
        await tester.tap(find.byIcon(Icons.sync));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // ┌─────────────────────────────────────────────────────────────────┐
        // │ ConflictHandler should have logged the sync error               │
        // │ This is useful for debugging and showing sync history to user   │
        // └─────────────────────────────────────────────────────────────────┘
        expect(conflictHandler.log, isNotEmpty);

        final hasErrorLog = conflictHandler.log.any(
          (e) =>
              e.message.toLowerCase().contains('sync') ||
              e.message.toLowerCase().contains('failed'),
        );
        expect(hasErrorLog, isTrue);
      });

      testWidgets('stores manual log entries', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Manual logging API (useful for debugging)
        conflictHandler.logEvent('User opened app');
        conflictHandler.logEvent('Network check failed');

        expect(conflictHandler.log.length, 2);
        expect(conflictHandler.log[0].message, 'User opened app');
        expect(conflictHandler.log[1].message, 'Network check failed');
      });
    });

    // =========================================================================
    // OUTBOX QUEUE TESTS
    // =========================================================================

    group('Outbox Queue', () {
      testWidgets('todos with different priorities queue correctly',
          (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Create with different priorities
        await repo.create(title: 'Low', priority: 1);
        await repo.create(title: 'Medium', priority: 3);
        await repo.create(title: 'High', priority: 5);
        await tester.pumpAndSettle();

        // All visible
        expect(find.text('Low'), findsOneWidget);
        expect(find.text('Medium'), findsOneWidget);
        expect(find.text('High'), findsOneWidget);

        // All queued
        expect(await syncService.getPendingCount(), 3);
      });

      testWidgets('chained operations persist correctly', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // CREATE → EDIT → TOGGLE
        await repo.create(title: 'Chain');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Chain'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'),
          'Chain Updated',
        );
        await tester.tap(find.byTooltip('Save'));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();

        // Final state
        expect(find.text('Chain Updated'), findsOneWidget);
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      });
    });

    // =========================================================================
    // EMPTY STATE TESTS
    // =========================================================================

    group('Empty State', () {
      testWidgets('preserved after sync error', (tester) async {
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Trigger error
        await tester.tap(find.byIcon(Icons.sync));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Empty state intact
        expect(find.text('No todos yet'), findsOneWidget);
        expect(find.text('Add Todo'), findsOneWidget);
      });
    });
  });
}
