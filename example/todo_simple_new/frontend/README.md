# todo_simple_new_frontend

Frontend часть нового примера `todo_simple_new`.

## Запуск

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome --dart-define=BACKEND_URL=http://localhost:8080
```

Для iOS/Android:

```bash
flutter run -d ios --dart-define=BACKEND_URL=http://127.0.0.1:8080
flutter run -d android --dart-define=BACKEND_URL=http://10.0.2.2:8080
```

## Ключевые места

- `lib/sync/todo_sync.dart` — `syncTable` sugar
- `lib/repositories/todo_repository.dart` — `replaceAndEnqueueDiff`
- `lib/services/sync_service.dart` — `createRestSyncEngine`, `SyncCoordinator`, `syncRun`
- `lib/ui/widgets/sync_status_indicator.dart` — `watchPendingPushCount`

## Тесты

```bash
flutter test
flutter test test/e2e/full_sync_e2e_test.dart
flutter test integration_test/
```

Для `integration_test/network_recovery_test.dart` backend должен быть поднят заранее:

```bash
cd ../backend
dart_frog dev --port 8080
```

## Web и Drift

Текущий пример использует `drift_flutter` + `driftDatabase(name: ...)` в `lib/database/database.dart`.
Этот путь работает в текущей конфигурации примера и покрыт запуском `flutter run -d chrome` + тестами.
