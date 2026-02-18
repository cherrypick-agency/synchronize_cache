---
sidebar_position: 5
---
# Advanced Cache

A guide for experienced developers: conflict resolution, field-level merge, retry strategies, and sync monitoring.

> Before reading this guide, make sure you have completed the [Simple Cache](./simple-cache.md) guide.

---

## When You Need Advanced Cache

Simple cache is sufficient for apps with a single device and short offline periods. Advanced settings are needed when:

- **Multiple devices** — the user edits data on a phone and tablet simultaneously
- **Collaboration** — multiple users edit the same entity
- **Extended offline** — the device can be offline for hours or days, during which server data changes
- **Data criticality** — losing user changes is unacceptable (medical records, finances, notes)

In all these scenarios, when pushing local changes, the server may return a **conflict**: the data you are trying to update has already been modified by someone else.

---

## Conflict Resolution Strategies

`SyncConfig` accepts a `conflictStrategy` parameter that defines the behavior on conflict. The default is `autoPreserve`.

```dart
final config = SyncConfig(
  conflictStrategy: ConflictStrategy.autoPreserve,
);
```

### `autoPreserve` — smart merge without data loss (default)

The most advanced strategy. Uses `ConflictUtils.preservingMerge`, which:

1. Takes server data as the base
2. If `changedFields` are specified — applies **only the changed fields** from local data
3. If the local value is not `null` but the server value is `null` — takes the local value
4. Lists are merged (union by `id` for objects, by value for primitives)
5. Nested Maps are merged recursively
6. System fields (`id`, `updatedAt`, `createdAt`, `deletedAt`) are always taken from the server

```dart
final engine = SyncEngine(
  db: database,
  transport: transport,
  tables: tables,
  config: const SyncConfig(
    conflictStrategy: ConflictStrategy.autoPreserve,
  ),
);
```

**When to use:** In most applications. A safe default strategy — no data is lost.

**Example scenario:** A user changed the `title` of a task while offline, and another user changed the `priority`. With `autoPreserve`, the result will contain both changes.

### `serverWins` — server is always right

The simplest strategy. On conflict, local changes are discarded and server data is applied.

```dart
const SyncConfig(
  conflictStrategy: ConflictStrategy.serverWins,
)
```

**When to use:** Reference data, system settings, data generated only by the server. Cases where the server version is authoritative.

**Risks:** Local user changes will be lost without warning.

### `clientWins` — client is always right

On conflict, the operation is retried with a forced push via `forcePush`. Server data is overwritten.

```dart
const SyncConfig(
  conflictStrategy: ConflictStrategy.clientWins,
)
```

**When to use:** Personal user data that is not collaboratively edited (profile, personal settings).

**Risks:** Other users' changes will be lost. If `forcePush` returns a conflict again, there will be up to `maxConflictRetries` retry attempts.

### `lastWriteWins` — the latest timestamp wins

Compares `localTimestamp` and `serverTimestamp`. The record with the later timestamp wins.

```dart
const SyncConfig(
  conflictStrategy: ConflictStrategy.lastWriteWins,
)
```

**When to use:** Data where recency is determined by time (statuses, positions, last known location).

**Important:** Requires synchronized clocks. If the client clock is off, the result will be incorrect.

### `merge` — custom merge

Calls `MergeFunction` to combine data. If no function is provided, `ConflictUtils.defaultMerge` is used.

```dart
SyncConfig(
  conflictStrategy: ConflictStrategy.merge,
  mergeFunction: (local, server) {
    // Custom logic: server as base + non-null local fields
    final merged = Map<String, Object?>.from(server);
    for (final entry in local.entries) {
      if (entry.key == 'tags' && server['tags'] is List) {
        // For tags -- merge lists
        final serverTags = (server['tags']! as List).cast<String>();
        final localTags = (entry.value! as List).cast<String>();
        merged['tags'] = {...serverTags, ...localTags}.toList();
      } else if (entry.value != null) {
        merged[entry.key] = entry.value;
      }
    }
    return merged;
  },
)
```

**When to use:** When the merge logic is specific to your domain model.

### `manual` — manual resolution via callback

Calls `ConflictResolver` — an async callback that receives a `Conflict` object and returns a `ConflictResolution`.

```dart
SyncConfig(
  conflictStrategy: ConflictStrategy.manual,
  conflictResolver: (conflict) async {
    // Show user a choice dialog
    final userChoice = await showConflictDialog(conflict);
    return userChoice;
  },
)
```

If `conflictResolver` is not provided, the conflict is deferred (`DeferResolution`) and remains in the outbox until the next sync.

**When to use:** Critical data where the user must decide which version to keep.

---

## Tracking Changed Fields (Field-Level Merge)

The key to smart merging is the `changedFields` field in `UpsertOp`. It indicates which specific fields the user changed locally.

### How It Works

When creating an operation in the outbox, you can specify which fields were changed:

```dart
final op = UpsertOp.create(
  kind: 'todos',
  id: todo.id,
  localTimestamp: DateTime.now().toUtc(),
  payloadJson: todo.toJson(),
  baseUpdatedAt: todo.updatedAt,
  changedFields: {'title', 'description'}, // Only these fields were changed
);

await engine.outbox.enqueue(op);
```

### How `autoPreserve` Uses `changedFields`

When `changedFields` is specified, `ConflictUtils.preservingMerge` applies **only the listed fields** from local data. The remaining fields are taken from the server.

```dart
// Local data (user changed title):
// {id: '1', title: 'New Title', priority: 3, status: 'open'}

// Server data (another user changed priority):
// {id: '1', title: 'Old Title', priority: 5, status: 'done'}

// changedFields: {'title'}

// preservingMerge result:
// {id: '1', title: 'New Title', priority: 5, status: 'done'}
//            ^^ from local       ^^ from server  ^^ from server
```

When `changedFields` is `null`, all non-null local fields are considered changed.

### `PreservingMergeResult`

The `preservingMerge` method returns not just data, but a `PreservingMergeResult` with information about field sources:

```dart
final result = ConflictUtils.preservingMerge(
  localData,
  serverData,
  changedFields: {'title'},
);

print(result.data);         // Merged data
print(result.localFields);  // {'title'} -- fields taken from local data
print(result.serverFields); // {'priority', 'status'} -- fields from server
```

---

## Per-Table Configuration

Different entity types may require different strategies. `TableConflictConfig` allows you to set a strategy for each table individually.

```dart
final engine = SyncEngine(
  db: database,
  transport: transport,
  tables: [todosTable, settingsTable, commentsTable],
  config: const SyncConfig(
    // Default global strategy
    conflictStrategy: ConflictStrategy.autoPreserve,
  ),
  tableConflictConfigs: {
    // User settings -- client is always right
    'settings': const TableConflictConfig(
      strategy: ConflictStrategy.clientWins,
    ),
    // Comments -- server is always right
    'comments': const TableConflictConfig(
      strategy: ConflictStrategy.serverWins,
    ),
    // Tasks -- custom merge with special timestamps field
    'todos': TableConflictConfig(
      strategy: ConflictStrategy.merge,
      timestampField: 'updatedAt',
      mergeFunction: (local, server) {
        final merged = Map<String, Object?>.from(server);
        // Priority always from server
        merged['title'] = local['title'] ?? server['title'];
        merged['description'] = local['description'] ?? server['description'];
        return merged;
      },
    ),
  },
);
```

If no configuration is specified for a table, the global strategy from `SyncConfig` is used.

Each `TableConflictConfig` can override:
- `strategy` — strategy for this table
- `resolver` — custom `ConflictResolver` (for the `manual` strategy)
- `mergeFunction` — custom merge function (for the `merge` strategy)
- `timestampField` — field name for time comparison (default is `'updatedAt'`)

---

## Custom ConflictResolver

For the `manual` strategy, you implement a `ConflictResolver` — a function with the following signature:

```dart
typedef ConflictResolver = Future<ConflictResolution> Function(Conflict conflict);
```

### The Conflict Object

`Conflict` contains all the information needed to make a decision:

```dart
class Conflict {
  final String kind;                      // Entity type ('todos', 'notes')
  final String entityId;                  // Entity ID
  final String opId;                      // Outbox operation ID
  final Map<String, Object?> localData;   // Client data
  final Map<String, Object?> serverData;  // Server data
  final DateTime localTimestamp;          // Local change time
  final DateTime serverTimestamp;         // Server change time
  final String? serverVersion;            // Server version (ETag)
  final Set<String>? changedFields;       // Fields changed by client
}
```

### Full Example: Conflict Resolution UI

```dart
SyncConfig(
  conflictStrategy: ConflictStrategy.manual,
  conflictResolver: (conflict) async {
    // Get BuildContext (e.g., via GlobalKey<NavigatorState>)
    final context = navigatorKey.currentContext!;

    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Conflict: ${conflict.kind}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your version: ${conflict.localData}'),
            const SizedBox(height: 8),
            Text('Server version: ${conflict.serverData}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'server'),
            child: const Text('Use server version'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'client'),
            child: const Text('Keep mine'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'defer'),
            child: const Text('Decide later'),
          ),
        ],
      ),
    );

    return switch (choice) {
      'server' => const AcceptServer(),
      'client' => const AcceptClient(),
      _ => const DeferResolution(),
    };
  },
)
```

---

## ConflictResolution Types

`ConflictResolution` is a sealed class with five subtypes. Your `ConflictResolver` must return one of them:

### AcceptServer

Accept the server version. Local data is overwritten with server data in the local DB, and the operation is removed from the outbox.

```dart
const AcceptServer()
```

### AcceptClient

Accept the client version. The operation is retried via `forcePush`. If `forcePush` returns a conflict again, there will be up to `maxConflictRetries` retries (default 3) with a `conflictRetryDelay` (default 500ms).

```dart
const AcceptClient()
```

### AcceptMerged

Use the merged data. A new operation with `mergedData` is sent via `forcePush`. On success, the data is also written to the local DB.

```dart
AcceptMerged(
  {'title': 'Merged Title', 'priority': 5},
  mergeInfo: MergeInfo(
    localFields: {'title'},
    serverFields: {'priority'},
  ),
)
```

`mergeInfo` is optional but useful for logging and debugging.

### DeferResolution

Defer the decision. The operation remains in the outbox and will be processed during the next sync. Generates a `ConflictUnresolvedEvent`.

```dart
const DeferResolution()
```

### DiscardOperation

Cancel the operation. The operation is removed from the outbox; neither the local DB nor the server is modified. Data in the local DB remains as-is.

```dart
const DiscardOperation()
```

---

## Full Resync

Full resynchronization resets all cursors and re-downloads all data from the server.

### Automatic Full Resync

Configured via `fullResyncInterval`. Default is every 7 days.

```dart
const SyncConfig(
  fullResyncInterval: Duration(days: 7),
)
```

On each `sync()` call, the engine checks whether enough time has passed since the last full resync. If so, it triggers a full resynchronization with reason `FullResyncReason.scheduled`.

### Manual Full Resync

```dart
final stats = await engine.fullResync(clearData: false);
```

The `clearData` parameter:
- `false` (default) — cursors are reset, data is preserved, pull applies data on top (insertOrReplace)
- `true` — local data is cleared before pull

### Full Resync Workflow

1. `FullResyncStarted` is emitted with the reason (`scheduled` or `manual`)
2. All operations from the outbox are pushed
3. Cursors for all tables are reset
4. (if `clearData: true`) Data in synced tables is cleared
5. Pull is performed for all tables
6. The last full resync timestamp is updated
7. `SyncCompleted` is emitted

---

## Retry and Backoff

### Exponential Backoff for Push

On a push error (not a conflict, but a network error or server unavailability), the engine retries with an exponentially increasing delay:

```dart
const SyncConfig(
  maxPushRetries: 5,             // Maximum 5 attempts
  backoffMin: Duration(seconds: 1),  // Initial delay 1 sec
  backoffMax: Duration(minutes: 2),  // Maximum delay 2 min
  backoffMultiplier: 2.0,           // Multiplier
)
```

Delay formula: `min(backoffMin * backoffMultiplier^(attempt-1), backoffMax)`

| Attempt | Delay  |
|---------|--------|
| 1       | 1 sec  |
| 2       | 2 sec  |
| 3       | 4 sec  |
| 4       | 8 sec  |
| 5       | 16 sec |

### MaxRetriesExceededException

If all attempts are exhausted, a `MaxRetriesExceededException` is thrown:

```dart
try {
  await engine.sync();
} on MaxRetriesExceededException catch (e) {
  print('Push failed after ${e.attempts}/${e.maxRetries} attempts');
  print('Reason: ${e.cause}');
}
```

### Conflict Retries

Retry settings for conflict resolution (for `AcceptClient` and `AcceptMerged`) are configured separately:

```dart
const SyncConfig(
  maxConflictRetries: 3,                      // forcePush attempts
  conflictRetryDelay: Duration(milliseconds: 500), // Delay between them
)
```

### skipConflictingOps

If a conflict could not be resolved:

```dart
const SyncConfig(
  skipConflictingOps: true,  // Remove operation from outbox
  // skipConflictingOps: false, // Keep in outbox (default)
)
```

---

## Sync Monitoring

### SyncEvent

`SyncEvent` is a sealed class. Subscribe to `engine.events` to track the entire sync lifecycle:

```dart
engine.events.listen((event) {
  switch (event) {
    case SyncStarted(:final phase):
      print('Sync: $phase');

    case SyncProgress(:final phase, :final done, :final total):
      print('$phase: $done/$total (${(event.progress * 100).toInt()}%)');

    case SyncCompleted(:final took, :final stats):
      print('Completed in ${took.inMilliseconds}ms');
      if (stats != null) {
        print('  pushed: ${stats.pushed}');
        print('  pulled: ${stats.pulled}');
        print('  conflicts: ${stats.conflicts}');
        print('  resolved: ${stats.conflictsResolved}');
        print('  errors: ${stats.errors}');
      }

    case SyncErrorEvent(:final phase, :final error):
      print('Error $phase: $error');

    case FullResyncStarted(:final reason):
      print('Full resync: $reason');

    case ConflictDetectedEvent(:final conflict, :final strategy):
      print('Conflict: ${conflict.kind}/${conflict.entityId}, '
          'strategy: $strategy');

    case ConflictResolvedEvent(:final conflict, :final resolution):
      print('Resolved: ${conflict.entityId} -> '
          '${resolution.runtimeType}');

    case ConflictUnresolvedEvent(:final conflict, :final reason):
      print('Unresolved: ${conflict.entityId}, reason: $reason');

    case DataMergedEvent(:final kind, :final entityId,
        :final localFields, :final serverFields):
      print('Merge $kind/$entityId: '
          'local=${localFields.length}, server=${serverFields.length}');

    case CacheUpdateEvent(:final kind, :final upserts, :final deletes):
      print('Cache $kind: +$upserts -$deletes');

    case OperationPushedEvent(:final kind, :final entityId, :final operationType):
      print('Pushed: $operationType $kind/$entityId');

    case OperationFailedEvent(:final kind, :final entityId,
        :final error, :final willRetry):
      print('Failed: $kind/$entityId, retry=$willRetry: $error');
  }
});
```

### SyncStats

`SyncStats` is returned from `sync()` and `fullResync()`, and is also included in `SyncCompleted`:

```dart
final stats = await engine.sync();

print('Pushed: ${stats.pushed}');
print('Pulled: ${stats.pulled}');
print('Conflicts: ${stats.conflicts}');
print('Resolved: ${stats.conflictsResolved}');
print('Errors: ${stats.errors}');
```

### Logging Pattern

```dart
import 'dart:developer' as dev;

void setupSyncLogging(SyncEngine engine) {
  engine.events.listen((event) {
    switch (event) {
      case SyncErrorEvent(:final error, :final stackTrace):
        dev.log(
          'Sync error',
          error: error,
          stackTrace: stackTrace,
          name: 'sync',
        );
      case ConflictDetectedEvent(:final conflict, :final strategy):
        dev.log(
          'Conflict: ${conflict.kind}/${conflict.entityId} [$strategy]',
          name: 'sync.conflict',
        );
      case SyncCompleted(:final took, :final stats):
        dev.log(
          'Sync done in ${took.inMilliseconds}ms: $stats',
          name: 'sync',
        );
      default:
        dev.log('$event', name: 'sync');
    }
  });
}
```

---

## Exception Hierarchy

All sync exceptions inherit the sealed class `SyncException`. Use pattern matching for handling:

```dart
try {
  await engine.sync();
} on MaxRetriesExceededException catch (e) {
  // Push attempts exhausted
  showSnackBar('Server unavailable. Try again later.');
} on NetworkException catch (e) {
  // Network error
  showSnackBar('No network connection');
} on ConflictException catch (e) {
  // Unresolved conflict
  showSnackBar('Data conflict: ${e.kind}/${e.entityId}');
} on TransportException catch (e) {
  // HTTP error
  showSnackBar('Server error: ${e.statusCode}');
} on DatabaseException catch (e) {
  // Database error
  showSnackBar('Database error');
} on SyncOperationException catch (e) {
  // General sync error
  showSnackBar('Sync error: ${e.message}');
}
```

---

## Full Example: Collaborative Task App

```dart
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

// 1. Configure SyncEngine with advanced settings
final engine = SyncEngine(
  db: database,
  transport: apiTransport,
  tables: [
    SyncableTable<Todo>(
      kind: 'todos',
      table: database.todos,
      fromJson: Todo.fromJson,
      toJson: (t) => t.toJson(),
      toInsertable: (t) => t.toInsertable(),
    ),
    SyncableTable<Comment>(
      kind: 'comments',
      table: database.comments,
      fromJson: Comment.fromJson,
      toJson: (c) => c.toJson(),
      toInsertable: (c) => c.toInsertable(),
    ),
  ],
  config: SyncConfig(
    // Smart merge by default
    conflictStrategy: ConflictStrategy.autoPreserve,
    // Push retries
    maxPushRetries: 5,
    backoffMin: const Duration(seconds: 1),
    backoffMax: const Duration(minutes: 2),
    // Conflicts
    maxConflictRetries: 3,
    conflictRetryDelay: const Duration(milliseconds: 500),
    // Full resync every 3 days
    fullResyncInterval: const Duration(days: 3),
  ),
  tableConflictConfigs: {
    // Comments are not collaboratively edited -- server is always right
    'comments': const TableConflictConfig(
      strategy: ConflictStrategy.serverWins,
    ),
  },
);

// 2. Subscribe to events
engine.events.listen((event) {
  switch (event) {
    case ConflictDetectedEvent(:final conflict, :final strategy):
      debugPrint('Conflict ${conflict.kind}/${conflict.entityId}: $strategy');
    case SyncCompleted(:final stats):
      if (stats != null && stats.conflicts > 0) {
        debugPrint('Resolved ${stats.conflictsResolved}/${stats.conflicts} '
            'conflicts');
      }
    case SyncErrorEvent(:final error):
      debugPrint('Sync error: $error');
    default:
      break;
  }
});

// 3. Start auto-sync
engine.startAuto(interval: const Duration(minutes: 5));

// 4. Create an operation with changed fields tracking
Future<void> updateTodoTitle(Todo todo, String newTitle) async {
  // Update locally
  final updated = todo.copyWith(title: newTitle);
  await database.into(database.todos).insertOnConflictUpdate(
    updated.toInsertable(),
  );

  // Add to outbox with changedFields
  await engine.outbox.enqueue(
    UpsertOp.create(
      kind: 'todos',
      id: todo.id,
      localTimestamp: DateTime.now().toUtc(),
      payloadJson: updated.toJson(),
      baseUpdatedAt: todo.updatedAt,
      changedFields: {'title'}, // Only title changed
    ),
  );
}

// 5. Sync with error handling
Future<void> syncWithErrorHandling() async {
  try {
    final stats = await engine.sync();
    if (stats.conflicts > 0) {
      debugPrint('Conflicts: ${stats.conflicts}, '
          'resolved: ${stats.conflictsResolved}');
    }
  } on MaxRetriesExceededException {
    // Show notification to user
  } on NetworkException {
    // Retry later
  } on SyncException catch (e) {
    debugPrint('Sync error: $e');
  }
}

// 6. Don't forget to release resources
engine.dispose();
```

---

## Protection Against Concurrent Calls

`SyncEngine` automatically handles concurrent `sync()` and `fullResync()` calls. If a sync is already in progress, a subsequent call **does not start** a new process but returns the same `Future`:

```dart
// Both calls share the same result
final future1 = engine.sync();
final future2 = engine.sync();
// future1 == future2 by result
```

This protects against duplicate push/pull operations when `sync()` is called from multiple sources (automatic timer, UI button, push notification).
