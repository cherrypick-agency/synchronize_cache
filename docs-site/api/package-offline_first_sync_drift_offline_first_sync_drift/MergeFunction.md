---
title: "MergeFunction typedef"
description: "API documentation for the MergeFunction typedef from offline_first_sync_drift"
category: "Typedefs"
library: "offline_first_sync_drift"
outline: false
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# MergeFunction

<div class="member-signature"><pre><code><span class="kw">typedef</span> <span class="fn">MergeFunction</span> = <span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="type">Function</span>(
  <span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="param">local</span>,
  <span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="param">server</span>,
)</code></pre></div>

Callback for data merging.

