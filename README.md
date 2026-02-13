# Offline-first Cache Sync

[![CI](https://github.com/cherrypick-agency/synchronize_cache/actions/workflows/ci.yml/badge.svg)](https://github.com/cherrypick-agency/synchronize_cache/actions/workflows/ci.yml)
![coverage](https://img.shields.io/badge/coverage-69.9%25-yellow)

Dart/Flutter library for offline-first data handling. Local cache on Drift + server sync.

**Principle:** read locally → write locally + to outbox → `sync()` pushes and pulls data.

Built on [Drift](https://drift.simonbinder.eu/) (best Flutter ORM) + Outbox pattern (used by Shopify, Uber, Stripe).

## Table of contents

- [Offline-first Cache Sync](#offline-first-cache-sync)
  - [Table of contents](#table-of-contents)
  - [Why this library?](#why-this-library)
    - [Detailed comparison](#detailed-comparison)
    - [Advantages](#advantages)
    - [Disadvantages](#disadvantages)
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

## Why this library?

The Flutter ecosystem has several offline-first solutions, but each comes with trade-offs. Here is a fair, research-backed comparison (last updated: February 2026).

### Detailed comparison

| Feature | This library | PowerSync | Brick | Firebase | sql_crdt |
|---------|:------------:|:---------:|:-----:|:--------:|:--------:|
| **Offline read/write** | Full | Full | Full | Partial | Full |
| **Conflict resolution** | 6 strategies (client-side) | 7 strategies (server-side) | None (de facto LWW) | LWW only | LWW only (HLC) |
| **Field-level merge** | Yes (`changedFields`) | Yes (field-level LWW) | No | Partial (`set(merge:true)`) | No (row-level) |
| **Per-table config** | Yes | Partial (via bucket definitions) | No (per-request policies) | No | No |
| **ORM** | Drift (type-safe) | Optional Drift (alpha) | Custom DSL (sqflite) | No | Raw SQL / drift_crdt |
| **Backend support** | Any (TransportAdapter) | Postgres, MongoDB, MySQL (beta), SQL Server (alpha) | REST, GraphQL, Supabase | Firebase only | Any (changeset-based) |
| **Web support** | Yes | Beta (production-ready) | Experimental | Yes (with limitations) | Experimental |
| **Self-hosted** | Yes | Yes (Open Edition, free) | Yes (it's a library) | No (emulator only for dev) | Yes |
| **Real-time sync** | Manual / timer | Yes (streaming) | Partial (Supabase only) | Yes (snapshot listeners) | Yes (WebSocket) |
| **Price** | Free (MIT) | Free tier + $49+/mo Pro | Free (MIT) | Pay-per-use (free tier) | Free (Apache 2.0) |
| **Vendor lock-in** | None | Low-Medium (FSL→Apache 2.0) | Medium (custom DSL) | High | None |
| **Community** | New | Growing (230 GitHub stars) | Small (500 GitHub stars) | Large | Niche (~180 GitHub stars) |

<details>
<summary><strong>Notes on each competitor</strong></summary>

**PowerSync** — more capable than we previously stated. Has a free tier (2 GB/mo, 50 connections), supports 7 conflict resolution strategies implemented on the backend (field-level LWW, timestamp-based, sequence versioning, business rules, conflict recording, change-level tracking, cumulative deltas), and field-level LWW by default. Client SDKs are Apache 2.0, server is FSL (converts to Apache 2.0 after 2 years). Self-hosted Open Edition is free. Web is beta but functionally production-ready. Drift integration via `drift_sqlite_async` (alpha).

**Brick** — has no built-in conflict resolution at all; operations are replayed sequentially from an HTTP request queue, so the last request to reach the server wins. Uses its own annotation-based DSL over sqflite (not Drift). Web support is experimental only (`sqflite_common_ffi_web`), not officially supported. The Supabase provider includes `subscribeToRealtime()` for real-time push sync. Documentation exists but is considered hard to follow by the community.

**Firebase Firestore** — offline read/write works for cached data, but transactions fail offline entirely, write promises on web never resolve when offline, and queries on cached data are slow without `enablePersistentCacheIndexAutoCreation()` (3-12s, not "8+ minutes" as sometimes claimed). Auto-generated document IDs work fully offline (client-side). `set(merge: true)` provides field-level writes, but conflicts are still LWW per-field. No self-hosting, no per-collection cache settings. Free tier: 50K reads/day, 20K writes/day.

**sql_crdt** — true CRDT implementation using Hybrid Logical Clocks (HLC). Automatic conflict resolution but only LWW at row level (not field-level). No custom strategies. Drift integration exists via third-party `drift_crdt` package (requires dependency overrides). Project of a single developer, used in production (Libra app, 1M+ installs). No built-in P2P — client-server via WebSocket (`crdt_sync`).

**Also researched but not recommended:**
- **Amplify DataStore** — effectively deprecated. Gen 1 in maintenance mode (Flutter v1 deprecated April 2025, JS v4 EOS April 2026), Gen 2 does not support DataStore. No web, no self-hosting, AWS-only.
- **Realm** — Atlas Device Sync shut down September 2025. Local DB continues as community fork but no sync.
- **ObjectBox Sync** — active, but proprietary sync with unpublished pricing, no web support.
- **Isar** — no sync capabilities, uncertain maintenance status, v4 unstable.

</details>

### Advantages

- **True field-level merge** — if User A edits `title` and User B edits `description`, both changes are preserved. PowerSync also does field-level LWW, but our `changedFields` + `autoPreserve` can merge non-conflicting fields even when the server returns 409.
- **6 conflict strategies** — `autoPreserve`, `serverWins`, `clientWins`, `lastWriteWins`, `merge`, `manual`
- **Per-table configuration** — different strategies for different data types
- **Any backend** — REST, GraphQL, gRPC, WebSocket via `TransportAdapter` (PowerSync is limited to Postgres/MongoDB/MySQL/SQL Server)
- **Drift ORM** — type-safe, reactive, actively maintained (Brick uses custom DSL, Firebase has no ORM)
- **Outbox pattern** — event-based, not HTTP request queue (unlike Brick)
- **Free & open source** — MIT license, no vendor lock-in, no SaaS dependency

### Disadvantages

| vs | Trade-off |
|----|-----------|
| PowerSync | More initial setup (~50 lines vs plug-and-play). No real-time push streaming (manual/timer sync). No managed cloud dashboard. Smaller community. |
| Brick | More concepts to learn (outbox, changedFields, conflict strategies). Brick is simpler if you only need basic offline cache. |
| sql_crdt | Not true CRDT (requires server, no P2P). sql_crdt guarantees eventual consistency mathematically; we rely on server-side conflict checks. |
| Firebase | No managed infrastructure — you run your own backend. No built-in auth, analytics, or push notifications. |
| All | Newer project, smaller community. |

---

## Quick start

Minimal checklist: install packages, prepare a Drift database with `include` for sync tables, then register your tables in `SyncEngine`.

### 1. Installation

```yaml
dependencies:
  offline_first_sync_drift: ^0.1.2
  offline_first_sync_drift_rest: ^0.1.2
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
