---
title: "createRestSyncEngine<DB extends GeneratedDatabase> function"
description: "API documentation for the createRestSyncEngine<DB extends GeneratedDatabase> function from offline_first_sync_drift_rest"
category: "Functions"
library: "offline_first_sync_drift_rest"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift_rest/lib/src/rest_sync_engine.dart#L7"
outline: false
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# createRestSyncEngine\<DB extends GeneratedDatabase\>

<div class="member-signature"><pre><code><a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEngine" class="type-link">SyncEngine</a>&lt;<span class="type">DB</span>&gt; <span class="fn">createRestSyncEngine&lt;DB extends GeneratedDatabase&gt;</span>({
  <span class="kw">required</span> <span class="type">DB</span> <span class="param">db</span>,
  <span class="kw">required</span> <span class="type">Uri</span> <span class="param">base</span>,
  <span class="kw">required</span> <span class="type">Future</span>&lt;<span class="type">String</span>&gt; <span class="type">Function</span>() <span class="param">token</span>,
  <span class="kw">required</span> <span class="type">List</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable" class="type-link">SyncableTable</a>&lt;<span class="type">dynamic</span>&gt;&gt; <span class="param">tables</span>,
  <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncConfig" class="type-link">SyncConfig</a> <span class="param">config</span> = const SyncConfig(),
  <span class="type">Map</span>&lt;<span class="type">String</span>, <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/TableConflictConfig" class="type-link">TableConflictConfig</a>&gt;? <span class="param">tableConflictConfigs</span>,
  <span class="type">Client</span>? <span class="param">client</span>,
  <span class="type">Duration</span> <span class="param">backoffMin</span> = const Duration(seconds: 1),
  <span class="type">Duration</span> <span class="param">backoffMax</span> = const Duration(minutes: 2),
  <span class="type">int</span> <span class="param">maxRetries</span> = <span class="num-lit">5</span>,
  <span class="type">int</span> <span class="param">pushConcurrency</span> = <span class="num-lit">1</span>,
  <span class="type">bool</span> <span class="param">enableBatch</span> = <span class="kw">false</span>,
  <span class="type">int</span> <span class="param">batchSize</span> = <span class="num-lit">100</span>,
  <span class="type">String</span> <span class="param">batchPath</span> = <span class="str-lit">'batch'</span>,
})</code></pre></div>

One-liner helper that creates [RestTransport](/api/package-offline_first_sync_drift_rest_offline_first_sync_drift_rest/RestTransport) and [SyncEngine](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEngine) together.

