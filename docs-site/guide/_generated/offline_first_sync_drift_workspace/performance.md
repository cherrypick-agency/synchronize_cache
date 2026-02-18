# Performance and Optimization

Guide to tuning sync engine performance. All default values and parameters are taken directly from the source code.

---

## SyncConfig Parameters

Full table of `SyncConfig` parameters with default values:

| Parameter | Type | Default Value | Description |
|---|---|---|---|
| `pageSize` | `int` | `500` | Page size for pull operations |
| `backoffMin` | `Duration` | `1 second` | Minimum retry backoff delay |
| `backoffMax` | `Duration` | `2 minutes` | Maximum retry backoff delay |
| `backoffMultiplier` | `double` | `2.0` | Exponential backoff multiplier |
| `maxPushRetries` | `int` | `5` | Maximum number of push retries |
| `fullResyncInterval` | `Duration` | `7 days` | Interval between full resyncs |
| `pullOnStartup` | `bool` | `false` | Perform pull on startup |
| `pushImmediately` | `bool` | `true` | Push changes immediately |
| `reconcileInterval` | `Duration?` | `null` | Data reconciliation interval |
| `lazyReconcileOnMiss` | `bool` | `false` | Lazy reconciliation on cache miss |
| `conflictStrategy` | `ConflictStrategy` | `autoPreserve` | Conflict resolution strategy |
| `maxConflictRetries` | `int` | `3` | Maximum conflict resolution attempts |
| `conflictRetryDelay` | `Duration` | `500 ms` | Delay between conflict resolution attempts |
| `skipConflictingOps` | `bool` | `false` | Skip operations with unresolved conflicts |

Additional `RestTransport` parameters:

| Parameter | Type | Default Value | Description |
|---|---|---|---|
| `pushConcurrency` | `int` | `1` | Number of concurrent push requests |
| `enableBatch` | `bool` | `false` | Enable batch API mode |
| `batchSize` | `int` | `100` | Maximum operations per batch request |
| `batchPath` | `String` | `'batch'` | Batch endpoint path |
| `backoffMin` | `Duration` | `1 second` | Minimum transport-level retry delay |
| `backoffMax` | `Duration` | `2 minutes` | Maximum transport-level retry delay |
| `maxRetries` | `int` | `5` | Maximum HTTP-level retries |

---

## Page Size (pageSize)

The `pageSize` parameter determines the number of records requested per HTTP call during pull operations and the number of operations fetched from the outbox per push cycle.

**Default value:** `500`

### Performance Impact

- **Pull:** determines the `limit` parameter in the server request. Larger pages mean fewer HTTP requests but higher memory consumption for JSON parsing and DB writes.
- **Push:** determines the `limit` for `OutboxService.take()`. Operations from the outbox are fetched in batches of `pageSize` and sent to the server.

### Trade-offs

| Size | HTTP Calls | Memory | Single Page Latency |
|---|---|---|---|
| Small (50-100) | Many | Low | Low |
| Medium (500) | Moderate | Moderate | Medium |
| Large (1000-5000) | Few | High | High |

### Scenario Recommendations

```dart
// Mobile app: conserve memory
final config = SyncConfig(pageSize: 200);

// Desktop app: balanced
final config = SyncConfig(pageSize: 500); // default value

// Background sync on server: maximum throughput
final config = SyncConfig(pageSize: 2000);
```

---

## Concurrent Push (pushConcurrency)

The `pushConcurrency` parameter in `RestTransport` controls the number of simultaneously executing push requests.

**Default value:** `1` (sequential sending)

### How It Works

When `pushConcurrency == 1`, operations are sent strictly sequentially one after another.
When `pushConcurrency > 1`, operations are grouped into chunks of `pushConcurrency` and sent in parallel via `Future.wait()`:

```dart
// From rest_transport.dart, push() method:
if (pushConcurrency > 1) {
  for (var i = 0; i < ops.length; i += pushConcurrency) {
    final end = (i + pushConcurrency).clamp(0, ops.length);
    final chunk = ops.sublist(i, end);
    final chunkResults = await Future.wait(
      chunk.map((op) async {
        return await _pushSingleOp(op, auth);
      }),
    );
  }
}
```

### When to Increase

- Many small operations in the outbox (tens to hundreds)
- The server supports concurrent requests without degradation
- High-latency network (each request waits for a response)

### Impact on Order

When `pushConcurrency > 1`, the execution order of operations within a single chunk is not guaranteed. If order is critical (e.g., creating a parent before a child record), use `pushConcurrency: 1`.

### Configuration Examples

```dart
// Sequential sending (default, strict order)
final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer $token',
  pushConcurrency: 1,
);

// Parallel sending (5 concurrent requests)
final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer $token',
  pushConcurrency: 5,
);

// Aggressive parallelization (for background tasks)
final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer $token',
  pushConcurrency: 10,
);
```

### Resource Impact

| pushConcurrency | Network Connections | Server Load | Speed |
|---|---|---|---|
| 1 | 1 | Minimal | Baseline |
| 3-5 | 3-5 | Moderate | 2-4x |
| 10+ | 10+ | High | 5-8x |

---

## Batch Push

Batch mode sends multiple operations in a single HTTP request to the `/{batchPath}` endpoint.

### Configuration

```dart
final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer $token',
  enableBatch: true,   // enable batch mode (default: false)
  batchSize: 100,      // max operations per request (default: 100)
  batchPath: 'batch',  // endpoint path (default: 'batch')
);
```

### How Batch Push Works

Operations are split into chunks of `batchSize`. Each chunk is sent as a single POST request. If `pushConcurrency > 1`, chunks are processed in parallel:

```dart
// Example: 250 operations, batchSize=100, pushConcurrency=2
// Chunk 1: 100 operations  }
// Chunk 2: 100 operations  } sent in parallel
// Chunk 3:  50 operations    sent separately
```

### When to Use Batch

**Batch is beneficial:**
- Many small operations (tens to hundreds of upsert/delete)
- The server API supports a batch endpoint
- Need to minimize the number of HTTP round-trips

**Individual sending is better:**
- Large payload per operation
- Immediate feedback per operation is needed
- The server does not support batch API
- Strict send order is important

### Performance Comparison

| Scenario | Without Batch | Batch (100) | Batch (100) + Concurrency 3 |
|---|---|---|---|
| 10 operations | 10 requests | 1 request | 1 request |
| 100 operations | 100 requests | 1 request | 1 request |
| 500 operations | 500 requests | 5 requests | 2 requests |

---

## Retry and Backoff (Two-Level Architecture)

The retry system operates on **two independent levels**. This is important for understanding error behavior:

1. **RestTransport._withRetry()** (HTTP level) -- retries individual HTTP requests on 429/5xx.
   Respects the `Retry-After` header from the server. Wraps every network call.
2. **PushService._pushBatch()** (sync engine level) -- retries the entire batch on exception.
   Triggers when RestTransport has exhausted its retries and thrown an exception.

In the worst case, the total number of HTTP requests per operation:
`maxRetries(RestTransport) x maxPushRetries(SyncConfig)` = `5 x 5 = 25` requests.

When configuring both levels, consider the cumulative wait time.

### Default Values

| Parameter | SyncConfig | RestTransport |
|---|---|---|
| Min delay | `1 second` | `1 second` |
| Max delay | `2 minutes` | `2 minutes` |
| Multiplier | `2.0` | `2.0` (hardcoded) |
| Max attempts | `5` | `5` |

### Delay Calculation

Formula from `PushService._pushBatch()`:

```
delay = backoffMin * (backoffMultiplier ^ (attempt - 1))
if delay > backoffMax, then delay = backoffMax
```

Delay table with default parameters (`backoffMin=1s`, `backoffMultiplier=2.0`, `backoffMax=120s`):

| Attempt | Calculation | Delay |
|---|---|---|
| 1 | `1s * 2^0` | 1 second |
| 2 | `1s * 2^1` | 2 seconds |
| 3 | `1s * 2^2` | 4 seconds |
| 4 | `1s * 2^3` | 8 seconds |
| 5 | `1s * 2^4` | 16 seconds |

Total wait time over 5 attempts: ~31 seconds.

### When to Change maxPushRetries

```dart
// Stable server, fast error detection
final config = SyncConfig(maxPushRetries: 3);

// Unstable network (mobile app)
final config = SyncConfig(maxPushRetries: 7);

// Critical data, maximum reliability
final config = SyncConfig(
  maxPushRetries: 10,
  backoffMax: Duration(minutes: 5),
);
```

### Impact on Sync Duration

| maxPushRetries | backoffMultiplier | Max Wait Time |
|---|---|---|
| 3 | 2.0 | ~7 seconds |
| 5 | 2.0 | ~31 seconds |
| 7 | 2.0 | ~127 seconds |
| 5 | 1.5 | ~12 seconds |
| 5 | 3.0 | ~121 seconds |

### Retry-After

`RestTransport` respects the `Retry-After` header from the server. If the server returns this header, its value is used instead of the calculated backoff, but clamped to the `[backoffMin, backoffMax]` range.

---

## Auto Sync Interval

The `startAuto()` method starts periodic synchronization via `Timer.periodic`.

**Default value:** `5 minutes`

```dart
// From sync_engine.dart:
void startAuto({Duration interval = const Duration(minutes: 5)}) {
  stopAuto();
  _autoTimer = Timer.periodic(interval, (_) => sync());
}
```

### Recommendations by Application Type

| Application Type | Interval | Rationale |
|---|---|---|
| Messenger / chat | 15-30 seconds | Data freshness is critical |
| Task tracker | 2-5 minutes | Balance of freshness and resources |
| Documents / notes | 10-15 minutes | Infrequent changes, battery savings |
| IoT / telemetry | 30-60 minutes | Minimize traffic |

### Examples

```dart
// Chat app: frequent sync
engine.startAuto(interval: Duration(seconds: 30));

// Task manager: medium frequency
engine.startAuto(interval: Duration(minutes: 5)); // default value

// Notes app: infrequent sync
engine.startAuto(interval: Duration(minutes: 15));
```

### Trade-offs

| Frequency | Battery | Traffic | Data Freshness |
|---|---|---|---|
| 15-30 sec | High consumption | High | Maximum |
| 2-5 min | Moderate | Moderate | Good |
| 10-15 min | Low | Low | Acceptable |
| 30-60 min | Minimal | Minimal | Low |

---

## Full Resync

Full resync resets all cursors and reloads all data from the server.

**Default interval:** `7 days`

### When Full Resync Occurs

From `SyncEngine._doSync()`: before each sync, a check is made whether `fullResyncInterval` has elapsed since the last full resync. If so, a full resync is triggered instead of an incremental one.

```dart
final lastFullResync = await _cursorService.getLastFullResync();
final needsFullResync =
    lastFullResync == null ||
    started.difference(lastFullResync) >= _config.fullResyncInterval;
```

### Configuring the Interval

```dart
// Frequent full resyncs (data is frequently modified by external systems)
final config = SyncConfig(fullResyncInterval: Duration(days: 1));

// Standard interval (default)
final config = SyncConfig(fullResyncInterval: Duration(days: 7));

// Infrequent resyncs (large data volume, stable server)
final config = SyncConfig(fullResyncInterval: Duration(days: 30));

// Practically disable automatic full resync
final config = SyncConfig(fullResyncInterval: Duration(days: 365));
```

### Cost of Full Resync

Full resync is expensive because:
1. It resets all cursors (`_cursorService.resetAll()`)
2. It may clear local tables (if `clearData: true`)
3. It loads all records from the server page by page

For a table with 100,000 records and `pageSize: 500` -- that is a minimum of 200 HTTP requests.

### Manual Full Resync

```dart
// Without clearing data (default):
// cursors are reset, pull overwrites data via insertOrReplace
await engine.fullResync();

// With clearing: all local data is deleted before pull
await engine.fullResync(clearData: true);
```

---

## Outbox Cleanup

`OutboxService.purgeOlderThan()` removes operations from the outbox older than the specified threshold.

```dart
// Remove operations older than 7 days
final deleted = await engine.outbox.purgeOlderThan(
  DateTime.now().subtract(Duration(days: 7)),
);
```

### Cleanup Strategy

| Retention Period | Use Case |
|---|---|
| 1-3 days | Mobile app with frequent sync |
| 7 days | Standard option |
| 30 days | App that works offline for weeks |

### Impact of Outbox Size on Performance

A large outbox slows down sync:
- `OutboxService.take()` fetches records in batches of `pageSize`
- Each batch is processed, sent, and acknowledged
- The cycle repeats until the outbox is empty

```dart
// Recommended: periodically clean the outbox
Timer.periodic(Duration(hours: 6), (_) async {
  final threshold = DateTime.now().subtract(Duration(days: 7));
  await engine.outbox.purgeOlderThan(threshold);
});
```

---

## Performance Monitoring

### Extracting Timing from SyncCompleted

The `SyncCompleted` event contains the sync duration and statistics:

```dart
engine.events.listen((event) {
  if (event is SyncCompleted) {
    final duration = event.took;
    final timestamp = event.at;
    final stats = event.stats;

    print('Sync completed in ${duration.inMilliseconds}ms');
    print('Pushed: ${stats?.pushed}, Pulled: ${stats?.pulled}');
    print('Conflicts: ${stats?.conflicts}, Resolved: ${stats?.conflictsResolved}');
    print('Errors: ${stats?.errors}');
  }
});
```

### Tracking Push/Pull Statistics

`SyncStats` provides counters:
- `pushed` -- number of successfully pushed operations
- `pulled` -- number of received records
- `conflicts` -- number of detected conflicts
- `conflictsResolved` -- number of successfully resolved conflicts
- `errors` -- number of errors

### Detecting Slow Syncs

```dart
engine.events.listen((event) {
  if (event is SyncCompleted) {
    if (event.took > Duration(seconds: 30)) {
      logWarning('Slow sync detected: ${event.took.inSeconds}s');
    }
  }
});
```

### Error Monitoring

```dart
int errorCount = 0;
DateTime? errorWindowStart;

engine.events.listen((event) {
  if (event is SyncErrorEvent) {
    errorWindowStart ??= DateTime.now();
    errorCount++;

    // Check error threshold
    final windowDuration = DateTime.now().difference(errorWindowStart!);
    if (windowDuration < Duration(minutes: 5) && errorCount > 10) {
      logAlert('High sync error rate: $errorCount errors in ${windowDuration.inSeconds}s');
      errorCount = 0;
      errorWindowStart = null;
    }
  }

  if (event is OperationFailedEvent) {
    logError(
      'Operation ${event.opId} failed for ${event.kind}/${event.entityId}, '
      'willRetry: ${event.willRetry}',
    );
  }
});
```

### Pull Progress Monitoring

```dart
engine.events.listen((event) {
  if (event is SyncProgress && event.phase == SyncPhase.pull) {
    print('Pull progress: ${event.done} records');
  }

  if (event is CacheUpdateEvent) {
    print('Cache update [${event.kind}]: '
        '+${event.upserts} upserts, -${event.deletes} deletes');
  }
});
```

---

## Optimization for Large Datasets

### Selective Sync

The `sync()` method accepts a `kinds` parameter to sync only specified types:

```dart
// Sync only critical tables
await engine.sync(kinds: {'users', 'messages'});

// Less important tables -- less frequently
Timer.periodic(Duration(minutes: 30), (_) async {
  await engine.sync(kinds: {'audit_logs', 'analytics'});
});
```

This allows:
- Prioritizing important data
- Reducing load during frequent sync
- Splitting sync into stages

### Cursor-based Pagination Efficiency

The pull service uses cursor-based pagination based on `updatedSince` + `afterId`. This means:
- Only records changed since the last pull are requested
- No data duplication between pages
- Each subsequent sync requests only the delta

```dart
// Cursor is saved after each page
await _cursorService.set(kind, Cursor(ts: since, lastId: afterId));
```

### Preventing Full Table Scans

To ensure the server API works efficiently:
- Ensure the server has an index on `updatedAt` + `id` for each table
- Use `includeDeleted: true` (default) to correctly handle soft-delete without separate queries

---

## Network Optimization

### Reducing Round-Trips via Batch Push

The most effective way to reduce the number of HTTP requests:

```dart
final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer $token',
  enableBatch: true,
  batchSize: 100,
  pushConcurrency: 3,
);
```

### HTTP Client Reuse

By default, `RestTransport` creates a new `http.Client()`. To reuse connections, pass your own client:

```dart
import 'package:http/http.dart' as http;

// Single client for the entire app (keep-alive, connection pooling)
final httpClient = http.Client();

final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer $token',
  client: httpClient,
);

// Don't forget to close the client when done
// httpClient.close();
```

### Retry Timeout Configuration

```dart
// Fast failure on unstable network
final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer $token',
  maxRetries: 3,
  backoffMin: Duration(milliseconds: 500),
  backoffMax: Duration(seconds: 30),
);

// Persistent sending for critical data
final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer $token',
  maxRetries: 10,
  backoffMin: Duration(seconds: 2),
  backoffMax: Duration(minutes: 5),
);
```

---

## Scenario Recommendations

### Configuration Profiles

| Parameter | Mobile App | Desktop | Background Service | IoT Device |
|---|---|---|---|---|
| `pageSize` | 200 | 500 | 2000 | 100 |
| `pushConcurrency` | 1-3 | 3-5 | 5-10 | 1 |
| `enableBatch` | `true` | `true` | `true` | `false` |
| `batchSize` | 50 | 100 | 200 | -- |
| `maxPushRetries` | 5 | 3 | 7 | 10 |
| `backoffMin` | 1s | 1s | 500ms | 5s |
| `backoffMax` | 2min | 1min | 30s | 10min |
| `fullResyncInterval` | 7 days | 7 days | 1 day | 30 days |
| auto sync interval | 2-5 min | 1-3 min | 30 sec | 30-60 min |

### Mobile App

```dart
final config = SyncConfig(
  pageSize: 200,
  maxPushRetries: 5,
  fullResyncInterval: Duration(days: 7),
  pushImmediately: true,
);

final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer $token',
  pushConcurrency: 3,
  enableBatch: true,
  batchSize: 50,
);

final engine = SyncEngine(
  db: database,
  transport: transport,
  tables: tables,
  config: config,
);

engine.startAuto(interval: Duration(minutes: 3));
```

### Desktop App

```dart
final config = SyncConfig(
  pageSize: 500,
  maxPushRetries: 3,
  backoffMax: Duration(minutes: 1),
  fullResyncInterval: Duration(days: 7),
);

final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer $token',
  pushConcurrency: 5,
  enableBatch: true,
  batchSize: 100,
);

engine.startAuto(interval: Duration(minutes: 1));
```

### Background Service

```dart
final config = SyncConfig(
  pageSize: 2000,
  maxPushRetries: 7,
  backoffMin: Duration(milliseconds: 500),
  backoffMax: Duration(seconds: 30),
  fullResyncInterval: Duration(days: 1),
);

final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer $token',
  pushConcurrency: 10,
  enableBatch: true,
  batchSize: 200,
);

engine.startAuto(interval: Duration(seconds: 30));
```

### IoT Device

```dart
final config = SyncConfig(
  pageSize: 100,
  maxPushRetries: 10,
  backoffMin: Duration(seconds: 5),
  backoffMax: Duration(minutes: 10),
  fullResyncInterval: Duration(days: 30),
);

final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer $token',
  pushConcurrency: 1,
  enableBatch: false,
  maxRetries: 10,
);

engine.startAuto(interval: Duration(minutes: 60));
```
