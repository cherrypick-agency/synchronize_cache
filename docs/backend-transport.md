---
sidebar_position: 7
---
# Backend and Transport

A guide for backend developers on implementing a server API compatible with `offline_first_sync_drift`, and for client developers on configuring the transport layer.

---

## REST API Contract

The client library expects a specific set of endpoints from the server. Each endpoint is described below with exact request and response formats.

### Pull: Fetching Data

```
GET /{kind}
```

Fetches a list of entities from the server with pagination and incremental sync support.

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|:---:|-------------|
| `updatedSince` | `string` (ISO 8601) | yes | Return records where `updated_at >= value` |
| `limit` | `int` | yes | Maximum number of records per page |
| `pageToken` | `string` | no | Next page token (from previous response) |
| `afterId` | `string` | no | ID of the last element for cursor-based pagination |
| `includeDeleted` | `bool` | no | Include soft-deleted records (defaults to `true`) |

**Request Headers:**

```http
GET /tasks?updatedSince=2025-01-01T00:00:00.000Z&limit=500&includeDeleted=true
Accept: application/json
Authorization: Bearer eyJhbGciOi...
```

**Response Format (200 OK):**

```json
{
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Buy milk",
      "done": false,
      "updated_at": "2025-01-15T10:00:00Z"
    },
    {
      "id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
      "title": "Call mom",
      "done": true,
      "updated_at": "2025-01-15T10:05:00Z",
      "deleted_at": "2025-01-15T11:00:00Z"
    }
  ],
  "nextPageToken": "eyJ0cyI6IjIwMjUtMDEtMTVUMTA6MDU6MDBaIiwibGFzdElkIjoiNmJhN2..."
}
```

- `items` — array of JSON objects. Each object must contain `id` and `updated_at` (or `updatedAt`).
- `nextPageToken` — string for requesting the next page. `null` if this is the last page.
- Sorting: `ORDER BY updated_at ASC, id ASC` — required for stable pagination.

**Response Codes:**

| Code | Description |
|------|-------------|
| 200 | Success |
| 401 | Unauthorized |
| 429 | Rate limit (client will automatically retry, see `Retry-After`) |
| 5xx | Server error (client will automatically retry) |

---

### Push: Creating/Updating a Single Entity

```
PUT /{kind}/{id}
```

Creates or updates an entity (upsert). The client generates the `id` (UUID) itself.

**Request Headers:**

| Header | Description |
|--------|-------------|
| `Authorization` | Authorization token |
| `Content-Type` | `application/json` |
| `X-Idempotency-Key` | Operation UUID (`opId`) for duplicate protection |
| `X-Force-Update` | `true` — skip conflict checks (after client-side merge) |

**Request Body:**

```json
{
  "title": "Buy milk",
  "done": true,
  "_baseUpdatedAt": "2025-01-15T10:00:00Z"
}
```

- `_baseUpdatedAt` — timestamp of the version the client based its changes on. The server compares it with the current `updated_at` of the record to detect conflicts. Absent for new records.

**Response Format (200 OK / 201 Created):**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Buy milk",
  "done": true,
  "updated_at": "2025-01-15T12:00:00Z"
}
```

Optional `ETag` header with record version:

```http
HTTP/1.1 200 OK
ETag: "v3"
Content-Type: application/json
```

**Response Codes:**

| Code | Description |
|------|-------------|
| 200 | Updated |
| 201 | Created (upsert of a new record) |
| 404 | Not found (if id is empty, POST is used) |
| 409 | Version conflict (see "Conflicts" section) |
| 429 | Rate limit |
| 5xx | Server error |

---

### Push: Creating a New Entity (Without id)

```
POST /{kind}
```

Rarely used—only when the client does not generate an `id`. In most cases the client uses `PUT` with a pre-generated UUID.

**Request Body:**

```json
{
  "title": "New task",
  "done": false
}
```

**Response (201 Created):**

```json
{
  "id": "server-generated-uuid",
  "title": "New task",
  "done": false,
  "updated_at": "2025-01-15T12:00:00Z"
}
```

---

### Force Push: Forced Update

```
PUT /{kind}/{id}
```

Same endpoint as regular push, but with the `X-Force-Update: true` header (for upsert) or `X-Force-Delete: true` (for deletion).

```http
PUT /tasks/550e8400-e29b-41d4-a716-446655440000
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json
X-Idempotency-Key: op-789
X-Force-Update: true

{
  "title": "Buy milk and bread",
  "done": true
}
```

When the server sees `X-Force-Update: true`, it **skips** the `_baseUpdatedAt` check and saves the data unconditionally. The client sends a force push after merging conflicting data on its side.

---

### Delete: Deleting an Entity

```
DELETE /{kind}/{id}
```

**Request Headers:**

| Header | Description |
|--------|-------------|
| `Authorization` | Authorization token |
| `X-Idempotency-Key` | Operation UUID |
| `X-Force-Delete` | `true` — skip conflict checks |

**Query Parameters:**

| Parameter | Description |
|-----------|-------------|
| `_baseUpdatedAt` | Version timestamp for conflict detection |

**Example Request:**

```http
DELETE /tasks/550e8400-e29b-41d4-a716-446655440000?_baseUpdatedAt=2025-01-15T10:00:00Z
Authorization: Bearer eyJhbGciOi...
X-Idempotency-Key: op-456
```

**Response Codes:**

| Code | Description |
|------|-------------|
| 200 | Deleted (with response body) |
| 204 | Deleted (no body) |
| 404 | Not found |
| 409 | Version conflict |

---

### Fetch: Retrieving a Single Entity

```
GET /{kind}/{id}
```

Retrieves the current state of a single entity. Used by the client during conflict resolution (`serverWins` and `merge` strategies).

**Example Request:**

```http
GET /tasks/550e8400-e29b-41d4-a716-446655440000
Authorization: Bearer eyJhbGciOi...
Accept: application/json
```

**Response (200 OK):**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Buy milk",
  "done": true,
  "updated_at": "2025-01-15T12:00:00Z"
}
```

Optional `ETag` header:

```http
HTTP/1.1 200 OK
ETag: "v3"
```

**Response Codes:**

| Code | Description |
|------|-------------|
| 200 | Found (`FetchSuccess`) |
| 404 | Not found (`FetchNotFound`) |
| other | Error (`FetchError`) |

---

### Health: Availability Check

```
GET /health
```

**Example Request:**

```http
GET /health
Authorization: Bearer eyJhbGciOi...
Accept: application/json
```

**Response:**

Any `2xx` status means the server is available. The response body is irrelevant.

```json
{
  "status": "ok"
}
```

The client calls `health()` before starting synchronization to verify server availability.

---

## RestTransport Configuration

`RestTransport` — a ready-made `TransportAdapter` implementation for REST APIs. Located in the `offline_first_sync_drift_rest` package.

### Constructor Parameters

```dart
RestTransport({
  required Uri base,
  required AuthTokenProvider token,
  http.Client? client,
  Duration backoffMin = const Duration(seconds: 1),
  Duration backoffMax = const Duration(minutes: 2),
  int maxRetries = 5,
  int pushConcurrency = 1,
  bool enableBatch = false,
  int batchSize = 100,
  String batchPath = 'batch',
})
```

| Parameter | Type | Default | Description |
|-----------|------|:---:|-------------|
| `base` | `Uri` | — | Base API URL. All requests are built relative to it |
| `token` | `Future<String> Function()` | — | Function returning the `Authorization` header value |
| `client` | `http.Client?` | `http.Client()` | HTTP client. Useful for tests or adding interceptors |
| `backoffMin` | `Duration` | 1 second | Minimum delay between retries |
| `backoffMax` | `Duration` | 2 minutes | Maximum delay between retries |
| `maxRetries` | `int` | 5 | Maximum number of retry attempts |
| `pushConcurrency` | `int` | 1 | Number of parallel push requests. 1 = sequential |
| `enableBatch` | `bool` | `false` | Enable batch API (multiple operations in one request) |
| `batchSize` | `int` | 100 | Maximum number of operations per batch request |
| `batchPath` | `String` | `'batch'` | Batch endpoint path (relative to `base`) |

### Minimal Configuration

```dart
final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer ${await authService.getAccessToken()}',
);
```

### Configuration with Parallel Push

```dart
final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer ${await authService.getAccessToken()}',
  pushConcurrency: 5,
  maxRetries: 3,
  backoffMin: const Duration(milliseconds: 500),
  backoffMax: const Duration(seconds: 30),
);
```

With `pushConcurrency: 5` the client sends up to 5 operations in parallel. This significantly speeds up push when there is a large backlog of accumulated offline changes.

### Configuration with Batch API

```dart
final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer ${await authService.getAccessToken()}',
  enableBatch: true,
  batchSize: 50,
  batchPath: 'batch',
  pushConcurrency: 3,
);
```

With `enableBatch: true` the client groups operations into batch requests of `batchSize` items and can send multiple batches in parallel (`pushConcurrency`).

### Configuration with a Custom HTTP Client

```dart
import 'package:http/http.dart' as http;

// For example, to log requests
class LoggingClient extends http.BaseClient {
  LoggingClient(this._inner);
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    print('${request.method} ${request.url}');
    return _inner.send(request);
  }
}

final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer ${await authService.getAccessToken()}',
  client: LoggingClient(http.Client()),
);
```

---

## Server-Side Conflicts

A conflict occurs when a client attempts to update a record that has already been modified by another client (or the server) since the last pull.

### Detection Mechanism

1. The client receives a record with `updated_at: "2025-01-15T10:00:00Z"` during pull
2. The client modifies the record offline
3. Another client updates the same record, `updated_at` becomes `"2025-01-15T11:00:00Z"`
4. The first client sends a push with `_baseUpdatedAt: "2025-01-15T10:00:00Z"`
5. The server compares: `10:00:00 != 11:00:00` — conflict

### Server-Side Validation Algorithm

```
if (X-Force-Update != true)
  AND (_baseUpdatedAt exists)
  AND (existing.updated_at != _baseUpdatedAt)
then
  return 409 Conflict
```

### 409 Conflict Response Format

The client supports multiple response formats. Recommended:

```json
{
  "error": "conflict",
  "current": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Buy milk (updated by another device)",
    "done": false,
    "updated_at": "2025-01-15T11:00:00Z"
  }
}
```

The client looks for server data in the following priority order:
1. `body["current"]` — recommended format
2. `body["serverData"]` — alternative format
3. `body` as a whole — fallback

Server timestamp is extracted from:
1. `body["serverTimestamp"]`
2. `current["updatedAt"]` or `current["updated_at"]`

Server version (optional):
1. `body["version"]`
2. `current["version"]`
3. `ETag` header

### What Happens After a 409 on the Client

Depending on the configured `ConflictStrategy`:

| Strategy | Behavior |
|----------|----------|
| `serverWins` | Accepts the server version, discards local changes |
| `clientWins` | Retries push with `X-Force-Update: true` |
| `lastWriteWins` | Compares timestamps, the later one wins |
| `merge` | Calls `mergeFunction`, sends the result with force |
| `autoPreserve` | Smart merge without data loss, then force push |
| `manual` | Calls `conflictResolver` callback |

---

## Idempotency

### X-Idempotency-Key Header

The client sends a unique `opId` (UUID) in the `X-Idempotency-Key` header with every push and delete operation. This ensures that resending the same operation (e.g., after a network loss) does not create duplicates.

```http
PUT /tasks/abc-123
X-Idempotency-Key: 7f3d2a1b-4e5c-6d8f-9a0b-1c2d3e4f5a6b
Content-Type: application/json

{"title": "Task", "done": false}
```

### Why Idempotency Matters for Offline Sync

1. The client sends an operation, the server processes it
2. The connection drops before the client receives a response
3. The client does not know whether the operation was processed
4. The operation remains in the outbox and is resent
5. Without idempotency this would create a duplicate or double update

### Server Requirements

```javascript
async function handlePut(req, res) {
  const idempotencyKey = req.header('x-idempotency-key');

  // 1. Check idempotency cache
  if (idempotencyKey) {
    const cached = await cache.get(`idempotency:${idempotencyKey}`);
    if (cached) return res.status(cached.statusCode).json(cached.body);
  }

  // 2. Process the request...
  const result = await processRequest(req);

  // 3. Cache the response for 24 hours
  if (idempotencyKey) {
    await cache.set(`idempotency:${idempotencyKey}`, {
      statusCode: result.status,
      body: result.data,
    }, 86400); // 24 hours
  }

  return res.status(result.status).json(result.data);
}
```

Recommendations:
- Store the cache for 24 hours (sufficient to cover extended offline periods)
- Cache key — `idempotency:{opId}`
- Cache the full response (status + body)
- For DELETE it is sufficient to store the execution flag

---

## Custom TransportAdapter

If your backend uses GraphQL, gRPC, WebSocket, or another protocol, you can implement a custom `TransportAdapter`.

### Abstract Interface

```dart
abstract interface class TransportAdapter {
  /// Fetch a page of data from the server.
  Future<PullPage> pull({
    required String kind,
    required DateTime updatedSince,
    required int pageSize,
    String? pageToken,
    String? afterId,
    bool includeDeleted = true,
  });

  /// Send operations to the server.
  /// Returns a result for each operation including conflicts.
  Future<BatchPushResult> push(List<Op> ops);

  /// Force-push an operation (ignore version conflict).
  /// Used for the clientWins strategy.
  Future<PushResult> forcePush(Op op);

  /// Fetch the current version of an entity from the server.
  Future<FetchResult> fetch({required String kind, required String id});

  /// Check server availability.
  Future<bool> health();
}
```

### Data Types

**PullPage** — pull request result:

```dart
class PullPage {
  PullPage({required this.items, this.nextPageToken});

  final List<Map<String, Object?>> items;
  final String? nextPageToken;
}
```

**Op** — sealed class of outbox operations:

```dart
sealed class Op {
  final String opId;          // Operation UUID (for idempotency)
  final String kind;          // Entity type ("tasks", "notes")
  final String id;            // Entity ID
  final DateTime localTimestamp; // Operation creation time
}

class UpsertOp extends Op {
  final Map<String, Object?> payloadJson; // Data to send
  final DateTime? baseUpdatedAt;          // null = new record
  final Set<String>? changedFields;       // Changed fields (for merge)
}

class DeleteOp extends Op {
  final DateTime? baseUpdatedAt;
}
```

**PushResult** — sealed class of push results:

```dart
sealed class PushResult {}

class PushSuccess extends PushResult {
  final Map<String, Object?>? serverData;  // Data from the server
  final String? serverVersion;             // ETag/version
}

class PushConflict extends PushResult {
  final Map<String, Object?> serverData;   // Current data on the server
  final DateTime serverTimestamp;           // Server timestamp
  final String? serverVersion;
}

class PushNotFound extends PushResult {}

class PushError extends PushResult {
  final Object error;
  final StackTrace? stackTrace;
}
```

**BatchPushResult** — batch push result:

```dart
class BatchPushResult {
  final List<OpPushResult> results;

  bool get allSuccess => results.every((r) => r.isSuccess);
  bool get hasConflicts => results.any((r) => r.isConflict);
  bool get hasErrors => results.any((r) => r.isError);
}

class OpPushResult {
  final String opId;
  final PushResult result;
}
```

**FetchResult** — sealed class of fetch results:

```dart
sealed class FetchResult {}

class FetchSuccess extends FetchResult {
  final Map<String, Object?> data;
  final String? version;  // ETag
}

class FetchNotFound extends FetchResult {}

class FetchError extends FetchResult {
  final Object error;
  final StackTrace? stackTrace;
}
```

### Example: GraphQL TransportAdapter

```dart
import 'package:graphql/graphql.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

class GraphQLTransport implements TransportAdapter {
  GraphQLTransport({required this.client});

  final GraphQLClient client;

  @override
  Future<PullPage> pull({
    required String kind,
    required DateTime updatedSince,
    required int pageSize,
    String? pageToken,
    String? afterId,
    bool includeDeleted = true,
  }) async {
    final result = await client.query(QueryOptions(
      document: gql('''
        query Pull(\$kind: String!, \$updatedSince: DateTime!,
                    \$limit: Int!, \$cursor: String) {
          syncPull(kind: \$kind, updatedSince: \$updatedSince,
                   limit: \$limit, cursor: \$cursor) {
            items
            nextPageToken
          }
        }
      '''),
      variables: {
        'kind': kind,
        'updatedSince': updatedSince.toUtc().toIso8601String(),
        'limit': pageSize,
        'cursor': pageToken,
      },
    ));

    if (result.hasException) {
      throw NetworkException.fromError(result.exception!);
    }

    final data = result.data!['syncPull'];
    final items = (data['items'] as List)
        .cast<Map<String, Object?>>();

    return PullPage(
      items: items,
      nextPageToken: data['nextPageToken'] as String?,
    );
  }

  @override
  Future<BatchPushResult> push(List<Op> ops) async {
    final results = <OpPushResult>[];

    for (final op in ops) {
      final pushResult = await _pushSingle(op);
      results.add(OpPushResult(opId: op.opId, result: pushResult));
    }

    return BatchPushResult(results: results);
  }

  Future<PushResult> _pushSingle(Op op) async {
    try {
      if (op is UpsertOp) {
        final result = await client.mutate(MutationOptions(
          document: gql('''
            mutation Upsert(\$kind: String!, \$id: String!,
                            \$data: JSON!, \$baseUpdatedAt: DateTime) {
              syncUpsert(kind: \$kind, id: \$id, data: \$data,
                         baseUpdatedAt: \$baseUpdatedAt) {
                success
                conflict
                data
                serverTimestamp
              }
            }
          '''),
          variables: {
            'kind': op.kind,
            'id': op.id,
            'data': op.payloadJson,
            'baseUpdatedAt': op.baseUpdatedAt?.toUtc().toIso8601String(),
          },
        ));

        if (result.hasException) {
          return PushError(result.exception!);
        }

        final response = result.data!['syncUpsert'];

        if (response['conflict'] == true) {
          return PushConflict(
            serverData: (response['data'] as Map).cast<String, Object?>(),
            serverTimestamp: DateTime.parse(response['serverTimestamp']),
          );
        }

        return PushSuccess(
          serverData: (response['data'] as Map?)?.cast<String, Object?>(),
        );
      } else if (op is DeleteOp) {
        final result = await client.mutate(MutationOptions(
          document: gql('''
            mutation Delete(\$kind: String!, \$id: String!,
                            \$baseUpdatedAt: DateTime) {
              syncDelete(kind: \$kind, id: \$id,
                         baseUpdatedAt: \$baseUpdatedAt) {
                success
                notFound
                conflict
                data
                serverTimestamp
              }
            }
          '''),
          variables: {
            'kind': op.kind,
            'id': op.id,
            'baseUpdatedAt': op.baseUpdatedAt?.toUtc().toIso8601String(),
          },
        ));

        if (result.hasException) {
          return PushError(result.exception!);
        }

        final response = result.data!['syncDelete'];

        if (response['notFound'] == true) return const PushNotFound();

        if (response['conflict'] == true) {
          return PushConflict(
            serverData: (response['data'] as Map).cast<String, Object?>(),
            serverTimestamp: DateTime.parse(response['serverTimestamp']),
          );
        }

        return const PushSuccess();
      }

      return PushError(ArgumentError('Unknown op type: $op'));
    } catch (e, st) {
      return PushError(e, st);
    }
  }

  @override
  Future<PushResult> forcePush(Op op) async {
    // Same as _pushSingle, but with force: true parameter
    // Server skips conflict checks
    return _pushSingle(op); // simplified
  }

  @override
  Future<FetchResult> fetch({
    required String kind,
    required String id,
  }) async {
    try {
      final result = await client.query(QueryOptions(
        document: gql('''
          query Fetch(\$kind: String!, \$id: String!) {
            syncFetch(kind: \$kind, id: \$id) {
              found
              data
              version
            }
          }
        '''),
        variables: {'kind': kind, 'id': id},
      ));

      if (result.hasException) {
        return FetchError(result.exception!);
      }

      final response = result.data!['syncFetch'];

      if (response['found'] != true) return const FetchNotFound();

      return FetchSuccess(
        data: (response['data'] as Map).cast<String, Object?>(),
        version: response['version'] as String?,
      );
    } catch (e, st) {
      return FetchError(e, st);
    }
  }

  @override
  Future<bool> health() async {
    try {
      final result = await client.query(QueryOptions(
        document: gql('query { health }'),
      ));
      return !result.hasException;
    } catch (_) {
      return false;
    }
  }
}
```

---

## Pagination (Cursor-Based)

### Cursor Class

```dart
class Cursor {
  const Cursor({required this.ts, required this.lastId});

  final DateTime ts;    // Timestamp of the last element
  final String lastId;  // ID of the last element
}
```

The Cursor stores the last synchronization position for each `kind`. On the next pull, the client passes `updatedSince = cursor.ts` and `afterId = cursor.lastId`.

### How Cursor-Based Pagination Works

1. **First pull:** `updatedSince=1970-01-01T00:00:00Z`, `pageToken=null`, `afterId=null`
2. The server returns the first N records sorted by `(updated_at, id)`
3. If more records exist — it returns `nextPageToken`
4. The client requests the next page with `pageToken`
5. When `nextPageToken == null` — all data has been fetched
6. The client saves the cursor: `ts` and `lastId` from the last element
7. **Next pull:** `updatedSince = saved cursor.ts`, `afterId = cursor.lastId`

### Pagination Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `updatedSince` | `DateTime` (ISO 8601) | Get records updated since this moment |
| `limit` | `int` | Page size (defaults to 500 in `SyncConfig.pageSize`) |
| `pageToken` | `String?` | Next page token |
| `afterId` | `String?` | ID of the last element (for cursor) |

### Why Cursor Is Better Than Offset for Sync

**Offset-based pagination** (`OFFSET 100 LIMIT 50`):
- Records can shift when inserts/deletes happen between pages
- Records can be skipped or duplicated
- Performance degrades at large offsets

**Cursor-based pagination** (`WHERE (updated_at, id) > (cursor_ts, cursor_id)`):
- Stable: each record is guaranteed to be processed exactly once
- Unaffected by inserts/deletes between requests
- Performance is consistent at any position

### Server-Side Implementation

```sql
-- Cursor-based pagination (recommended)
SELECT * FROM tasks
WHERE updated_at >= :updatedSince
  AND (updated_at > :cursorTs OR (updated_at = :cursorTs AND id > :cursorId))
ORDER BY updated_at ASC, id ASC
LIMIT :pageSize;
```

```javascript
async function handleList(req, res) {
  const { kind } = req.params;
  const { updatedSince, pageToken, afterId } = req.query;
  const limit = parseInt(req.query.limit || '500', 10);

  let query = db(kind)
    .where('updated_at', '>=', updatedSince)
    .orderBy('updated_at', 'asc')
    .orderBy('id', 'asc');

  // Cursor-based pagination via afterId
  if (afterId && updatedSince) {
    query = query.where(function() {
      this.where('updated_at', '>', updatedSince)
        .orWhere(function() {
          this.where('updated_at', '=', updatedSince)
            .andWhere('id', '>', afterId);
        });
    });
  }

  // Or simple offset-based pagination via pageToken
  if (pageToken && !afterId) {
    const offset = parseInt(pageToken, 10);
    query = query.offset(offset);
  }

  const items = await query.limit(limit + 1); // +1 to check for next page
  const hasMore = items.length > limit;
  if (hasMore) items.pop();

  const nextPageToken = hasMore
    ? JSON.stringify({
        ts: items[items.length - 1].updated_at,
        lastId: items[items.length - 1].id,
      })
    : null;

  return res.json({ items, nextPageToken });
}
```

---

## Soft Delete

Soft delete is necessary for synchronization across multiple devices: the client needs to learn that a record was deleted on another device.

### The deleted_at Field on the Server

Instead of physically deleting a record, the server sets `deleted_at`:

```json
{
  "id": "abc-123",
  "title": "Deleted task",
  "done": false,
  "updated_at": "2025-01-15T12:00:00Z",
  "deleted_at": "2025-01-15T12:00:00Z"
}
```

### The includeDeleted Parameter in Pull

The client passes `includeDeleted=true` (default) to receive deleted records:

```http
GET /tasks?updatedSince=2025-01-01T00:00:00Z&limit=500&includeDeleted=true
```

The server must:
- When `includeDeleted=true` — return **all** records, including those where `deleted_at IS NOT NULL`
- When `includeDeleted=false` — return only records where `deleted_at IS NULL`

### Client-Side Handling

The client supports both formats: `deletedAt` (camelCase) and `deleted_at` (snake_case). When the client receives a record with `deleted_at != null`, it deletes it from the local database.

### Hard Delete vs Soft Delete

| | Hard Delete | Soft Delete |
|---|---|---|
| **Implementation** | `DELETE FROM table` | `UPDATE SET deleted_at = NOW()` |
| **Multi-device sync** | Not supported | Supported |
| **DB size** | Does not grow | Grows (cleanup needed) |
| **Recommendation** | Single device | Multiple devices |

If you use hard delete, the client will only learn about deletions during a full resync (`fullResyncInterval`, default 7 days).

---

## Batch Push

The Batch API allows sending multiple operations in a single HTTP request, reducing the number of round-trips and speeding up synchronization.

### Client Configuration

```dart
final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer ${await getToken()}',
  enableBatch: true,   // Enable batch mode
  batchSize: 50,       // Up to 50 operations per request
  batchPath: 'batch',  // POST /batch
  pushConcurrency: 3,  // Up to 3 batch requests in parallel
);
```

### Request Format

```http
POST /batch
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json
```

```json
{
  "ops": [
    {
      "opId": "op-001",
      "kind": "tasks",
      "id": "abc-123",
      "type": "upsert",
      "payload": {
        "title": "Buy milk",
        "done": true
      },
      "baseUpdatedAt": "2025-01-15T10:00:00Z"
    },
    {
      "opId": "op-002",
      "kind": "tasks",
      "id": "def-456",
      "type": "delete",
      "baseUpdatedAt": "2025-01-15T09:30:00Z"
    },
    {
      "opId": "op-003",
      "kind": "notes",
      "id": "ghi-789",
      "type": "upsert",
      "payload": {
        "text": "Note"
      }
    }
  ]
}
```

**Fields for each operation:**

| Field | Type | Description |
|-------|------|-------------|
| `opId` | `string` | Operation UUID (for idempotency and result matching) |
| `kind` | `string` | Entity type |
| `id` | `string` | Entity ID |
| `type` | `string` | `"upsert"` or `"delete"` |
| `payload` | `object?` | Data (upsert only) |
| `baseUpdatedAt` | `string?` | ISO 8601 timestamp for conflict detection |

### Response Format

```json
{
  "results": [
    {
      "opId": "op-001",
      "statusCode": 200,
      "data": {
        "id": "abc-123",
        "title": "Buy milk",
        "done": true,
        "updated_at": "2025-01-15T12:00:00Z"
      },
      "version": "v3"
    },
    {
      "opId": "op-002",
      "statusCode": 409,
      "error": {
        "error": "conflict",
        "current": {
          "id": "def-456",
          "title": "Modified task",
          "updated_at": "2025-01-15T11:30:00Z"
        }
      }
    },
    {
      "opId": "op-003",
      "statusCode": 201,
      "data": {
        "id": "ghi-789",
        "text": "Note",
        "updated_at": "2025-01-15T12:00:00Z"
      }
    }
  ]
}
```

**Fields for each result:**

| Field | Type | Description |
|-------|------|-------------|
| `opId` | `string` | Operation UUID (for matching with the request) |
| `statusCode` | `int` | HTTP status of the operation (200, 201, 404, 409, 500) |
| `data` | `object?` | Data on success |
| `version` | `string?` | Version/ETag on success |
| `error` | `object?` | Error object on 409 (same format as a single 409) |

The client parses each result by `statusCode`:
- `200-299` -> `PushSuccess`
- `404` -> `PushNotFound`
- `409` -> `PushConflict` (parses `error` as a conflict)
- Other -> `PushError`

### Performance Considerations

- Batch reduces the number of HTTP round-trips: 100 operations = 1 request instead of 100
- On the server, operations can be processed within a transaction
- `batchSize` limits the payload size to prevent timeouts
- With `pushConcurrency > 1`, multiple batches are sent in parallel

### Server-Side Implementation

```javascript
app.post('/batch', async (req, res) => {
  const { ops } = req.body;
  const results = [];

  for (const op of ops) {
    try {
      if (op.type === 'upsert') {
        const result = await handleUpsertOp(op);
        results.push({ opId: op.opId, ...result });
      } else if (op.type === 'delete') {
        const result = await handleDeleteOp(op);
        results.push({ opId: op.opId, ...result });
      }
    } catch (err) {
      results.push({
        opId: op.opId,
        statusCode: 500,
        error: { message: err.message },
      });
    }
  }

  return res.json({ results });
});

async function handleUpsertOp(op) {
  const existing = await db(op.kind).where({ id: op.id }).first();
  const now = new Date().toISOString();

  if (!existing) {
    await db(op.kind).insert({ ...op.payload, id: op.id, updated_at: now });
    const created = await db(op.kind).where({ id: op.id }).first();
    return { statusCode: 201, data: created };
  }

  if (op.baseUpdatedAt && existing.updated_at !== op.baseUpdatedAt) {
    return {
      statusCode: 409,
      error: { error: 'conflict', current: existing },
    };
  }

  await db(op.kind).where({ id: op.id }).update({
    ...op.payload,
    updated_at: now,
  });
  const updated = await db(op.kind).where({ id: op.id }).first();
  return { statusCode: 200, data: updated };
}

async function handleDeleteOp(op) {
  const existing = await db(op.kind).where({ id: op.id }).first();

  if (!existing) return { statusCode: 404 };

  if (op.baseUpdatedAt && existing.updated_at !== op.baseUpdatedAt) {
    return {
      statusCode: 409,
      error: { error: 'conflict', current: existing },
    };
  }

  await db(op.kind).where({ id: op.id }).delete();
  return { statusCode: 204 };
}
```

---

## Automatic Retries

`RestTransport` automatically retries requests on network errors and certain HTTP status codes.

### Which Codes Are Retried

- `429 Too Many Requests` — respecting the `Retry-After` header
- `500-599` — server errors

### Exponential Backoff

The delay between attempts doubles with each retry:

```
Attempt 1: 1 sec  (backoffMin)
Attempt 2: 2 sec
Attempt 3: 4 sec
Attempt 4: 8 sec
Attempt 5: 16 sec
... up to backoffMax (2 min by default)
```

If the server returns `Retry-After` (in seconds), the client uses that value instead of backoff.

### Server Recommendations

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 30
```

The `Retry-After` value is clamped to the `[backoffMin, backoffMax]` range on the client.
