---
title: "SyncRunResult"
description: "API documentation for SyncRunResult class from offline_first_sync_drift"
category: "Classes"
library: "offline_first_sync_drift"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift/lib/src/sync_engine.dart#L19"
outline: [2, 3]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# SyncRunResult

<div class="member-signature"><pre><code><span class="kw">class</span> <span class="fn">SyncRunResult</span></code></pre></div>

Rich result model for a sync run.

## Constructors {#section-constructors}

### SyncRunResult() <Badge type="tip" text="const" /> {#ctor-syncrunresult}

<div class="member-signature"><pre><code><span class="kw">const</span> <span class="fn">SyncRunResult</span>({
  <span class="kw">required</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/PushStats" class="type-link">PushStats</a> <span class="param">push</span>,
  <span class="kw">required</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/PullStats" class="type-link">PullStats</a> <span class="param">pull</span>,
  <span class="kw">required</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncStats" class="type-link">SyncStats</a> <span class="param">stats</span>,
  <span class="kw">required</span> <span class="type">Duration</span> <span class="param">duration</span>,
  <span class="kw">required</span> <span class="type">Set</span>&lt;<span class="type">String</span>&gt; <span class="param">kindsPushed</span>,
  <span class="kw">required</span> <span class="type">Set</span>&lt;<span class="type">String</span>&gt; <span class="param">kindsPulled</span>,
  <span class="kw">required</span> <span class="type">int</span> <span class="param">stuckOpsCount</span>,
  <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncErrorInfo" class="type-link">SyncErrorInfo</a>? <span class="param">firstError</span>,
})</code></pre></div>

:::details Implementation
```dart
const SyncRunResult({
  required this.push,
  required this.pull,
  required this.stats,
  required this.duration,
  required this.kindsPushed,
  required this.kindsPulled,
  required this.stuckOpsCount,
  this.firstError,
});
```
:::

## Properties {#section-properties}

### duration <Badge type="tip" text="final" /> {#prop-duration}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Duration</span> <span class="fn">duration</span></code></pre></div>

:::details Implementation
```dart
final Duration duration;
```
:::

### firstError <Badge type="tip" text="final" /> {#prop-firsterror}

<div class="member-signature"><pre><code><span class="kw">final</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncErrorInfo" class="type-link">SyncErrorInfo</a>? <span class="fn">firstError</span></code></pre></div>

:::details Implementation
```dart
final SyncErrorInfo? firstError;
```
:::

### hadErrors <Badge type="tip" text="no setter" /> {#prop-haderrors}

<div class="member-signature"><pre><code><span class="type">bool</span> <span class="kw">get</span> <span class="fn">hadErrors</span></code></pre></div>

:::details Implementation
```dart
bool get hadErrors => stats.errors > 0 || firstError != null;
```
:::

### hashCode <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-hashcode}

<div class="member-signature"><pre><code><span class="type">int</span> <span class="kw">get</span> <span class="fn">hashCode</span></code></pre></div>

The hash code for this object.

A hash code is a single integer which represents the state of the object
that affects [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncRunResult#operator-equals) comparisons.

All objects have hash codes.
The default hash code implemented by [Object](https://api.flutter.dev/flutter/dart-core/Object-class.html)
represents only the identity of the object,
the same way as the default [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncRunResult#operator-equals) implementation only considers objects
equal if they are identical (see [identityHashCode](https://api.flutter.dev/flutter/dart-core/identityHashCode.html)).

If [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncRunResult#operator-equals) is overridden to use the object state instead,
the hash code must also be changed to represent that state,
otherwise the object cannot be used in hash based data structures
like the default [Set](https://api.flutter.dev/flutter/dart-core/Set-class.html) and [Map](https://api.flutter.dev/flutter/dart-core/Map-class.html) implementations.

Hash codes must be the same for objects that are equal to each other
according to [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncRunResult#operator-equals).
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

If a subclass overrides [hashCode](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncRunResult#prop-hashcode), it should override the
[operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncRunResult#operator-equals) operator as well to maintain consistency.

*Inherited from Object.*

:::details Implementation
```dart
external int get hashCode;
```
:::

### kindsPulled <Badge type="tip" text="final" /> {#prop-kindspulled}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Set</span>&lt;<span class="type">String</span>&gt; <span class="fn">kindsPulled</span></code></pre></div>

:::details Implementation
```dart
final Set<String> kindsPulled;
```
:::

### kindsPushed <Badge type="tip" text="final" /> {#prop-kindspushed}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Set</span>&lt;<span class="type">String</span>&gt; <span class="fn">kindsPushed</span></code></pre></div>

:::details Implementation
```dart
final Set<String> kindsPushed;
```
:::

### pull <Badge type="tip" text="final" /> {#prop-pull}

<div class="member-signature"><pre><code><span class="kw">final</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/PullStats" class="type-link">PullStats</a> <span class="fn">pull</span></code></pre></div>

:::details Implementation
```dart
final PullStats pull;
```
:::

### push <Badge type="tip" text="final" /> {#prop-push}

<div class="member-signature"><pre><code><span class="kw">final</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/PushStats" class="type-link">PushStats</a> <span class="fn">push</span></code></pre></div>

:::details Implementation
```dart
final PushStats push;
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

### stats <Badge type="tip" text="final" /> {#prop-stats}

<div class="member-signature"><pre><code><span class="kw">final</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncStats" class="type-link">SyncStats</a> <span class="fn">stats</span></code></pre></div>

:::details Implementation
```dart
final SyncStats stats;
```
:::

### stuckOpsCount <Badge type="tip" text="final" /> {#prop-stuckopscount}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">int</span> <span class="fn">stuckOpsCount</span></code></pre></div>

:::details Implementation
```dart
final int stuckOpsCount;
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

