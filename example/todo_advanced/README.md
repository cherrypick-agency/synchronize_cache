# TODO Advanced

An advanced TODO application demonstrating the `offline_first_sync_drift` library with **Full Flow** - both client and server changes with conflict detection and manual resolution.

## Overview

This example shows how to build an offline-first application where:
- Both client and server can modify data
- Conflicts are detected via timestamp comparison
- Manual conflict resolution with UI dialog
- Server simulation endpoints to trigger conflicts

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Web App                         │
├─────────────────────────────────────────────────────────────┤
│  UI Layer          │  Screens + ConflictDialog + DiffViewer │
│  Conflict Handler  │  Manual resolution with user choice    │
│  Repository        │  TodoRepository (CRUD + Outbox)        │
│  Database          │  Drift + SyncDatabaseMixin             │
│  Sync Engine       │  SyncEngine (manual strategy)          │
│  Transport         │  RestTransport (HTTP + conflict aware) │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Dart Frog Backend                       │
├─────────────────────────────────────────────────────────────┤
│  Routes            │  /todos (CRUD + conflict detection)    │
│  Simulation        │  /simulate/* (server-side changes)     │
│  Storage           │  In-memory with timestamps             │
└─────────────────────────────────────────────────────────────┘
```

## Features

- All features from todo_simple
- **Conflict Detection**: Server returns 409 when base timestamp doesn't match
- **Manual Resolution**: User chooses between local, server, or merged data
- **Diff Viewer**: Visual comparison of conflicting values
- **Merge Editor**: Pick individual field values from each version
- **Server Simulation**: Endpoints to trigger server-side modifications
- **Sync Log**: View history of sync operations

## Project Structure

```
todo_advanced/
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── database/
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── services/
│   │   │   ├── sync_service.dart
│   │   │   └── conflict_handler.dart   # Manual resolution
│   │   └── ui/
│   │       ├── screens/
│   │       │   └── sync_log_screen.dart
│   │       └── widgets/
│   │           ├── conflict_dialog.dart
│   │           └── diff_viewer.dart
│   └── test/
│
└── backend/
    ├── routes/
    │   ├── todos/              # CRUD with conflict detection
    │   └── simulate/           # Server modification triggers
    │       ├── reminder.dart
    │       ├── complete.dart
    │       └── prioritize.dart
    ├── lib/
    └── test/
```

## Running the Application

### Prerequisites

- Flutter SDK 3.35+
- Dart SDK 3.8+

### Backend

```bash
cd backend

# Install dependencies
dart pub get

# Run the server
dart_frog dev
```

The server starts at `http://localhost:8080`.

### Frontend

```bash
cd frontend

# Install dependencies
flutter pub get

# Generate code
dart run build_runner build --delete-conflicting-outputs

# Run on Chrome
flutter run -d chrome
```

## API Endpoints

### CRUD Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/todos` | List todos with pagination |
| GET | `/todos/:id` | Get single todo |
| POST | `/todos` | Create todo |
| PUT | `/todos/:id` | Update todo (conflict check) |
| DELETE | `/todos/:id` | Delete todo (conflict check) |

### Conflict Headers

| Header | Purpose |
|--------|---------|
| `X-Idempotency-Key` | Duplicate request prevention |
| `X-Base-Updated-At` | Expected server timestamp (for conflict check) |
| `X-Force-Update: true` | Skip conflict check (after resolution) |
| `X-Force-Delete: true` | Force delete (after resolution) |

### Conflict Response (409)

```json
{
  "error": "conflict",
  "message": "Resource was modified on server",
  "current": {
    "id": "uuid",
    "title": "Server Version",
    "updated_at": "2025-01-15T12:00:00.000Z"
  }
}
```

### Simulation Endpoints

| Method | Endpoint | Body | Description |
|--------|----------|------|-------------|
| POST | `/simulate/reminder` | `{"id": "...", "reminder": "..."}` | Append reminder to description |
| POST | `/simulate/complete` | `{"id": "..."}` | Mark todo as completed |
| POST | `/simulate/prioritize` | `{"id": "...", "priority": 1}` | Change priority |

## Demo Scenarios

### 1. Trigger and Resolve a Conflict

1. Create a todo in the app and sync:
   ```
   Title: "Buy groceries"
   Priority: 3
   ```

2. Simulate server modification:
   ```bash
   curl -X POST http://localhost:8080/simulate/prioritize \
     -H "Content-Type: application/json" \
     -d '{"id":"<todo-id>","priority":1}'
   ```

3. Edit the same todo locally:
   ```
   Title: "Buy groceries today"
   ```

4. Click "Sync"

5. **Conflict dialog appears** showing:
   - Local: Title="Buy groceries today", Priority=3
   - Server: Title="Buy groceries", Priority=1

6. Choose resolution:
   - **Use Local**: Keep your changes
   - **Use Server**: Accept server version
   - **Merge**: Pick individual fields

### 2. Server Reminder Simulation

1. Create and sync a todo

2. Add a server-side reminder:
   ```bash
   curl -X POST http://localhost:8080/simulate/reminder \
     -H "Content-Type: application/json" \
     -d '{"id":"<todo-id>","reminder":"Don'\''t forget!"}'
   ```

3. Sync the app

4. The description now includes the reminder

### 3. Auto-Complete Simulation

1. Create a todo with a past due date

2. Trigger auto-complete:
   ```bash
   curl -X POST http://localhost:8080/simulate/complete \
     -H "Content-Type: application/json" \
     -d '{"id":"<todo-id>"}'
   ```

3. Sync - the todo is now marked completed

### 4. View Sync Log

1. Open the menu (hamburger icon)
2. Select "Sync Log"
3. View history of:
   - Sync operations
   - Conflicts detected
   - Resolutions applied

## Conflict Resolution Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Local Change │     │   Server     │     │   Conflict   │
│   (Push)     │────▶│   (409)      │────▶│   Detected   │
└──────────────┘     └──────────────┘     └──────────────┘
                                                 │
                                                 ▼
                                          ┌──────────────┐
                                          │   Dialog     │
                                          │   Shows      │
                                          └──────────────┘
                                                 │
                     ┌───────────────────────────┼───────────────────────────┐
                     ▼                           ▼                           ▼
              ┌──────────────┐           ┌──────────────┐           ┌──────────────┐
              │ Use Local    │           │ Use Server   │           │    Merge     │
              │ AcceptClient │           │ AcceptServer │           │ AcceptMerged │
              └──────────────┘           └──────────────┘           └──────────────┘
                     │                           │                           │
                     ▼                           ▼                           ▼
              ┌──────────────┐           ┌──────────────┐           ┌──────────────┐
              │ Force Push   │           │ Accept Pull  │           │ Force Push   │
              │ X-Force-*    │           │ (No action)  │           │ Merged Data  │
              └──────────────┘           └──────────────┘           └──────────────┘
```

## Running Tests

### Backend Tests

```bash
cd backend
dart test
```

Tests include:
- CRUD operations
- Conflict detection (409 responses)
- Force update/delete headers
- Simulation endpoints

### Frontend Tests

```bash
cd frontend
flutter test
```

Tests include:
- Model serialization
- Repository operations
- Conflict handler resolution
- Sync service events

## Key Implementation Details

### Conflict Handler

```dart
class ConflictHandler extends ChangeNotifier {
  Future<ConflictResolution> resolve(Conflict conflict) async {
    // Convert to domain objects
    final info = ConflictInfo(
      conflict: conflict,
      localTodo: Todo.fromJson(conflict.localData),
      serverTodo: Todo.fromJson(conflict.serverData),
    );

    // Queue for UI display
    _pendingConflicts.add(info);
    notifyListeners();

    // Wait for user decision
    return await _completer.future;
  }

  void resolveWithLocal() {
    _complete(const AcceptClient());
  }

  void resolveWithServer() {
    _complete(const AcceptServer());
  }

  void resolveWithMerged(Todo merged) {
    _complete(AcceptMerged(merged.toJson()));
  }
}
```

### Sync Configuration

```dart
_engine = SyncEngine(
  db: db,
  transport: _transport,
  tables: [SyncableTable<Todo>(...)],
  config: SyncConfig(
    conflictStrategy: ConflictStrategy.manual,
    conflictResolver: conflictHandler.resolve,
  ),
);
```

### Conflict Detection (Server)

```dart
// PUT /todos/:id
final baseUpdatedAt = request.headers['x-base-updated-at'];
final forceUpdate = request.headers['x-force-update'] == 'true';

if (!forceUpdate && baseUpdatedAt != null) {
  final base = DateTime.parse(baseUpdatedAt);
  if (existing.updatedAt.isAfter(base)) {
    return Response.json(
      statusCode: 409,
      body: {
        'error': 'conflict',
        'current': existing.toJson(),
      },
    );
  }
}
```

## Diff Viewer

The diff viewer highlights conflicting fields:

```
┌─────────────────────────────────────────┐
│            Sync Conflict                │
├─────────────────────────────────────────┤
│  Field      │  Local    │  Server      │
├─────────────────────────────────────────┤
│  title      │  Buy...   │  Buy...      │
│  completed  │  false    │  true   ⚠️   │
│  priority   │  3        │  1      ⚠️   │
└─────────────────────────────────────────┘
```

## Troubleshooting

### Conflict dialog not appearing

- Ensure `ConflictStrategy.manual` is configured
- Check that `conflictResolver` callback is set
- Verify server returns 409 with `current` data

### Force headers not working

- Headers are case-insensitive: `x-force-update` or `X-Force-Update`
- Value must be exactly `true` (string)

### Simulation endpoints returning 404

- Ensure the todo exists and is synced to server
- Check the todo ID is correct

## Related

- [todo_simple](../todo_simple/) - Simplified flow without conflicts
- [offline_first_sync_drift documentation](../../../packages/offline_first_sync_drift/)
- [Backend Guidelines](../../../docs/backend_guidelines.md)
