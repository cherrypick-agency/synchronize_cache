---
title: "RestTransport"
description: "API documentation for RestTransport class from offline_first_sync_drift_rest"
category: "Classes"
library: "offline_first_sync_drift_rest"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift_rest/lib/src/rest_transport.dart#L28"
outline: [2, 3]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# RestTransport

<div class="member-signature"><pre><code><span class="kw">class</span> <span class="fn">RestTransport</span> <span class="kw">implements</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/TransportAdapter" class="type-link">TransportAdapter</a></code></pre></div>

REST implementation of [TransportAdapter](/api/package-offline_first_sync_drift_offline_first_sync_drift/TransportAdapter) with full conflict resolution support.

Features:

- Automatic retry with exponential backoff
- Parallel push support via [pushConcurrency](/api/package-offline_first_sync_drift_rest_offline_first_sync_drift_rest/RestTransport#prop-pushconcurrency)
- Batch API support via [enableBatch](/api/package-offline_first_sync_drift_rest_offline_first_sync_drift_rest/RestTransport#prop-enablebatch)
- Conflict detection with `409 Conflict` response handling
- Force push headers (`X-Force-Update`, `X-Force-Delete`)
- Idempotency support via `X-Idempotency-Key` header

Example:

```dart
final transport = RestTransport(
  base: Uri.parse('https://api.example.com'),
  token: () async => 'Bearer ${await getToken()}',
  pushConcurrency: 5,
);
```

:::info Implemented types
- [TransportAdapter](/api/package-offline_first_sync_drift_offline_first_sync_drift/TransportAdapter)
:::

## Constructors {#section-constructors}

### RestTransport() {#ctor-resttransport}

<div class="member-signature"><pre><code><span class="fn">RestTransport</span>({
  <span class="kw">required</span> <span class="type">Uri</span> <span class="param">base</span>,
  <span class="kw">required</span> <span class="type">Future</span>&lt;<span class="type">String</span>&gt; <span class="type">Function</span>() <span class="param">token</span>,
  <span class="type">Client</span>? <span class="param">client</span>,
  <span class="type">Duration</span> <span class="param">backoffMin</span> = const Duration(seconds: 1),
  <span class="type">Duration</span> <span class="param">backoffMax</span> = const Duration(minutes: 2),
  <span class="type">int</span> <span class="param">maxRetries</span> = <span class="num-lit">5</span>,
  <span class="type">int</span> <span class="param">pushConcurrency</span> = <span class="num-lit">1</span>,
  <span class="type">bool</span> <span class="param">enableBatch</span> = <span class="kw">false</span>,
  <span class="type">int</span> <span class="param">batchSize</span> = <span class="num-lit">100</span>,
  <span class="type">String</span> <span class="param">batchPath</span> = <span class="str-lit">'batch'</span>,
})</code></pre></div>

Creates a new REST transport.

`base` is the base URL for all API requests.
`token` is a function that returns the authorization token.
`client` is an optional HTTP client (defaults to a new client).
`backoffMin` is the minimum retry delay (default: 1 second).
`backoffMax` is the maximum retry delay (default: 2 minutes).
`maxRetries` is the maximum number of retry attempts (default: 5).
`pushConcurrency` is the number of parallel push requests (default: 1).
`enableBatch` enables batch API mode (default: false).
`batchSize` is the maximum operations per batch request (default: 100).
`batchPath` is the batch endpoint path (default: 'batch').

:::details Implementation
```dart
RestTransport({
  required this.base,
  required this.token,
  http.Client? client,
  this.backoffMin = const Duration(seconds: 1),
  this.backoffMax = const Duration(minutes: 2),
  this.maxRetries = 5,
  this.pushConcurrency = 1,
  this.enableBatch = false,
  this.batchSize = 100,
  this.batchPath = 'batch',
}) : client = client ?? http.Client();
```
:::

## Properties {#section-properties}

### backoffMax <Badge type="tip" text="final" /> {#prop-backoffmax}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Duration</span> <span class="fn">backoffMax</span></code></pre></div>

Maximum delay between retry attempts.

:::details Implementation
```dart
final Duration backoffMax;
```
:::

### backoffMin <Badge type="tip" text="final" /> {#prop-backoffmin}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Duration</span> <span class="fn">backoffMin</span></code></pre></div>

Minimum delay between retry attempts.

:::details Implementation
```dart
final Duration backoffMin;
```
:::

### base <Badge type="tip" text="final" /> {#prop-base}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Uri</span> <span class="fn">base</span></code></pre></div>

Base URL for all API requests.

:::details Implementation
```dart
final Uri base;
```
:::

### batchPath <Badge type="tip" text="final" /> {#prop-batchpath}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">String</span> <span class="fn">batchPath</span></code></pre></div>

Batch endpoint path (relative to [base](/api/package-offline_first_sync_drift_rest_offline_first_sync_drift_rest/RestTransport#prop-base)).

:::details Implementation
```dart
final String batchPath;
```
:::

### batchSize <Badge type="tip" text="final" /> {#prop-batchsize}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">int</span> <span class="fn">batchSize</span></code></pre></div>

Maximum operations per batch request.

:::details Implementation
```dart
final int batchSize;
```
:::

### client <Badge type="tip" text="final" /> {#prop-client}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Client</span> <span class="fn">client</span></code></pre></div>

HTTP client used for requests.

:::details Implementation
```dart
final http.Client client;
```
:::

### enableBatch <Badge type="tip" text="final" /> {#prop-enablebatch}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">bool</span> <span class="fn">enableBatch</span></code></pre></div>

Enable batch API mode.

:::details Implementation
```dart
final bool enableBatch;
```
:::

### hashCode <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-hashcode}

<div class="member-signature"><pre><code><span class="type">int</span> <span class="kw">get</span> <span class="fn">hashCode</span></code></pre></div>

The hash code for this object.

A hash code is a single integer which represents the state of the object
that affects [operator ==](/api/package-offline_first_sync_drift_rest_offline_first_sync_drift_rest/RestTransport#operator-equals) comparisons.

All objects have hash codes.
The default hash code implemented by [Object](https://api.flutter.dev/flutter/dart-core/Object-class.html)
represents only the identity of the object,
the same way as the default [operator ==](/api/package-offline_first_sync_drift_rest_offline_first_sync_drift_rest/RestTransport#operator-equals) implementation only considers objects
equal if they are identical (see [identityHashCode](https://api.flutter.dev/flutter/dart-core/identityHashCode.html)).

If [operator ==](/api/package-offline_first_sync_drift_rest_offline_first_sync_drift_rest/RestTransport#operator-equals) is overridden to use the object state instead,
the hash code must also be changed to represent that state,
otherwise the object cannot be used in hash based data structures
like the default [Set](https://api.flutter.dev/flutter/dart-core/Set-class.html) and [Map](https://api.flutter.dev/flutter/dart-core/Map-class.html) implementations.

Hash codes must be the same for objects that are equal to each other
according to [operator ==](/api/package-offline_first_sync_drift_rest_offline_first_sync_drift_rest/RestTransport#operator-equals).
The hash code of an object should only change if the object changes
in a way that affects equality.
There are no further requirements for the hash codes.
They need not be consistent between executions of the same program
and there are no distribution guarantees.

Objects that are not equal are allowed to have the same hash code.
It is even technically allowed that all instances have the same hash code,
but if clashes happen too often,
it may reduce the efficiency of hash-based data structures
like [HashSet](https://api.flutter.dev/flutter/dart-collection/HashSet-class.html) or [HashMap](https://api.flutter.dev/flutter/dart-collection/HashMap-class.html).

If a subclass overrides [hashCode](/api/package-offline_first_sync_drift_rest_offline_first_sync_drift_rest/RestTransport#prop-hashcode), it should override the
[operator ==](/api/package-offline_first_sync_drift_rest_offline_first_sync_drift_rest/RestTransport#operator-equals) operator as well to maintain consistency.

*Inherited from Object.*

:::details Implementation
```dart
external int get hashCode;
```
:::

### maxRetries <Badge type="tip" text="final" /> {#prop-maxretries}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">int</span> <span class="fn">maxRetries</span></code></pre></div>

Maximum number of retry attempts.

:::details Implementation
```dart
final int maxRetries;
```
:::

### pushConcurrency <Badge type="tip" text="final" /> {#prop-pushconcurrency}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">int</span> <span class="fn">pushConcurrency</span></code></pre></div>

Number of concurrent push requests.

If 1, requests are sent sequentially (default).
If > 1, requests are sent in parallel batches.

:::details Implementation
```dart
final int pushConcurrency;
```
:::

### runtimeType <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-runtimetype}

<div class="member-signature"><pre><code><span class="type">Type</span> <span class="kw">get</span> <span class="fn">runtimeType</span></code></pre></div>

A representation of the runtime type of the object.

*Inherited from Object.*

:::details Implementation
```dart
external Type get runtimeType;
```
:::

### token <Badge type="tip" text="final" /> {#prop-token}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Future</span>&lt;<span class="type">String</span>&gt; <span class="type">Function</span>() <span class="fn">token</span></code></pre></div>

Authorization token provider function.

:::details Implementation
```dart
final AuthTokenProvider token;
```
:::

## Methods {#section-methods}

### fetch() <Badge type="info" text="override" /> {#fetch}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/FetchResult" class="type-link">FetchResult</a>&gt; <span class="fn">fetch</span>({<span class="kw">required</span> <span class="type">String</span> <span class="param">kind</span>, <span class="kw">required</span> <span class="type">String</span> <span class="param">id</span>})</code></pre></div>

Fetches a single entity from the server.

Makes a GET request to `/{kind}/{id}`.
Returns [FetchSuccess](/api/package-offline_first_sync_drift_offline_first_sync_drift/FetchSuccess), [FetchNotFound](/api/package-offline_first_sync_drift_offline_first_sync_drift/FetchNotFound), or [FetchError](/api/package-offline_first_sync_drift_offline_first_sync_drift/FetchError).

:::details Implementation
```dart
@override
Future<FetchResult> fetch({required String kind, required String id}) async {
  try {
    final auth = await token();
    final uri = _url('$kind&#47;$id');

    final res = await _withRetry(
      () => client.get(uri, headers: _headers(auth)),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, Object?>;
      final version = res.headers['etag'];
      return FetchSuccess(data: data, version: version);
    }

    if (res.statusCode == 404) {
      return const FetchNotFound();
    }

    return FetchError(TransportException.httpError(res.statusCode, res.body));
  } on SyncException catch (e, st) {
    return FetchError(e, st);
  } catch (e, st) {
    return FetchError(NetworkException.fromError(e, st), st);
  }
}
```
:::

### forcePush() <Badge type="info" text="override" /> {#forcepush}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/PushResult" class="type-link">PushResult</a>&gt; <span class="fn">forcePush</span>(<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/Op" class="type-link">Op</a> <span class="param">op</span>)</code></pre></div>

Forces push of an operation, bypassing conflict detection.

Sends `X-Force-Update` or `X-Force-Delete` header.

:::details Implementation
```dart
@override
Future<PushResult> forcePush(Op op) async {
  final auth = await token();
  return _pushSingleOp(op, auth, force: true);
}
```
:::

### health() <Badge type="info" text="override" /> {#health}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">bool</span>&gt; <span class="fn">health</span>()</code></pre></div>

Checks server health.

Makes a GET request to `/health`.
Returns `true` if server responds with 2xx status.

:::details Implementation
```dart
@override
Future<bool> health() async {
  try {
    final auth = await token();
    final res = await client.get(_url('health'), headers: _headers(auth));
    return res.statusCode >= 200 && res.statusCode < 300;
  } catch (_) {
    return false;
  }
}
```
:::

### noSuchMethod() <Badge type="info" text="inherited" /> {#nosuchmethod}

<div class="member-signature"><pre><code><span class="type">dynamic</span> <span class="fn">noSuchMethod</span>(<span class="type">Invocation</span> <span class="param">invocation</span>)</code></pre></div>

Invoked when a nonexistent method or property is accessed.

A dynamic member invocation can attempt to call a member which
doesn't exist on the receiving object. Example:

```dart
dynamic object = 1;
object.add(42); // Statically allowed, run-time error
```

This invalid code will invoke the `noSuchMethod` method
of the integer `1` with an [Invocation](https://api.flutter.dev/flutter/dart-core/Invocation-class.html) representing the
`.add(42)` call and arguments (which then throws).

Classes can override [noSuchMethod](https://api.flutter.dev/flutter/dart-core/Object/noSuchMethod.html) to provide custom behavior
for such invalid dynamic invocations.

A class with a non-default [noSuchMethod](https://api.flutter.dev/flutter/dart-core/Object/noSuchMethod.html) invocation can also
omit implementations for members of its interface.
Example:

```dart
class MockList<T> implements List<T> {
  noSuchMethod(Invocation invocation) {
    log(invocation);
    super.noSuchMethod(invocation); // Will throw.
  }
}
void main() {
  MockList().add(42);
}
```

This code has no compile-time warnings or errors even though
the `MockList` class has no concrete implementation of
any of the `List` interface methods.
Calls to `List` methods are forwarded to `noSuchMethod`,
so this code will `log` an invocation similar to
`Invocation.method(#add, [42])` and then throw.

If a value is returned from `noSuchMethod`,
it becomes the result of the original invocation.
If the value is not of a type that can be returned by the original
invocation, a type error occurs at the invocation.

The default behavior is to throw a [NoSuchMethodError](https://api.flutter.dev/flutter/dart-core/NoSuchMethodError-class.html).

*Inherited from Object.*

:::details Implementation
```dart
@pragma("vm:entry-point")
@pragma("wasm:entry-point")
external dynamic noSuchMethod(Invocation invocation);
```
:::

### pull() <Badge type="info" text="override" /> {#pull}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/PullPage" class="type-link">PullPage</a>&gt; <span class="fn">pull</span>({
  <span class="kw">required</span> <span class="type">String</span> <span class="param">kind</span>,
  <span class="kw">required</span> <span class="type">DateTime</span> <span class="param">updatedSince</span>,
  <span class="kw">required</span> <span class="type">int</span> <span class="param">pageSize</span>,
  <span class="type">String</span>? <span class="param">pageToken</span>,
  <span class="type">String</span>? <span class="param">afterId</span>,
  <span class="type">bool</span> <span class="param">includeDeleted</span> = <span class="kw">true</span>,
})</code></pre></div>

Pulls entities from the server with pagination.

Makes a GET request to `/{kind}` with query parameters:

- `updatedSince`: ISO8601 timestamp
- `limit`: page size
- `pageToken`: next page token (if provided)
- `afterId`: cursor ID (if provided)
- `includeDeleted`: include soft-deleted entities

:::details Implementation
```dart
@override
Future<PullPage> pull({
  required String kind,
  required DateTime updatedSince,
  required int pageSize,
  String? pageToken,
  String? afterId,
  bool includeDeleted = true,
}) async {
  final auth = await token();
  final params = <String, String>{
    'updatedSince': updatedSince.toUtc().toIso8601String(),
    'limit': '$pageSize',
    'includeDeleted': includeDeleted ? 'true' : 'false',
  };
  if (pageToken != null) params['pageToken'] = pageToken;
  if (afterId != null) params['afterId'] = afterId;

  final res = await _withRetry(
    () => client.get(_url(kind, params), headers: _headers(auth)),
  );

  if (res.statusCode >= 200 && res.statusCode < 300) {
    final body = jsonDecode(res.body) as Map<String, Object?>;
    final items =
        (body['items'] as List<dynamic>? ?? []).cast<Map<String, Object?>>();
    final next = body['nextPageToken'] as String?;
    return PullPage(items: items, nextPageToken: next);
  }
  throw TransportException.httpError(res.statusCode, res.body);
}
```
:::

### push() <Badge type="info" text="override" /> {#push}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/BatchPushResult" class="type-link">BatchPushResult</a>&gt; <span class="fn">push</span>(<span class="type">List</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/Op" class="type-link">Op</a>&gt; <span class="param">ops</span>)</code></pre></div>

Pushes operations to the server.

If [enableBatch](/api/package-offline_first_sync_drift_rest_offline_first_sync_drift_rest/RestTransport#prop-enablebatch) is true, uses batch API.
If [pushConcurrency](/api/package-offline_first_sync_drift_rest_offline_first_sync_drift_rest/RestTransport#prop-pushconcurrency) > 1, sends requests in parallel.

Returns [BatchPushResult](/api/package-offline_first_sync_drift_offline_first_sync_drift/BatchPushResult) with results for each operation.

:::details Implementation
```dart
@override
Future<BatchPushResult> push(List<Op> ops) async {
  if (ops.isEmpty) {
    return const BatchPushResult(results: []);
  }

  final auth = await token();

  if (enableBatch) {
    return _pushBatch(ops, auth);
  }

  final results = <OpPushResult>[];

  if (pushConcurrency > 1) {
    &#47;&#47; Parallel push in chunks
    for (var i = 0; i < ops.length; i += pushConcurrency) {
      final end =
          (i + pushConcurrency < ops.length)
              ? i + pushConcurrency
              : ops.length;
      final chunk = ops.sublist(i, end);

      final chunkResults = await Future.wait(
        chunk.map((op) async {
          final result = await _pushSingleOp(op, auth);
          return OpPushResult(opId: op.opId, result: result);
        }),
      );
      results.addAll(chunkResults);
    }
  } else {
    &#47;&#47; Sequential push
    for (final op in ops) {
      final result = await _pushSingleOp(op, auth);
      results.add(OpPushResult(opId: op.opId, result: result));
    }
  }

  return BatchPushResult(results: results);
}
```
:::

### toString() <Badge type="info" text="inherited" /> {#tostring}

<div class="member-signature"><pre><code><span class="type">String</span> <span class="fn">toString</span>()</code></pre></div>

A string representation of this object.

Some classes have a default textual representation,
often paired with a static `parse` function (like [int.parse](https://api.flutter.dev/flutter/dart-core/int/parse.html)).
These classes will provide the textual representation as
their string representation.

Other classes have no meaningful textual representation
that a program will care about.
Such classes will typically override `toString` to provide
useful information when inspecting the object,
mainly for debugging or logging.

*Inherited from Object.*

:::details Implementation
```dart
external String toString();
```
:::

## Operators {#section-operators}

### operator ==() <Badge type="info" text="inherited" /> {#operator-equals}

<div class="member-signature"><pre><code><span class="type">bool</span> <span class="fn">operator ==</span>(<span class="type">Object</span> <span class="param">other</span>)</code></pre></div>

The equality operator.

The default behavior for all [Object](https://api.flutter.dev/flutter/dart-core/Object-class.html)s is to return true if and
only if this object and `other` are the same object.

Override this method to specify a different equality relation on
a class. The overriding method must still be an equivalence relation.
That is, it must be:

- Total: It must return a boolean for all arguments. It should never throw.

- Reflexive: For all objects `o`, `o == o` must be true.

- Symmetric: For all objects `o1` and `o2`, `o1 == o2` and `o2 == o1` must
either both be true, or both be false.

- Transitive: For all objects `o1`, `o2`, and `o3`, if `o1 == o2` and
`o2 == o3` are true, then `o1 == o3` must be true.

The method should also be consistent over time,
so whether two objects are equal should only change
if at least one of the objects was modified.

If a subclass overrides the equality operator, it should override
the [hashCode](https://api.flutter.dev/flutter/dart-core/Object/hashCode.html) method as well to maintain consistency.

*Inherited from Object.*

:::details Implementation
```dart
external bool operator ==(Object other);
```
:::

