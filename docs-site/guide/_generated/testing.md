# Testing

A guide to testing applications that use `offline_first_sync_drift`. All examples are based on real patterns from the project's test suite.

## Table of Contents

- [Test Dependencies](#test-dependencies)
- [Mocking TransportAdapter](#mocking-transportadapter)
- [In-memory Database](#in-memory-database)
- [Testing the Sync Cycle](#testing-the-sync-cycle)
- [Testing Conflicts](#testing-conflicts)
- [Testing Auto Sync](#testing-auto-sync)
- [Testing Errors](#testing-errors)
- [Testing Outbox](#testing-outbox)
- [Testing Cursors](#testing-cursors)
- [Integration Tests](#integration-tests)
- [Full Test Example](#full-test-example)

---

## Test Dependencies

Add to `pubspec.yaml`:

```yaml
dev_dependencies:
  test: ^1.25.15
  mocktail: ^1.0.4
  drift_dev: ^2.26.1
  build_runner: ^2.4.15
```

Core dependencies:

| Package | Purpose |
|---------|---------|
| `test` | Testing framework |
| `mocktail` | Class mocking (optional -- can be done manually) |
| `drift` | Drift in-memory database for tests |

---

## Mocking TransportAdapter

`TransportAdapter` is the network transport interface. Tests require a mock implementation.

### Basic Mock

Simplest implementation that returns successful results:

```dart
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
```

### Mock with Conflicts

For testing conflict scenarios -- push always returns `PushConflict`:

```dart
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
  Future<FetchResult> fetch({
    required String kind,
    required String id,
  }) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}
```

### Mock with Network Errors

For testing error handling:

```dart
class FailingTransport implements TransportAdapter {
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
```

### Mock with Retries

Transport that fails `N` times and then responds successfully:

```dart
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
  Future<FetchResult> fetch({
    required String kind,
    required String id,
  }) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}
```

### Mock with PushError (Once)

Transport that returns `PushError` on the first push call and `PushSuccess` on the second:

```dart
class ErrorOnceTransport implements TransportAdapter {
  int pushCallCount = 0;

  @override
  Future<BatchPushResult> push(List<Op> ops) async {
    pushCallCount++;
    return BatchPushResult(
      results: ops
          .map((op) => OpPushResult(
                opId: op.opId,
                result: pushCallCount == 1
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
  Future<FetchResult> fetch({
    required String kind,
    required String id,
  }) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}
```

### Mock with Persistent Push Failure

Transport that always throws an exception on push:

```dart
class AlwaysFailingPushTransport implements TransportAdapter {
  @override
  Future<BatchPushResult> push(List<Op> ops) async {
    throw Exception('Push always fails');
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
    throw Exception('ForcePush always fails');
  }

  @override
  Future<FetchResult> fetch({
    required String kind,
    required String id,
  }) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}
```

### Mock with Deleted Items

Transport that returns a given list of items on pull (including deleted ones):

```dart
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
  Future<BatchPushResult> push(List<Op> ops) async {
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
  Future<PushResult> forcePush(Op op) async => const PushSuccess();

  @override
  Future<FetchResult> fetch({
    required String kind,
    required String id,
  }) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}
```

### Mock with Delay

Transport with artificial delay for testing concurrent calls:

```dart
class SlowTransport implements TransportAdapter {
  final Duration delay;

  SlowTransport({this.delay = const Duration(milliseconds: 100)});

  @override
  Future<PullPage> pull({
    required String kind,
    required DateTime updatedSince,
    required int pageSize,
    String? pageToken,
    String? afterId,
    bool includeDeleted = true,
  }) async {
    await Future<void>.delayed(delay);
    return PullPage(items: []);
  }

  @override
  Future<BatchPushResult> push(List<Op> ops) async {
    await Future<void>.delayed(delay);
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
    await Future<void>.delayed(delay);
    return const PushSuccess();
  }

  @override
  Future<FetchResult> fetch({
    required String kind,
    required String id,
  }) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}
```

### PushResult Types for Mocking

| Type | Description | Usage |
|------|-------------|-------|
| `PushSuccess()` | Operation succeeded | Default response |
| `PushConflict(serverData: {...}, serverTimestamp: ts)` | Version conflict | Conflict tests |
| `PushNotFound()` | Entity not found on server | Deleting non-existent items test |
| `PushError(Exception('msg'))` | Push error | Error handling tests |

---

## In-memory Database

Tests use a Drift in-memory database via `NativeDatabase.memory()`.

### Setting Up a Test Table

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

// Test model
class TestItem {
  TestItem({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
  });

  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
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

// Test table with SyncColumns mixin
@UseRowClass(TestItem, generateInsertable: true)
class TestItems extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Setting Up a Test Database

```dart
@DriftDatabase(
  include: {'package:offline_first_sync_drift/src/sync_tables.drift'},
  tables: [TestItems],
)
class TestDatabase extends $TestDatabase with SyncDatabaseMixin {
  TestDatabase() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}
```

After defining tables and the database, run code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### setUp/tearDown Template

```dart
void main() {
  late TestDatabase db;

  setUp(() async {
    db = TestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  // tests...
}
```

> Each test gets a clean in-memory database. The `tearDown` method closes the database to properly release resources.

---

## Testing the Sync Cycle

### Push: Sending Operations from Outbox

```dart
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

  // Add an operation to the outbox
  await db.enqueue(
    UpsertOp.create(
      kind: 'test_item',
      id: 'item-1',
      localTimestamp: DateTime.now().toUtc(),
      payloadJson: {'id': 'item-1', 'name': 'Test'},
      opId: 'test-op-1',
    ),
  );

  await engine.sync();

  // Verify push was called with our operation
  expect(transport.pushedOps.length, 1);
  expect(transport.pushedOps.first.opId, 'test-op-1');

  engine.dispose();
});
```

### Pull: Fetching Data from Server

```dart
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

  // Server data should be saved to the local DB
  final items = await db.select(db.testItems).get();
  expect(items.length, 1);
  expect(items.first.name, 'Pulled Item');

  engine.dispose();
});
```

### Outbox Cleanup After Successful Push

```dart
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

  await db.enqueue(
    UpsertOp.create(
      kind: 'test_item',
      id: 'item-1',
      localTimestamp: DateTime.now().toUtc(),
      payloadJson: {},
      opId: 'clear-test-1',
    ),
  );

  // Before sync -- outbox has an operation
  expect((await db.takeOutbox()).length, 1);

  await engine.sync();

  // After sync -- outbox is empty
  expect((await db.takeOutbox()).length, 0);

  engine.dispose();
});
```

### Verifying Sync Events

```dart
test('sync emits SyncStarted and SyncCompleted events', () async {
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

  // Should have 2 SyncStarted: push and pull
  expect(events.whereType<SyncStarted>().length, 2);
  expect(events.whereType<SyncCompleted>().length, 1);

  engine.dispose();
});
```

---

## Testing Conflicts

### serverWins Strategy

On conflict, server data is accepted:

```dart
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
    config: const SyncConfig(
      conflictStrategy: ConflictStrategy.serverWins,
    ),
  );

  engine.events.listen(events.add);

  await db.enqueue(UpsertOp.create(
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

  // Conflict detected and resolved
  expect(events.whereType<ConflictDetectedEvent>().length, 1);
  expect(events.whereType<ConflictResolvedEvent>().length, 1);

  // Server data saved to DB
  final items = await db.select(db.testItems).get();
  expect(items.length, 1);
  expect(items.first.name, 'Server Name');

  engine.dispose();
});
```

### clientWins Strategy

On conflict, client data is force-pushed:

```dart
test('clientWins force pushes client data', () async {
  final now = DateTime.now().toUtc();
  final transport = ConflictingTransport(
    serverData: {
      'id': 'item-2',
      'name': 'Server Name',
      'updated_at': now.toIso8601String(),
    },
    serverTimestamp: now,
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
      conflictStrategy: ConflictStrategy.clientWins,
    ),
  );

  await db.enqueue(UpsertOp.create(
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

  // forcePush was called
  expect(transport.forcePushCalled, isTrue);

  engine.dispose();
});
```

### lastWriteWins Strategy

The side with the newer data wins:

```dart
test('lastWriteWins accepts client when local is newer', () async {
  final oldServerTime = DateTime.now()
      .subtract(const Duration(hours: 2))
      .toUtc();
  final transport = ConflictingTransport(
    serverData: {
      'id': 'item-3',
      'name': 'Old Server Name',
      'updated_at': oldServerTime.toIso8601String(),
    },
    serverTimestamp: oldServerTime,
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
      conflictStrategy: ConflictStrategy.lastWriteWins,
    ),
  );

  final newLocalTime = DateTime.now().toUtc();
  await db.enqueue(UpsertOp.create(
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

  // Client is newer -- forcePush called
  expect(transport.forcePushCalled, isTrue);

  engine.dispose();
});
```

### autoPreserve Strategy

Automatic data merging without loss:

```dart
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

  await db.enqueue(UpsertOp.create(
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

  // forcePush was called with merged data
  expect(transport.forcePushCalled, isTrue);
  expect(events.whereType<ConflictDetectedEvent>().length, 1);
  expect(events.whereType<DataMergedEvent>().length, 1);
  expect(events.whereType<ConflictResolvedEvent>().length, 1);

  engine.dispose();
});
```

### merge Strategy with Custom Function

```dart
test('merge strategy merges data', () async {
  final now = DateTime.now().toUtc();
  final transport = ConflictingTransport(
    serverData: {
      'id': 'item-5',
      'name': 'Server Name',
      'updated_at': now.toIso8601String(),
    },
    serverTimestamp: now,
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
    config: SyncConfig(
      conflictStrategy: ConflictStrategy.merge,
      // Custom function: local on top of server
      mergeFunction: (local, server) => {...server, ...local},
    ),
  );

  await db.enqueue(UpsertOp.create(
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

  expect(transport.forcePushCalled, isTrue);

  engine.dispose();
});
```

### manual Strategy with ConflictResolver

```dart
test('manual strategy with resolver', () async {
  final now = DateTime.now().toUtc();
  final transport = ConflictingTransport(
    serverData: {
      'id': 'item-6',
      'name': 'Server Name',
      'updated_at': now.toIso8601String(),
    },
    serverTimestamp: now,
  );

  var resolverCalled = false;

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
        // Can return any resolution:
        // AcceptServer(), AcceptClient(),
        // AcceptMerged({...}), DiscardOperation()
        return const AcceptServer();
      },
    ),
  );

  await db.enqueue(UpsertOp.create(
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

  engine.dispose();
});
```

### Testing ConflictResolution: DiscardOperation

```dart
test('resolver can return DiscardOperation', () async {
  final now = DateTime.now().toUtc();
  final transport = ConflictingTransport(
    serverData: {
      'id': 'item-8',
      'name': 'Server Name',
      'updated_at': now.toIso8601String(),
    },
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

  await db.enqueue(UpsertOp.create(
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

  // Operation discarded, but conflict resolved
  expect(events.whereType<ConflictResolvedEvent>().length, 1);

  engine.dispose();
});
```

### Testing ConflictUtils.preservingMerge

The automatic data merging utility is tested separately:

```dart
test('merges non-conflicting fields', () {
  final local = {'name': 'Local Name', 'mood': 5};
  final server = {'name': 'Server Name', 'energy': 7};

  final result = ConflictUtils.preservingMerge(local, server);

  // Local fields preserved
  expect(result.data['name'], 'Local Name');
  expect(result.data['mood'], 5);
  // Server fields added
  expect(result.data['energy'], 7);
  // Field tracking
  expect(result.localFields, contains('name'));
  expect(result.localFields, contains('mood'));
  expect(result.serverFields, contains('energy'));
});

test('respects changedFields', () {
  final local = {'name': 'Local', 'mood': 10, 'notes': 'Local notes'};
  final server = {'name': 'Server', 'mood': 5, 'notes': 'Server notes'};

  final result = ConflictUtils.preservingMerge(
    local,
    server,
    changedFields: {'mood'}, // Only mood was changed locally
  );

  // Only mood is taken from local, the rest -- from server
  expect(result.data['name'], 'Server');
  expect(result.data['mood'], 10);
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
```

---

## Testing Auto Sync

### startAuto / stopAuto

```dart
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

  // Wait for a few cycles
  await Future<void>.delayed(const Duration(milliseconds: 250));

  engine
    ..stopAuto()
    ..dispose();

  // Should have synced at least once
  expect(transport.pullCallCount, greaterThan(0));
});
```

> Use a short interval (`milliseconds: 100`) in tests to avoid waiting.

---

## Testing Errors

### Transport Error Throws Exception

```dart
test('sync throws on transport failure', () async {
  final errorTransport = FailingTransport();
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
```

### SyncErrorEvent Emission

```dart
test('sync emits error event before throwing', () async {
  final errorTransport = FailingTransport();
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
    // Expected exception
  }

  await Future<void>.delayed(const Duration(milliseconds: 50));
  await sub.cancel();

  expect(events.whereType<SyncErrorEvent>().length, greaterThan(0));

  engine.dispose();
});
```

### OperationFailedEvent on PushError

```dart
test('push emits OperationFailedEvent on PushError', () async {
  // Transport that returns PushError once, then PushSuccess
  // ErrorOnceTransport definition -- see above
  final transport = ErrorOnceTransport();
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

  await db.enqueue(UpsertOp.create(
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
  expect(failedEvents.first.willRetry, true);

  engine.dispose();
});
```

### Retry Logic: Push Retry Attempts

```dart
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
      backoffMin: Duration(milliseconds: 10),
      backoffMultiplier: 1.0,
    ),
  );

  await db.enqueue(UpsertOp.create(
    opId: 'op-1',
    kind: 'test_item',
    id: 'item-1',
    localTimestamp: DateTime.now().toUtc(),
    payloadJson: {'id': 'item-1', 'name': 'Test'},
  ));

  await engine.sync();

  // 2 failed + 1 successful = 3 attempts
  expect(transport.pushAttempts, 3);

  // Outbox cleared after success
  expect((await db.takeOutbox()).length, 0);

  engine.dispose();
});
```

### MaxRetriesExceededException

```dart
test('push throws MaxRetriesExceededException after retries exhausted',
    () async {
  // Transport that throws an exception on every push
  final transport = AlwaysFailingPushTransport();
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

  await db.enqueue(UpsertOp.create(
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
```

### skipConflictingOps: Removing Unresolved Conflicts

```dart
test('skipConflictingOps removes unresolved conflicts from outbox',
    () async {
  final transport = ConflictingTransport(
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
      conflictStrategy: ConflictStrategy.manual,
      // No resolver -- conflict will not be resolved
      skipConflictingOps: true,
    ),
  );

  await db.enqueue(UpsertOp.create(
    opId: 'op-conflict-1',
    kind: 'test_item',
    id: 'item-1',
    localTimestamp: DateTime.now().toUtc(),
    payloadJson: {'id': 'item-1', 'name': 'Local'},
  ));

  await engine.sync();

  // skipConflictingOps removed the unresolved conflict from outbox
  final remainingOps = await db.takeOutbox();
  expect(remainingOps.length, 0);

  engine.dispose();
});
```

---

## Testing Outbox

### Enqueueing Operations

```dart
test('enqueue UpsertOp', () async {
  await db.enqueue(UpsertOp.create(
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
  await db.enqueue(DeleteOp.create(
    opId: 'delete-1',
    kind: 'test_item',
    id: 'item-1',
    localTimestamp: DateTime.now().toUtc(),
  ));

  final ops = await db.takeOutbox();
  expect(ops.length, 1);
  expect(ops.first, isA<DeleteOp>());
});
```

### takeOutbox with Limit

```dart
test('takeOutbox respects limit', () async {
  for (var i = 0; i < 10; i++) {
    await db.enqueue(UpsertOp.create(
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
```

### ackOutbox: Acknowledging Operations

```dart
test('ackOutbox removes operations', () async {
  await db.enqueue(UpsertOp.create(
    opId: 'ack-1',
    kind: 'test_item',
    id: 'item-1',
    localTimestamp: DateTime.now().toUtc(),
    payloadJson: {},
  ));
  await db.enqueue(UpsertOp.create(
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
```

### Sorting by Timestamp

```dart
test('outbox ordering by timestamp', () async {
  final time1 = DateTime.now().subtract(const Duration(hours: 2)).toUtc();
  final time2 = DateTime.now().subtract(const Duration(hours: 1)).toUtc();
  final time3 = DateTime.now().toUtc();

  // Add in reverse order
  await db.enqueue(UpsertOp.create(
    opId: 'order-op-3',
    kind: 'test_item',
    id: 'item-3',
    localTimestamp: time3,
    payloadJson: {},
  ));
  await db.enqueue(UpsertOp.create(
    opId: 'order-op-1',
    kind: 'test_item',
    id: 'item-1',
    localTimestamp: time1,
    payloadJson: {},
  ));
  await db.enqueue(UpsertOp.create(
    opId: 'order-op-2',
    kind: 'test_item',
    id: 'item-2',
    localTimestamp: time2,
    payloadJson: {},
  ));

  final ops = await db.takeOutbox();
  // Operations sorted by timestamp
  expect(ops[0].opId, 'order-op-1');
  expect(ops[1].opId, 'order-op-2');
  expect(ops[2].opId, 'order-op-3');
});
```

### purgeOlderThan: Cleaning Up Old Operations

```dart
test('purgeOlderThan removes old operations', () async {
  final oldTime = DateTime.now().subtract(const Duration(days: 30)).toUtc();
  final newTime = DateTime.now().toUtc();

  await db.enqueue(UpsertOp.create(
    opId: 'old-op',
    kind: 'test_item',
    id: 'item-1',
    localTimestamp: oldTime,
    payloadJson: {},
  ));

  await db.enqueue(UpsertOp.create(
    opId: 'new-op',
    kind: 'test_item',
    id: 'item-2',
    localTimestamp: newTime,
    payloadJson: {},
  ));

  final threshold = DateTime.now()
      .subtract(const Duration(days: 7))
      .toUtc();
  final deleted = await db.purgeOutboxOlderThan(threshold);

  expect(deleted, 1);

  final remaining = await db.takeOutbox();
  expect(remaining.length, 1);
  expect(remaining.first.opId, 'new-op');
});
```

### OutboxService: hasOperations

```dart
test('hasOperations returns false when empty', () async {
  final outboxService = OutboxService(db);
  final hasOps = await outboxService.hasOperations();
  expect(hasOps, isFalse);
});

test('hasOperations returns true when not empty', () async {
  final outboxService = OutboxService(db);

  await outboxService.enqueue(UpsertOp.create(
    opId: 'has-ops-test',
    kind: 'test_item',
    id: 'item-1',
    localTimestamp: DateTime.now().toUtc(),
    payloadJson: {'id': 'item-1', 'name': 'Test'},
  ));

  final hasOps = await outboxService.hasOperations();
  expect(hasOps, isTrue);
});
```

### UpsertOp: baseUpdatedAt and changedFields

```dart
test('enqueue preserves baseUpdatedAt', () async {
  final baseTime = DateTime(2024, 1, 1, 12, 0, 0).toUtc();

  await db.enqueue(UpsertOp.create(
    opId: 'base-test',
    kind: 'test_item',
    id: 'item-1',
    localTimestamp: DateTime.now().toUtc(),
    payloadJson: {'id': 'item-1', 'name': 'Test'},
    baseUpdatedAt: baseTime,
  ));

  final ops = await db.takeOutbox();
  final op = ops.first as UpsertOp;
  expect(op.baseUpdatedAt, baseTime);
  expect(op.isNewRecord, isFalse);
});

test('isNewRecord returns true when baseUpdatedAt is null', () async {
  await db.enqueue(UpsertOp.create(
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
```

---

## Testing Cursors

### getCursor / setCursor

```dart
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
```

### Cursor Update After Pull

```dart
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
```

### Resetting Cursors

```dart
test('resetAllCursors clears cursors', () async {
  await db.setCursor('users', Cursor(
    ts: DateTime.now().toUtc(),
    lastId: 'item-1',
  ));
  await db.setCursor('posts', Cursor(
    ts: DateTime.now().toUtc(),
    lastId: 'item-2',
  ));

  await db.resetAllCursors({'users', 'posts'});

  expect(await db.getCursor('users') == null, isTrue);
  expect(await db.getCursor('posts') == null, isTrue);
});
```

### CursorService: reset and fullResync

```dart
test('reset sets cursor to epoch zero', () async {
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
```

---

## Integration Tests

### Full Sync Cycle with Mock Transport

```dart
test('full sync cycle: enqueue, push, pull, verify', () async {
  final transport = MockTransport();
  final now = DateTime.now().toUtc();

  // Server will return data on pull
  transport.pullResponses.addAll([
    {
      'id': 'server-item',
      'updated_at': now.toIso8601String(),
      'name': 'From Server',
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

  // 1. Add a local operation
  await db.enqueue(UpsertOp.create(
    opId: 'local-op-1',
    kind: 'test_item',
    id: 'local-item',
    localTimestamp: now,
    payloadJson: {'id': 'local-item', 'name': 'Local'},
  ));

  // 2. Run sync
  final stats = await engine.sync();

  // 3. Verify push
  expect(transport.pushedOps.length, 1);
  expect(transport.pushedOps.first.opId, 'local-op-1');
  expect(stats.pushed, 1);

  // 4. Verify pull
  expect(stats.pulled, 1);
  final items = await db.select(db.testItems).get();
  expect(items.any((i) => i.id == 'server-item'), isTrue);

  // 5. Outbox is empty
  final outbox = await db.takeOutbox();
  expect(outbox, isEmpty);

  // 6. Cursor updated
  final cursor = await db.getCursor('test_item');
  expect(cursor != null, isTrue);

  engine.dispose();
});
```

### Full Resync

```dart
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

  // Set an old cursor
  await db.setCursor('test_item', Cursor(
    ts: DateTime(2024, 1, 1).toUtc(),
    lastId: 'old-item',
  ));

  await engine.fullResync();

  // Cursor updated to new data
  final cursor = await db.getCursor('test_item');
  expect(cursor != null, isTrue);
  expect(cursor!.lastId, 'item-1');

  // Data fetched
  final items = await db.select(db.testItems).get();
  expect(items.length, 1);
  expect(items.first.name, 'Full Resync Item');

  engine.dispose();
});
```

### Full Resync with Data Clearing

```dart
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

  // Insert old data directly into DB
  await db.into(db.testItems).insert(TestItemsCompanion.insert(
    id: 'old-item',
    name: 'Old Item',
    updatedAt: DateTime(2024, 1, 1).toUtc(),
  ));

  // Before resync -- old data exists
  final itemsBefore = await db.select(db.testItems).get();
  expect(itemsBefore.length, 1);
  expect(itemsBefore.first.id, 'old-item');

  // clearData: true -- table is cleared before pull
  await engine.fullResync(clearData: true);

  // After resync -- only new data
  final itemsAfter = await db.select(db.testItems).get();
  expect(itemsAfter.length, 1);
  expect(itemsAfter.first.id, 'new-item');

  engine.dispose();
});
```

### Automatic fullResync by Interval

```dart
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

  // Without a saved cursor fullResync -- sync() will trigger fullResync
  await engine.sync();
  await Future<void>.delayed(const Duration(milliseconds: 10));

  await sub.cancel();

  final fullResyncEvents = events.whereType<FullResyncStarted>().toList();
  expect(fullResyncEvents.length, 1);
  expect(fullResyncEvents.first.reason, FullResyncReason.scheduled);

  engine.dispose();
});
```

### Concurrent sync/fullResync Calls

```dart
test('concurrent fullResync calls are prevented', () async {
  final transport = SlowTransport(); // Transport with 100ms delay
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

  // Second call gets empty stats (did not execute separately)
  expect(results[1].pushed, 0);
  expect(results[1].pulled, 0);

  engine.dispose();
});
```

### Pull with Deleted Items

```dart
test('pull handles items with deletedAt', () async {
  final deletedItemTime = DateTime.now()
      .subtract(const Duration(days: 1))
      .toUtc();

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

  final cacheUpdateEvents = events.whereType<CacheUpdateEvent>().toList();
  expect(cacheUpdateEvents, isNotEmpty);
  expect(cacheUpdateEvents.first.deletes, 1);
  expect(cacheUpdateEvents.first.upserts, 1);

  engine.dispose();
});
```

---

## Full Test Example

File `test/sync_engine_test.dart` demonstrating all core patterns:

```dart
import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';
import 'package:test/test.dart' hide isNotNull, isNull;

import 'sync_engine_test.drift.dart';

// --- Models ---

class TestItem {
  TestItem({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
  });

  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
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

// --- Tables ---

@UseRowClass(TestItem, generateInsertable: true)
class TestItems extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Database ---

@DriftDatabase(
  include: {'package:offline_first_sync_drift/src/sync_tables.drift'},
  tables: [TestItems],
)
class TestDatabase extends $TestDatabase with SyncDatabaseMixin {
  TestDatabase() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

// --- Mocks ---

class MockTransport implements TransportAdapter {
  final List<Map<String, dynamic>> pullResponses = [];
  final List<Op> pushedOps = [];
  int pullCallCount = 0;

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
    return PullPage(items: pullResponses);
  }

  @override
  Future<BatchPushResult> push(List<Op> ops) async {
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
  Future<PushResult> forcePush(Op op) async => const PushSuccess();

  @override
  Future<FetchResult> fetch({
    required String kind,
    required String id,
  }) async =>
      const FetchNotFound();

  @override
  Future<bool> health() async => true;
}

// --- Tests ---

void main() {
  late TestDatabase db;

  setUp(() async {
    db = TestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper: create a SyncEngine with MockTransport
  SyncEngine createEngine(MockTransport transport) => SyncEngine(
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

  group('Sync cycle', () {
    test('push sends operations from outbox', () async {
      final transport = MockTransport();
      final engine = createEngine(transport);

      await db.enqueue(UpsertOp.create(
        opId: 'op-1',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'name': 'Test'},
      ));

      await engine.sync();

      expect(transport.pushedOps.length, 1);
      expect(transport.pushedOps.first.opId, 'op-1');

      engine.dispose();
    });

    test('pull saves data to DB', () async {
      final transport = MockTransport();
      transport.pullResponses.add({
        'id': 'pulled-1',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'name': 'Pulled Item',
      });

      final engine = createEngine(transport);
      await engine.sync();

      final items = await db.select(db.testItems).get();
      expect(items.length, 1);
      expect(items.first.name, 'Pulled Item');

      engine.dispose();
    });

    test('outbox is cleared after successful push', () async {
      final transport = MockTransport();
      final engine = createEngine(transport);

      await db.enqueue(UpsertOp.create(
        opId: 'op-1',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {},
      ));

      await engine.sync();

      expect((await db.takeOutbox()).length, 0);
      engine.dispose();
    });
  });

  group('Events', () {
    test('sync emits SyncStarted and SyncCompleted', () async {
      final transport = MockTransport();
      final engine = createEngine(transport);

      final events = <SyncEvent>[];
      final sub = engine.events.listen(events.add);

      await engine.sync();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();

      expect(events.whereType<SyncStarted>().length, 2);
      expect(events.whereType<SyncCompleted>().length, 1);

      engine.dispose();
    });
  });

  group('Outbox', () {
    test('enqueue and takeOutbox work correctly', () async {
      await db.enqueue(UpsertOp.create(
        opId: 'op-1',
        kind: 'test_item',
        id: 'item-1',
        localTimestamp: DateTime.now().toUtc(),
        payloadJson: {'id': 'item-1', 'name': 'Test'},
      ));

      final ops = await db.takeOutbox();
      expect(ops.length, 1);
      expect(ops.first, isA<UpsertOp>());
    });
  });

  group('Cursors', () {
    test('cursor is updated after pull', () async {
      final transport = MockTransport();
      transport.pullResponses.add({
        'id': 'cursor-item',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'name': 'Test',
      });

      final engine = createEngine(transport);
      await engine.sync();

      final cursor = await db.getCursor('test_item');
      expect(cursor != null, isTrue);
      expect(cursor!.lastId, 'cursor-item');

      engine.dispose();
    });
  });
}
```

---

## Running Tests

```bash
# Run all tests
dart test

# Run with verbose output
dart test -r expanded

# Run a specific file
dart test test/sync_engine_test.dart

# Run a specific group
dart test --name "Sync cycle"

# With coverage (requires the coverage package)
dart test --coverage=coverage
dart run coverage:format_coverage \
  --lcov \
  --in=coverage \
  --out=coverage/lcov.info \
  --report-on=lib
```

---

## Testing Tips

1. **Always call `engine.dispose()`** at the end of each test to properly release `StreamController` resources.

2. **Use `await Future<void>.delayed()`** after `engine.sync()` before checking events -- events may be delivered asynchronously.

3. **Each test gets a clean DB** via `setUp` -- this guarantees test isolation.

4. **For retry tests, use minimal backoff** (`backoffMin: Duration(milliseconds: 10)`, `backoffMultiplier: 1.0`) so tests run quickly.

5. **Create specialized transports** for specific scenarios instead of a single universal mock -- the code is cleaner and more readable.

6. **Ops can be verified via pattern matching** thanks to sealed class:

```dart
final op = ops.first;
switch (op) {
  case UpsertOp(:final payloadJson):
    expect(payloadJson['name'], 'Test');
  case DeleteOp():
    expect(op.id, 'item-1');
}
```
