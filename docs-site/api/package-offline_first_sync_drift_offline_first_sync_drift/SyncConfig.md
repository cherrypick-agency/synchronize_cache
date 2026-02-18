---
title: "SyncConfig"
description: "API documentation for SyncConfig class from offline_first_sync_drift"
category: "Classes"
library: "offline_first_sync_drift"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift/lib/src/config.dart#L9"
outline: [2, 3]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# SyncConfig

<div class="member-signature"><pre><code><span class="kw">class</span> <span class="fn">SyncConfig</span></code></pre></div>

Synchronization configuration.

Configures all aspects of the sync engine behavior including:

- Pagination and retry logic
- Conflict resolution strategies
- Background sync intervals

## Constructors {#section-constructors}

### SyncConfig() <Badge type="tip" text="const" /> {#ctor-syncconfig}

<div class="member-signature"><pre><code><span class="kw">const</span> <span class="fn">SyncConfig</span>({
  <span class="type">int</span> <span class="param">pageSize</span> = <span class="num-lit">500</span>,
  <span class="type">Duration</span> <span class="param">backoffMin</span> = const Duration(seconds: 1),
  <span class="type">Duration</span> <span class="param">backoffMax</span> = const Duration(minutes: 2),
  <span class="type">double</span> <span class="param">backoffMultiplier</span> = <span class="num-lit">2.0</span>,
  <span class="type">int</span> <span class="param">maxPushRetries</span> = <span class="num-lit">5</span>,
  <span class="type">Duration</span> <span class="param">fullResyncInterval</span> = const Duration(days: 7),
  <span class="type">bool</span> <span class="param">pullOnStartup</span> = <span class="kw">false</span>,
  <span class="type">bool</span> <span class="param">pushImmediately</span> = <span class="kw">true</span>,
  <span class="type">Duration</span>? <span class="param">reconcileInterval</span>,
  <span class="type">bool</span> <span class="param">lazyReconcileOnMiss</span> = <span class="kw">false</span>,
  <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy" class="type-link">ConflictStrategy</a> <span class="param">conflictStrategy</span> = ConflictStrategy.autoPreserve,
  (<span class="type">Future</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictResolution" class="type-link">ConflictResolution</a>&gt; <span class="type">Function</span>(<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/Conflict" class="type-link">Conflict</a> <span class="param">conflict</span>))? <span class="param">conflictResolver</span>,
  (<span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="type">Function</span>(<span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="param">local</span>, <span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="param">server</span>))? <span class="param">mergeFunction</span>,
  <span class="type">int</span> <span class="param">maxConflictRetries</span> = <span class="num-lit">3</span>,
  <span class="type">Duration</span> <span class="param">conflictRetryDelay</span> = const Duration(milliseconds: 500),
  <span class="type">bool</span> <span class="param">skipConflictingOps</span> = <span class="kw">false</span>,
  <span class="type">int</span> <span class="param">maxOutboxTryCount</span> = <span class="num-lit">5</span>,
  <span class="type">bool</span> <span class="param">retryTransportErrorsInEngine</span> = <span class="kw">false</span>,
})</code></pre></div>

:::details Implementation
```dart
const SyncConfig({
  this.pageSize = 500,
  this.backoffMin = const Duration(seconds: 1),
  this.backoffMax = const Duration(minutes: 2),
  this.backoffMultiplier = 2.0,
  this.maxPushRetries = 5,
  this.fullResyncInterval = const Duration(days: 7),
  this.pullOnStartup = false,
  this.pushImmediately = true,
  this.reconcileInterval,
  this.lazyReconcileOnMiss = false,
  this.conflictStrategy = ConflictStrategy.autoPreserve,
  this.conflictResolver,
  this.mergeFunction,
  this.maxConflictRetries = 3,
  this.conflictRetryDelay = const Duration(milliseconds: 500),
  this.skipConflictingOps = false,
  this.maxOutboxTryCount = 5,
  this.retryTransportErrorsInEngine = false,
});
```
:::

## Properties {#section-properties}

### backoffMax <Badge type="tip" text="final" /> {#prop-backoffmax}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Duration</span> <span class="fn">backoffMax</span></code></pre></div>

Maximum delay for retry backoff.

:::details Implementation
```dart
final Duration backoffMax;
```
:::

### backoffMin <Badge type="tip" text="final" /> {#prop-backoffmin}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Duration</span> <span class="fn">backoffMin</span></code></pre></div>

Minimum delay for retry backoff.

:::details Implementation
```dart
final Duration backoffMin;
```
:::

### backoffMultiplier <Badge type="tip" text="final" /> {#prop-backoffmultiplier}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">double</span> <span class="fn">backoffMultiplier</span></code></pre></div>

Multiplier for exponential backoff.

:::details Implementation
```dart
final double backoffMultiplier;
```
:::

### conflictResolver <Badge type="tip" text="final" /> {#prop-conflictresolver}

<div class="member-signature"><pre><code><span class="kw">final</span> (<span class="type">Future</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictResolution" class="type-link">ConflictResolution</a>&gt; <span class="type">Function</span>(<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/Conflict" class="type-link">Conflict</a> <span class="param">conflict</span>))? <span class="fn">conflictResolver</span></code></pre></div>

Callback for manual conflict resolution.
Used when [conflictStrategy](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncConfig#prop-conflictstrategy) == [ConflictStrategy.manual](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy#value-manual).

:::details Implementation
```dart
final ConflictResolver? conflictResolver;
```
:::

### conflictRetryDelay <Badge type="tip" text="final" /> {#prop-conflictretrydelay}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Duration</span> <span class="fn">conflictRetryDelay</span></code></pre></div>

Delay between conflict resolution attempts.

:::details Implementation
```dart
final Duration conflictRetryDelay;
```
:::

### conflictStrategy <Badge type="tip" text="final" /> {#prop-conflictstrategy}

<div class="member-signature"><pre><code><span class="kw">final</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy" class="type-link">ConflictStrategy</a> <span class="fn">conflictStrategy</span></code></pre></div>

Default conflict resolution strategy.
Defaults to [ConflictStrategy.autoPreserve](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy#value-autopreserve) — automatic merge without data loss.

:::details Implementation
```dart
final ConflictStrategy conflictStrategy;
```
:::

### fullResyncInterval <Badge type="tip" text="final" /> {#prop-fullresyncinterval}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Duration</span> <span class="fn">fullResyncInterval</span></code></pre></div>

Interval for full resynchronization.

:::details Implementation
```dart
final Duration fullResyncInterval;
```
:::

### hashCode <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-hashcode}

<div class="member-signature"><pre><code><span class="type">int</span> <span class="kw">get</span> <span class="fn">hashCode</span></code></pre></div>

The hash code for this object.

A hash code is a single integer which represents the state of the object
that affects [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncConfig#operator-equals) comparisons.

All objects have hash codes.
The default hash code implemented by [Object](https://api.flutter.dev/flutter/dart-core/Object-class.html)
represents only the identity of the object,
the same way as the default [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncConfig#operator-equals) implementation only considers objects
equal if they are identical (see [identityHashCode](https://api.flutter.dev/flutter/dart-core/identityHashCode.html)).

If [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncConfig#operator-equals) is overridden to use the object state instead,
the hash code must also be changed to represent that state,
otherwise the object cannot be used in hash based data structures
like the default [Set](https://api.flutter.dev/flutter/dart-core/Set-class.html) and [Map](https://api.flutter.dev/flutter/dart-core/Map-class.html) implementations.

Hash codes must be the same for objects that are equal to each other
according to [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncConfig#operator-equals).
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

If a subclass overrides [hashCode](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncConfig#prop-hashcode), it should override the
[operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncConfig#operator-equals) operator as well to maintain consistency.

*Inherited from Object.*

:::details Implementation
```dart
external int get hashCode;
```
:::

### <Badge type="warning" text="deprecated" /> ~~lazyReconcileOnMiss~~ <Badge type="tip" text="final" /> {#prop-lazyreconcileonmiss}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">bool</span> <span class="fn">lazyReconcileOnMiss</span></code></pre></div>

:::warning DEPRECATED
Reserved for future API. Do not rely on this flag.
:::

Reserved for future use.

Deprecated until dedicated lazy-reconcile API is introduced.

:::details Implementation
```dart
@Deprecated('Reserved for future API. Do not rely on this flag.')
final bool lazyReconcileOnMiss;
```
:::

### maxConflictRetries <Badge type="tip" text="final" /> {#prop-maxconflictretries}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">int</span> <span class="fn">maxConflictRetries</span></code></pre></div>

Maximum number of conflict resolution attempts.

:::details Implementation
```dart
final int maxConflictRetries;
```
:::

### maxOutboxTryCount <Badge type="tip" text="final" /> {#prop-maxoutboxtrycount}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">int</span> <span class="fn">maxOutboxTryCount</span></code></pre></div>

Max attempt count before an outbox operation is considered stuck.

:::details Implementation
```dart
final int maxOutboxTryCount;
```
:::

### maxPushRetries <Badge type="tip" text="final" /> {#prop-maxpushretries}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">int</span> <span class="fn">maxPushRetries</span></code></pre></div>

Maximum number of push retry attempts.

:::details Implementation
```dart
final int maxPushRetries;
```
:::

### mergeFunction <Badge type="tip" text="final" /> {#prop-mergefunction}

<div class="member-signature"><pre><code><span class="kw">final</span> (<span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="type">Function</span>(<span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="param">local</span>, <span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="param">server</span>))? <span class="fn">mergeFunction</span></code></pre></div>

Data merge function.
Used when [conflictStrategy](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncConfig#prop-conflictstrategy) == [ConflictStrategy.merge](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy#value-merge).
If not specified, [ConflictUtils.defaultMerge](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictUtils#defaultmerge) is used.

:::details Implementation
```dart
final MergeFunction? mergeFunction;
```
:::

### pageSize <Badge type="tip" text="final" /> {#prop-pagesize}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">int</span> <span class="fn">pageSize</span></code></pre></div>

Page size for pull operations.

:::details Implementation
```dart
final int pageSize;
```
:::

### <Badge type="warning" text="deprecated" /> ~~pullOnStartup~~ <Badge type="tip" text="final" /> {#prop-pullonstartup}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">bool</span> <span class="fn">pullOnStartup</span></code></pre></div>

:::warning DEPRECATED
Use SyncCoordinator.pullOnStartup instead.
:::

Legacy app-flow flag.

Deprecated: use `SyncCoordinator(pullOnStartup: ...)` instead.

:::details Implementation
```dart
@Deprecated('Use SyncCoordinator.pullOnStartup instead.')
final bool pullOnStartup;
```
:::

### <Badge type="warning" text="deprecated" /> ~~pushImmediately~~ <Badge type="tip" text="final" /> {#prop-pushimmediately}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">bool</span> <span class="fn">pushImmediately</span></code></pre></div>

:::warning DEPRECATED
Use SyncCoordinator.pushOnOutboxChanges instead.
:::

Legacy app-flow flag.

Deprecated: use `SyncCoordinator(pushOnOutboxChanges: ...)` instead.

:::details Implementation
```dart
@Deprecated('Use SyncCoordinator.pushOnOutboxChanges instead.')
final bool pushImmediately;
```
:::

### <Badge type="warning" text="deprecated" /> ~~reconcileInterval~~ <Badge type="tip" text="final" /> {#prop-reconcileinterval}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Duration</span>? <span class="fn">reconcileInterval</span></code></pre></div>

:::warning DEPRECATED
Use SyncCoordinator.autoInterval instead.
:::

Legacy app-flow flag.

Deprecated: use `SyncCoordinator(autoInterval: ...)` instead.

:::details Implementation
```dart
@Deprecated('Use SyncCoordinator.autoInterval instead.')
final Duration? reconcileInterval;
```
:::

### retryTransportErrorsInEngine <Badge type="tip" text="final" /> {#prop-retrytransporterrorsinengine}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">bool</span> <span class="fn">retryTransportErrorsInEngine</span></code></pre></div>

Whether push transport errors should be retried at engine level.

Keep this false when transport already has robust retry logic
to avoid duplicate backoff layers.

:::details Implementation
```dart
final bool retryTransportErrorsInEngine;
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

### skipConflictingOps <Badge type="tip" text="final" /> {#prop-skipconflictingops}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">bool</span> <span class="fn">skipConflictingOps</span></code></pre></div>

Skip operations with unresolved conflicts.
If true, operation is removed from outbox.
If false, operation remains in outbox for next sync.

:::details Implementation
```dart
final bool skipConflictingOps;
```
:::

## Methods {#section-methods}

### copyWith() {#copywith}

<div class="member-signature"><pre><code><a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncConfig" class="type-link">SyncConfig</a> <span class="fn">copyWith</span>({
  <span class="type">int</span>? <span class="param">pageSize</span>,
  <span class="type">Duration</span>? <span class="param">backoffMin</span>,
  <span class="type">Duration</span>? <span class="param">backoffMax</span>,
  <span class="type">double</span>? <span class="param">backoffMultiplier</span>,
  <span class="type">int</span>? <span class="param">maxPushRetries</span>,
  <span class="type">Duration</span>? <span class="param">fullResyncInterval</span>,
  <span class="type">bool</span>? <span class="param">pullOnStartup</span>,
  <span class="type">bool</span>? <span class="param">pushImmediately</span>,
  <span class="type">Duration</span>? <span class="param">reconcileInterval</span>,
  <span class="type">bool</span>? <span class="param">lazyReconcileOnMiss</span>,
  <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy" class="type-link">ConflictStrategy</a>? <span class="param">conflictStrategy</span>,
  (<span class="type">Future</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictResolution" class="type-link">ConflictResolution</a>&gt; <span class="type">Function</span>(<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/Conflict" class="type-link">Conflict</a> <span class="param">conflict</span>))? <span class="param">conflictResolver</span>,
  (<span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="type">Function</span>(<span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="param">local</span>, <span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="param">server</span>))? <span class="param">mergeFunction</span>,
  <span class="type">int</span>? <span class="param">maxConflictRetries</span>,
  <span class="type">Duration</span>? <span class="param">conflictRetryDelay</span>,
  <span class="type">bool</span>? <span class="param">skipConflictingOps</span>,
  <span class="type">int</span>? <span class="param">maxOutboxTryCount</span>,
  <span class="type">bool</span>? <span class="param">retryTransportErrorsInEngine</span>,
})</code></pre></div>

Create a copy of configuration with modified parameters.

:::details Implementation
```dart
SyncConfig copyWith({
  int? pageSize,
  Duration? backoffMin,
  Duration? backoffMax,
  double? backoffMultiplier,
  int? maxPushRetries,
  Duration? fullResyncInterval,
  bool? pullOnStartup,
  bool? pushImmediately,
  Duration? reconcileInterval,
  bool? lazyReconcileOnMiss,
  ConflictStrategy? conflictStrategy,
  ConflictResolver? conflictResolver,
  MergeFunction? mergeFunction,
  int? maxConflictRetries,
  Duration? conflictRetryDelay,
  bool? skipConflictingOps,
  int? maxOutboxTryCount,
  bool? retryTransportErrorsInEngine,
}) => SyncConfig(
  pageSize: pageSize ?? this.pageSize,
  backoffMin: backoffMin ?? this.backoffMin,
  backoffMax: backoffMax ?? this.backoffMax,
  backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
  maxPushRetries: maxPushRetries ?? this.maxPushRetries,
  fullResyncInterval: fullResyncInterval ?? this.fullResyncInterval,
  pullOnStartup: pullOnStartup ?? this.pullOnStartup,
  pushImmediately: pushImmediately ?? this.pushImmediately,
  reconcileInterval: reconcileInterval ?? this.reconcileInterval,
  lazyReconcileOnMiss: lazyReconcileOnMiss ?? this.lazyReconcileOnMiss,
  conflictStrategy: conflictStrategy ?? this.conflictStrategy,
  conflictResolver: conflictResolver ?? this.conflictResolver,
  mergeFunction: mergeFunction ?? this.mergeFunction,
  maxConflictRetries: maxConflictRetries ?? this.maxConflictRetries,
  conflictRetryDelay: conflictRetryDelay ?? this.conflictRetryDelay,
  skipConflictingOps: skipConflictingOps ?? this.skipConflictingOps,
  maxOutboxTryCount: maxOutboxTryCount ?? this.maxOutboxTryCount,
  retryTransportErrorsInEngine:
      retryTransportErrorsInEngine ?? this.retryTransportErrorsInEngine,
);
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

