---
title: "SyncableTable<T>"
description: "API documentation for SyncableTable<T> class from offline_first_sync_drift"
category: "Classes"
library: "offline_first_sync_drift"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift/lib/src/syncable_table.dart#L6"
outline: [2, 3]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# SyncableTable\<T\>

<div class="member-signature"><pre><code><span class="kw">class</span> <span class="fn">SyncableTable</span>&lt;T&gt;</code></pre></div>

Configuration for a syncable table.
Registered in SyncEngine for automatic synchronization.

## Constructors {#section-constructors}

### SyncableTable() <Badge type="tip" text="const" /> {#ctor-syncabletable}

<div class="member-signature"><pre><code><span class="kw">const</span> <span class="fn">SyncableTable</span>({
  <span class="kw">required</span> <span class="type">String</span> <span class="param">kind</span>,
  <span class="kw">required</span> <span class="type">TableInfo</span>&lt;<span class="type">Table</span>, <span class="type">T</span>&gt; <span class="param">table</span>,
  <span class="kw">required</span> <span class="type">T</span> <span class="type">Function</span>(<span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">dynamic</span>&gt; <span class="param">json</span>) <span class="param">fromJson</span>,
  <span class="kw">required</span> <span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">dynamic</span>&gt; <span class="type">Function</span>(<span class="type">T</span> <span class="param">entity</span>) <span class="param">toJson</span>,
  (<span class="type">Insertable</span>&lt;<span class="type">T</span>&gt; <span class="type">Function</span>(<span class="type">T</span> <span class="param">entity</span>))? <span class="param">toInsertable</span>,
  (<span class="type">String</span> <span class="type">Function</span>(<span class="type">T</span> <span class="param">entity</span>))? <span class="param">getId</span>,
  (<span class="type">DateTime</span> <span class="type">Function</span>(<span class="type">T</span> <span class="param">entity</span>))? <span class="param">getUpdatedAt</span>,
})</code></pre></div>

:::details Implementation
```dart
const SyncableTable({
  required this.kind,
  required this.table,
  required this.fromJson,
  required this.toJson,
  this.toInsertable,
  this.getId,
  this.getUpdatedAt,
});
```
:::

## Properties {#section-properties}

### fromJson <Badge type="tip" text="final" /> {#prop-fromjson}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">T</span> <span class="type">Function</span>(<span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">dynamic</span>&gt; <span class="param">json</span>) <span class="fn">fromJson</span></code></pre></div>

Factory that creates an entity from server JSON.

:::details Implementation
```dart
final T Function(Map<String, dynamic> json) fromJson;
```
:::

### getId <Badge type="tip" text="final" /> {#prop-getid}

<div class="member-signature"><pre><code><span class="kw">final</span> (<span class="type">String</span> <span class="type">Function</span>(<span class="type">T</span> <span class="param">entity</span>))? <span class="fn">getId</span></code></pre></div>

Gets an entity ID. By default searches common ID field names.

:::details Implementation
```dart
final String Function(T entity)? getId;
```
:::

### getUpdatedAt <Badge type="tip" text="final" /> {#prop-getupdatedat}

<div class="member-signature"><pre><code><span class="kw">final</span> (<span class="type">DateTime</span> <span class="type">Function</span>(<span class="type">T</span> <span class="param">entity</span>))? <span class="fn">getUpdatedAt</span></code></pre></div>

Gets an entity updatedAt. By default searches common timestamp fields.

:::details Implementation
```dart
final DateTime Function(T entity)? getUpdatedAt;
```
:::

### hashCode <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-hashcode}

<div class="member-signature"><pre><code><span class="type">int</span> <span class="kw">get</span> <span class="fn">hashCode</span></code></pre></div>

The hash code for this object.

A hash code is a single integer which represents the state of the object
that affects [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable#operator-equals) comparisons.

All objects have hash codes.
The default hash code implemented by [Object](https://api.flutter.dev/flutter/dart-core/Object-class.html)
represents only the identity of the object,
the same way as the default [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable#operator-equals) implementation only considers objects
equal if they are identical (see [identityHashCode](https://api.flutter.dev/flutter/dart-core/identityHashCode.html)).

If [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable#operator-equals) is overridden to use the object state instead,
the hash code must also be changed to represent that state,
otherwise the object cannot be used in hash based data structures
like the default [Set](https://api.flutter.dev/flutter/dart-core/Set-class.html) and [Map](https://api.flutter.dev/flutter/dart-core/Map-class.html) implementations.

Hash codes must be the same for objects that are equal to each other
according to [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable#operator-equals).
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

If a subclass overrides [hashCode](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable#prop-hashcode), it should override the
[operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable#operator-equals) operator as well to maintain consistency.

*Inherited from Object.*

:::details Implementation
```dart
external int get hashCode;
```
:::

### kind <Badge type="tip" text="final" /> {#prop-kind}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">String</span> <span class="fn">kind</span></code></pre></div>

Entity kind on the server (for example, `daily_feeling`).

:::details Implementation
```dart
final String kind;
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

### table <Badge type="tip" text="final" /> {#prop-table}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">TableInfo</span>&lt;<span class="type">Table</span>, <span class="type">T</span>&gt; <span class="fn">table</span></code></pre></div>

Drift table.

:::details Implementation
```dart
final TableInfo<Table, T> table;
```
:::

### toInsertable <Badge type="tip" text="final" /> {#prop-toinsertable}

<div class="member-signature"><pre><code><span class="kw">final</span> (<span class="type">Insertable</span>&lt;<span class="type">T</span>&gt; <span class="type">Function</span>(<span class="type">T</span> <span class="param">entity</span>))? <span class="fn">toInsertable</span></code></pre></div>

Converts an entity to Insertable for DB writes.
If you use `@UseRowClass(T, generateInsertable: true)`,
pass: `toInsertable: (e) => e.toInsertable()`.
If `T` already implements `Insertable<T>`, this can be omitted.

:::details Implementation
```dart
final Insertable<T> Function(T entity)? toInsertable;
```
:::

### toJson <Badge type="tip" text="final" /> {#prop-tojson}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">dynamic</span>&gt; <span class="type">Function</span>(<span class="type">T</span> <span class="param">entity</span>) <span class="fn">toJson</span></code></pre></div>

Serializes an entity to JSON sent to the server.

:::details Implementation
```dart
final Map<String, dynamic> Function(T entity) toJson;
```
:::

## Methods {#section-methods}

### getInsertable() {#getinsertable}

<div class="member-signature"><pre><code><span class="type">Insertable</span>&lt;<span class="type">T</span>&gt; <span class="fn">getInsertable</span>(<span class="type">T</span> <span class="param">entity</span>)</code></pre></div>

Gets Insertable from an entity.

:::details Implementation
```dart
Insertable<T> getInsertable(T entity) {
  if (toInsertable != null) {
    return toInsertable!(entity);
  }
  &#47;&#47; Fallback: assume entity implements Insertable<T>
  return entity as Insertable<T>;
}
```
:::

### idOf() {#idof}

<div class="member-signature"><pre><code><span class="type">String</span> <span class="fn">idOf</span>(<span class="type">T</span> <span class="param">entity</span>)</code></pre></div>

Gets an entity ID.

Prefer providing [getId](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable#prop-getid) for best performance and correctness.
Fallback: derives id from [toJson](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable#prop-tojson) using [SyncFields.idFields](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncFields#prop-idfields).

:::details Implementation
```dart
String idOf(T entity) {
  if (getId != null) return getId!(entity);
  final json = toJson(entity);
  for (final key in SyncFields.idFields) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) {
      return value.toString();
    }
  }
  throw StateError(
    'Cannot determine entity id for kind "$kind". '
    'Provide getId: (e) => e.id (recommended).',
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

### updatedAtOf() {#updatedatof}

<div class="member-signature"><pre><code><span class="type">DateTime</span> <span class="fn">updatedAtOf</span>(<span class="type">T</span> <span class="param">entity</span>)</code></pre></div>

Gets entity updatedAt.

Prefer providing [getUpdatedAt](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable#prop-getupdatedat) for best performance and correctness.
Fallback: derives timestamp from [toJson](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable#prop-tojson) using [SyncFields.updatedAtFields](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncFields#prop-updatedatfields).

:::details Implementation
```dart
DateTime updatedAtOf(T entity) {
  if (getUpdatedAt != null) return getUpdatedAt!(entity);
  final json = toJson(entity);
  for (final key in SyncFields.updatedAtFields) {
    final value = json[key];
    if (value is DateTime) return value.toUtc();
    if (value != null) {
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) return parsed.toUtc();
    }
  }
  throw StateError(
    'Cannot determine entity updatedAt for kind "$kind". '
    'Provide getUpdatedAt: (e) => e.updatedAt (recommended).',
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

