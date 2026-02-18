---
title: "SyncEngine<DB extends GeneratedDatabase>"
description: "API documentation for SyncEngine<DB extends GeneratedDatabase> class from offline_first_sync_drift"
category: "Classes"
library: "offline_first_sync_drift"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift/lib/src/sync_engine.dart#L76"
outline: [2, 3]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# SyncEngine\<DB extends GeneratedDatabase\>

<div class="member-signature"><pre><code><span class="kw">class</span> <span class="fn">SyncEngine</span>&lt;DB <span class="kw">extends</span> <span class="type">GeneratedDatabase</span>&gt;</code></pre></div>

Synchronization engine: push → pull with pagination and conflict resolution.

The core engine that orchestrates the sync process between local database
and remote server. Handles:

- Pushing local changes from outbox to server
- Pulling remote changes with cursor-based pagination
- Conflict resolution with multiple strategies
- Automatic background sync

Example:

```dart
final engine = SyncEngine(
  db: database,
  transport: RestTransport(base: Uri.parse('https://api.example.com')),
  tables: [
    SyncableTable<Todo>(
      kind: 'todos',
      table: database.todos,
      fromJson: Todo.fromJson,
      toJson: (t) => t.toJson(),
      toInsertable: (t) => t.toInsertable(),
    ),
  ],
);

await engine.sync();
```

## Constructors {#section-constructors}

### SyncEngine() {#ctor-syncengine}

<div class="member-signature"><pre><code><span class="fn">SyncEngine</span>({
  <span class="kw">required</span> <span class="type">DB</span> <span class="param">db</span>,
  <span class="kw">required</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/TransportAdapter" class="type-link">TransportAdapter</a> <span class="param">transport</span>,
  <span class="kw">required</span> <span class="type">List</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable" class="type-link">SyncableTable</a>&lt;<span class="type">dynamic</span>&gt;&gt; <span class="param">tables</span>,
  <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncConfig" class="type-link">SyncConfig</a> <span class="param">config</span> = const SyncConfig(),
  <span class="type">Map</span>&lt;<span class="type">String</span>, <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/TableConflictConfig" class="type-link">TableConflictConfig</a>&gt;? <span class="param">tableConflictConfigs</span>,
})</code></pre></div>

:::details Implementation
```dart
SyncEngine({
  required DB db,
  required TransportAdapter transport,
  required List<SyncableTable<dynamic>> tables,
  SyncConfig config = const SyncConfig(),
  Map<String, TableConflictConfig>? tableConflictConfigs,
}) : _db = db,
     _transport = transport,
     _tables = _buildTablesMap(tables),
     _config = config,
     _tableConflictConfigs = tableConflictConfigs ?? {} {
  if (db is! SyncDatabaseMixin) {
    throw ArgumentError(
      'Database must implement SyncDatabaseMixin. '
      'Add "with SyncDatabaseMixin" to your database class.',
    );
  }

  _initServices();
}
```
:::

## Properties {#section-properties}

### cursors <Badge type="tip" text="no setter" /> {#prop-cursors}

<div class="member-signature"><pre><code><a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/CursorService" class="type-link">CursorService</a> <span class="kw">get</span> <span class="fn">cursors</span></code></pre></div>

Service for managing sync cursors.

:::details Implementation
```dart
CursorService get cursors => _cursorService;
```
:::

### events <Badge type="tip" text="no setter" /> {#prop-events}

<div class="member-signature"><pre><code><span class="type">Stream</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEvent" class="type-link">SyncEvent</a>&gt; <span class="kw">get</span> <span class="fn">events</span></code></pre></div>

Stream of sync events for monitoring progress and errors.

:::details Implementation
```dart
Stream<SyncEvent> get events => _events.stream;
```
:::

### hashCode <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-hashcode}

<div class="member-signature"><pre><code><span class="type">int</span> <span class="kw">get</span> <span class="fn">hashCode</span></code></pre></div>

The hash code for this object.

A hash code is a single integer which represents the state of the object
that affects [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEngine#operator-equals) comparisons.

All objects have hash codes.
The default hash code implemented by [Object](https://api.flutter.dev/flutter/dart-core/Object-class.html)
represents only the identity of the object,
the same way as the default [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEngine#operator-equals) implementation only considers objects
equal if they are identical (see [identityHashCode](https://api.flutter.dev/flutter/dart-core/identityHashCode.html)).

If [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEngine#operator-equals) is overridden to use the object state instead,
the hash code must also be changed to represent that state,
otherwise the object cannot be used in hash based data structures
like the default [Set](https://api.flutter.dev/flutter/dart-core/Set-class.html) and [Map](https://api.flutter.dev/flutter/dart-core/Map-class.html) implementations.

Hash codes must be the same for objects that are equal to each other
according to [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEngine#operator-equals).
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

If a subclass overrides [hashCode](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEngine#prop-hashcode), it should override the
[operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEngine#operator-equals) operator as well to maintain consistency.

*Inherited from Object.*

:::details Implementation
```dart
external int get hashCode;
```
:::

### outbox <Badge type="tip" text="no setter" /> {#prop-outbox}

<div class="member-signature"><pre><code><a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/OutboxService" class="type-link">OutboxService</a> <span class="kw">get</span> <span class="fn">outbox</span></code></pre></div>

Service for managing outbox operations.

:::details Implementation
```dart
OutboxService get outbox => _outboxService;
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

### dispose() {#dispose}

<div class="member-signature"><pre><code><span class="type">void</span> <span class="fn">dispose</span>()</code></pre></div>

Release resources.

IMPORTANT: Always call this method when done using the engine
to prevent memory leaks from the event stream controller.

:::details Implementation
```dart
void dispose() {
  stopAuto();
  _events.close();
}
```
:::

### dropStuckOperations() {#dropstuckoperations}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">dropStuckOperations</span>({<span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">kinds</span>})</code></pre></div>

Drop stuck operations from outbox.

:::details Implementation
```dart
Future<void> dropStuckOperations({Set<String>? kinds}) async {
  final stuck = await getStuckOperations(kinds: kinds);
  await _outboxService.ack(stuck.map((op) => op.opId));
}
```
:::

### fullResync() {#fullresync}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncStats" class="type-link">SyncStats</a>&gt; <span class="fn">fullResync</span>({<span class="type">bool</span> <span class="param">clearData</span> = <span class="kw">false</span>})</code></pre></div>

Perform a full resynchronization.

`clearData` — if true, clears local data before pull.
Default is false — data remains, cursors are reset,
then pull applies data on top (insertOrReplace).

If a full resync is already in progress, concurrent callers will
receive the same Future and share the result.

:::details Implementation
```dart
Future<SyncStats> fullResync({bool clearData = false}) {
  &#47;&#47; If full resync is already running, share the existing Future
  if (_fullResyncFuture != null) {
    return _fullResyncFuture!;
  }

  _fullResyncFuture = _doFullResync(
    reason: FullResyncReason.manual,
    clearData: clearData,
    started: DateTime.now(),
  );
  return _fullResyncFuture!.whenComplete(() => _fullResyncFuture = null);
}
```
:::

### getStuckOperations() {#getstuckoperations}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">List</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/Op" class="type-link">Op</a>&gt;&gt; <span class="fn">getStuckOperations</span>({<span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">kinds</span>})</code></pre></div>

Return operations that reached stuck threshold.

:::details Implementation
```dart
Future<List<Op>> getStuckOperations({Set<String>? kinds}) {
  return _outboxService.getStuck(
    minTryCount: _config.maxOutboxTryCount,
    kinds: kinds,
  );
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

### retryStuckOperations() {#retrystuckoperations}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">retryStuckOperations</span>({<span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">kinds</span>})</code></pre></div>

Reset retry counters for stuck operations.

:::details Implementation
```dart
Future<void> retryStuckOperations({Set<String>? kinds}) async {
  final stuck = await getStuckOperations(kinds: kinds);
  await _outboxService.resetTryCount(stuck.map((op) => op.opId));
}
```
:::

### startAuto() {#startauto}

<div class="member-signature"><pre><code><span class="type">void</span> <span class="fn">startAuto</span>({<span class="type">Duration</span> <span class="param">interval</span> = const Duration(minutes: 5)})</code></pre></div>

Start automatic periodic synchronization.

`interval` — time between sync attempts (default: 5 minutes).

:::details Implementation
```dart
void startAuto({Duration interval = const Duration(minutes: 5)}) {
  stopAuto();
  _autoTimer = Timer.periodic(interval, (_) => sync());
}
```
:::

### stopAuto() {#stopauto}

<div class="member-signature"><pre><code><span class="type">void</span> <span class="fn">stopAuto</span>()</code></pre></div>

Stop automatic synchronization.

:::details Implementation
```dart
void stopAuto() {
  _autoTimer?.cancel();
  _autoTimer = null;
}
```
:::

### sync() {#sync}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncStats" class="type-link">SyncStats</a>&gt; <span class="fn">sync</span>({
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">kinds</span>,
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">pushKinds</span>,
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">pullKinds</span>,
})</code></pre></div>

Perform synchronization.

`pushKinds` — if specified, push only these entity kinds.
`pullKinds` — if specified, pull only these entity kinds.

`kinds` is a legacy alias that applies the same filter to push and pull.
Use `pushKinds`/`pullKinds` for explicit behavior.

If a sync is already in progress, concurrent callers will receive
the same Future and share the result, avoiding duplicate operations.

:::details Implementation
```dart
Future<SyncStats> sync({
  @Deprecated('Use pushKinds&#47;pullKinds instead.') Set<String>? kinds,
  Set<String>? pushKinds,
  Set<String>? pullKinds,
}) {
  if (kinds != null && (pushKinds != null || pullKinds != null)) {
    throw ArgumentError(
      'Do not combine legacy "kinds" with "pushKinds"&#47;"pullKinds".',
    );
  }

  final targetPushKinds = pushKinds ?? kinds;
  final targetPullKinds = pullKinds ?? kinds;

  final runFuture = _ensureSyncRun(
    pushKinds: targetPushKinds,
    pullKinds: targetPullKinds,
  );
  return runFuture.then((r) => r.stats);
}
```
:::

### syncRun() {#syncrun}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncRunResult" class="type-link">SyncRunResult</a>&gt; <span class="fn">syncRun</span>({
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">kinds</span>,
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">pushKinds</span>,
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">pullKinds</span>,
})</code></pre></div>

Perform synchronization and return structured run metadata.

:::details Implementation
```dart
Future<SyncRunResult> syncRun({
  @Deprecated('Use pushKinds&#47;pullKinds instead.') Set<String>? kinds,
  Set<String>? pushKinds,
  Set<String>? pullKinds,
}) async {
  if (kinds != null && (pushKinds != null || pullKinds != null)) {
    throw ArgumentError(
      'Do not combine legacy "kinds" with "pushKinds"&#47;"pullKinds".',
    );
  }
  final targetPushKinds = pushKinds ?? kinds;
  final targetPullKinds = pullKinds ?? kinds;
  return _ensureSyncRun(
    pushKinds: targetPushKinds,
    pullKinds: targetPullKinds,
  );
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

### watchPendingPushCount() {#watchpendingpushcount}

<div class="member-signature"><pre><code><span class="type">Stream</span>&lt;<span class="type">int</span>&gt; <span class="fn">watchPendingPushCount</span>({
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">kinds</span>,
  <span class="type">bool</span> <span class="param">includeStuck</span> = <span class="kw">false</span>,
})</code></pre></div>

Reactive count of pending operations (excluding stuck by default).

:::details Implementation
```dart
Stream<int> watchPendingPushCount({
  Set<String>? kinds,
  bool includeStuck = false,
}) {
  return _outboxService.watchPendingCount(
    kinds: kinds,
    maxTryCountExclusive: includeStuck ? null : _config.maxOutboxTryCount,
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

