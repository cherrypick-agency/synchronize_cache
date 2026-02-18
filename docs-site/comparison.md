---
title: vs Alternatives
description: Honest comparison of offline_first_sync_drift with PowerSync, Firebase, Brick, and sql_crdt
---

# vs Alternatives

The Flutter ecosystem has several offline-first solutions. Each has real strengths — here is an honest breakdown of where this library fits and where alternatives may serve you better.

## Feature Matrix

| Feature | This library | PowerSync | Firebase | Brick | sql_crdt |
|---------|:------------:|:---------:|:--------:|:-----:|:--------:|
| **Offline read/write** | Full | Full | Partial | Full | Full |
| **Conflict resolution** | [6 strategies](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy), client-side, out of the box | You implement on your backend (7 documented patterns) | LWW only | None (de facto LWW) | LWW only (HLC, automatic) |
| **Field-level merge** | Yes — [`changedFields`](/api/package-offline_first_sync_drift_offline_first_sync_drift/ChangedFieldsDiff) tracking | Yes — field-level LWW (per-field timestamps) | Partial — `set(merge:true)` | No | No (row-level) |
| **Per-table conflict config** | Yes | No (bucket-level sync rules) | No | No (per-request policies) | No |
| **ORM** | Drift (native, type-safe) | Drift (alpha integration) | No | Custom DSL (sqflite) | Raw SQL / drift_crdt (third-party) |
| **Backend support** | Any ([TransportAdapter](/api/package-offline_first_sync_drift_offline_first_sync_drift/TransportAdapter)) | Postgres, MongoDB, MySQL (beta), SQL Server (alpha) | Firebase only | REST, GraphQL, Supabase | Any (changeset-based) |
| **Web support** | Yes | Beta (production-ready) | Yes (write promises hang offline) | Experimental | Experimental |
| **Real-time sync** | Manual / timer | Yes (streaming) | Yes (snapshot listeners) | Partial (Supabase only) | Yes (WebSocket) |
| **Self-hosted** | Yes (just a library) | Yes (Open Edition, free) | No | Yes (just a library) | Yes |
| **Price** | Free (MIT) | Free tier (7-day inactivity limit) + $49+/mo Pro | Pay-per-use (free tier: 50K reads/day) | Free (MIT) | Free (Apache 2.0) |
| **Vendor lock-in** | None | Low-Medium (FSL→Apache 2.0 after 2y) | High | Medium (custom DSL) | None |
| **Community** | New | Growing (230 GitHub stars) | Large | Small (500 GitHub stars) | Niche (~180 GitHub stars) |

## Where we are stronger

**Hybrid conflict resolution: client merges, server validates.** The library ships six ready-to-use strategies ([`autoPreserve`](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy), [`serverWins`](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy), [`clientWins`](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy), [`lastWriteWins`](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy), [`merge`](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy), [`manual`](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy)) that run on the client. The actual flow is hybrid:

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

**[`changedFields`](/api/package-offline_first_sync_drift_offline_first_sync_drift/ChangedFieldsDiff) + `autoPreserve` merge.** When the server returns 409:
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

**Works with any backend via [`TransportAdapter`](/api/package-offline_first_sync_drift_offline_first_sync_drift/TransportAdapter).** REST, GraphQL, gRPC, WebSocket, legacy SOAP — implement `TransportAdapter` and you are done. PowerSync requires Postgres, MongoDB, MySQL, or SQL Server as your *source database*. Firebase is Firebase-only. Brick supports REST/GraphQL/Supabase.

**Drift-native.** Built on Drift from the ground up — type-safe queries, reactive streams, code generation. PowerSync has Drift integration in alpha. Brick uses its own DSL over sqflite.

**Free forever, MIT license.** No SaaS, no usage limits, no deactivation after seven days of inactivity (PowerSync free tier does this). No vendor lock-in at all.

## Where others are stronger

We believe in honest comparison. Here is where alternatives genuinely win:

| Alternative | What they do better |
|-------------|---------------------|
| **PowerSync** | Real-time streaming sync (we only have manual/timer). Managed cloud dashboard with monitoring. Larger community (230 GitHub stars, funded company). Production-proven at Fortune 500 scale. Multi-platform SDKs beyond Flutter (React Native, Kotlin, Swift, .NET). |
| **Firebase** | Fully managed infrastructure — auth, analytics, push notifications, hosting, all integrated. Massive community and ecosystem. Real-time snapshot listeners. Zero backend to build. |
| **Brick** | Simpler mental model if you only need basic offline cache. No conflict concepts to learn. Just works as a transparent cache layer. |
| **sql_crdt** | True CRDT with mathematical convergence guarantees (HLC). Can work without a central server. Eventual consistency is provable, not dependent on server behavior. |

## When to choose what

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
