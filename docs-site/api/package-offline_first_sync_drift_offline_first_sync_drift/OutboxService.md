---
title: "OutboxService"
description: "API documentation for OutboxService class from offline_first_sync_drift"
category: "Classes"
library: "offline_first_sync_drift"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift/lib/src/services/outbox_service.dart#L6"
outline: [2, 3]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# OutboxService

<div class="member-signature"><pre><code><span class="kw">class</span> <span class="fn">OutboxService</span></code></pre></div>

Service for working with the outbox queue.

## Constructors {#section-constructors}

### OutboxService() {#ctor-outboxservice}

<div class="member-signature"><pre><code><span class="fn">OutboxService</span>(<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseMixin" class="type-link">SyncDatabaseMixin</a> <span class="param">_db</span>)</code></pre></div>

:::details Implementation
```dart
OutboxService(this._db);
```
:::

## Properties {#section-properties}

### hashCode <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-hashcode}

<div class="member-signature"><pre><code><span class="type">int</span> <span class="kw">get</span> <span class="fn">hashCode</span></code></pre></div>

The hash code for this object.

A hash code is a single integer which represents the state of the object
that affects [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/OutboxService#operator-equals) comparisons.

All objects have hash codes.
The default hash code implemented by [Object](https://api.flutter.dev/flutter/dart-core/Object-class.html)
represents only the identity of the object,
the same way as the default [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/OutboxService#operator-equals) implementation only considers objects
equal if they are identical (see [identityHashCode](https://api.flutter.dev/flutter/dart-core/identityHashCode.html)).

If [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/OutboxService#operator-equals) is overridden to use the object state instead,
the hash code must also be changed to represent that state,
otherwise the object cannot be used in hash based data structures
like the default [Set](https://api.flutter.dev/flutter/dart-core/Set-class.html) and [Map](https://api.flutter.dev/flutter/dart-core/Map-class.html) implementations.

Hash codes must be the same for objects that are equal to each other
according to [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/OutboxService#operator-equals).
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

If a subclass overrides [hashCode](/api/package-offline_first_sync_drift_offline_first_sync_drift/OutboxService#prop-hashcode), it should override the
[operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/OutboxService#operator-equals) operator as well to maintain consistency.

*Inherited from Object.*

:::details Implementation
```dart
external int get hashCode;
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

## Methods {#section-methods}

### ack() {#ack}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">ack</span>(<span class="type">Iterable</span>&lt;<span class="type">String</span>&gt; <span class="param">opIds</span>)</code></pre></div>

Acknowledge sent operations (remove from queue).

:::details Implementation
```dart
Future<void> ack(Iterable<String> opIds) async {
  if (opIds.isEmpty) return;
  try {
    await _db.ackOutbox(opIds);
  } catch (e, st) {
    throw DatabaseException.fromError(e, st);
  }
}
```
:::

### countStuck() {#countstuck}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">int</span>&gt; <span class="fn">countStuck</span>({<span class="kw">required</span> <span class="type">int</span> <span class="param">minTryCount</span>, <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">kinds</span>})</code></pre></div>

Count operations treated as stuck.

:::details Implementation
```dart
Future<int> countStuck({required int minTryCount, Set<String>? kinds}) async {
  try {
    return await _db.countStuckOutbox(minTryCount: minTryCount, kinds: kinds);
  } catch (e, st) {
    throw DatabaseException.fromError(e, st);
  }
}
```
:::

### enqueue() {#enqueue}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">enqueue</span>(<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/Op" class="type-link">Op</a> <span class="param">op</span>)</code></pre></div>

Add operation to the send queue.

:::details Implementation
```dart
Future<void> enqueue(Op op) async {
  try {
    await _db.enqueue(op);
  } catch (e, st) {
    throw DatabaseException.fromError(e, st);
  }
}
```
:::

### getStuck() {#getstuck}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">List</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/Op" class="type-link">Op</a>&gt;&gt; <span class="fn">getStuck</span>({
  <span class="kw">required</span> <span class="type">int</span> <span class="param">minTryCount</span>,
  <span class="type">int</span> <span class="param">limit</span> = <span class="num-lit">100</span>,
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">kinds</span>,
})</code></pre></div>

Get operations treated as stuck.

:::details Implementation
```dart
Future<List<Op>> getStuck({
  required int minTryCount,
  int limit = 100,
  Set<String>? kinds,
}) async {
  try {
    return await _db.getStuckOutbox(
      minTryCount: minTryCount,
      limit: limit,
      kinds: kinds,
    );
  } catch (e, st) {
    throw DatabaseException.fromError(e, st);
  }
}
```
:::

### hasOperations() {#hasoperations}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">bool</span>&gt; <span class="fn">hasOperations</span>({<span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">kinds</span>})</code></pre></div>

Check whether queue contains operations.

:::details Implementation
```dart
Future<bool> hasOperations({Set<String>? kinds}) async {
  final ops = await take(limit: 1, kinds: kinds);
  return ops.isNotEmpty;
}
```
:::

### incrementTryCount() {#incrementtrycount}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">incrementTryCount</span>(<span class="type">Iterable</span>&lt;<span class="type">String</span>&gt; <span class="param">opIds</span>)</code></pre></div>

Increment try count for operations.

:::details Implementation
```dart
Future<void> incrementTryCount(Iterable<String> opIds) async {
  try {
    await _db.incrementOutboxTryCount(opIds);
  } catch (e, st) {
    throw DatabaseException.fromError(e, st);
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

### purgeOlderThan() {#purgeolderthan}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">int</span>&gt; <span class="fn">purgeOlderThan</span>(<span class="type">DateTime</span> <span class="param">threshold</span>)</code></pre></div>

Purge operations older than threshold.

:::details Implementation
```dart
Future<int> purgeOlderThan(DateTime threshold) async {
  try {
    return await _db.purgeOutboxOlderThan(threshold);
  } catch (e, st) {
    throw DatabaseException.fromError(e, st);
  }
}
```
:::

### recordFailures() {#recordfailures}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">recordFailures</span>(<span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">String</span>&gt; <span class="param">errors</span>, {<span class="type">DateTime</span>? <span class="param">triedAt</span>})</code></pre></div>

Record per-operation failures: increments tryCount and stores metadata.

:::details Implementation
```dart
Future<void> recordFailures(
  Map<String, String> errors, {
  DateTime? triedAt,
}) async {
  try {
    await _db.recordOutboxFailures(errors, triedAt: triedAt);
  } catch (e, st) {
    throw DatabaseException.fromError(e, st);
  }
}
```
:::

### resetTryCount() {#resettrycount}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">resetTryCount</span>(<span class="type">Iterable</span>&lt;<span class="type">String</span>&gt; <span class="param">opIds</span>)</code></pre></div>

Reset try count for operations.

:::details Implementation
```dart
Future<void> resetTryCount(Iterable<String> opIds) async {
  try {
    await _db.resetOutboxTryCount(opIds);
  } catch (e, st) {
    throw DatabaseException.fromError(e, st);
  }
}
```
:::

### take() {#take}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">List</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/Op" class="type-link">Op</a>&gt;&gt; <span class="fn">take</span>({
  <span class="type">int</span> <span class="param">limit</span> = <span class="num-lit">100</span>,
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">kinds</span>,
  <span class="type">int</span>? <span class="param">maxTryCountExclusive</span>,
})</code></pre></div>

Get operations from queue for sending.

If `kinds` is provided, only operations for those kinds are returned.

:::details Implementation
```dart
Future<List<Op>> take({
  int limit = 100,
  Set<String>? kinds,
  int? maxTryCountExclusive,
}) async {
  try {
    return await _db.takeOutbox(
      limit: limit,
      kinds: kinds,
      maxTryCountExclusive: maxTryCountExclusive,
    );
  } catch (e, st) {
    throw DatabaseException.fromError(e, st);
  }
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

### watchHasOperations() {#watchhasoperations}

<div class="member-signature"><pre><code><span class="type">Stream</span>&lt;<span class="type">bool</span>&gt; <span class="fn">watchHasOperations</span>({<span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">kinds</span>, <span class="type">int</span>? <span class="param">maxTryCountExclusive</span>})</code></pre></div>

Reactive stream indicating whether pending operations exist.

:::details Implementation
```dart
Stream<bool> watchHasOperations({
  Set<String>? kinds,
  int? maxTryCountExclusive,
}) {
  return watchPendingCount(
    kinds: kinds,
    maxTryCountExclusive: maxTryCountExclusive,
  ).map((count) => count > 0);
}
```
:::

### watchPendingCount() {#watchpendingcount}

<div class="member-signature"><pre><code><span class="type">Stream</span>&lt;<span class="type">int</span>&gt; <span class="fn">watchPendingCount</span>({<span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">kinds</span>, <span class="type">int</span>? <span class="param">maxTryCountExclusive</span>})</code></pre></div>

Reactive stream of pending operations count.

:::details Implementation
```dart
Stream<int> watchPendingCount({
  Set<String>? kinds,
  int? maxTryCountExclusive,
}) {
  return _db.watchOutboxCount(
    kinds: kinds,
    maxTryCountExclusive: maxTryCountExclusive,
  );
}
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

