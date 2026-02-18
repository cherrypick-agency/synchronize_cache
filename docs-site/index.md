---
layout: home
hero:
  name: "offline_first_sync_drift"
  text: Read Locally. Sync When Ready.
  tagline: Offline-first data sync for Dart & Flutter — Outbox pattern on Drift ORM with smart conflict resolution
  actions:
    - theme: brand
      text: Quick Start
      link: /guide/_generated/offline_first_sync_drift_workspace/quick-start
    - theme: alt
      text: API Reference
      link: /api/
    - theme: alt
      text: GitHub
      link: https://github.com/cherrypick-agency/synchronize_cache
features:
  - icon: 📤
    title: Outbox Pattern
    details: Write locally, queue to outbox, push when online. The same pattern used by Shopify, Uber, and Stripe in production.
  - icon: 🔀
    title: 6 Conflict Strategies
    details: '<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy">autoPreserve</a>, <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy">serverWins</a>, <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy">clientWins</a>, <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy">lastWriteWins</a>, <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy">merge</a>, <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy">manual</a> — pick per table. Field-level tracking for smart merges.'
  - icon: 🗄️
    title: Built on Drift ORM
    details: Type-safe SQL, reactive streams, code generation. Not a wrapper — Drift is the foundation. Full offline CRUD out of the box.
  - icon: 🔌
    title: Any Backend
    details: 'REST, GraphQL, gRPC, WebSocket — implement <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/TransportAdapter">TransportAdapter</a> and you''re done. No vendor lock-in, no SaaS dependency.'
  - icon: 🧩
    title: Per-Table Config
    details: Different data needs different handling. Set conflict strategy, sync interval, and soft-delete policy per table independently.
  - icon: 📡
    title: Smart Sync
    details: Cursor-based pagination for pulls, batch push for writes, exponential backoff on failures. Handles flaky networks gracefully.
  - icon: 🔒
    title: Free & Open Source
    details: MIT license, no usage limits, no SaaS fees, no 7-day inactivity deactivation. Your data, your server, your rules.
  - icon: 📊
    title: Events & Monitoring
    details: 'Stream-based <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEvent">sync events</a> for UI feedback — progress, conflicts, errors. Build sync indicators and retry buttons with ease.'
---

## How It Works

```mermaid
flowchart LR
    A[Write locally] --> B[Queue to outbox]
    B --> C[Push when online]
    C --> D[Pull server changes]
    D --> E{Conflict?}
    E -- Yes --> F[Resolve — 6 strategies]
    F --> A
    E -- No --> A
```

## Quick Start

::: code-group
```yaml [pubspec.yaml]
dependencies:
  offline_first_sync_drift: ^0.1.2
  offline_first_sync_drift_rest: ^0.1.2
  drift: ^2.26.1

dev_dependencies:
  drift_dev: ^2.26.1
  build_runner: ^2.4.15
```
```dart [Setup]
final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer ${await getToken()}',
);

final engine = SyncEngine(
  db: database,
  transport: transport,
  tables: [todoSync],
  config: const SyncConfig(
    conflictStrategy: ConflictStrategy.autoPreserve,
  ),
);

// Sync on demand
await engine.sync();
```
```dart [CRUD]
// Read locally — instant, works offline
final todos = await db.select(db.todos).get();

// Write + enqueue in one call (syncWriter sugar)
// Sugar for: db.into(table).insert(...) + db.enqueue(UpsertOp.create(...))
final writer = db.syncWriter().forTable(todoSync);
await writer.insertAndEnqueue(todo);

// Update: read existing, modify, write back
final existing = await (db.select(db.todos)
  ..where((t) => t.id.equals('todo-1'))).getSingle();
final updated = existing.copyWith(title: 'New title');
await writer.replaceAndEnqueue(
  updated,
  baseUpdatedAt: existing.updatedAt,
  changedFields: {'title'},
);

// Push & pull when ready
await engine.sync();
```
:::

## Conflict Resolution

The killer feature: **field-level change tracking + hybrid resolution**.

```
Local change:  {mood: 5, notes: "My notes"}   (changedFields: {mood, notes})
Server state:  {mood: 3, energy: 7, notes: "Old"}
───────────────────────────────────────────────
autoPreserve:  {mood: 5, energy: 7, notes: "My notes"}
               ↑ local   ↑ server   ↑ local
```

Only the fields you changed overwrite the server. Fields modified by other clients are preserved.

