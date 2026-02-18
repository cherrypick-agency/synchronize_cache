---
title: "SyncTableRegistrationExtension<T>"
description: "API documentation for SyncTableRegistrationExtension<T> extension from offline_first_sync_drift"
category: "Extensions"
library: "offline_first_sync_drift"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift/lib/src/syncable_table.dart#L92"
outline: [2, 3]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# SyncTableRegistrationExtension\<T\>

<div class="member-signature"><pre><code><span class="kw">extension</span> <span class="fn">SyncTableRegistrationExtension</span>&lt;T&gt; <span class="kw">on</span> <span class="type">TableInfo</span>&lt;<span class="type">Table</span>, <span class="type">T</span>&gt;</code></pre></div>

Sugar for concise table registration.

## Methods {#section-methods}

### syncTable() <Badge type="info" text="extension" /> {#synctable}

<div class="member-signature"><pre><code><a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable" class="type-link">SyncableTable</a>&lt;<span class="type">T</span>&gt; <span class="fn">syncTable</span>({
  <span class="type">String</span>? <span class="param">kind</span>,
  <span class="kw">required</span> <span class="type">T</span> <span class="type">Function</span>(<span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">dynamic</span>&gt; <span class="param">json</span>) <span class="param">fromJson</span>,
  <span class="kw">required</span> <span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">dynamic</span>&gt; <span class="type">Function</span>(<span class="type">T</span> <span class="param">entity</span>) <span class="param">toJson</span>,
  (<span class="type">Insertable</span>&lt;<span class="type">T</span>&gt; <span class="type">Function</span>(<span class="type">T</span> <span class="param">entity</span>))? <span class="param">toInsertable</span>,
  <span class="kw">required</span> <span class="type">String</span> <span class="type">Function</span>(<span class="type">T</span> <span class="param">entity</span>) <span class="param">getId</span>,
  <span class="kw">required</span> <span class="type">DateTime</span> <span class="type">Function</span>(<span class="type">T</span> <span class="param">entity</span>) <span class="param">getUpdatedAt</span>,
})</code></pre></div>

Create [SyncableTable](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable) from a Drift table reference.

Defaults `kind` to `actualTableName` when omitted.
Requires explicit `getId` and `getUpdatedAt` to avoid runtime reflection
fallbacks and fail fast during setup.

*Available on TableInfo\<TableDsl extends Table, D\>, provided by the [SyncTableRegistrationExtension\<T\>](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncTableRegistrationExtension) extension*

:::details Implementation
```dart
SyncableTable<T> syncTable({
  String? kind,
  required T Function(Map<String, dynamic> json) fromJson,
  required Map<String, dynamic> Function(T entity) toJson,
  Insertable<T> Function(T entity)? toInsertable,
  required String Function(T entity) getId,
  required DateTime Function(T entity) getUpdatedAt,
}) {
  final resolvedKind = (kind ?? actualTableName).trim();
  if (resolvedKind.isEmpty) {
    throw ArgumentError.value(kind, 'kind', 'kind must not be empty');
  }

  return SyncableTable<T>(
    kind: resolvedKind,
    table: this,
    fromJson: fromJson,
    toJson: toJson,
    toInsertable: toInsertable,
    getId: getId,
    getUpdatedAt: getUpdatedAt,
  );
}
```
:::

