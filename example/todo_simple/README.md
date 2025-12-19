# TODO Simple

A simple TODO application demonstrating the `offline_first_sync_drift` library with **Simplified Flow** - client-only changes without server-side modifications.

## Overview

This example shows how to build an offline-first application where:
- All changes originate from the client
- Server acts as a passive data store
- No conflict detection needed (autoPreserve strategy)
- Simple sync flow: push local changes, pull server state

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Web App                         │
├─────────────────────────────────────────────────────────────┤
│  UI Layer          │  TodoListScreen, TodoEditScreen        │
│  Repository        │  TodoRepository (CRUD + Outbox)        │
│  Database          │  Drift + SyncDatabaseMixin             │
│  Sync Engine       │  SyncEngine (autoPreserve strategy)    │
│  Transport         │  RestTransport (HTTP)                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Dart Frog Backend                       │
├─────────────────────────────────────────────────────────────┤
│  Routes            │  /todos (CRUD endpoints)               │
│  Storage           │  In-memory Map<String, Todo>           │
└─────────────────────────────────────────────────────────────┘
```

## Features

- Create, read, update, delete todos
- Offline support with local SQLite database
- Automatic sync when online
- Visual sync status indicator
- Priority levels (1-5)
- Due dates
- Soft delete support

## Project Structure

```
todo_simple/
├── frontend/                 # Flutter Web application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── database/
│   │   │   ├── database.dart
│   │   │   └── tables/todos.dart
│   │   ├── models/
│   │   │   └── todo.dart
│   │   ├── repositories/
│   │   │   └── todo_repository.dart
│   │   ├── services/
│   │   │   └── sync_service.dart
│   │   └── ui/
│   │       ├── screens/
│   │       └── widgets/
│   └── test/
│
└── backend/                  # Dart Frog server
    ├── routes/
    │   ├── health.dart
    │   └── todos/
    │       ├── index.dart
    │       └── [id].dart
    ├── lib/
    │   ├── models/
    │   └── repositories/
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

# Generate code (Drift, JSON serialization)
dart run build_runner build --delete-conflicting-outputs

# Run on Chrome
flutter run -d chrome
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/todos` | List todos (supports `updatedSince`, `limit`, `pageToken`) |
| GET | `/todos/:id` | Get single todo |
| POST | `/todos` | Create todo |
| PUT | `/todos/:id` | Update todo |
| DELETE | `/todos/:id` | Delete todo |

### Query Parameters

- `updatedSince` - ISO 8601 timestamp, returns todos updated after this time
- `limit` - Maximum number of results (default: 500)
- `pageToken` - Pagination token for next page

### Response Format

```json
{
  "items": [
    {
      "id": "uuid",
      "title": "Buy groceries",
      "description": "Milk, eggs, bread",
      "completed": false,
      "priority": 3,
      "due_date": "2025-01-20T00:00:00.000Z",
      "updated_at": "2025-01-15T10:30:00.000Z",
      "deleted_at": null
    }
  ],
  "nextPageToken": "optional-token"
}
```

## Demo Scenarios

### 1. Offline Create

1. Stop the backend server
2. Create several todos in the app
3. Notice the "Offline" indicator
4. Start the backend server
5. Click "Sync" or wait for auto-sync
6. Todos appear on the server

### 2. Pull Changes

1. Create a todo via API:
   ```bash
   curl -X POST http://localhost:8080/todos \
     -H "Content-Type: application/json" \
     -d '{"id":"test-1","title":"Server Todo","priority":1,"updated_at":"2025-01-15T12:00:00Z"}'
   ```
2. Click "Sync" in the app
3. The new todo appears in the list

### 3. Update and Delete

1. Create a todo in the app
2. Sync to server
3. Edit the todo (change title, toggle completed)
4. Delete another todo
5. Sync again
6. Verify changes on server:
   ```bash
   curl http://localhost:8080/todos
   ```

## Running Tests

### Backend Tests

```bash
cd backend
dart test
```

### Frontend Tests

```bash
cd frontend
flutter test
```

## Key Implementation Details

### Sync Strategy

This app uses `ConflictStrategy.autoPreserve`:
- Local changes are always pushed to server
- Server state is accepted without conflict checks
- Simple and efficient for single-client scenarios

### Database Schema

```dart
class Todos extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get priority => integer().withDefault(const Constant(3))();
  DateTimeColumn get dueDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

The `SyncColumns` mixin adds:
- `updatedAt` - Server timestamp
- `deletedAt` - Server soft delete timestamp
- `deletedAtLocal` - Local soft delete timestamp

### Outbox Pattern

Local changes are queued in an outbox table:
1. User creates/updates/deletes a todo
2. Change is saved locally + queued in outbox
3. Sync engine pushes outbox items to server
4. On success, outbox item is acknowledged

## Troubleshooting

### "Connection refused" error

Make sure the backend is running:
```bash
cd backend && dart_frog dev
```

### Build errors after code changes

Regenerate code:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Database issues

Clear the browser's IndexedDB storage or use incognito mode.

## Related

- [todo_advanced](../todo_advanced/) - Full conflict resolution example
- [offline_first_sync_drift documentation](../../../packages/offline_first_sync_drift/)
