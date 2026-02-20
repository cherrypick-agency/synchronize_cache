# Offline-first Cache Sync

[![CI](https://github.com/cherrypick-agency/synchronize_cache/actions/workflows/ci.yml/badge.svg)](https://github.com/cherrypick-agency/synchronize_cache/actions/workflows/ci.yml)
![coverage](https://img.shields.io/badge/coverage-67.2%25-yellow)

**[Documentation](https://cherrypick-agency.github.io/synchronize_cache/)**

Dart/Flutter library for offline-first data handling. Local cache on Drift + server sync.

**Principle:** read locally → write locally + to outbox → `sync()` pushes and pulls data.

Built on [Drift](https://drift.simonbinder.eu/) (best Flutter ORM) + Outbox pattern (used by Shopify, Uber, Stripe).

## Table of contents

- [Offline-first Cache Sync](#offline-first-cache-sync)
  - [Table of contents](#table-of-contents)
  - [Why this library?](#why-this-library)
    - [Where we are stronger](#where-we-are-stronger)
    - [Where others are stronger](#where-others-are-stronger)
    - [When to choose what](#when-to-choose-what)
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
  - [Detailed comparison](#detailed-comparison)

---

## Why this library?

The Flutter ecosystem has several offline-first solutions. Each has real strengths — here is an honest breakdown of where this library fits and where alternatives may serve you better.

### Where we are stronger

**Hybrid conflict resolution: client merges, server validates.** The library ships six ready-to-use strategies (`autoPreserve`, `serverWins`, `clientWins`, `lastWriteWins`, `merge`, `manual`) that run on the client. The actual flow is hybrid:

```
1. Client → PUT /todos/123  {data, _baseUpdatedAt: "..."}
2. Server checks _baseUpdatedAt → 409 + current server data
3. Client merges (autoPreserve / chosen strategy)
4. Client → PUT /todos/123  {merged}  + X-Force-Update: true
5. Server validates and accepts — or rejects if business rules are violated
```

The server retains the final say — it can reject a force-update if needed (e.g., no seats left, budget exceeded). But you don't need to write merge logic on the backend — just detect the conflict (`409`) and validate the result.

> **Client-side vs server-side — when to use what:**
> For most CRUD apps (notes, tasks, CRM, health tracking) client-side resolution is simpler and faster to ship. For financial transactions, bookings, or multi-platform products with 5+ clients — server-side resolution (PowerSync's approach) is more reliable, because only the server knows the full state.

PowerSync documents 7 conflict resolution *patterns*, but they are **design guidelines for your backend code** — the PowerSync SDK itself does not resolve conflicts. Brick has **no** conflict handling at all. Firebase is LWW only.

**`changedFields` + `autoPreserve` merge.** When the server returns 409:
```
Local change:  {mood: 5, notes: "My notes"}   (changedFields: {mood, notes})
Server state:  {mood: 3, energy: 7, notes: "Old"}
─────────────────────────────────────────────
autoPreserve:  {mood: 5, energy: 7, notes: "My notes"}
               ↑ local   ↑ server   ↑ local (was in changedFields)
```

Only the fields you actually changed overwrite the server. Fields modified by other users are preserved. PowerSync's field-level LWW resolves per-field, but doesn't track *which* fields the client intended to change — it compares timestamps per field.

**Per-table conflict strategies.** Different data needs different handling:
```dart
tableConflictConfigs: {
  'user_settings': TableConflictConfig(strategy: ConflictStrategy.clientWins),
  'shared_docs':   TableConflictConfig(strategy: ConflictStrategy.manual),
  'analytics':     TableConflictConfig(strategy: ConflictStrategy.serverWins),
}
```

No other Flutter library offers this.

**Works with any backend via TransportAdapter.** REST, GraphQL, gRPC, WebSocket, legacy SOAP — implement `TransportAdapter` and you are done. PowerSync requires Postgres, MongoDB, MySQL, or SQL Server as your *source database*. Firebase is Firebase-only. Brick supports REST/GraphQL/Supabase.

**Drift-native.** Built on Drift from the ground up — type-safe queries, reactive streams, code generation. PowerSync has Drift integration in alpha. Brick uses its own DSL over sqflite.

**Free forever, MIT license.** No SaaS, no usage limits, no deactivation after seven days of inactivity (PowerSync free tier does this). No vendor lock-in at all.

### Where others are stronger

We believe in honest comparison. Here is where alternatives genuinely win:

| Alternative | What they do better |
|-------------|---------------------|
| **PowerSync** | Real-time streaming sync (we only have manual/timer). Managed cloud dashboard with monitoring. Larger community (230 GitHub stars, funded company). Production-proven at Fortune 500 scale. Multi-platform SDKs beyond Flutter (React Native, Kotlin, Swift, .NET). |
| **Firebase** | Fully managed infrastructure — auth, analytics, push notifications, hosting, all integrated. Massive community and ecosystem. Real-time snapshot listeners. Zero backend to build. |
| **Brick** | Simpler mental model if you only need basic offline cache. No conflict concepts to learn. Just works as a transparent cache layer. |
| **sql_crdt** | True CRDT with mathematical convergence guarantees (HLC). Can work without a central server. Eventual consistency is provable, not dependent on server behavior. |

### When to choose what

| You need | Use |
|----------|-----|
| Smart conflict resolution without writing backend logic | **This library** |
| CRUD app with one Flutter client, any backend | **This library** |
| Zero cost, full control, MIT license | **This library** |
| Financial/booking system where only the server knows the full state | **PowerSync** (server-side resolution) |
| Managed real-time sync with dashboard and monitoring | **PowerSync** |
| Multi-platform product (Flutter + React Native + Web) | **PowerSync** (SDKs for all platforms) |
| Full managed backend (auth, storage, analytics) | **Firebase** |
| Simple offline cache, no conflict handling needed | **Brick** |
| P2P sync or mathematical CRDT guarantees | **sql_crdt** |

See [Detailed comparison](#detailed-comparison) at the end for a full feature matrix.

---

## Quick start

Minimal checklist: install packages, prepare a Drift database with `include` for sync tables, then register your tables in `SyncEngine`.

### 1. Installation

```yaml
dependencies:
  offline_first_sync_drift: ^0.1.2
  offline_first_sync_drift_rest: ^0.1.2
  drift: ^2.26.1
  json_annotation: ^4.8.0

dev_dependencies:
  drift_dev: ^2.26.1
  build_runner: ^2.4.15
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

final dailyFeelingSync = db.dailyFeelings.syncTable<DailyFeeling>(
  kind: 'daily_feeling',
  fromJson: DailyFeeling.fromJson,
  toJson: (e) => e.toJson(),
  toInsertable: (e) => e.toInsertable(),
  getId: (e) => e.id,
  getUpdatedAt: (e) => e.updatedAt,
);

final engine = SyncEngine(
  db: db,
  transport: transport,
  tables: [dailyFeelingSync],
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
  
  await db.enqueue(
    UpsertOp.create(
      kind: 'daily_feeling',
      id: feeling.id,
      payloadJson: feeling.toJson(),
    ),
  );
}

Future<void> updateFeeling(DailyFeeling updated, Set<String> changedFields) async {
  await db.update(db.dailyFeelings).replace(updated);
  
  await db.enqueue(
    UpsertOp.create(
      kind: 'daily_feeling',
      id: updated.id,
      payloadJson: updated.toJson(),
      baseUpdatedAt: updated.updatedAt,
      changedFields: changedFields,
    ),
  );
}

Future<void> deleteFeeling(String id, DateTime? serverUpdatedAt) async {
  await (db.delete(db.dailyFeelings)..where((t) => t.id.equals(id))).go();
  
  await db.enqueue(
    DeleteOp.create(
      kind: 'daily_feeling',
      id: id,
      baseUpdatedAt: serverUpdatedAt,
    ),
  );
}
```

Less boilerplate (optional): use the typed writer helpers for atomic "local write + enqueue":

```dart
final writer = db.syncWriter().forTable(dailyFeelingSync);

await writer.insertAndEnqueue(feeling);
await writer.replaceAndEnqueue(
  updated,
  baseUpdatedAt: updated.updatedAt,
  changedFields: {'mood', 'notes'},
);

await writer.replaceAndEnqueueDiff(
  before: previous,
  after: updated,
  baseUpdatedAt: previous.updatedAt,
);
```

### Synchronization

Call `sync()` manually when needed (pull/push/merge) or enable the auto timer. You can limit `kinds` if you only need to refresh part of the data.

```dart
// Manual
final stats = await engine.sync();

// Auto-sync every 5 minutes
engine.startAuto(interval: Duration(minutes: 5));
engine.stopAuto();

// For specific tables only
await engine.sync(kinds: {'daily_feeling', 'health_record'});

// Independent push/pull filters
await engine.sync(
  pushKinds: {'daily_feeling'},
  pullKinds: {'daily_feeling', 'health_record'},
);
```

Optional app-flow automation:

```dart
final coordinator = SyncCoordinator(
  engine: engine,
  pullOnStartup: true,
  autoInterval: const Duration(minutes: 5),
  pushOnOutboxChanges: true,
);

await coordinator.start();
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
// Local:  {mood: 5, notes: "My notes"}
// Server: {mood: 3, energy: 7}
// Result: {mood: 5, energy: 7, notes: "My notes"}
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
      print('Started: $phase');
    case SyncProgress(:final done, :final total):
      print('Progress: $done/$total');
    case SyncCompleted(:final stats):
      print('Done: pushed=${stats.pushed}, pulled=${stats.pulled}');
    case ConflictDetectedEvent(:final conflict):
      print('Conflict: ${conflict.entityId}');
    case SyncErrorEvent(:final error):
      print('Error: $error');
  }
});

// Stats after sync
final stats = await engine.sync();
print('Pushed: ${stats.pushed}');
print('Pulled: ${stats.pulled}');
print('Conflicts: ${stats.conflicts}');
print('Resolved: ${stats.conflictsResolved}');
print('Errors: ${stats.errors}');
```

---

## Server requirements

The server must support a predictable REST contract: idempotent PUT requests, stable pagination, and conflict checks via `updatedAt`. See [`docs/backend-transport.md`](docs/backend-transport.md) for the full guide with examples and a checklist.

Quick reminder:

- implement CRUD endpoints `/{kind}` with filters `updatedSince`, `afterId`, `limit`, `includeDeleted`;
- keep `updatedAt` and (optionally) `deletedAt`, setting system fields on the server;
- on PUT, validate `_baseUpdatedAt`, return `409` with current data, and support `X-Force-Update` + `X-Idempotency-Key`;
- return lists as `{ "items": [...], "nextPageToken": "..." }`, building the cursor from `(updatedAt, id)`;
- refer to the e2e example in `packages/offline_first_sync_drift_rest/test/e2e` for a reference implementation.

---

## Migration guide

For API migration in the current release and schema migration patterns, see:

- [`docs/migration.md`](docs/migration.md)

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

---

## Detailed comparison

Feature matrix based on research of official docs, pub.dev, and GitHub (last updated: February 2026).

| Feature | This library | PowerSync | Brick | Firebase | sql_crdt |
|---------|:------------:|:---------:|:-----:|:--------:|:--------:|
| **Offline read/write** | Full | Full | Full | Partial | Full |
| **Conflict resolution** | 6 strategies, client-side, out of the box | You implement on your backend (7 documented patterns) | None (de facto LWW) | LWW only | LWW only (HLC, automatic) |
| **Field-level merge** | Yes — `changedFields` tracking | Yes — field-level LWW (per-field timestamps) | No | Partial — `set(merge:true)` | No (row-level) |
| **Per-table conflict config** | Yes | No (bucket-level sync rules) | No (per-request policies) | No | No |
| **ORM** | Drift (native, type-safe) | Drift (alpha integration) | Custom DSL (sqflite) | No | Raw SQL / drift_crdt (third-party) |
| **Backend support** | Any (TransportAdapter) | Postgres, MongoDB, MySQL (beta), SQL Server (alpha) | REST, GraphQL, Supabase | Firebase only | Any (changeset-based) |
| **Web support** | Yes | Beta (production-ready) | Experimental | Yes (write promises hang offline) | Experimental |
| **Real-time sync** | Manual / timer | Yes (streaming) | Partial (Supabase only) | Yes (snapshot listeners) | Yes (WebSocket) |
| **Self-hosted** | Yes (just a library) | Yes (Open Edition, free) | Yes (just a library) | No | Yes |
| **Price** | Free (MIT) | Free tier (7-day inactivity limit) + $49+/mo Pro | Free (MIT) | Pay-per-use (free tier: 50K reads/day) | Free (Apache 2.0) |
| **Vendor lock-in** | None | Low-Medium (FSL→Apache 2.0 after 2y) | Medium (custom DSL) | High | None |
| **Community** | New | Growing (230 GitHub stars) | Small (500 GitHub stars) | Large | Niche (~180 GitHub stars) |

<details>
<summary><strong>Notes on each competitor (click to expand)</strong></summary>

**PowerSync** — a well-funded sync platform. Free tier exists (2 GB/mo, 50 connections) but deactivates after 7 days of inactivity. Documents 7 conflict resolution patterns (field-level LWW, timestamp-based, sequence versioning, business rules, conflict recording, change-level tracking, cumulative deltas), but these are **design patterns you implement in your backend** — the PowerSync client SDK only sends data via `uploadData()` callback, it does not resolve conflicts itself. Client SDKs are Apache 2.0, server is FSL (converts to Apache 2.0 after 2 years). Self-hosted Open Edition is free. Web is beta but functionally production-ready. Drift integration via `drift_sqlite_async` (alpha).

**Brick** — a transparent offline cache layer with no built-in conflict resolution. Operations are replayed sequentially from an HTTP request queue — the last request to reach the server wins. Uses its own annotation-based DSL over sqflite (not Drift). Web support is not officially listed on pub.dev; experimental only via `sqflite_common_ffi_web`. The Supabase provider includes `subscribeToRealtime()` for real-time push sync. Documentation exists but is considered hard to follow by the community.

**Firebase Firestore** — a fully managed platform with the largest ecosystem. Offline read/write works for previously cached data, but: transactions fail offline entirely, write promises on web never resolve when offline (confirmed WONTFIX), cached queries are slow without `enablePersistentCacheIndexAutoCreation()` (3-12s per query, not "8+ minutes" as sometimes claimed). Auto-generated document IDs work fully offline. `set(merge: true)` provides field-level writes, but conflicts are still LWW per-field — no custom strategies. No self-hosting, no per-collection cache settings. Free tier: 50K reads/day, 20K writes/day.

**sql_crdt** — a true CRDT implementation using Hybrid Logical Clocks. Conflict resolution is automatic (LWW at row level, not field-level) with mathematical convergence guarantees. No custom strategies available. Drift integration exists via third-party `drift_crdt` package (requires dependency overrides). Project of a single developer (Daniel Cachapa), used in production (Libra app, 1M+ installs). No built-in P2P — client-server sync via WebSocket (`crdt_sync`).

**Also researched (not recommended for new projects):**
- **Amplify DataStore** — effectively deprecated. Gen 1 in maintenance mode (Flutter v1 deprecated April 2025, JS v4 EOS April 2026), Gen 2 does not support DataStore. No web, no self-hosting, AWS-only.
- **Realm** — Atlas Device Sync shut down September 30, 2025. Local DB continues as community fork but no sync.
- **ObjectBox Sync** — active, but proprietary sync with unpublished pricing, no web support.
- **Isar** — no sync capabilities, uncertain maintenance status, v4 unstable.

</details>
