---
title: "ConflictUtils"
description: "API documentation for ConflictUtils class from offline_first_sync_drift"
category: "Classes"
library: "offline_first_sync_drift"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift/lib/src/conflict_resolution.dart#L179"
outline: [2, 3]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# ConflictUtils <Badge type="info" text="abstract" /> <Badge type="info" text="final" />

<div class="member-signature"><pre><code><span class="kw">abstract</span> <span class="kw">final</span> <span class="kw">class</span> <span class="fn">ConflictUtils</span></code></pre></div>

Conflict utility functions.

## Properties {#section-properties}

### hashCode <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-hashcode}

<div class="member-signature"><pre><code><span class="type">int</span> <span class="kw">get</span> <span class="fn">hashCode</span></code></pre></div>

The hash code for this object.

A hash code is a single integer which represents the state of the object
that affects [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictUtils#operator-equals) comparisons.

All objects have hash codes.
The default hash code implemented by [Object](https://api.flutter.dev/flutter/dart-core/Object-class.html)
represents only the identity of the object,
the same way as the default [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictUtils#operator-equals) implementation only considers objects
equal if they are identical (see [identityHashCode](https://api.flutter.dev/flutter/dart-core/identityHashCode.html)).

If [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictUtils#operator-equals) is overridden to use the object state instead,
the hash code must also be changed to represent that state,
otherwise the object cannot be used in hash based data structures
like the default [Set](https://api.flutter.dev/flutter/dart-core/Set-class.html) and [Map](https://api.flutter.dev/flutter/dart-core/Map-class.html) implementations.

Hash codes must be the same for objects that are equal to each other
according to [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictUtils#operator-equals).
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

If a subclass overrides [hashCode](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictUtils#prop-hashcode), it should override the
[operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictUtils#operator-equals) operator as well to maintain consistency.

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

## Static Methods {#section-static-methods}

### deepMerge() {#deepmerge}

<div class="member-signature"><pre><code><span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="fn">deepMerge</span>(
  <span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="param">local</span>,
  <span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="param">server</span>,
)</code></pre></div>

Deep merge for nested objects.

:::details Implementation
```dart
static Map<String, Object?> deepMerge(
  Map<String, Object?> local,
  Map<String, Object?> server,
) {
  final merged = <String, Object?>{};

  final allKeys = {...local.keys, ...server.keys};

  for (final key in allKeys) {
    final localValue = local[key];
    final serverValue = server[key];

    if (localValue is Map<String, Object?> &&
        serverValue is Map<String, Object?>) {
      merged[key] = deepMerge(localValue, serverValue);
    } else if (local.containsKey(key)) {
      merged[key] = localValue;
    } else {
      merged[key] = serverValue;
    }
  }

  return merged;
}
```
:::

### defaultMerge() {#defaultmerge}

<div class="member-signature"><pre><code><span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="fn">defaultMerge</span>(
  <span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="param">local</span>,
  <span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="param">server</span>,
)</code></pre></div>

Default merge: server fields + changed client fields.
Keeps server values for fields not changed by client.

:::details Implementation
```dart
static Map<String, Object?> defaultMerge(
  Map<String, Object?> local,
  Map<String, Object?> server,
) {
  final merged = Map<String, Object?>.from(server);
  for (final entry in local.entries) {
    if (entry.value != null) {
      merged[entry.key] = entry.value;
    }
  }
  return merged;
}
```
:::

### extractTimestamp() {#extracttimestamp}

<div class="member-signature"><pre><code><span class="type">DateTime</span>? <span class="fn">extractTimestamp</span>(<span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="param">data</span>)</code></pre></div>

Extract timestamp from JSON data.

:::details Implementation
```dart
static DateTime? extractTimestamp(Map<String, Object?> data) {
  final ts = data[SyncFields.updatedAt] ?? data[SyncFields.updatedAtSnake];
  if (ts == null) return null;
  if (ts is DateTime) return ts;
  return DateTime.tryParse(ts.toString())?.toUtc();
}
```
:::

### preservingMerge() {#preservingmerge}

<div class="member-signature"><pre><code><a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/PreservingMergeResult" class="type-link">PreservingMergeResult</a> <span class="fn">preservingMerge</span>(
  <span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="param">local</span>,
  <span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Object</span>?&gt; <span class="param">server</span>, {
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">changedFields</span>,
})</code></pre></div>

Smart merge that preserves ALL data without loss.

Rules:

- System fields always come from server
- If `changedFields` is provided, only those local fields are applied
- If local value is non-null and server value is null, use local
- Lists are merged as union
- Nested objects are merged recursively

:::details Implementation
```dart
static PreservingMergeResult preservingMerge(
  Map<String, Object?> local,
  Map<String, Object?> server, {
  Set<String>? changedFields,
}) {
  final result = Map<String, Object?>.from(server);
  final localFieldsUsed = <String>{};
  final serverFieldsUsed = <String>{};

  &#47;&#47; All server fields are used by default
  for (final key in server.keys) {
    if (!systemFields.contains(key)) {
      serverFieldsUsed.add(key);
    }
  }

  for (final key in local.keys) {
    &#47;&#47; System fields always come from server
    if (systemFields.contains(key)) continue;

    final localVal = local[key];
    final serverVal = server[key];

    &#47;&#47; If changedFields is provided, apply only those fields
    if (changedFields != null && !changedFields.contains(key)) {
      continue;
    }

    &#47;&#47; Both null: skip
    if (localVal == null && serverVal == null) continue;

    &#47;&#47; Local is present and server is missing: use local
    if (localVal != null && serverVal == null) {
      result[key] = localVal;
      localFieldsUsed.add(key);
      serverFieldsUsed.remove(key);
      continue;
    }

    &#47;&#47; Local is null and server is present: keep server
    if (localVal == null && serverVal != null) {
      continue;
    }

    &#47;&#47; Both present: smart merge by value type
    if (localVal is List && serverVal is List) {
      result[key] = _mergeLists(localVal, serverVal);
      localFieldsUsed.add(key);
      &#47;&#47; Lists were merged; both sources were used
    } else if (localVal is Map<String, Object?> &&
        serverVal is Map<String, Object?>) {
      final nestedResult = preservingMerge(localVal, serverVal);
      result[key] = nestedResult.data;
      if (nestedResult.localFields.isNotEmpty) {
        localFieldsUsed.add(key);
      }
    } else {
      &#47;&#47; Primitive values: use local (user changed it)
      result[key] = localVal;
      localFieldsUsed.add(key);
      serverFieldsUsed.remove(key);
    }
  }

  return PreservingMergeResult(
    data: result,
    localFields: localFieldsUsed,
    serverFields: serverFieldsUsed,
  );
}
```
:::

## Constants {#section-constants}

### systemFields {#prop-systemfields}

<div class="member-signature"><pre><code><span class="kw">const</span> <span class="type">Set</span>&lt;<span class="type">String</span>&gt; <span class="fn">systemFields</span></code></pre></div>

System fields that should not be merged.

:::details Implementation
```dart
static const systemFields = {
  SyncFields.id,
  SyncFields.idUpper,
  SyncFields.uuid,
  SyncFields.updatedAt,
  SyncFields.updatedAtSnake,
  SyncFields.createdAt,
  SyncFields.createdAtSnake,
  SyncFields.deletedAt,
  SyncFields.deletedAtSnake,
};
```
:::

