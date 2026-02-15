import 'package:drift/drift.dart' show Value;
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';
import 'package:test/test.dart';

import '../sync_engine_test.dart';
import '../sync_engine_test.drift.dart';

void main() {
  group('SyncCoordinator', () {
    late TestDatabase db;
    late MockTransport transport;
    late SyncEngine<TestDatabase> engine;

    setUp(() async {
      db = TestDatabase();
      transport = MockTransport();
      engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable:
                (item) => TestItemsCompanion.insert(
                  updatedAt: item.updatedAt,
                  deletedAt: Value(item.deletedAt),
                  deletedAtLocal: Value(item.deletedAtLocal),
                  id: item.id,
                  name: item.name,
                ),
          ),
        ],
        config: const SyncConfig(fullResyncInterval: Duration(days: 365)),
      );
    });

    tearDown(() async {
      engine.dispose();
      await db.close();
    });

    test('pullOnStartup runs pull-only sync', () async {
      await db.setCursor(
        CursorKinds.fullResync,
        Cursor(ts: DateTime.now().toUtc(), lastId: ''),
      );

      final coordinator = SyncCoordinator(engine: engine, pullOnStartup: true);
      addTearDown(coordinator.dispose);

      await coordinator.start();

      expect(transport.pullCallCount, 1);
      expect(transport.pushCallCount, 0);
    });

    test('pushOnOutboxChanges pushes with debounce', () async {
      await db.setCursor(
        CursorKinds.fullResync,
        Cursor(ts: DateTime.now().toUtc(), lastId: ''),
      );

      final coordinator = SyncCoordinator(
        engine: engine,
        pushOnOutboxChanges: true,
        outboxPollInterval: const Duration(milliseconds: 20),
        pushDebounce: const Duration(milliseconds: 30),
      );
      addTearDown(coordinator.dispose);

      await coordinator.start();

      await db.enqueue(
        UpsertOp(
          opId: 'coord-op',
          kind: 'test_item',
          id: 'item-1',
          localTimestamp: DateTime.now().toUtc(),
          payloadJson: {'id': 'item-1', 'name': 'Test'},
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(transport.pushCallCount, greaterThanOrEqualTo(1));
      expect((await db.takeOutbox()).isEmpty, isTrue);
    });

    test('fromLegacyConfig maps old SyncConfig flags', () async {
      final coordinator = SyncCoordinator.fromLegacyConfig(
        engine: engine,
        config: const SyncConfig(
          pullOnStartup: true,
          pushImmediately: true,
          reconcileInterval: Duration(minutes: 1),
        ),
      );
      addTearDown(coordinator.dispose);

      expect(coordinator.pullOnStartup, isTrue);
      expect(coordinator.pushOnOutboxChanges, isTrue);
      expect(coordinator.autoInterval, const Duration(minutes: 1));
    });

    test(
      'pushOnOutboxChanges reacts to new ops even when stuck ops exist',
      () async {
        await db.setCursor(
          CursorKinds.fullResync,
          Cursor(ts: DateTime.now().toUtc(), lastId: ''),
        );

        await db.enqueue(
          UpsertOp(
            opId: 'stuck-op',
            kind: 'test_item',
            id: 'stuck-1',
            localTimestamp: DateTime.now().toUtc(),
            payloadJson: {'id': 'stuck-1', 'name': 'Stuck'},
          ),
        );
        for (var i = 0; i < 5; i++) {
          await db.incrementOutboxTryCount(['stuck-op']);
        }

        final coordinator = SyncCoordinator(
          engine: engine,
          pushOnOutboxChanges: true,
          pushDebounce: const Duration(milliseconds: 30),
        );
        addTearDown(coordinator.dispose);

        await coordinator.start();

        await db.enqueue(
          UpsertOp(
            opId: 'fresh-op',
            kind: 'test_item',
            id: 'fresh-1',
            localTimestamp: DateTime.now().toUtc(),
            payloadJson: {'id': 'fresh-1', 'name': 'Fresh'},
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 500));

        expect(transport.pushCallCount, greaterThanOrEqualTo(1));

        final remaining = await db.takeOutbox();
        expect(remaining.length, 1);
        expect(remaining.first.opId, 'stuck-op');
      },
    );
  });
}
