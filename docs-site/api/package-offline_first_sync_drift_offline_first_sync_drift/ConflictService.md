---
title: "ConflictService<DB extends GeneratedDatabase>"
description: "API documentation for ConflictService<DB extends GeneratedDatabase> class from offline_first_sync_drift"
category: "Classes"
library: "offline_first_sync_drift"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift/lib/src/services/conflict_service.dart#L23"
outline: [2, 3]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# ConflictService\<DB extends GeneratedDatabase\>

<div class="member-signature"><pre><code><span class="kw">class</span> <span class="fn">ConflictService</span>&lt;DB <span class="kw">extends</span> <span class="type">GeneratedDatabase</span>&gt;</code></pre></div>

Service for sync conflict resolution.

## Constructors {#section-constructors}

### ConflictService() {#ctor-conflictservice}

<div class="member-signature"><pre><code><span class="fn">ConflictService</span>({
  <span class="kw">required</span> <span class="type">DB</span> <span class="param">db</span>,
  <span class="kw">required</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/TransportAdapter" class="type-link">TransportAdapter</a> <span class="param">transport</span>,
  <span class="kw">required</span> <span class="type">Map</span>&lt;<span class="type">String</span>, <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable" class="type-link">SyncableTable</a>&lt;<span class="type">dynamic</span>&gt;&gt; <span class="param">tables</span>,
  <span class="kw">required</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncConfig" class="type-link">SyncConfig</a> <span class="param">config</span>,
  <span class="kw">required</span> <span class="type">Map</span>&lt;<span class="type">String</span>, <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/TableConflictConfig" class="type-link">TableConflictConfig</a>&gt; <span class="param">tableConflictConfigs</span>,
  <span class="kw">required</span> <span class="type">StreamController</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEvent" class="type-link">SyncEvent</a>&gt; <span class="param">events</span>,
})</code></pre></div>

:::details Implementation
```dart
ConflictService({
  required DB db,
  required TransportAdapter transport,
  required Map<String, SyncableTable<dynamic>> tables,
  required SyncConfig config,
  required Map<String, TableConflictConfig> tableConflictConfigs,
  required StreamController<SyncEvent> events,
}) : _db = db,
     _transport = transport,
     _tables = tables,
     _config = config,
     _tableConflictConfigs = tableConflictConfigs,
     _events = events;
```
:::

## Properties {#section-properties}

### hashCode <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-hashcode}

<div class="member-signature"><pre><code><span class="type">int</span> <span class="kw">get</span> <span class="fn">hashCode</span></code></pre></div>

The hash code for this object.

A hash code is a single integer which represents the state of the object
that affects [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictService#operator-equals) comparisons.

All objects have hash codes.
The default hash code implemented by [Object](https://api.flutter.dev/flutter/dart-core/Object-class.html)
represents only the identity of the object,
the same way as the default [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictService#operator-equals) implementation only considers objects
equal if they are identical (see [identityHashCode](https://api.flutter.dev/flutter/dart-core/identityHashCode.html)).

If [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictService#operator-equals) is overridden to use the object state instead,
the hash code must also be changed to represent that state,
otherwise the object cannot be used in hash based data structures
like the default [Set](https://api.flutter.dev/flutter/dart-core/Set-class.html) and [Map](https://api.flutter.dev/flutter/dart-core/Map-class.html) implementations.

Hash codes must be the same for objects that are equal to each other
according to [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictService#operator-equals).
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

If a subclass overrides [hashCode](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictService#prop-hashcode), it should override the
[operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictService#operator-equals) operator as well to maintain consistency.

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

### resolve() {#resolve}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictResolutionResult" class="type-link">ConflictResolutionResult</a>&gt; <span class="fn">resolve</span>(<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/Op" class="type-link">Op</a> <span class="param">op</span>, <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/PushConflict" class="type-link">PushConflict</a> <span class="param">serverConflict</span>)</code></pre></div>

Resolve conflict for an operation.

:::details Implementation
```dart
Future<ConflictResolutionResult> resolve(
  Op op,
  PushConflict serverConflict,
) async {
  final tableConfig = _tableConflictConfigs[op.kind];
  final strategy = tableConfig?.strategy ?? _config.conflictStrategy;

  final localData = op is UpsertOp ? op.payloadJson : <String, Object?>{};
  final changedFields = op is UpsertOp ? op.changedFields : null;

  final conflict = Conflict(
    kind: op.kind,
    entityId: op.id,
    opId: op.opId,
    localData: localData,
    serverData: serverConflict.serverData,
    localTimestamp: op.localTimestamp,
    serverTimestamp: serverConflict.serverTimestamp,
    serverVersion: serverConflict.serverVersion,
    changedFields: changedFields,
  );

  _events.add(ConflictDetectedEvent(conflict: conflict, strategy: strategy));

  final resolution = await _determineResolution(
    conflict,
    strategy,
    tableConfig,
  );

  return _applyResolution(op, conflict, resolution);
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

