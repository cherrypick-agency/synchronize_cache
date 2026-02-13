# Offline-first Cache Sync

[![CI](https://github.com/cherrypick-agency/synchronize_cache/actions/workflows/ci.yml/badge.svg)](https://github.com/cherrypick-agency/synchronize_cache/actions/workflows/ci.yml)
![coverage](https://img.shields.io/badge/coverage-72.0%25-yellow)

Dart/Flutter library for offline-first data handling. Local cache on Drift + server sync.

**Principle:** read locally → write locally + to outbox → `sync()` pushes and pulls data.

## Why this library?

Quick comparison with popular alternatives:

**vs PowerSync** ($49+/mo):
- Free, no vendor lock-in
- Field-level merge (LWW loses concurrent edits)
- Any backend, not just Postgres/MongoDB

**vs Brick** (free):
- Drift ORM vs custom DSL
- 5 conflict strategies vs LWW only
- Better documentation

**vs Firebase**:
- Truly offline-first (Firebase has issues: 8+ min offline query delays, transactions don't persist across app restarts, need to be online to generate document IDs)
- No vendor lock-in
- Field-level merge vs LWW only

The "complexity" is ~50 lines of explicit config. You get:
- `changedFields` tracking (concurrent edits preserved)
- Per-table conflict strategies
- Any backend via TransportAdapter

**Trade-off:** More setup, but full control + $600/year saved vs PowerSync.

Built on Drift (best Flutter ORM) + Outbox pattern (used by Shopify, Uber).

### Detailed comparison

| Feature | This library | PowerSync | Brick | Firebase |
|---------|--------------|-----------|-------|----------|
| **Offline read/write** | Yes | Yes | Yes | Partial (delays, issues) |
| **Conflict resolution** | 5 strategies | LWW only | LWW only | LWW only |
| **Field-level merge** | Yes (`changedFields`) | No | No | No |
| **Per-table config** | Yes | No | No | No |
| **ORM** | Drift (type-safe) | Optional Drift | Custom DSL | No |
| **Any backend** | Yes (TransportAdapter) | Postgres/MongoDB/MySQL | REST/GraphQL/Supabase | Firebase only |
| **Web support** | Yes | Beta | Yes | Yes |
| **Self-hosted** | Yes | Yes | Yes | No |
| **Price** | Free | $49+/mo | Free | Pay-per-use |
| **Vendor lock-in** | None | Medium | Low | High |

### Advantages

- **Field-level merge** — if User A edits `title` and User B edits `description`, both changes are preserved (others lose one with LWW)
- **5 conflict strategies** — `autoPreserve`, `serverWins`, `clientWins`, `lastWriteWins`, `manual`
- **Per-table configuration** — different strategies for different data types
- **Any backend** — REST, GraphQL, gRPC, WebSocket via `TransportAdapter`
- **Drift ORM** — type-safe, reactive, actively maintained
- **Outbox pattern** — battle-tested, used by Shopify, Uber, Stripe
- **Free & open source** — MIT license, no vendor lock-in

### Disadvantages

| vs | Trade-off |
|----|-----------|
| PowerSync | More initial setup (~50 lines vs plug-and-play) |
| sql_crdt | Not true CRDT (requires server, no P2P) |
| Firebase | No managed infrastructure (you run your own backend) |
| All | Newer project, smaller community |

---

## Table of contents

- [Offline-first Cache Sync](#offline-first-cache-sync)
  - [Why this library?](#why-this-library)
  - [Table of contents](#table-of-contents)
  - [Quick start](#quick-start)
    - [1. Installation](#1-installation)
    - [2. Database setup](#2-database-setup)
    - [3. SyncEngine setup](#3-syncengine-setup)
    - [4. Data model](#4-data-model)
  - [Working with data](#working-with-data)
    - [Reading](#reading)
    - [Local changes + outbox](#local-changes--outbox)
    - [Synchronization](#synchronization)
  - [Conflict resolution](#conflict-resolution)
    - [Strategies](#strategies)
    - [autoPreserve](#autopreserve)
    - [Manual resolution](#manual-resolution)
    - [Custom merge](#custom-merge)
    - [Per-table strategy](#per-table-strategy)
  - [Events and stats](#events-and-stats)
  - [Server requirements](#server-requirements)
  - [CI/CD](#cicd)

---

## Quick start

Minimal checklist: install packages, prepare a Drift database with `include` for sync tables, then register your tables in `SyncEngine`.

### 1. Installation

```yaml
dependencies:
  offline_first_sync_drift: ^0.1.1
  offline_first_sync_drift_rest: ^0.1.1
  drift: ^2.0.0
  json_annotation: ^4.8.0

dev_dependencies:
  drift_dev: ^2.0.0
  build_runner: ^2.0.0
  json_serializable: ^6.7.0
```

**build.yaml** (modular generation is required for cross-package sharing):

```yaml
targets:
  $default:
    builders:
      drift_dev:
        enabled: false
      drift_dev:analyzer:
        enabled: true
        options: &options
          store_date_time_values_as_text: true
      drift_dev:modular:
        enabled: true
        options: *options
```

### 2. Database setup

1. Describe your domain tables and add `SyncColumns` to automatically get `updatedAt/deletedAt/deletedAtLocal`.
2. Include the sync tables via `include` — this will automatically add `sync_outbox` and `sync_cursors`.
3. Extend `SyncDatabaseMixin`, which provides `enqueue()`, `takeOutbox()`, `setCursor()`, and other utilities.

```dart
import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

import 'database.drift.dart';
import 'models/daily_feeling.dart'; // see "Data model" section

@DriftDatabase(
  include: {'package:offline_first_sync_drift/src/sync_tables.drift'},
  tables: [DailyFeelings],
)
class AppDatabase extends $AppDatabase with SyncDatabaseMixin {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
```

### 3. SyncEngine setup

SyncEngine connects the local DB and the transport. In `tables` list each entity: `kind` is the server name, `table` is the Drift table reference, `fromJson`/`toJson` convert between the local model and the API.

```dart
import 'package:offline_first_sync_drift_rest/offline_first_sync_drift_rest.dart';

final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer ${await getToken()}',
);

final engine = SyncEngine(
  db: db,
  transport: transport,
  tables: [
    SyncableTable<DailyFeeling>(
      kind: 'daily_feeling',
      table: db.dailyFeelings,
      fromJson: DailyFeeling.fromJson,
      toJson: (e) => e.toJson(),
      toInsertable: (e) => e.toInsertable(),
    ),
  ],
);
```

### 4. Data model

To participate in sync a table must:

- have a string primary key `id`;
- store `updatedAt` in UTC (the server updates this field);
- optionally have `deletedAt` for soft-delete and `deletedAtLocal` for local marks;
- contain any of your business fields.

Add `SyncColumns` to get all required system fields automatically — you only describe domain columns. The table automatically implements `SynchronizableTable`, so you can type-safely distinguish it from regular Drift tables:

```dart
import 'package:drift/drift.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

part 'daily_feeling.g.dart';

/// Data model (row class).
@JsonSerializable(fieldRename: FieldRename.snake)
class DailyFeeling {
  DailyFeeling({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    this.deletedAtLocal,
    required this.date,
    this.mood,
    this.energy,
    this.notes,
  });

  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? deletedAtLocal;
  final DateTime date;
  final int? mood;
  final int? energy;
  final String? notes;

  factory DailyFeeling.fromJson(Map<String, dynamic> json) =>
      _$DailyFeelingFromJson(json);

  Map<String, dynamic> toJson() => _$DailyFeelingToJson(this);

  // toInsertable() is generated automatically thanks to generateInsertable: true
}

/// Drift table with all sync fields.
@UseRowClass(DailyFeeling, generateInsertable: true)
class DailyFeelings extends Table with SyncColumns {
  TextColumn get id => text()();
  IntColumn get mood => integer().nullable()();
  IntColumn get energy => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

---

## Working with data

Use Drift as usual, and for changes follow the pattern “update locally → put the operation into outbox”.

### Reading

Queries behave the same as standard Drift: data is already in the local DB, queries are instant and offline-friendly.

```dart
final all = await db.select(db.dailyFeelings).get();

final today = await (db.select(db.dailyFeelings)
  ..where((t) => t.date.equals(DateTime.now())))
  .getSingleOrNull();

db.select(db.dailyFeelings).watch().listen((list) {
  setState(() => _feelings = list);
});
```

### Local changes + outbox

Each operation has two steps: first update the local table, then enqueue the operation via `db.enqueue(...)`. For updates, always send `baseUpdatedAt` (when the record arrived from the server) and `changedFields` (which fields the user modified).

```dart
Future<void> create(DailyFeeling feeling) async {
  await db.into(db.dailyFeelings).insert(feeling);
  
  await db.enqueue(UpsertOp(
    opId: uuid.v4(),
    kind: 'daily_feeling',
    id: feeling.id,
    localTimestamp: DateTime.now().toUtc(),
    payloadJson: feeling.toJson(),
  ));
}

Future<void> updateFeeling(DailyFeeling updated, Set<String> changedFields) async {
  await db.update(db.dailyFeelings).replace(updated);
  
  await db.enqueue(UpsertOp(
    opId: uuid.v4(),
    kind: 'daily_feeling',
    id: updated.id,
    localTimestamp: DateTime.now().toUtc(),
    payloadJson: updated.toJson(),
    baseUpdatedAt: updated.updatedAt,
    changedFields: changedFields,
  ));
}

Future<void> deleteFeeling(String id, DateTime? serverUpdatedAt) async {
  await (db.delete(db.dailyFeelings)..where((t) => t.id.equals(id))).go();
  
  await db.enqueue(DeleteOp(
    opId: uuid.v4(),
    kind: 'daily_feeling',
    id: id,
    localTimestamp: DateTime.now().toUtc(),
    baseUpdatedAt: serverUpdatedAt,
  ));
}
```

### Synchronization

Call `sync()` manually when needed (pull/push/merge) or enable the auto timer. You can limit `kinds` if you only need to refresh part of the data.

```dart
// Вручную
final stats = await engine.sync();

// Автоматически каждые 5 минут
engine.startAuto(interval: Duration(minutes: 5));
engine.stopAuto();

// Для конкретных таблиц
await engine.sync(kinds: {'daily_feeling', 'health_record'});
```

---

## Conflict resolution

A conflict happens when data changed both on the client and server. Configure behavior via `SyncConfig(conflictStrategy: ...)` globally or `tableConflictConfigs` for specific tables.

### Strategies

| Strategy | Description |
|----------|-------------|
| `autoPreserve` | **(default)** Smart merge that keeps all data |
| `serverWins` | Server version wins |
| `clientWins` | Client version wins (force push) |
| `lastWriteWins` | Later timestamp wins |
| `merge` | Custom merge function |
| `manual` | Manual resolution via callback |

### autoPreserve

Default strategy — merges without losing data:

```dart
// Локально: {mood: 5, notes: "My notes"}
// На сервере: {mood: 3, energy: 7}
// Результат:  {mood: 5, energy: 7, notes: "My notes"}
```

How it works:
1. Takes server data as the base
2. Applies local changes (only `changedFields` if provided)
3. Merges lists without duplicates
4. Merges nested objects recursively
5. Uses server values for system fields (`id`, `updatedAt`, `createdAt`)
6. Sends the result with `X-Force-Update: true`

### Manual resolution

```dart
final engine = SyncEngine(
  // ...
  config: SyncConfig(
    conflictStrategy: ConflictStrategy.manual,
    conflictResolver: (conflict) async {
      // Show a dialog to the user or resolve programmatically
      final choice = await showConflictDialog(conflict);
      
      return switch (choice) {
        'server' => AcceptServer(),
        'client' => AcceptClient(),
        'merge'  => AcceptMerged({...}),
        'defer'  => DeferResolution(),
        _        => DiscardOperation(),
      };
    },
  ),
);
```

### Custom merge

```dart
final engine = SyncEngine(
  // ...
  config: SyncConfig(
    conflictStrategy: ConflictStrategy.merge,
    mergeFunction: (local, server) {
      return {...server, ...local};
    },
  ),
);

// Built-in helpers
ConflictUtils.defaultMerge(local, server);
ConflictUtils.deepMerge(local, server);
ConflictUtils.preservingMerge(local, server, changedFields: {'mood'});
```

### Per-table strategy

```dart
final engine = SyncEngine(
  // ...
  tableConflictConfigs: {
    'user_settings': TableConflictConfig(
      strategy: ConflictStrategy.clientWins,
    ),
  },
);
```

---

## Events and stats

SyncEngine emits an event stream that is handy for UI indicators, logging, and metrics.

```dart
// Subscribe to events
engine.events.listen((event) {
  switch (event) {
    case SyncStarted(:final phase):
      print('Начало: $phase');
    case SyncProgress(:final done, :final total):
      print('Прогресс: $done/$total');
    case SyncCompleted(:final stats):
      print('Готово: pushed=${stats.pushed}, pulled=${stats.pulled}');
    case ConflictDetectedEvent(:final conflict):
      print('Конфликт: ${conflict.entityId}');
    case SyncErrorEvent(:final error):
      print('Ошибка: $error');
  }
});

// Stats after sync
final stats = await engine.sync();
print('Отправлено: ${stats.pushed}');
print('Получено: ${stats.pulled}');
print('Конфликтов: ${stats.conflicts}');
print('Разрешено: ${stats.conflictsResolved}');
print('Ошибок: ${stats.errors}');
```

---

## Server requirements

The server must support a predictable REST contract: idempotent PUT requests, stable pagination, and conflict checks via `updatedAt`. See [`docs/backend_guidelines.md`](docs/backend_guidelines.md) for the full guide with examples and a checklist.

Quick reminder:

- implement CRUD endpoints `/{kind}` with filters `updatedSince`, `afterId`, `limit`, `includeDeleted`;
- keep `updatedAt` and (optionally) `deletedAt`, setting system fields on the server;
- on PUT, validate `_baseUpdatedAt`, return `409` with current data, and support `X-Force-Update` + `X-Idempotency-Key`;
- return lists as `{ "items": [...], "nextPageToken": "..." }`, building the cursor from `(updatedAt, id)`;
- refer to the e2e example in `packages/offline_first_sync_drift_rest/test/e2e` for a reference implementation.

---

## CI/CD

The GitHub Actions pipeline `.github/workflows/ci.yml` runs `dart analyze` and tests for all workspace packages (`packages/offline_first_sync_drift`, `packages/offline_first_sync_drift_rest`, `example`) on every push and pull request to `main`/`master`. Locally you can mirror the same checks with:

```bash
dart pub get
dart analyze .
dart test packages/offline_first_sync_drift
dart test packages/offline_first_sync_drift_rest
dart test
```
