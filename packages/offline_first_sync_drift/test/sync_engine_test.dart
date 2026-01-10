import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';
import 'package:test/test.dart' hide isNotNull, isNull;

import 'sync_engine_test.drift.dart';

// Тестовая модель
class TestItem {
  TestItem({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    this.deletedAtLocal,
    required this.name,
  });

  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? deletedAtLocal;
  final String name;

  factory TestItem.fromJson(Map<String, dynamic> json) => TestItem(
        id: json['id'] as String,
        updatedAt: DateTime.parse(json['updated_at'] as String),
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'] as String)
            : null,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'updated_at': updatedAt.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'name': name,
      };
}

// Тестовая таблица
@UseRowClass(TestItem, generateInsertable: true)
class TestItems extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  include: {'package:offline_first_sync_drift/src/sync_tables.drift'},
  tables: [TestItems],
)
class TestDatabase extends $TestDatabase with SyncDatabaseMixin {
  TestDatabase() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

// Мок транспорта
class MockTransport implements TransportAdapter {
  final List<Map<String, dynamic>> pullResponses = [];
  final List<Op> pushedOps = [];
  bool healthStatus = true;
  int pullCallCount = 0;
  int pushCallCount = 0;
  String? lastAfterId;

  @override
  Future<PullPage> pull({
    required String kind,
    required DateTime updatedSince,
    required int pageSize,
    String? pageToken,
    String? afterId,
    bool includeDeleted = true,
  }) async {
    pullCallCount++;
    lastAfterId = afterId;
    return PullPage(items: pullResponses);
  }

  @override
  Future<BatchPushResult> push(List<Op> ops) async {
    pushCallCount++;
    pushedOps.addAll(ops);
    return BatchPushResult(
      results: ops
          .map((op) => OpPushResult(
                opId: op.opId,
                result: const PushSuccess(),
              ))
          .toList(),
    );
  }

  @override
  Future<PushResult> forcePush(Op op) async {
    pushedOps.add(op);
    return const PushSuccess();
  }

  @override
  Future<FetchResult> fetch({
    required String kind,
    required String id,
  }) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => healthStatus;
}

void main() {
  late TestDatabase db;

  setUp(() async {
    db = TestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncEngine', () {
    test('sync calls pull for registered kinds', () async {
      final transport = MockTransport();
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      await engine.sync();

      // Pull вызывается для каждого зарегистрированного kind
      expect(transport.pullCallCount, 1);

      engine.dispose();
    });

    test('sync pushes outbox operations', () async {
      final transport = MockTransport();
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      await db.enqueue(UpsertOp(
        opId: 'test-op-1',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'name': 'Test'},
      ));

      await engine.sync();

      expect(transport.pushedOps.length, 1);
      expect(transport.pushedOps.first.opId, 'test-op-1');

      engine.dispose();
    });

    test('sync pulls and inserts items', () async {
      final transport = MockTransport();
      transport.pullResponses.addAll([
        {
          'id': 'pulled-1',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'name': 'Pulled Item',
        },
      ]);

      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      await engine.sync();

      final items = await db.select(db.testItems).get();
      expect(items.length, 1);
      expect(items.first.name, 'Pulled Item');

      engine.dispose();
    });

    test('sync emits SyncStarted events', () async {
      final transport = MockTransport();
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      final events = <SyncEvent>[];
      final sub = engine.events.listen(events.add);

      await engine.sync();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await sub.cancel();

      // Должно быть 2 SyncStarted: один для push, один для pull
      expect(events.whereType<SyncStarted>().length, 2);

      engine.dispose();
    });

    test('sync emits SyncCompleted event', () async {
      final transport = MockTransport();
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      final events = <SyncEvent>[];
      final sub = engine.events.listen(events.add);

      await engine.sync();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await sub.cancel();

      expect(events.whereType<SyncCompleted>().length, 1);

      engine.dispose();
    });

    test('sync updates cursor after pull', () async {
      final transport = MockTransport();
      final now = DateTime.now().toUtc();
      transport.pullResponses.addAll([
        {
          'id': 'cursor-test-1',
          'updated_at': now.toIso8601String(),
          'name': 'Test',
        },
      ]);

      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      await engine.sync();

      final cursor = await db.getCursor('test_item');
      expect(cursor != null, isTrue);
      expect(cursor!.lastId, 'cursor-test-1');

      engine.dispose();
    });

    test('sync clears outbox after successful push', () async {
      final transport = MockTransport();
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      await db.enqueue(UpsertOp(
        opId: 'clear-test-1',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {},
      ));

      expect((await db.takeOutbox()).length, 1);

      await engine.sync();

      expect((await db.takeOutbox()).length, 0);

      engine.dispose();
    });

    test('sync can filter by kinds', () async {
      final transport = MockTransport();
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      await db.setCursor(CursorKinds.fullResync, Cursor(
        ts: DateTime.now().toUtc(),
        lastId: '',
      ));

      await engine.sync(kinds: {'other_kind'});

      // Should not pull test_item since we only asked for other_kind
      expect(transport.pullCallCount, 0);

      engine.dispose();
    });

    test('startAuto and stopAuto', () async {
      final transport = MockTransport();
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      )..startAuto(interval: const Duration(milliseconds: 100));

      await Future<void>.delayed(const Duration(milliseconds: 250));

      engine
        ..stopAuto()
        ..dispose();

      // Should have synced at least once
      expect(transport.pullCallCount, greaterThan(0));
    });
  });

  group('Error handling', () {
    test('sync throws on transport failure', () async {
      final errorTransport = _FailingTransport();
      final engine = SyncEngine(
        db: db,
        transport: errorTransport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      await expectLater(
        engine.sync(),
        throwsA(isA<Exception>()),
      );

      engine.dispose();
    });

    test('sync emits error event before throwing', () async {
      final errorTransport = _FailingTransport();
      final engine = SyncEngine(
        db: db,
        transport: errorTransport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      final events = <SyncEvent>[];
      final sub = engine.events.listen(events.add);

      try {
        await engine.sync();
      } catch (_) {
        // Expected
      }

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(events.whereType<SyncErrorEvent>().length, greaterThan(0));

      engine.dispose();
    });

    test('push emits OperationFailedEvent on PushError', () async {
      // Transport that returns error once, then success
      final transport = _ErrorOnceTransport();
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      await db.enqueue(UpsertOp(
        opId: 'op-error-1',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'name': 'Test'},
      ));

      final events = <SyncEvent>[];
      final sub = engine.events.listen(events.add);

      await engine.sync();

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      final failedEvents = events.whereType<OperationFailedEvent>().toList();
      expect(failedEvents.length, 1);
      expect(failedEvents.first.opId, 'op-error-1');
      expect(failedEvents.first.kind, 'test_item');
      expect(failedEvents.first.entityId, 'item-1');
      expect(failedEvents.first.willRetry, true);

      engine.dispose();
    });

    test('skipConflictingOps removes unresolved conflicts from outbox', () async {
      final transport = ErrorPushTransport(
        serverData: {'id': 'item-1', 'name': 'Server'},
        serverTimestamp: DateTime.now().toUtc(),
      );
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
        config: const SyncConfig(
          // With manual strategy and no resolver, conflicts won't be resolved
          conflictStrategy: ConflictStrategy.manual,
          skipConflictingOps: true,
        ),
      );

      await db.enqueue(UpsertOp(
        opId: 'op-conflict-1',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'name': 'Local'},
      ));

      await engine.sync();

      // Verify outbox is empty (skipConflictingOps removed the unresolved conflict)
      final remainingOps = await db.takeOutbox();
      expect(remainingOps.length, 0);

      engine.dispose();
    });

    test('push throws MaxRetriesExceededException after retries exhausted', () async {
      // Create a transport that throws during push (not PushError, but actual exception)
      final transport = _ExceptionThrowingPushTransport();
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
        config: const SyncConfig(
          maxPushRetries: 1,
          backoffMin: Duration.zero,
        ),
      );

      await db.enqueue(UpsertOp(
        opId: 'op-throw-1',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'name': 'Test'},
      ));

      await expectLater(
        engine.sync(),
        throwsA(isA<MaxRetriesExceededException>()),
      );

      engine.dispose();
    });
  });

  group('Retry logic', () {
    test('sync retries push on failure', () async {
      final transport = RetryTransport(failCount: 2);
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
        config: const SyncConfig(
          maxPushRetries: 3,
          backoffMin: Duration(milliseconds: 10), // Fast retry for test
          backoffMultiplier: 1.0,
        ),
      );

      await db.enqueue(UpsertOp(
        opId: 'op-1',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'name': 'Test'},
      ));

      await engine.sync();

      expect(transport.pushAttempts, 3); // 2 failures + 1 success

      // Verify outbox is empty
      expect((await db.takeOutbox()).length, 0);

      engine.dispose();
    });

    test('sync gives up after max retries', () async {
      final transport = RetryTransport(failCount: 5);
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
        config: const SyncConfig(
          maxPushRetries: 3,
          backoffMin: Duration(milliseconds: 10),
          backoffMultiplier: 1.0,
        ),
      );

      await db.enqueue(UpsertOp(
        opId: 'op-1',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'name': 'Test'},
      ));

      await expectLater(engine.sync(), throwsA(isA<Exception>()));

      expect(transport.pushAttempts, 3); // Max retries reached

      // Verify outbox is NOT empty
      expect((await db.takeOutbox()).length, 1);

      engine.dispose();
    });
  });

  group('Outbox operations', () {
    test('enqueue UpsertOp', () async {
      await db.enqueue(UpsertOp(
        opId: 'upsert-1',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'name': 'Test'},
      ));

      final ops = await db.takeOutbox();
      expect(ops.length, 1);
      expect(ops.first, isA<UpsertOp>());
    });

    test('enqueue DeleteOp', () async {
      await db.enqueue(DeleteOp(
        opId: 'delete-1',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
      ));

      final ops = await db.takeOutbox();
      expect(ops.length, 1);
      expect(ops.first, isA<DeleteOp>());
    });

    test('takeOutbox respects limit', () async {
      for (var i = 0; i < 10; i++) {
        await db.enqueue(UpsertOp(
          opId: 'limit-$i',
          kind: 'test_item',
          id: 'item-$i',
          localTimestamp: DateTime.now().toUtc(),
          payloadJson: {},
        ));
      }

      final ops = await db.takeOutbox(limit: 3);
      expect(ops.length, 3);
    });

    test('ackOutbox removes operations', () async {
      await db.enqueue(UpsertOp(
        opId: 'ack-1',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {},
      ));
      await db.enqueue(UpsertOp(
        opId: 'ack-2',
        kind: 'test_item',
        id: 'item-2',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {},
      ));

      await db.ackOutbox(['ack-1']);

      final ops = await db.takeOutbox();
      expect(ops.length, 1);
      expect(ops.first.opId, 'ack-2');
    });
  });

  group('Cursor operations', () {
    test('getCursor returns null for unknown kind', () async {
      final cursor = await db.getCursor('unknown');
      expect(cursor == null, isTrue);
    });

    test('setCursor and getCursor roundtrip', () async {
      final original = Cursor(
        ts: DateTime(2024, 1, 1, 12, 0, 0).toUtc(),
        lastId: 'last-id-123',
      );

      await db.setCursor('test_kind', original);
      final retrieved = await db.getCursor('test_kind');

      expect(retrieved != null, isTrue);
      expect(retrieved!.lastId, original.lastId);
      expect(retrieved.ts.year, 2024);
    });
  });

  group('ConflictUtils.preservingMerge', () {
    test('merges non-conflicting fields', () {
      final local = {'name': 'Local Name', 'mood': 5};
      final server = {'name': 'Server Name', 'energy': 7};

      final result = ConflictUtils.preservingMerge(local, server);

      expect(result.data['name'], 'Local Name');
      expect(result.data['energy'], 7);
      expect(result.data['mood'], 5);
      expect(result.localFields, contains('name'));
      expect(result.localFields, contains('mood'));
      expect(result.serverFields, contains('energy'));
    });

    test('keeps local changes when server has null', () {
      final local = {'notes': 'My notes'};
      final server = {'notes': null, 'mood': 5};

      final result = ConflictUtils.preservingMerge(local, server);

      expect(result.data['notes'], 'My notes');
      expect(result.data['mood'], 5);
    });

    test('keeps server value when local is null', () {
      final local = <String, Object?>{'notes': null};
      final server = {'notes': 'Server notes'};

      final result = ConflictUtils.preservingMerge(local, server);

      expect(result.data['notes'], 'Server notes');
    });

    test('unions lists correctly', () {
      final local = {
        'tags': ['a', 'b', 'c']
      };
      final server = {
        'tags': ['b', 'd']
      };

      final result = ConflictUtils.preservingMerge(local, server);
      final tags = result.data['tags'] as List;

      expect(tags, containsAll(['a', 'b', 'c', 'd']));
    });

    test('unions lists of objects by id', () {
      final local = {
        'items': [
          {'id': '1', 'name': 'Local 1'},
          {'id': '3', 'name': 'Local 3'},
        ]
      };
      final server = {
        'items': [
          {'id': '1', 'name': 'Server 1'},
          {'id': '2', 'name': 'Server 2'},
        ]
      };

      final result = ConflictUtils.preservingMerge(local, server);
      final items = result.data['items'] as List;

      expect(items.length, 3);
    });

    test('respects changedFields', () {
      final local = {'name': 'Local', 'mood': 10, 'notes': 'Local notes'};
      final server = {'name': 'Server', 'mood': 5, 'notes': 'Server notes'};

      final result = ConflictUtils.preservingMerge(
        local,
        server,
        changedFields: {'mood'},
      );

      expect(result.data['name'], 'Server');
      expect(result.data['mood'], 10);
      expect(result.data['notes'], 'Server notes');
    });

    test('does not lose server data', () {
      final local = {'mood': 5};
      final server = {'mood': 3, 'energy': 7, 'notes': 'Server notes'};

      final result = ConflictUtils.preservingMerge(local, server);

      expect(result.data['mood'], 5);
      expect(result.data['energy'], 7);
      expect(result.data['notes'], 'Server notes');
    });

    test('handles nested objects', () {
      final local = {
        'settings': {'theme': 'dark', 'fontSize': 14}
      };
      final server = {
        'settings': {'theme': 'light', 'language': 'en'}
      };

      final result = ConflictUtils.preservingMerge(local, server);
      final settings = result.data['settings'] as Map<String, Object?>;

      expect(settings['theme'], 'dark');
      expect(settings['fontSize'], 14);
      expect(settings['language'], 'en');
    });

    test('preserves system fields from server', () {
      final local = {
        'id': 'local-id',
        'updatedAt': '2024-01-01T00:00:00Z',
        'name': 'Local',
      };
      final server = {
        'id': 'server-id',
        'updatedAt': '2024-01-02T00:00:00Z',
        'name': 'Server',
      };

      final result = ConflictUtils.preservingMerge(local, server);

      expect(result.data['id'], 'server-id');
      expect(result.data['updatedAt'], '2024-01-02T00:00:00Z');
      expect(result.data['name'], 'Local');
    });
  });

  group('autoPreserve conflict strategy', () {
    test('autoPreserve merges and force-pushes', () async {
      final serverData = {
        'id': 'item-1',
        'name': 'Server Name',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'energy': 7,
      };

      final transport = ConflictingTransport(
        serverData: serverData,
        serverTimestamp: DateTime.now().toUtc(),
      );

      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
        config: const SyncConfig(
          conflictStrategy: ConflictStrategy.autoPreserve,
        ),
      );

      await db.enqueue(UpsertOp(
        opId: 'conflict-op',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'name': 'Local Name', 'mood': 5},
      ));

      final events = <SyncEvent>[];
      final sub = engine.events.listen(events.add);

      await engine.sync();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await sub.cancel();

      expect(transport.forcePushCalled, isTrue);
      expect(events.whereType<ConflictDetectedEvent>().length, 1);
      expect(events.whereType<DataMergedEvent>().length, 1);
      expect(events.whereType<ConflictResolvedEvent>().length, 1);

      engine.dispose();
    });

    test('autoPreserve emits DataMergedEvent with correct fields', () async {
      final serverData = {
        'id': 'item-1',
        'name': 'Server Name',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final transport = ConflictingTransport(
        serverData: serverData,
        serverTimestamp: DateTime.now().toUtc(),
      );

      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
        config: const SyncConfig(
          conflictStrategy: ConflictStrategy.autoPreserve,
        ),
      );

      await db.enqueue(UpsertOp(
        opId: 'merge-test',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'mood': 5},
      ));

      final events = <SyncEvent>[];
      final sub = engine.events.listen(events.add);

      await engine.sync();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await sub.cancel();

      final mergeEvent = events.whereType<DataMergedEvent>().first;
      expect(mergeEvent.kind, 'test_item');
      expect(mergeEvent.entityId, 'item-1');
      expect(mergeEvent.localFields, contains('mood'));

      engine.dispose();
    });
  });

  group('Full Resync', () {
    test('fullResync resets cursors and pulls all data', () async {
      final transport = MockTransport();
      final now = DateTime.now().toUtc();
      transport.pullResponses.addAll([
        {
          'id': 'item-1',
          'updated_at': now.toIso8601String(),
          'name': 'Full Resync Item',
        },
      ]);

      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      await db.setCursor('test_item', Cursor(
        ts: DateTime(2024, 1, 1).toUtc(),
        lastId: 'old-item',
      ));

      await engine.fullResync();

      final cursor = await db.getCursor('test_item');
      expect(cursor != null, isTrue);
      expect(cursor!.lastId, 'item-1');

      final items = await db.select(db.testItems).get();
      expect(items.length, 1);
      expect(items.first.name, 'Full Resync Item');

      engine.dispose();
    });

    test('fullResync emits FullResyncStarted event with manual reason', () async {
      final transport = MockTransport();
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      final events = <SyncEvent>[];
      final sub = engine.events.listen(events.add);

      await engine.fullResync();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await sub.cancel();

      final fullResyncEvents = events.whereType<FullResyncStarted>().toList();
      expect(fullResyncEvents.length, 1);
      expect(fullResyncEvents.first.reason, FullResyncReason.manual);

      engine.dispose();
    });

    test('sync triggers fullResync when interval exceeded', () async {
      final transport = MockTransport();
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
        config: const SyncConfig(
          fullResyncInterval: Duration(days: 7),
        ),
      );

      final events = <SyncEvent>[];
      final sub = engine.events.listen(events.add);

      await engine.sync();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await sub.cancel();

      final fullResyncEvents = events.whereType<FullResyncStarted>().toList();
      expect(fullResyncEvents.length, 1);
      expect(fullResyncEvents.first.reason, FullResyncReason.scheduled);

      engine.dispose();
    });

    test('sync does not trigger fullResync when interval not exceeded', () async {
      final transport = MockTransport();
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
        config: const SyncConfig(
          fullResyncInterval: Duration(days: 7),
        ),
      );

      await db.setCursor(CursorKinds.fullResync, Cursor(
        ts: DateTime.now().toUtc(),
        lastId: '',
      ));

      final events = <SyncEvent>[];
      final sub = engine.events.listen(events.add);

      await engine.sync();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await sub.cancel();

      final fullResyncEvents = events.whereType<FullResyncStarted>().toList();
      expect(fullResyncEvents, isEmpty);

      engine.dispose();
    });

    test('fullResync pushes outbox before resetting cursors', () async {
      final transport = MockTransport();
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      await db.enqueue(UpsertOp(
        opId: 'before-resync',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'name': 'Test'},
      ));

      await engine.fullResync();

      expect(transport.pushedOps.length, 1);
      expect(transport.pushedOps.first.opId, 'before-resync');

      final outbox = await db.takeOutbox();
      expect(outbox, isEmpty);

      engine.dispose();
    });

    test('fullResync with clearData clears tables', () async {
      final transport = MockTransport();
      final now = DateTime.now().toUtc();
      transport.pullResponses.addAll([
        {
          'id': 'new-item',
          'updated_at': now.toIso8601String(),
          'name': 'New Item After Clear',
        },
      ]);

      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      await db.into(db.testItems).insert(TestItemsCompanion.insert(
        id: 'old-item',
        name: 'Old Item',
        updatedAt: DateTime(2024, 1, 1).toUtc(),
      ));

      final itemsBefore = await db.select(db.testItems).get();
      expect(itemsBefore.length, 1);
      expect(itemsBefore.first.id, 'old-item');

      await engine.fullResync(clearData: true);

      final itemsAfter = await db.select(db.testItems).get();
      expect(itemsAfter.length, 1);
      expect(itemsAfter.first.id, 'new-item');
      expect(itemsAfter.first.name, 'New Item After Clear');

      engine.dispose();
    });

    test('fullResync saves lastFullResync timestamp', () async {
      final transport = MockTransport();
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      final beforeSync = DateTime.now().toUtc();
      await engine.fullResync();
      final afterSync = DateTime.now().toUtc();

      final cursor = await db.getCursor(CursorKinds.fullResync);
      expect(cursor != null, isTrue);
      expect(cursor!.ts.isAfter(beforeSync.subtract(const Duration(seconds: 1))), isTrue);
      expect(cursor.ts.isBefore(afterSync.add(const Duration(seconds: 1))), isTrue);

      engine.dispose();
    });

    test('fullResync returns SyncStats', () async {
      final transport = MockTransport();
      final now = DateTime.now().toUtc();
      transport.pullResponses.addAll([
        {'id': 'item-1', 'updated_at': now.toIso8601String(), 'name': 'Item 1'},
        {'id': 'item-2', 'updated_at': now.toIso8601String(), 'name': 'Item 2'},
      ]);

      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      await db.enqueue(UpsertOp(
        opId: 'op-1',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'name': 'Test'},
      ));

      final stats = await engine.fullResync();

      expect(stats.pushed, 1);
      expect(stats.pulled, 2);

      engine.dispose();
    });

    test('concurrent fullResync calls are prevented', () async {
      final transport = SlowTransport();
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      final future1 = engine.fullResync();
      final future2 = engine.fullResync();

      final results = await Future.wait([future1, future2]);

      expect(results[1].pushed, 0);
      expect(results[1].pulled, 0);

      engine.dispose();
    });
  });

  group('UpsertOp with baseUpdatedAt and changedFields', () {
    test('enqueue preserves baseUpdatedAt', () async {
      final baseTime = DateTime(2024, 1, 1, 12, 0, 0).toUtc();

      await db.enqueue(UpsertOp(
        opId: 'base-test',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'name': 'Test'},
        baseUpdatedAt: baseTime,
      ));

      final ops = await db.takeOutbox();
      expect(ops.length, 1);

      final op = ops.first as UpsertOp;
      expect(op.baseUpdatedAt, baseTime);
      expect(op.isNewRecord, isFalse);
    });

    test('enqueue preserves changedFields', () async {
      await db.enqueue(UpsertOp(
        opId: 'changed-test',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'name': 'Test', 'mood': 5},
        changedFields: {'mood'},
      ));

      final ops = await db.takeOutbox();
      expect(ops.length, 1);

      final op = ops.first as UpsertOp;
      expect(op.changedFields, {'mood'});
    });

    test('isNewRecord returns true when baseUpdatedAt is null', () async {
      await db.enqueue(UpsertOp(
        opId: 'new-record',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'name': 'New'},
      ));

      final ops = await db.takeOutbox();
      final op = ops.first as UpsertOp;
      expect(op.isNewRecord, isTrue);
    });
  });

  group('ConflictStrategy tests', () {
    test('serverWins accepts server data on conflict', () async {
      final now = DateTime.now().toUtc();
      final serverData = {
        'id': 'item-1',
        'name': 'Server Name',
        'updated_at': now.toIso8601String(),
      };
      final transport = ConflictingTransport(
        serverData: serverData,
        serverTimestamp: now,
      );

      final events = <SyncEvent>[];
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
        config: const SyncConfig(conflictStrategy: ConflictStrategy.serverWins),
      );

      engine.events.listen(events.add);

      await db.enqueue(UpsertOp(
        opId: 'server-wins-op',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: now,
        payloadJson: {
          'id': 'item-1',
          'name': 'Local Name',
          'updated_at': now.toIso8601String(),
        },
      ));

      await engine.sync();

      expect(events.whereType<ConflictDetectedEvent>().length, 1);
      expect(events.whereType<ConflictResolvedEvent>().length, 1);

      final items = await db.select(db.testItems).get();
      expect(items.length, 1);
      expect(items.first.name, 'Server Name');

      engine.dispose();
    });

    test('clientWins force pushes client data', () async {
      final now = DateTime.now().toUtc();
      final serverData = {
        'id': 'item-2',
        'name': 'Server Name',
        'updated_at': now.toIso8601String(),
      };
      final transport = ConflictingTransport(
        serverData: serverData,
        serverTimestamp: now,
      );

      final events = <SyncEvent>[];
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
        config: const SyncConfig(conflictStrategy: ConflictStrategy.clientWins),
      );

      engine.events.listen(events.add);

      await db.enqueue(UpsertOp(
        opId: 'client-wins-op',
        kind: 'test_item',
        id: 'item-2',
        localTimestamp: now,
        payloadJson: {
          'id': 'item-2',
          'name': 'Local Name',
          'updated_at': now.toIso8601String(),
        },
      ));

      await engine.sync();

      expect(events.whereType<ConflictDetectedEvent>().length, 1);
      expect(transport.forcePushCalled, isTrue);

      engine.dispose();
    });

    test('lastWriteWins accepts client when local is newer', () async {
      final oldServerTime = DateTime.now().subtract(const Duration(hours: 2)).toUtc();
      final serverData = {
        'id': 'item-3',
        'name': 'Old Server Name',
        'updated_at': oldServerTime.toIso8601String(),
      };
      final transport = ConflictingTransport(
        serverData: serverData,
        serverTimestamp: oldServerTime,
      );

      final events = <SyncEvent>[];
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
        config: const SyncConfig(conflictStrategy: ConflictStrategy.lastWriteWins),
      );

      engine.events.listen(events.add);

      final newLocalTime = DateTime.now().toUtc();
      await db.enqueue(UpsertOp(
        opId: 'lww-client-op',
        kind: 'test_item',
        id: 'item-3',
        localTimestamp: newLocalTime,
        payloadJson: {
          'id': 'item-3',
          'name': 'New Local Name',
          'updated_at': newLocalTime.toIso8601String(),
        },
      ));

      await engine.sync();

      expect(events.whereType<ConflictDetectedEvent>().length, 1);
      expect(transport.forcePushCalled, isTrue);

      engine.dispose();
    });

    test('lastWriteWins accepts server when server is newer', () async {
      final newServerTime = DateTime.now().add(const Duration(hours: 1)).toUtc();
      final serverData = {
        'id': 'item-4',
        'name': 'New Server Name',
        'updated_at': newServerTime.toIso8601String(),
      };
      final transport = ConflictingTransport(
        serverData: serverData,
        serverTimestamp: newServerTime,
      );

      final events = <SyncEvent>[];
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
        config: const SyncConfig(conflictStrategy: ConflictStrategy.lastWriteWins),
      );

      engine.events.listen(events.add);

      final oldLocalTime = DateTime.now().subtract(const Duration(hours: 2)).toUtc();
      await db.enqueue(UpsertOp(
        opId: 'lww-server-op',
        kind: 'test_item',
        id: 'item-4',
        localTimestamp: oldLocalTime,
        payloadJson: {
          'id': 'item-4',
          'name': 'Old Local Name',
          'updated_at': oldLocalTime.toIso8601String(),
        },
      ));

      await engine.sync();

      expect(events.whereType<ConflictDetectedEvent>().length, 1);
      expect(events.whereType<ConflictResolvedEvent>().length, 1);
      expect(transport.forcePushCalled, isFalse);

      final items = await db.select(db.testItems).get();
      expect(items.length, 1);
      expect(items.first.name, 'New Server Name');

      engine.dispose();
    });

    test('merge strategy merges data', () async {
      final now = DateTime.now().toUtc();
      final serverData = {
        'id': 'item-5',
        'name': 'Server Name',
        'updated_at': now.toIso8601String(),
      };
      final transport = ConflictingTransport(
        serverData: serverData,
        serverTimestamp: now,
      );

      final events = <SyncEvent>[];
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
        config: SyncConfig(
          conflictStrategy: ConflictStrategy.merge,
          mergeFunction: (local, server) => {...server, ...local},
        ),
      );

      engine.events.listen(events.add);

      await db.enqueue(UpsertOp(
        opId: 'merge-op',
        kind: 'test_item',
        id: 'item-5',
        localTimestamp: now,
        payloadJson: {
          'id': 'item-5',
          'name': 'Local Name',
          'updated_at': now.toIso8601String(),
        },
      ));

      await engine.sync();

      expect(events.whereType<ConflictDetectedEvent>().length, 1);
      expect(transport.forcePushCalled, isTrue);

      engine.dispose();
    });

    test('manual strategy with resolver', () async {
      final now = DateTime.now().toUtc();
      final serverData = {
        'id': 'item-6',
        'name': 'Server Name',
        'updated_at': now.toIso8601String(),
      };
      final transport = ConflictingTransport(
        serverData: serverData,
        serverTimestamp: now,
      );

      var resolverCalled = false;
      final events = <SyncEvent>[];
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
        config: SyncConfig(
          conflictStrategy: ConflictStrategy.manual,
          conflictResolver: (conflict) async {
            resolverCalled = true;
            return const AcceptServer();
          },
        ),
      );

      engine.events.listen(events.add);

      await db.enqueue(UpsertOp(
        opId: 'manual-op',
        kind: 'test_item',
        id: 'item-6',
        localTimestamp: now,
        payloadJson: {
          'id': 'item-6',
          'name': 'Local Name',
          'updated_at': now.toIso8601String(),
        },
      ));

      await engine.sync();

      expect(resolverCalled, isTrue);
      expect(events.whereType<ConflictResolvedEvent>().length, 1);

      engine.dispose();
    });

    test('resolver can return DiscardOperation', () async {
      final now = DateTime.now().toUtc();
      final serverData = {
        'id': 'item-8',
        'name': 'Server Name',
        'updated_at': now.toIso8601String(),
      };
      final transport = ConflictingTransport(
        serverData: serverData,
        serverTimestamp: now,
      );

      final events = <SyncEvent>[];
      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
        config: SyncConfig(
          conflictStrategy: ConflictStrategy.manual,
          conflictResolver: (conflict) async => const DiscardOperation(),
        ),
      );

      engine.events.listen(events.add);

      await db.enqueue(UpsertOp(
        opId: 'discard-op',
        kind: 'test_item',
        id: 'item-8',
        localTimestamp: now,
        payloadJson: {
          'id': 'item-8',
          'name': 'Local Name',
          'updated_at': now.toIso8601String(),
        },
      ));

      await engine.sync();

      expect(events.whereType<ConflictResolvedEvent>().length, 1);

      engine.dispose();
    });

  });

  group('DeleteOp tests', () {
    test('enqueue DeleteOp preserves baseUpdatedAt', () async {
      final baseTime = DateTime(2024, 1, 1, 12, 0, 0).toUtc();

      await db.enqueue(DeleteOp(
        opId: 'delete-base-test',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        baseUpdatedAt: baseTime,
      ));

      final ops = await db.takeOutbox();
      expect(ops.length, 1);

      final op = ops.first as DeleteOp;
      expect(op.baseUpdatedAt, baseTime);
    });

    test('DeleteOp syncs correctly', () async {
      final transport = MockTransport();
      final now = DateTime.now().toUtc();

      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      await db.enqueue(DeleteOp(
        opId: 'delete-op-1',
        kind: 'test_item',
        id: 'item-to-delete',
        localTimestamp: now,
      ));

      await engine.sync();

      expect(transport.pushedOps.length, 1);
      expect(transport.pushedOps.first, isA<DeleteOp>());
      expect(transport.pushedOps.first.id, 'item-to-delete');

      final outbox = await db.takeOutbox();
      expect(outbox, isEmpty);

      engine.dispose();
    });
  });

  group('PushNotFound handling', () {
    test('push ignores PushNotFound results', () async {
      final transport = NotFoundTransport();

      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      await db.enqueue(UpsertOp(
        opId: 'not-found-op',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {
          'id': 'item-1',
          'name': 'Test',
          'updated_at': DateTime.now().toIso8601String(),
        },
      ));

      await engine.sync();

      final outbox = await db.takeOutbox();
      expect(outbox, isEmpty);

      engine.dispose();
    });
  });

  group('Drift DAC queries', () {
    test('filter outbox by kind using DAC', () async {
      await db.enqueue(UpsertOp(
        opId: 'dac-op-1',
        kind: 'users',
        id: 'user-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'user-1', 'name': 'User 1'},
      ));

      await db.enqueue(UpsertOp(
        opId: 'dac-op-2',
        kind: 'posts',
        id: 'post-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'post-1', 'title': 'Post 1'},
      ));

      final allOps = await db.takeOutbox();
      expect(allOps.length, 2);

      await db.ackOutbox(['dac-op-1', 'dac-op-2']);
    });

    test('outbox ordering by timestamp', () async {
      final time1 = DateTime.now().subtract(const Duration(hours: 2)).toUtc();
      final time2 = DateTime.now().subtract(const Duration(hours: 1)).toUtc();
      final time3 = DateTime.now().toUtc();

      await db.enqueue(UpsertOp(
        opId: 'order-op-3',
        kind: 'test_item',
        id: 'item-3',
        localTimestamp: time3,
        payloadJson: {'id': 'item-3', 'name': 'Third'},
      ));

      await db.enqueue(UpsertOp(
        opId: 'order-op-1',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: time1,
        payloadJson: {'id': 'item-1', 'name': 'First'},
      ));

      await db.enqueue(UpsertOp(
        opId: 'order-op-2',
        kind: 'test_item',
        id: 'item-2',
        localTimestamp: time2,
        payloadJson: {'id': 'item-2', 'name': 'Second'},
      ));

      final ops = await db.takeOutbox();
      expect(ops.length, 3);
      expect(ops[0].opId, 'order-op-1');
      expect(ops[1].opId, 'order-op-2');
      expect(ops[2].opId, 'order-op-3');

      await db.ackOutbox(['order-op-1', 'order-op-2', 'order-op-3']);
    });

    test('cursor operations', () async {
      final cursor1 = Cursor(ts: DateTime.now().toUtc(), lastId: 'item-1');
      await db.setCursor('users', cursor1);

      final cursor2 = Cursor(ts: DateTime.now().toUtc(), lastId: 'item-2');
      await db.setCursor('posts', cursor2);

      final userCursor = await db.getCursor('users');
      expect(userCursor != null, isTrue);
      expect(userCursor!.lastId, 'item-1');

      final postCursor = await db.getCursor('posts');
      expect(postCursor != null, isTrue);
      expect(postCursor!.lastId, 'item-2');

      await db.resetAllCursors({'users', 'posts'});

      final resetUserCursor = await db.getCursor('users');
      expect(resetUserCursor == null, isTrue);

      final resetPostCursor = await db.getCursor('posts');
      expect(resetPostCursor == null, isTrue);
    });

    test('cursor update replaces existing', () async {
      final cursor1 = Cursor(ts: DateTime.now().toUtc(), lastId: 'old-id');
      await db.setCursor('test_kind', cursor1);

      final cursor2 = Cursor(ts: DateTime.now().toUtc(), lastId: 'new-id');
      await db.setCursor('test_kind', cursor2);

      final cursor = await db.getCursor('test_kind');
      expect(cursor != null, isTrue);
      expect(cursor!.lastId, 'new-id');

      await db.resetAllCursors({'test_kind'});
    });
  });

  group('CursorService methods', () {
    test('reset sets cursor to epoch zero', () async {
      final engine = SyncEngine(
        db: db,
        transport: MockTransport(),
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      await db.setCursor('test_kind', Cursor(
        ts: DateTime.now().toUtc(),
        lastId: 'some-id',
      ));

      final cursorService = CursorService(db);
      await cursorService.reset('test_kind');

      final cursor = await db.getCursor('test_kind');
      expect(cursor != null, isTrue);
      expect(cursor!.ts.millisecondsSinceEpoch, 0);
      expect(cursor.lastId, '');

      engine.dispose();
    });

    test('getLastFullResync returns null when not set', () async {
      final cursorService = CursorService(db);
      final lastFullResync = await cursorService.getLastFullResync();
      expect(lastFullResync == null, isTrue);
    });

    test('setLastFullResync and getLastFullResync work together', () async {
      final cursorService = CursorService(db);
      final timestamp = DateTime.now().toUtc();

      await cursorService.setLastFullResync(timestamp);

      final lastFullResync = await cursorService.getLastFullResync();
      expect(lastFullResync != null, isTrue);
      expect(
        lastFullResync!.difference(timestamp).inSeconds.abs(),
        lessThan(1),
      );
    });
  });

  group('OutboxService methods', () {
    test('hasOperations returns false when empty', () async {
      final outboxService = OutboxService(db);
      final hasOps = await outboxService.hasOperations();
      expect(hasOps, isFalse);
    });

    test('hasOperations returns true when not empty', () async {
      final outboxService = OutboxService(db);

      await outboxService.enqueue(UpsertOp(
        opId: 'has-ops-test',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'name': 'Test'},
      ));

      final hasOps = await outboxService.hasOperations();
      expect(hasOps, isTrue);

      await outboxService.ack(['has-ops-test']);
    });

    test('purgeOlderThan removes old operations', () async {
      final outboxService = OutboxService(db);
      final oldTime = DateTime.now().subtract(const Duration(days: 30)).toUtc();

      await outboxService.enqueue(UpsertOp(
        opId: 'old-purge-op',
        kind: 'test_item',
        id: 'item-old',
        localTimestamp: oldTime,
        payloadJson: {'id': 'item-old', 'name': 'Old'},
      ));

      final threshold = DateTime.now().subtract(const Duration(days: 7)).toUtc();
      final deleted = await outboxService.purgeOlderThan(threshold);

      expect(deleted, 1);
    });
  });

  group('SyncDatabase methods', () {
    test('purgeOutboxOlderThan removes old operations', () async {
      final oldTime = DateTime.now().subtract(const Duration(days: 30)).toUtc();
      final newTime = DateTime.now().toUtc();

      await db.enqueue(UpsertOp(
        opId: 'old-op',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: oldTime,
        payloadJson: {'id': 'item-1', 'name': 'Old'},
      ));

      await db.enqueue(UpsertOp(
        opId: 'new-op',
        kind: 'test_item',
        id: 'item-2',
        localTimestamp: newTime,
        payloadJson: {'id': 'item-2', 'name': 'New'},
      ));

      final threshold = DateTime.now().subtract(const Duration(days: 7)).toUtc();
      final deleted = await db.purgeOutboxOlderThan(threshold);

      expect(deleted, 1);

      final remaining = await db.takeOutbox();
      expect(remaining.length, 1);
      expect(remaining.first.opId, 'new-op');
    });

    test('ackOutbox with empty list does nothing', () async {
      await db.enqueue(UpsertOp(
        opId: 'op-1',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'name': 'Test'},
      ));

      await db.ackOutbox([]);

      final ops = await db.takeOutbox();
      expect(ops.length, 1);
    });

    test('resetAllCursors with empty set does nothing', () async {
      await db.setCursor('test_item', Cursor(
        ts: DateTime.now().toUtc(),
        lastId: 'item-1',
      ));

      await db.resetAllCursors({});

      final cursor = await db.getCursor('test_item');
      expect(cursor != null, isTrue);
    });

    test('clearSyncableTables clears specified tables', () async {
      await db.into(db.testItems).insert(TestItemsCompanion.insert(
        id: 'item-1',
        name: 'Test Item',
        updatedAt: DateTime.now().toUtc(),
      ));

      final itemsBefore = await db.select(db.testItems).get();
      expect(itemsBefore.length, 1);

      await db.clearSyncableTables(['test_items']);

      final itemsAfter = await db.select(db.testItems).get();
      expect(itemsAfter, isEmpty);
    });
  });

  group('SyncEngine getters', () {
    test('outbox returns OutboxService', () async {
      final engine = SyncEngine(
        db: db,
        transport: MockTransport(),
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      final outbox = engine.outbox;
      expect(outbox, isA<OutboxService>());

      engine.dispose();
    });

    test('cursors returns CursorService', () async {
      final engine = SyncEngine(
        db: db,
        transport: MockTransport(),
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      final cursors = engine.cursors;
      expect(cursors, isA<CursorService>());

      engine.dispose();
    });
  });

  group('Pull with deleted items', () {
    test('pull handles items with deletedAt', () async {
      final deletedItemTime = DateTime.now().subtract(const Duration(days: 1)).toUtc();

      final transport = DeletedItemsTransport(
        items: [
          {
            'id': 'deleted-1',
            'name': 'Deleted Item',
            'updated_at': deletedItemTime.toIso8601String(),
            'deleted_at': deletedItemTime.toIso8601String(),
          },
          {
            'id': 'active-1',
            'name': 'Active Item',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
        ],
      );

      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: TestItem.fromJson,
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      final events = <SyncEvent>[];
      engine.events.listen(events.add);

      await engine.sync();

      final cacheUpdateEvents =
          events.whereType<CacheUpdateEvent>().toList();
      expect(cacheUpdateEvents, isNotEmpty);
      expect(cacheUpdateEvents.first.deletes, 1);
      expect(cacheUpdateEvents.first.upserts, 1);

      engine.dispose();
    });
  });

  group('Pull with uuid field', () {
    test('pull uses uuid when id and ID are not present', () async {
      final transport = UuidItemsTransport(
        items: [
          {
            'uuid': 'uuid-12345',
            'name': 'UUID Item',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
        ],
      );

      final engine = SyncEngine(
        db: db,
        transport: transport,
        tables: [
          SyncableTable<TestItem>(
            kind: 'test_item',
            table: db.testItems,
            fromJson: (json) => TestItem(
              id: json['uuid'] as String? ?? json['id'] as String,
              name: json['name'] as String,
              updatedAt: DateTime.parse(json['updated_at'] as String),
            ),
            toJson: (item) => item.toJson(),
            toInsertable: (item) => item.toInsertable(),
          ),
        ],
      );

      await engine.sync();

      engine.dispose();
    });
  });

}

class DeletedItemsTransport implements TransportAdapter {
  final List<Map<String, dynamic>> items;

  DeletedItemsTransport({required this.items});

  @override
  Future<PullPage> pull({
    required String kind,
    required DateTime updatedSince,
    required int pageSize,
    String? pageToken,
    String? afterId,
    bool includeDeleted = true,
  }) async =>
      PullPage(items: items);

  @override
  Future<BatchPushResult> push(List<Op> ops) async => BatchPushResult(
        results: ops.map((op) => OpPushResult(opId: op.opId, result: const PushSuccess())).toList(),
      );

  @override
  Future<PushResult> forcePush(Op op) async => const PushSuccess();

  @override
  Future<FetchResult> fetch({required String kind, required String id}) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}

class UuidItemsTransport implements TransportAdapter {
  final List<Map<String, dynamic>> items;

  UuidItemsTransport({required this.items});

  @override
  Future<PullPage> pull({
    required String kind,
    required DateTime updatedSince,
    required int pageSize,
    String? pageToken,
    String? afterId,
    bool includeDeleted = true,
  }) async =>
      PullPage(items: items);

  @override
  Future<BatchPushResult> push(List<Op> ops) async => BatchPushResult(
        results: ops.map((op) => OpPushResult(opId: op.opId, result: const PushSuccess())).toList(),
      );

  @override
  Future<PushResult> forcePush(Op op) async => const PushSuccess();

  @override
  Future<FetchResult> fetch({required String kind, required String id}) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}

class _FailingTransport implements TransportAdapter {
  @override
  Future<PullPage> pull({
    required String kind,
    required DateTime updatedSince,
    required int pageSize,
    String? pageToken,
    String? afterId,
    bool includeDeleted = true,
  }) async {
    throw Exception('Network error');
  }

  @override
  Future<BatchPushResult> push(List<Op> ops) async {
    throw Exception('Network error');
  }

  @override
  Future<PushResult> forcePush(Op op) async {
    throw Exception('Network error');
  }

  @override
  Future<FetchResult> fetch({
    required String kind,
    required String id,
  }) async {
    throw Exception('Network error');
  }

  @override
  Future<bool> health() async => false;
}

class RetryTransport implements TransportAdapter {
  int pushAttempts = 0;
  final int failCount;

  RetryTransport({this.failCount = 2});

  @override
  Future<BatchPushResult> push(List<Op> ops) async {
    pushAttempts++;
    if (pushAttempts <= failCount) {
      throw Exception('Network error attempt $pushAttempts');
    }
    return BatchPushResult(
      results: ops
          .map((op) => OpPushResult(
                opId: op.opId,
                result: const PushSuccess(),
              ))
          .toList(),
    );
  }

  @override
  Future<PullPage> pull({
    required String kind,
    required DateTime updatedSince,
    required int pageSize,
    String? pageToken,
    String? afterId,
    bool includeDeleted = true,
  }) async =>
      PullPage(items: []);

  @override
  Future<PushResult> forcePush(Op op) async => const PushSuccess();

  @override
  Future<FetchResult> fetch({required String kind, required String id}) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}

class ConflictingTransport implements TransportAdapter {
  final Map<String, Object?> serverData;
  final DateTime serverTimestamp;
  int pushCallCount = 0;
  bool forcePushCalled = false;

  ConflictingTransport({
    required this.serverData,
    required this.serverTimestamp,
  });

  @override
  Future<BatchPushResult> push(List<Op> ops) async {
    pushCallCount++;
    return BatchPushResult(
      results: ops
          .map((op) => OpPushResult(
                opId: op.opId,
                result: PushConflict(
                  serverData: serverData,
                  serverTimestamp: serverTimestamp,
                ),
              ))
          .toList(),
    );
  }

  @override
  Future<PullPage> pull({
    required String kind,
    required DateTime updatedSince,
    required int pageSize,
    String? pageToken,
    String? afterId,
    bool includeDeleted = true,
  }) async =>
      PullPage(items: []);

  @override
  Future<PushResult> forcePush(Op op) async {
    forcePushCalled = true;
    return const PushSuccess();
  }

  @override
  Future<FetchResult> fetch({required String kind, required String id}) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}

class SlowTransport implements TransportAdapter {
  @override
  Future<BatchPushResult> push(List<Op> ops) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return BatchPushResult(
      results: ops
          .map((op) => OpPushResult(
                opId: op.opId,
                result: const PushSuccess(),
              ))
          .toList(),
    );
  }

  @override
  Future<PullPage> pull({
    required String kind,
    required DateTime updatedSince,
    required int pageSize,
    String? pageToken,
    String? afterId,
    bool includeDeleted = true,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return PullPage(items: []);
  }

  @override
  Future<PushResult> forcePush(Op op) async => const PushSuccess();

  @override
  Future<FetchResult> fetch({required String kind, required String id}) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}

class RetryingConflictTransport implements TransportAdapter {
  final Map<String, Object?> serverData;
  final DateTime serverTimestamp;
  int forcePushCallCount = 0;
  final int conflictCount;

  RetryingConflictTransport({
    required this.serverData,
    required this.serverTimestamp,
    this.conflictCount = 1,
  });

  @override
  Future<BatchPushResult> push(List<Op> ops) async => BatchPushResult(
        results: ops
            .map((op) => OpPushResult(
                  opId: op.opId,
                  result: PushConflict(
                    serverData: serverData,
                    serverTimestamp: serverTimestamp,
                  ),
                ))
            .toList(),
      );

  @override
  Future<PullPage> pull({
    required String kind,
    required DateTime updatedSince,
    required int pageSize,
    String? pageToken,
    String? afterId,
    bool includeDeleted = true,
  }) async =>
      PullPage(items: []);

  @override
  Future<PushResult> forcePush(Op op) async {
    forcePushCallCount++;
    if (forcePushCallCount <= conflictCount) {
      return PushConflict(
        serverData: serverData,
        serverTimestamp: serverTimestamp,
      );
    }
    return const PushSuccess();
  }

  @override
  Future<FetchResult> fetch({required String kind, required String id}) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}

class NotFoundTransport implements TransportAdapter {
  @override
  Future<BatchPushResult> push(List<Op> ops) async => BatchPushResult(
        results: ops
            .map((op) => OpPushResult(
                  opId: op.opId,
                  result: const PushNotFound(),
                ))
            .toList(),
      );

  @override
  Future<PullPage> pull({
    required String kind,
    required DateTime updatedSince,
    required int pageSize,
    String? pageToken,
    String? afterId,
    bool includeDeleted = true,
  }) async =>
      PullPage(items: []);

  @override
  Future<PushResult> forcePush(Op op) async => const PushSuccess();

  @override
  Future<FetchResult> fetch({required String kind, required String id}) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}

class ErrorResultTransport implements TransportAdapter {
  @override
  Future<BatchPushResult> push(List<Op> ops) async => BatchPushResult(
        results: ops
            .map((op) => OpPushResult(
                  opId: op.opId,
                  result: PushError(Exception('Push error')),
                ))
            .toList(),
      );

  @override
  Future<PullPage> pull({
    required String kind,
    required DateTime updatedSince,
    required int pageSize,
    String? pageToken,
    String? afterId,
    bool includeDeleted = true,
  }) async =>
      PullPage(items: []);

  @override
  Future<PushResult> forcePush(Op op) async => const PushSuccess();

  @override
  Future<FetchResult> fetch({required String kind, required String id}) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}

class ErrorPushTransport implements TransportAdapter {
  final Map<String, Object?> serverData;
  final DateTime serverTimestamp;

  ErrorPushTransport({
    required this.serverData,
    required this.serverTimestamp,
  });

  @override
  Future<BatchPushResult> push(List<Op> ops) async => BatchPushResult(
        results: ops
            .map((op) => OpPushResult(
                  opId: op.opId,
                  result: PushConflict(
                    serverData: serverData,
                    serverTimestamp: serverTimestamp,
                  ),
                ))
            .toList(),
      );

  @override
  Future<PullPage> pull({
    required String kind,
    required DateTime updatedSince,
    required int pageSize,
    String? pageToken,
    String? afterId,
    bool includeDeleted = true,
  }) async =>
      PullPage(items: []);

  @override
  Future<PushResult> forcePush(Op op) async =>
      PushError(Exception('Force push failed'));

  @override
  Future<FetchResult> fetch({required String kind, required String id}) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}

/// Transport that returns PushError on first call, then PushSuccess.
class _ErrorOnceTransport implements TransportAdapter {
  int _pushCallCount = 0;

  @override
  Future<BatchPushResult> push(List<Op> ops) async {
    _pushCallCount++;
    return BatchPushResult(
      results: ops
          .map((op) => OpPushResult(
                opId: op.opId,
                result: _pushCallCount == 1
                    ? PushError(Exception('Temporary error'))
                    : const PushSuccess(),
              ))
          .toList(),
    );
  }

  @override
  Future<PullPage> pull({
    required String kind,
    required DateTime updatedSince,
    required int pageSize,
    String? pageToken,
    String? afterId,
    bool includeDeleted = true,
  }) async =>
      PullPage(items: []);

  @override
  Future<PushResult> forcePush(Op op) async => const PushSuccess();

  @override
  Future<FetchResult> fetch({required String kind, required String id}) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}

/// Transport that throws exception during push (for testing exception wrapping).
class _ExceptionThrowingPushTransport implements TransportAdapter {
  @override
  Future<BatchPushResult> push(List<Op> ops) async {
    throw Exception('Network connection failed');
  }

  @override
  Future<PullPage> pull({
    required String kind,
    required DateTime updatedSince,
    required int pageSize,
    String? pageToken,
    String? afterId,
    bool includeDeleted = true,
  }) async =>
      PullPage(items: []);

  @override
  Future<PushResult> forcePush(Op op) async => const PushSuccess();

  @override
  Future<FetchResult> fetch({required String kind, required String id}) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}
