---
title: "SyncWriterDatabaseExtension<DB extends GeneratedDatabase>"
description: "API documentation for SyncWriterDatabaseExtension<DB extends GeneratedDatabase> extension from offline_first_sync_drift"
category: "Extensions"
library: "offline_first_sync_drift"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift/lib/src/sync_writer.dart#L202"
outline: [2, 3]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# SyncWriterDatabaseExtension\<DB extends GeneratedDatabase\>

<div class="member-signature"><pre><code><span class="kw">extension</span> <span class="fn">SyncWriterDatabaseExtension</span>&lt;DB <span class="kw">extends</span> <span class="type">GeneratedDatabase</span>&gt; <span class="kw">on</span> <span class="type">DB</span></code></pre></div>

Convenience accessors on Drift databases.

## Methods {#section-methods}

### syncWriter() <Badge type="info" text="extension" /> {#syncwriter}

<div class="member-signature"><pre><code><a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncWriter" class="type-link">SyncWriter</a>&lt;<span class="type">DB</span>&gt; <span class="fn">syncWriter</span>({
  (<span class="type">String</span> <span class="type">Function</span>())? <span class="param">opIdFactory</span>,
  (<span class="type">DateTime</span> <span class="type">Function</span>())? <span class="param">clock</span>,
})</code></pre></div>

Create a [SyncWriter](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncWriter) for this database.

Throws if the database does not implement [SyncDatabaseMixin](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseMixin).

*Available on DB extends GeneratedDatabase, provided by the [SyncWriterDatabaseExtension\<DB extends GeneratedDatabase\>](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncWriterDatabaseExtension) extension*

:::details Implementation
```dart
SyncWriter<DB> syncWriter({OpIdFactory? opIdFactory, SyncClock? clock}) =>
    SyncWriter<DB>(this, opIdFactory: opIdFactory, clock: clock);
```
:::

