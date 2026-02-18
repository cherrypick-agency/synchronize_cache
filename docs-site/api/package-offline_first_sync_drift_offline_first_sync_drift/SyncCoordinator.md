---
title: "SyncCoordinator"
description: "API documentation for SyncCoordinator class from offline_first_sync_drift"
category: "Classes"
library: "offline_first_sync_drift"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift/lib/src/sync_coordinator.dart#L10"
outline: [2, 3]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# SyncCoordinator

<div class="member-signature"><pre><code><span class="kw">class</span> <span class="fn">SyncCoordinator</span></code></pre></div>

Orchestrates sync triggers around [SyncEngine](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEngine).

This optional DX layer moves app-flow concerns (startup sync, periodic sync,
push debounce) out of [SyncConfig](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncConfig), keeping the engine focused on sync logic.

## Constructors {#section-constructors}

### SyncCoordinator() {#ctor-synccoordinator}

<div class="member-signature"><pre><code><span class="fn">SyncCoordinator</span>({
  <span class="kw">required</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEngine" class="type-link">SyncEngine</a>&lt;<span class="type">GeneratedDatabase</span>&gt; <span class="param">engine</span>,
  <span class="type">bool</span> <span class="param">pullOnStartup</span> = <span class="kw">false</span>,
  <span class="type">Duration</span>? <span class="param">autoInterval</span>,
  <span class="type">bool</span> <span class="param">pushOnOutboxChanges</span> = <span class="kw">false</span>,
  <span class="type">Duration</span> <span class="param">pushDebounce</span> = const Duration(seconds: 2),
  <span class="type">Duration</span> <span class="param">outboxPollInterval</span> = const Duration(seconds: 1),
})</code></pre></div>

:::details Implementation
```dart
SyncCoordinator({
  required SyncEngine engine,
  this.pullOnStartup = false,
  this.autoInterval,
  this.pushOnOutboxChanges = false,
  this.pushDebounce = const Duration(seconds: 2),
  @Deprecated('Polling is replaced by outbox streams.')
  this.outboxPollInterval = const Duration(seconds: 1),
}) : _engine = engine;
```
:::

### SyncCoordinator.fromLegacyConfig() <Badge type="tip" text="factory" /> {#fromlegacyconfig}

<div class="member-signature"><pre><code><span class="kw">factory</span> <span class="fn">SyncCoordinator.fromLegacyConfig</span>({
  <span class="kw">required</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEngine" class="type-link">SyncEngine</a>&lt;<span class="type">GeneratedDatabase</span>&gt; <span class="param">engine</span>,
  <span class="kw">required</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncConfig" class="type-link">SyncConfig</a> <span class="param">config</span>,
  <span class="type">Duration</span>? <span class="param">outboxPollInterval</span>,
  <span class="type">Duration</span>? <span class="param">pushDebounce</span>,
})</code></pre></div>

Build coordinator behavior from legacy [SyncConfig](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncConfig) flags.

:::details Implementation
```dart
factory SyncCoordinator.fromLegacyConfig({
  required SyncEngine engine,
  required SyncConfig config,
  Duration? outboxPollInterval,
  Duration? pushDebounce,
}) {
  return SyncCoordinator(
    engine: engine,
    pullOnStartup: config.pullOnStartup,
    autoInterval: config.reconcileInterval,
    pushOnOutboxChanges: config.pushImmediately,
    outboxPollInterval: outboxPollInterval ?? const Duration(seconds: 1),
    pushDebounce: pushDebounce ?? const Duration(seconds: 2),
  );
}
```
:::

## Properties {#section-properties}

### autoInterval <Badge type="tip" text="final" /> {#prop-autointerval}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Duration</span>? <span class="fn">autoInterval</span></code></pre></div>

Start periodic full syncs with this interval.

:::details Implementation
```dart
final Duration? autoInterval;
```
:::

### hashCode <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-hashcode}

<div class="member-signature"><pre><code><span class="type">int</span> <span class="kw">get</span> <span class="fn">hashCode</span></code></pre></div>

The hash code for this object.

A hash code is a single integer which represents the state of the object
that affects [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncCoordinator#operator-equals) comparisons.

All objects have hash codes.
The default hash code implemented by [Object](https://api.flutter.dev/flutter/dart-core/Object-class.html)
represents only the identity of the object,
the same way as the default [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncCoordinator#operator-equals) implementation only considers objects
equal if they are identical (see [identityHashCode](https://api.flutter.dev/flutter/dart-core/identityHashCode.html)).

If [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncCoordinator#operator-equals) is overridden to use the object state instead,
the hash code must also be changed to represent that state,
otherwise the object cannot be used in hash based data structures
like the default [Set](https://api.flutter.dev/flutter/dart-core/Set-class.html) and [Map](https://api.flutter.dev/flutter/dart-core/Map-class.html) implementations.

Hash codes must be the same for objects that are equal to each other
according to [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncCoordinator#operator-equals).
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

If a subclass overrides [hashCode](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncCoordinator#prop-hashcode), it should override the
[operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncCoordinator#operator-equals) operator as well to maintain consistency.

*Inherited from Object.*

:::details Implementation
```dart
external int get hashCode;
```
:::

### <Badge type="warning" text="deprecated" /> ~~outboxPollInterval~~ <Badge type="tip" text="final" /> {#prop-outboxpollinterval}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Duration</span> <span class="fn">outboxPollInterval</span></code></pre></div>

:::warning DEPRECATED
Polling is replaced by outbox streams.
:::

Polling interval used when [pushOnOutboxChanges](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncCoordinator#prop-pushonoutboxchanges) is enabled.

:::details Implementation
```dart
@Deprecated('Polling is replaced by outbox streams.')
final Duration outboxPollInterval;
```
:::

### pullOnStartup <Badge type="tip" text="final" /> {#prop-pullonstartup}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">bool</span> <span class="fn">pullOnStartup</span></code></pre></div>

Run pull-only sync once on [start](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncCoordinator#start).

:::details Implementation
```dart
final bool pullOnStartup;
```
:::

### pushDebounce <Badge type="tip" text="final" /> {#prop-pushdebounce}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Duration</span> <span class="fn">pushDebounce</span></code></pre></div>

Debounce delay before push-only sync.

:::details Implementation
```dart
final Duration pushDebounce;
```
:::

### pushOnOutboxChanges <Badge type="tip" text="final" /> {#prop-pushonoutboxchanges}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">bool</span> <span class="fn">pushOnOutboxChanges</span></code></pre></div>

Poll outbox and push when there are pending operations.

:::details Implementation
```dart
final bool pushOnOutboxChanges;
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

Dispose coordinator timers. Does not dispose the engine.

:::details Implementation
```dart
void dispose() {
  if (_disposed) return;
  stop();
  _disposed = true;
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

### start() {#start}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">start</span>()</code></pre></div>

Start coordinator automation.

:::details Implementation
```dart
Future<void> start() async {
  _ensureNotDisposed();
  if (_started) return;
  _started = true;

  if (pullOnStartup) {
    await _engine.sync(pushKinds: const <String>{});
  }

  if (autoInterval != null) {
    _engine.startAuto(interval: autoInterval!);
  }

  if (pushOnOutboxChanges) {
    _outboxSubscription = _engine.watchPendingPushCount().distinct().listen(
      _onOutboxPendingCountChanged,
    );
  }
}
```
:::

### stop() {#stop}

<div class="member-signature"><pre><code><span class="type">void</span> <span class="fn">stop</span>()</code></pre></div>

Stop coordinator automation.

:::details Implementation
```dart
void stop() {
  if (!_started) return;
  _started = false;
  _engine.stopAuto();
  _outboxSubscription?.cancel();
  _outboxSubscription = null;
  _pushDebounceTimer?.cancel();
  _pushDebounceTimer = null;
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

