---
title: "SyncDatabaseDx"
description: "API documentation for SyncDatabaseDx extension from offline_first_sync_drift"
category: "Extensions"
library: "offline_first_sync_drift"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift/lib/src/sync_database_dx.dart#L9"
outline: [2, 3]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# SyncDatabaseDx

<div class="member-signature"><pre><code><span class="kw">extension</span> <span class="fn">SyncDatabaseDx</span> <span class="kw">on</span> <span class="type">GeneratedDatabase</span></code></pre></div>

One-liner helpers for "local write + enqueue" flows.

These are convenience wrappers over [SyncWriter](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncWriter) / [SyncEntityWriter](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEntityWriter).

## Methods {#section-methods}

### enqueueDelete() <Badge type="info" text="extension" /> {#enqueuedelete}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">enqueueDelete&lt;T&gt;</span>(
  <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable" class="type-link">SyncableTable</a>&lt;<span class="type">T</span>&gt; <span class="param">table</span>, {
  <span class="kw">required</span> <span class="type">String</span> <span class="param">id</span>,
  <span class="type">DateTime</span>? <span class="param">baseUpdatedAt</span>,
  (<span class="type">String</span> <span class="type">Function</span>())? <span class="param">opIdFactory</span>,
  (<span class="type">DateTime</span> <span class="type">Function</span>())? <span class="param">clock</span>,
  <span class="type">String</span>? <span class="param">opId</span>,
  <span class="type">DateTime</span>? <span class="param">localTimestamp</span>,
})</code></pre></div>

Enqueue a delete (without touching local DB).

*Available on GeneratedDatabase, provided by the [SyncDatabaseDx](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseDx) extension*

:::details Implementation
```dart
Future<void> enqueueDelete<T>(
  SyncableTable<T> table, {
  required String id,
  DateTime? baseUpdatedAt,
  OpIdFactory? opIdFactory,
  SyncClock? clock,
  String? opId,
  DateTime? localTimestamp,
}) => syncWriter(opIdFactory: opIdFactory, clock: clock)
    .forTable(table)
    .enqueueDelete(
      id: id,
      baseUpdatedAt: baseUpdatedAt,
      opId: opId,
      localTimestamp: localTimestamp,
    );
```
:::

### insertAndEnqueue() <Badge type="info" text="extension" /> {#insertandenqueue}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">insertAndEnqueue&lt;T&gt;</span>(
  <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable" class="type-link">SyncableTable</a>&lt;<span class="type">T</span>&gt; <span class="param">table</span>,
  <span class="type">T</span> <span class="param">entity</span>, {
  (<span class="type">String</span> <span class="type">Function</span>())? <span class="param">opIdFactory</span>,
  (<span class="type">DateTime</span> <span class="type">Function</span>())? <span class="param">clock</span>,
  <span class="type">String</span>? <span class="param">opId</span>,
  <span class="type">DateTime</span>? <span class="param">localTimestamp</span>,
})</code></pre></div>

Insert `entity` and enqueue an upsert.

*Available on GeneratedDatabase, provided by the [SyncDatabaseDx](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseDx) extension*

:::details Implementation
```dart
Future<void> insertAndEnqueue<T>(
  SyncableTable<T> table,
  T entity, {
  OpIdFactory? opIdFactory,
  SyncClock? clock,
  String? opId,
  DateTime? localTimestamp,
}) => syncWriter(opIdFactory: opIdFactory, clock: clock)
    .forTable(table)
    .insertAndEnqueue(entity, opId: opId, localTimestamp: localTimestamp);
```
:::

### replaceAndEnqueue() <Badge type="info" text="extension" /> {#replaceandenqueue}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">replaceAndEnqueue&lt;T&gt;</span>(
  <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable" class="type-link">SyncableTable</a>&lt;<span class="type">T</span>&gt; <span class="param">table</span>,
  <span class="type">T</span> <span class="param">entity</span>, {
  <span class="kw">required</span> <span class="type">DateTime</span> <span class="param">baseUpdatedAt</span>,
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">changedFields</span>,
  (<span class="type">String</span> <span class="type">Function</span>())? <span class="param">opIdFactory</span>,
  (<span class="type">DateTime</span> <span class="type">Function</span>())? <span class="param">clock</span>,
  <span class="type">String</span>? <span class="param">opId</span>,
  <span class="type">DateTime</span>? <span class="param">localTimestamp</span>,
})</code></pre></div>

Replace `entity` and enqueue an upsert.

*Available on GeneratedDatabase, provided by the [SyncDatabaseDx](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseDx) extension*

:::details Implementation
```dart
Future<void> replaceAndEnqueue<T>(
  SyncableTable<T> table,
  T entity, {
  required DateTime baseUpdatedAt,
  Set<String>? changedFields,
  OpIdFactory? opIdFactory,
  SyncClock? clock,
  String? opId,
  DateTime? localTimestamp,
}) => syncWriter(opIdFactory: opIdFactory, clock: clock)
    .forTable(table)
    .replaceAndEnqueue(
      entity,
      baseUpdatedAt: baseUpdatedAt,
      changedFields: changedFields,
      opId: opId,
      localTimestamp: localTimestamp,
    );
```
:::

### replaceAndEnqueueDiff() <Badge type="info" text="extension" /> {#replaceandenqueuediff}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">replaceAndEnqueueDiff&lt;T&gt;</span>(
  <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable" class="type-link">SyncableTable</a>&lt;<span class="type">T</span>&gt; <span class="param">table</span>, {
  <span class="kw">required</span> <span class="type">T</span> <span class="param">before</span>,
  <span class="kw">required</span> <span class="type">T</span> <span class="param">after</span>,
  <span class="kw">required</span> <span class="type">DateTime</span> <span class="param">baseUpdatedAt</span>,
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt; <span class="param">ignoredFields</span> = ChangedFieldsDiff.defaultIgnoredFields,
  (<span class="type">String</span> <span class="type">Function</span>())? <span class="param">opIdFactory</span>,
  (<span class="type">DateTime</span> <span class="type">Function</span>())? <span class="param">clock</span>,
  <span class="type">String</span>? <span class="param">opId</span>,
  <span class="type">DateTime</span>? <span class="param">localTimestamp</span>,
})</code></pre></div>

Replace `after` and enqueue an upsert with auto-diff `changedFields`.

*Available on GeneratedDatabase, provided by the [SyncDatabaseDx](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseDx) extension*

:::details Implementation
```dart
Future<void> replaceAndEnqueueDiff<T>(
  SyncableTable<T> table, {
  required T before,
  required T after,
  required DateTime baseUpdatedAt,
  Set<String> ignoredFields = ChangedFieldsDiff.defaultIgnoredFields,
  OpIdFactory? opIdFactory,
  SyncClock? clock,
  String? opId,
  DateTime? localTimestamp,
}) => syncWriter(opIdFactory: opIdFactory, clock: clock)
    .forTable(table)
    .replaceAndEnqueueDiff(
      before: before,
      after: after,
      baseUpdatedAt: baseUpdatedAt,
      ignoredFields: ignoredFields,
      opId: opId,
      localTimestamp: localTimestamp,
    );
```
:::

### writeAndEnqueueDelete() <Badge type="info" text="extension" /> {#writeandenqueuedelete}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">writeAndEnqueueDelete&lt;T&gt;</span>(
  <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable" class="type-link">SyncableTable</a>&lt;<span class="type">T</span>&gt; <span class="param">table</span>, {
  <span class="kw">required</span> <span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="type">Function</span>() <span class="param">localWrite</span>,
  <span class="kw">required</span> <span class="type">String</span> <span class="param">id</span>,
  <span class="type">DateTime</span>? <span class="param">baseUpdatedAt</span>,
  (<span class="type">String</span> <span class="type">Function</span>())? <span class="param">opIdFactory</span>,
  (<span class="type">DateTime</span> <span class="type">Function</span>())? <span class="param">clock</span>,
  <span class="type">String</span>? <span class="param">opId</span>,
  <span class="type">DateTime</span>? <span class="param">localTimestamp</span>,
})</code></pre></div>

Run `localWrite` and enqueue delete atomically.

*Available on GeneratedDatabase, provided by the [SyncDatabaseDx](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseDx) extension*

:::details Implementation
```dart
Future<void> writeAndEnqueueDelete<T>(
  SyncableTable<T> table, {
  required Future<void> Function() localWrite,
  required String id,
  DateTime? baseUpdatedAt,
  OpIdFactory? opIdFactory,
  SyncClock? clock,
  String? opId,
  DateTime? localTimestamp,
}) => syncWriter(opIdFactory: opIdFactory, clock: clock)
    .forTable(table)
    .writeAndEnqueueDelete(
      localWrite: localWrite,
      id: id,
      baseUpdatedAt: baseUpdatedAt,
      opId: opId,
      localTimestamp: localTimestamp,
    );
```
:::

