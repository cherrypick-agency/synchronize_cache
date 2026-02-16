# TODO Simple New

Новый пример использования `offline_first_sync_drift` без legacy-подходов.

## Что показывает пример

- `syncTable` sugar для регистрации таблиц
- `replaceAndEnqueueDiff` для авто-диффа измененных полей
- `createRestSyncEngine` как one-liner для transport + engine
- `SyncCoordinator` для app-flow (`pullOnStartup`, reactive push по outbox, interval)
- `syncRun()` для структурированного результата синка
- реактивный pending outbox через `watchPendingPushCount()`

## Структура

- `backend/` — Dart Frog API
- `frontend/` — Flutter app (iOS + Android + Web)

## Быстрый старт

### 1) Backend

```bash
cd example/todo_simple_new/backend
dart pub get
dart run build_runner build --delete-conflicting-outputs
dart_frog dev
```

### 2) Frontend

```bash
cd example/todo_simple_new/frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome --dart-define=BACKEND_URL=http://localhost:8080
```

Для iOS/Android:

```bash
flutter run -d ios --dart-define=BACKEND_URL=http://localhost:8080
flutter run -d android --dart-define=BACKEND_URL=http://10.0.2.2:8080
```

## API-пример (актуальный)

```dart
final todoSync = db.todos.syncTable(
  fromJson: Todo.fromJson,
  toJson: (t) => t.toJson(),
  toInsertable: (t) => t.toInsertable(),
  getId: (t) => t.id,
  getUpdatedAt: (t) => t.updatedAt,
);
```

```dart
final engine = createRestSyncEngine<AppDatabase>(
  db: db,
  base: Uri.parse(baseUrl),
  token: () async => '',
  tables: [todoSync],
  config: const SyncConfig(
    conflictStrategy: ConflictStrategy.autoPreserve,
  ),
);
```

```dart
final coordinator = SyncCoordinator(
  engine: engine,
  pullOnStartup: true,
  pushOnOutboxChanges: true,
  autoInterval: const Duration(minutes: 5),
);
await coordinator.start();
```

```dart
final run = await engine.syncRun();
debugPrint('pushed=${run.push.pushed}, pulled=${run.pull.pulled}, stuck=${run.stuckOpsCount}');
```
