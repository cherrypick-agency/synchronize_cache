# Flutter Integration

Integration patterns for `offline_first_sync_drift` with Flutter: Provider/Riverpod, reactive UI, lifecycle management, error handling.

---

## Dependencies

```yaml
dependencies:
  drift: ^2.26.1
  drift_flutter: ^0.2.4
  offline_first_sync_drift: ^0.1.1
  offline_first_sync_drift_rest: ^0.1.1
  provider: ^6.1.5
  connectivity_plus: ^6.1.4
  uuid: ^4.5.1
```

---

## 1. SyncService -- ChangeNotifier Wrapper over SyncEngine

```dart
enum SyncStatus { idle, syncing, error }

class SyncService extends ChangeNotifier {
  SyncService({required AppDatabase db, required String baseUrl}) {
    _transport = RestTransport(
      base: Uri.parse(baseUrl),
      token: () async => 'Bearer ${await getAuthToken()}',
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
        conflictStrategy: ConflictStrategy.autoPreserve,
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
  double _progress = 0.0;
  double get progress => _progress;
  SyncStats? _lastStats;
  bool get isSyncing => _status == SyncStatus.syncing;
  Stream<SyncEvent> get events => _engine.events;

  Future<SyncStats> sync() async {
    _status = SyncStatus.syncing;
    _error = null;
    notifyListeners();
    try {
      final stats = await _engine.sync();
      _lastStats = stats;
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

  void startAuto({Duration interval = const Duration(minutes: 5)}) =>
      _engine.startAuto(interval: interval);
  void stopAuto() => _engine.stopAuto();
  Future<SyncStats> fullResync({bool clearData = false}) =>
      _engine.fullResync(clearData: clearData);

  void _handleEvent(SyncEvent event) {
    switch (event) {
      case SyncStarted():         _status = SyncStatus.syncing;
      case SyncProgress(:final done, :final total):
        if (total > 0) _progress = done / total;
      case SyncCompleted(:final stats):
        _lastStats = stats; _status = SyncStatus.idle;
      case SyncErrorEvent(:final error):
        _error = error.toString(); _status = SyncStatus.error;
      default: return;
    }
    notifyListeners();
  }

  @override
  void dispose() { _subscription.cancel(); _engine.dispose(); super.dispose(); }
}
```

---

## 2. Provider Integration

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase.open();
  final syncService = SyncService(db: db, baseUrl: 'https://api.example.com');

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        Provider<TodoRepository>.value(value: TodoRepository(db)),
        ChangeNotifierProvider<SyncService>.value(value: syncService),
      ],
      child: const MyApp(),
    ),
  );
}
```

### Riverpod Variant

```dart
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final syncServiceProvider = ChangeNotifierProvider<SyncService>((ref) {
  return SyncService(
    db: ref.watch(appDatabaseProvider),
    baseUrl: 'https://api.example.com',
  );
});
```

---

## 3. StreamBuilder for Reactive Data

Drift `watch()` returns a `Stream` that updates automatically -- both on local writes and on pull from the server:

```dart
class TodoListBody extends StatelessWidget {
  const TodoListBody({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TodoRepository>();
    return StreamBuilder<List<Todo>>(
      stream: repo.watchAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final todos = snapshot.data ?? [];
        if (todos.isEmpty) {
          return const Center(child: Text('No records'));
        }
        return ListView.builder(
          itemCount: todos.length,
          itemBuilder: (context, index) => TodoCard(todo: todos[index]),
        );
      },
    );
  }
}
```

The `watchAll()` method in the repository filters deleted records via `deletedAt.isNull() & deletedAtLocal.isNull()` and returns `.watch()`.

---

## 4. Sync on Application Lifecycle

`WidgetsBindingObserver` triggers sync when returning from the background and stops auto-sync when going to background:

```dart
class SyncLifecycleObserver extends StatefulWidget {
  const SyncLifecycleObserver({super.key, required this.child});
  final Widget child;

  @override
  State<SyncLifecycleObserver> createState() => _SyncLifecycleObserverState();
}

class _SyncLifecycleObserverState extends State<SyncLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final sync = context.read<SyncService>();
    sync.sync().ignore();
    sync.startAuto(interval: const Duration(minutes: 5));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final sync = context.read<SyncService>();
    switch (state) {
      case AppLifecycleState.resumed:
        sync.sync().ignore();
        sync.startAuto(interval: const Duration(minutes: 5));
      case AppLifecycleState.paused:
        sync.stopAuto();
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

Usage:

```dart
MaterialApp(
  home: const SyncLifecycleObserver(child: TodoListScreen()),
)
```

---

## 5. Sync on Network Connectivity

`connectivity_plus` triggers sync when the network is restored:

```dart
class ConnectivitySyncObserver extends StatefulWidget {
  const ConnectivitySyncObserver({super.key, required this.child});
  final Widget child;

  @override
  State<ConnectivitySyncObserver> createState() =>
      _ConnectivitySyncObserverState();
}

class _ConnectivitySyncObserverState extends State<ConnectivitySyncObserver> {
  late final StreamSubscription<List<ConnectivityResult>> _sub;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final isOffline = results.contains(ConnectivityResult.none);
      if (_wasOffline && !isOffline) {
        context.read<SyncService>().sync().ignore();
      }
      _wasOffline = isOffline;
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

Combining: `SyncLifecycleObserver > ConnectivitySyncObserver > SyncErrorListener > TodoListScreen`.

---

## 6. Pull-to-Refresh

```dart
Scaffold(
  body: StreamBuilder<List<Todo>>(
    stream: repo.watchAll(),
    builder: (context, snapshot) {
      final todos = snapshot.data ?? [];
      return RefreshIndicator(
        onRefresh: () async {
          try {
            await context.read<SyncService>().sync();
          } on SyncException catch (_) {
            // Error handled in SyncService
          }
        },
        child: ListView.builder(
          itemCount: todos.length,
          itemBuilder: (context, i) => TodoCard(todo: todos[i]),
        ),
      );
    },
  ),
)
```

For an empty list, wrap the placeholder in a `ListView` -- `RefreshIndicator` requires a scrollable child.

---

## 7. Sync Status Indicator in AppBar

```dart
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, sync, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SyncBadge(status: sync.status),
            const SizedBox(width: 8),
            if (sync.isSyncing)
              const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'Synchronize',
                onPressed: () async {
                  try {
                    final stats = await sync.sync();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${stats.pushed} pushed, ${stats.pulled} pulled'),
                      ));
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error: ${sync.error}'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ));
                    }
                  }
                },
              ),
          ],
        );
      },
    );
  }
}

// _SyncBadge -- colored badge with status (idle/syncing/error).
// Full implementation: example/todo_simple/frontend/lib/ui/widgets/sync_status_indicator.dart
```

---

## 8. Error Handling and SnackBar Notifications

```dart
class SyncErrorListener extends StatefulWidget {
  const SyncErrorListener({super.key, required this.child});
  final Widget child;

  @override
  State<SyncErrorListener> createState() => _SyncErrorListenerState();
}

class _SyncErrorListenerState extends State<SyncErrorListener> {
  late final StreamSubscription<SyncEvent> _sub;

  @override
  void initState() {
    super.initState();
    _sub = context.read<SyncService>().events.listen(_onEvent);
  }

  void _onEvent(SyncEvent event) {
    if (!mounted) return;
    switch (event) {
      case SyncErrorEvent(:final error):
        _showError(_formatError(error));
      case OperationFailedEvent(:final kind, :final entityId):
        _showError('Failed to push $kind/$entityId');
      case SyncCompleted(:final stats):
        if (stats != null && stats.errors > 0) {
          _showWarning('Sync: ${stats.errors} errors');
        }
      default:
        break;
    }
  }

  String _formatError(Object error) => switch (error) {
    NetworkException() => 'No connection to server',
    TransportException(:final statusCode) when statusCode == 401 =>
      'Session expired',
    TransportException(:final statusCode)
        when statusCode != null && statusCode >= 500 =>
      'Server error ($statusCode)',
    MaxRetriesExceededException() => 'Server unavailable',
    ParseException() => 'Invalid data from server',
    _ => 'Sync error',
  };

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Theme.of(context).colorScheme.error,
      action: SnackBarAction(
        label: 'Retry',
        textColor: Colors.white,
        onPressed: () => context.read<SyncService>().sync().ignore(),
      ),
    ));
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.orange,
    ));
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

### Error Handling on User Actions

```dart
Future<void> _saveTodo(BuildContext context) async {
  await context.read<TodoRepository>().create(title: 'New task');
  if (!context.mounted) return;
  try {
    await context.read<SyncService>().sync();
  } on NetworkException {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved. Will sync when connected.')),
    );
  } on SyncException {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved locally.')),
    );
  }
}
```

---

## 9. Dispose -- Cleanup Order

```
1. StreamSubscription.cancel()  -- stop listening to events
2. SyncEngine.dispose()         -- stop timer + close stream controller
3. Database.close()             -- close DB connection (last)
```

`SyncEngine.dispose()` **does not close** the database and **does not await** completion of the current `sync()`.

**Provider** -- `ChangeNotifierProvider` calls `dispose()` automatically. The DB at the `main()` level does not need to be closed explicitly.

**Riverpod:**

```dart
final syncServiceProvider = ChangeNotifierProvider<SyncService>((ref) {
  final service = SyncService(db: ref.watch(appDatabaseProvider), baseUrl: url);
  ref.onDispose(service.dispose);
  return service;
});
```

**Account switching:** `stopAuto()` -> `dispose()` -> `db.close()` -> open new DB -> create new SyncService -> `sync()` -> `startAuto()`.

---

## Project Structure

```
lib/
  main.dart                          database/database.dart
  database/tables/todos.dart         models/todo.dart
  repositories/todo_repository.dart  services/sync_service.dart
  ui/screens/todo_list_screen.dart
  ui/widgets/  sync_status_indicator | sync_error_listener
               sync_lifecycle_observer | connectivity_sync_observer
```
