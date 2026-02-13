# Simple Cache

A guide to the basic offline-first scenario: local data storage with automatic server synchronization.

## When to Use

Simple cache is suitable for applications where:

- Data is read much more frequently than written (read-heavy)
- The application is primarily used on a single device
- Conflicts are rare or a "server wins" strategy is acceptable
- Instant UI responsiveness without waiting for the network is required

| Criterion | Simple Cache | Advanced Cache |
|---|---|---|
| Conflict resolution | `serverWins` / `autoPreserve` | `merge` / `manual` / `lastWriteWins` |
| Multi-device support | Single device | Multiple devices |
| Field tracking | Not needed | `changedFields` for field-level merge |
| Integration complexity | Minimal | Moderate |

## How It Works

The library uses the **Outbox pattern**:

1. **Reading** -- always from the local Drift database. Instant response, works offline.
2. **Writing** -- data is saved to the local DB and the operation is placed in a queue (outbox) via `db.enqueue(...)`.
3. **Push** -- when `engine.sync()` is called, all operations from the outbox are sent to the server.
4. **Pull** -- after push, the engine downloads new data from the server (cursor-based pagination) and applies it to the local DB.

```
UI  -->  Drift DB  -->  Outbox  -->  sync()  -->  Server
         (read)        (write)      (push+pull)
```

## Project Setup

### 1. Dependencies

```yaml
dependencies:
  drift: ^2.26.1
  drift_flutter: ^0.2.4
  offline_first_sync_drift: ^0.1.1
  offline_first_sync_drift_rest: ^0.1.1
  uuid: ^4.5.1

dev_dependencies:
  drift_dev: ^2.26.1
  build_runner: ^2.4.15
```

### 2. Data Model

Create a model with JSON serialization:

```dart
// lib/models/todo.dart
import 'package:json_annotation/json_annotation.dart';

part 'todo.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Todo {
  Todo({
    required this.id,
    required this.title,
    this.description,
    this.completed = false,
    this.priority = 3,
    required this.updatedAt,
    this.deletedAt,
    this.deletedAtLocal,
  });

  final String id;
  final String title;
  final String? description;
  final bool completed;
  final int priority;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? deletedAtLocal;

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);
  Map<String, dynamic> toJson() => _$TodoToJson(this);

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    int? priority,
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? deletedAtLocal,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedAtLocal: deletedAtLocal ?? this.deletedAtLocal,
    );
  }
}
```

### 3. Drift Table

The table must use the `SyncColumns` mixin to add system fields (`updatedAt`, `deletedAt`, `deletedAtLocal`):

```dart
// lib/database/tables/todos.dart
import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

import '../../models/todo.dart';

@UseRowClass(Todo, generateInsertable: true)
class Todos extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get priority => integer().withDefault(const Constant(3))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 4. Database

The DB class includes sync tables via `include` and applies `SyncDatabaseMixin`:

```dart
// lib/database/database.dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

import '../models/todo.dart';
import 'tables/todos.dart';

part 'database.g.dart';

@DriftDatabase(
  include: {'package:offline_first_sync_drift/src/sync_tables.drift'},
  tables: [Todos],
)
class AppDatabase extends _$AppDatabase with SyncDatabaseMixin {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'todo_simple');
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
      );
}
```

> `SyncDatabaseMixin` provides the methods `enqueue()`, `takeOutbox()`, `ackOutbox()`, and cursor management.

## SyncEngine Configuration

For simple cache, use a minimal configuration:

```dart
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';
import 'package:offline_first_sync_drift_rest/offline_first_sync_drift_rest.dart';

final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'your-auth-token',
);

final engine = SyncEngine(
  db: database,
  transport: transport,
  tables: [
    SyncableTable<Todo>(
      kind: 'todos',
      table: database.todos,
      fromJson: Todo.fromJson,
      toJson: (t) => t.toJson(),
      toInsertable: (t) => t.toInsertable(),
    ),
  ],
  config: const SyncConfig(
    conflictStrategy: ConflictStrategy.serverWins,
    pageSize: 500,
    maxPushRetries: 5,
  ),
);
```

### SyncConfig Parameters for Simple Scenario

| Parameter | Value | Description |
|---|---|---|
| `conflictStrategy` | `ConflictStrategy.serverWins` | Server version wins on conflict |
| `pageSize` | `500` | Records per pull page |
| `maxPushRetries` | `5` | Max push attempts per operation |
| `pushImmediately` | `true` (default) | Push immediately on sync call |
| `fullResyncInterval` | `Duration(days: 7)` (default) | Full resync interval |

> For getting started, `ConflictStrategy.serverWins` is the simplest choice. If you want automatic merging without data loss, use `ConflictStrategy.autoPreserve` (the default value).

## CRUD Operations

### Reading

Reading is done from the local Drift DB -- instant and network-free.

**Get a list (one-shot):**

```dart
Future<List<Todo>> getAll() {
  return (db.select(db.todos)
        ..where((t) => t.deletedAt.isNull() & t.deletedAtLocal.isNull())
        ..orderBy([
          (t) => OrderingTerm(expression: t.priority),
          (t) => OrderingTerm(expression: t.title),
        ]))
      .get();
}
```

**Reactive stream (auto-updates on DB changes):**

```dart
Stream<List<Todo>> watchAll() {
  return (db.select(db.todos)
        ..where((t) => t.deletedAt.isNull() & t.deletedAtLocal.isNull())
        ..orderBy([
          (t) => OrderingTerm(expression: t.priority),
          (t) => OrderingTerm(expression: t.title),
        ]))
      .watch();
}
```

**Get by ID:**

```dart
Future<Todo?> getById(String id) {
  return (db.select(db.todos)..where((t) => t.id.equals(id)))
      .getSingleOrNull();
}
```

### Creating

Insert into the local DB and add the operation to the outbox:

```dart
Future<Todo> create({required String title, String? description}) async {
  final now = DateTime.now().toUtc();
  final id = const Uuid().v4();

  final todo = Todo(
    id: id,
    title: title,
    description: description,
    updatedAt: now,
  );

  // 1. Save locally
  await db.into(db.todos).insert(todo.toInsertable());

  // 2. Enqueue for sync
  await db.enqueue(UpsertOp(
    opId: const Uuid().v4(),
    kind: 'todos',
    id: id,
    localTimestamp: now,
    payloadJson: todo.toJson(),
    // baseUpdatedAt: null -- new record, no conflicts possible
  ));

  return todo;
}
```

### Updating

When updating, pass `baseUpdatedAt` -- the timestamp of the last known server state. This allows the engine to detect a conflict if the server updated the record since the last pull.

```dart
Future<Todo> update(Todo todo, {String? title, bool? completed}) async {
  final now = DateTime.now().toUtc();

  final updated = todo.copyWith(
    title: title ?? todo.title,
    completed: completed ?? todo.completed,
    updatedAt: now,
  );

  // 1. Update locally
  await db.update(db.todos).replace(updated.toInsertable());

  // 2. Enqueue
  await db.enqueue(UpsertOp(
    opId: const Uuid().v4(),
    kind: 'todos',
    id: todo.id,
    localTimestamp: now,
    payloadJson: updated.toJson(),
    baseUpdatedAt: todo.updatedAt, // for conflict detection
  ));

  return updated;
}
```

### Deleting

Deletion is a soft delete: mark `deletedAtLocal` and enqueue a `DeleteOp` in the outbox.

```dart
Future<void> delete(Todo todo) async {
  final now = DateTime.now().toUtc();

  // 1. Soft delete locally
  final deleted = todo.copyWith(deletedAtLocal: now);
  await db.update(db.todos).replace(deleted.toInsertable());

  // 2. Enqueue
  await db.enqueue(DeleteOp(
    opId: const Uuid().v4(),
    kind: 'todos',
    id: todo.id,
    localTimestamp: now,
    baseUpdatedAt: todo.updatedAt,
  ));
}
```

> When filtering lists, remember to exclude records with `deletedAt` or `deletedAtLocal`:
> ```dart
> ..where((t) => t.deletedAt.isNull() & t.deletedAtLocal.isNull())
> ```

## Automatic Sync

### Periodic Sync

```dart
// Start auto-sync every 5 minutes
engine.startAuto(interval: const Duration(minutes: 5));

// Stop
engine.stopAuto();
```

### Sync on App Startup

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  final engine = SyncEngine(/* ... */);

  // Sync on startup (non-blocking for UI)
  engine.sync().catchError((e) {
    debugPrint('Initial sync failed: $e');
  });

  // Auto-sync
  engine.startAuto(interval: const Duration(minutes: 5));

  runApp(MyApp());
}
```

### Sync on Network Restore (Conceptual)

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

Connectivity().onConnectivityChanged.listen((result) {
  if (result != ConnectivityResult.none) {
    engine.sync();
  }
});
```

### Manual Sync

```dart
// Full sync (push + pull)
final stats = await engine.sync();
print('Pushed: ${stats.pushed}, Pulled: ${stats.pulled}');

// Full resync (reset cursors + pull all data)
final stats = await engine.fullResync();
```

## Error Handling

### Event Subscription

`SyncEngine` provides an event stream for tracking status and errors:

```dart
engine.events.listen((event) {
  switch (event) {
    case SyncStarted(:final phase):
      print('Sync started: $phase'); // push or pull
    case SyncProgress(:final done, :final total):
      print('Progress: $done/$total');
    case SyncCompleted(:final stats):
      print('Done: pushed=${stats?.pushed}, pulled=${stats?.pulled}');
    case SyncErrorEvent(:final error, :final phase):
      print('Error during $phase: $error');
    default:
      break;
  }
});
```

### Exception Types

All exceptions inherit from `SyncException` and support pattern matching:

```dart
try {
  await engine.sync();
} on NetworkException catch (e) {
  // No network, timeout, server unavailable
  showSnackBar('No server connection');
} on TransportException catch (e) {
  // HTTP error (4xx, 5xx)
  showSnackBar('Server error: ${e.statusCode}');
} on SyncOperationException catch (e) {
  // General sync error
  showSnackBar('Sync error');
} on SyncException catch (e) {
  // Any other sync error
  showSnackBar('Something went wrong');
}
```

### SyncService Pattern for Flutter

Wrap `SyncEngine` in a service with `ChangeNotifier` for convenient UI integration:

```dart
class SyncService extends ChangeNotifier {
  SyncService({required AppDatabase db, required String baseUrl}) {
    _transport = RestTransport(
      base: Uri.parse(baseUrl),
      token: () async => '',
    );

    _engine = SyncEngine(
      db: db,
      transport: _transport,
      tables: [
        SyncableTable<Todo>(
          kind: 'todos',
          table: db.todos,
          fromJson: Todo.fromJson,
          toJson: (t) => t.toJson(),
          toInsertable: (t) => t.toInsertable(),
        ),
      ],
      config: const SyncConfig(
        conflictStrategy: ConflictStrategy.serverWins,
        pageSize: 500,
        maxPushRetries: 5,
      ),
    );

    _subscription = _engine.events.listen(_handleEvent);
  }

  late final RestTransport _transport;
  late final SyncEngine _engine;
  late final StreamSubscription<SyncEvent> _subscription;

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  String? _error;
  String? get error => _error;

  bool get isSyncing => _status == SyncStatus.syncing;

  Future<SyncStats> sync() async {
    _status = SyncStatus.syncing;
    _error = null;
    notifyListeners();

    try {
      final stats = await _engine.sync();
      _status = SyncStatus.idle;
      notifyListeners();
      return stats;
    } catch (e) {
      _error = e.toString();
      _status = SyncStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  void startAuto({Duration interval = const Duration(minutes: 5)}) {
    _engine.startAuto(interval: interval);
  }

  void stopAuto() {
    _engine.stopAuto();
  }

  void _handleEvent(SyncEvent event) {
    switch (event) {
      case SyncStarted():
        _status = SyncStatus.syncing;
        notifyListeners();
      case SyncCompleted():
        _status = SyncStatus.idle;
        notifyListeners();
      case SyncErrorEvent(:final error):
        _error = error.toString();
        _status = SyncStatus.error;
        notifyListeners();
      default:
        break;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _engine.dispose();
    super.dispose();
  }
}

enum SyncStatus { idle, syncing, error }
```

## Full Example: Todo App

A complete working example is located in `example/todo_simple/frontend/`.

### Project Structure

```
example/todo_simple/frontend/lib/
  main.dart                           # Entry point, DI via Provider
  database/
    database.dart                     # AppDatabase with SyncDatabaseMixin
    tables/
      todos.dart                      # Drift table Todos with SyncColumns
  models/
    todo.dart                         # Todo model with JSON serialization
  repositories/
    todo_repository.dart              # CRUD + operation enqueue
  services/
    sync_service.dart                 # SyncEngine wrapper with ChangeNotifier
  ui/
    screens/
      todo_list_screen.dart           # Task list (StreamBuilder + watchAll)
      todo_edit_screen.dart           # Task editing
    widgets/
      todo_card.dart                  # Task card
      sync_status_indicator.dart      # Sync status indicator
```

### Entry Point

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  final todoRepo = TodoRepository(db);
  final syncService = SyncService(db: db, baseUrl: 'http://localhost:8080');

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<TodoRepository>.value(value: todoRepo),
        ChangeNotifierProvider<SyncService>.value(value: syncService),
      ],
      child: const MyApp(),
    ),
  );
}
```

### List Display with Reactive Updates

```dart
class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TodoRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: StreamBuilder<List<Todo>>(
        stream: repo.watchAll(),
        builder: (context, snapshot) {
          final todos = snapshot.data ?? [];
          if (todos.isEmpty) {
            return const Center(child: Text('No tasks'));
          }
          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return ListTile(
                title: Text(todo.title),
                trailing: Checkbox(
                  value: todo.completed,
                  onChanged: (_) => repo.toggleCompleted(todo),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

### Sync Indicator

```dart
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, _) {
        if (syncService.isSyncing) {
          return const SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        return IconButton(
          icon: const Icon(Icons.sync),
          onPressed: () async {
            try {
              final stats = await syncService.sync();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(
                    'Pushed: ${stats.pushed}, Pulled: ${stats.pulled}',
                  )),
                );
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync failed')),
                );
              }
            }
          },
        );
      },
    );
  }
}
```

## Running the Example

```bash
cd example/todo_simple/frontend

# Install dependencies
flutter pub get

# Generate code (Drift, JSON)
dart run build_runner build --delete-conflicting-outputs

# Run
flutter run
```

A backend server is required for sync to work (see `example/todo_simple/backend/`).

## What's Next

- **[Advanced Cache](./advanced-cache.md)** -- field-level merge, manual conflict resolution, multi-device sync
- **[Backend & Transport](./backend-transport.md)** -- server-side implementation and `TransportAdapter` configuration
