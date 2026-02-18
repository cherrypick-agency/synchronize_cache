---
title: "SyncRepository<T, DB extends GeneratedDatabase>"
description: "API documentation for SyncRepository<T, DB extends GeneratedDatabase> class from offline_first_sync_drift"
category: "Classes"
library: "offline_first_sync_drift"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift/lib/src/sync_repository.dart#L9"
outline: [2, 3]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# SyncRepository\<T, DB extends GeneratedDatabase\> <Badge type="info" text="abstract" />

<div class="member-signature"><pre><code><span class="kw">abstract</span> <span class="kw">class</span> <span class="fn">SyncRepository</span>&lt;T, DB <span class="kw">extends</span> <span class="type">GeneratedDatabase</span>&gt;</code></pre></div>

Base repository for syncable entities.

This is an optional DX layer. It does not replace Drift, but provides
a consistent "local write + enqueue" API across entity types.

## Constructors {#section-constructors}

### SyncRepository() {#ctor-syncrepository}

<div class="member-signature"><pre><code><span class="fn">SyncRepository</span>(
  <span class="type">DB</span> <span class="param">db</span>, {
  <span class="kw">required</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable" class="type-link">SyncableTable</a>&lt;<span class="type">T</span>&gt; <span class="param">syncTable</span>,
  (<span class="type">String</span> <span class="type">Function</span>())? <span class="param">opIdFactory</span>,
  (<span class="type">DateTime</span> <span class="type">Function</span>())? <span class="param">clock</span>,
})</code></pre></div>

:::details Implementation
```dart
SyncRepository(
  this.db, {
  required SyncableTable<T> syncTable,
  OpIdFactory? opIdFactory,
  SyncClock? clock,
}) : syncTable = syncTable,
     writer = SyncWriter<DB>(
       db,
       opIdFactory: opIdFactory,
       clock: clock,
     ).forTable(syncTable);
```
:::

## Properties {#section-properties}

### db <Badge type="tip" text="final" /> {#prop-db}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">DB</span> <span class="fn">db</span></code></pre></div>

:::details Implementation
```dart
final DB db;
```
:::

### hashCode <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-hashcode}

<div class="member-signature"><pre><code><span class="type">int</span> <span class="kw">get</span> <span class="fn">hashCode</span></code></pre></div>

The hash code for this object.

A hash code is a single integer which represents the state of the object
that affects [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncRepository#operator-equals) comparisons.

All objects have hash codes.
The default hash code implemented by [Object](https://api.flutter.dev/flutter/dart-core/Object-class.html)
represents only the identity of the object,
the same way as the default [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncRepository#operator-equals) implementation only considers objects
equal if they are identical (see [identityHashCode](https://api.flutter.dev/flutter/dart-core/identityHashCode.html)).

If [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncRepository#operator-equals) is overridden to use the object state instead,
the hash code must also be changed to represent that state,
otherwise the object cannot be used in hash based data structures
like the default [Set](https://api.flutter.dev/flutter/dart-core/Set-class.html) and [Map](https://api.flutter.dev/flutter/dart-core/Map-class.html) implementations.

Hash codes must be the same for objects that are equal to each other
according to [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncRepository#operator-equals).
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

If a subclass overrides [hashCode](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncRepository#prop-hashcode), it should override the
[operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncRepository#operator-equals) operator as well to maintain consistency.

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

### syncTable <Badge type="tip" text="final" /> {#prop-synctable}

<div class="member-signature"><pre><code><span class="kw">final</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable" class="type-link">SyncableTable</a>&lt;<span class="type">T</span>&gt; <span class="fn">syncTable</span></code></pre></div>

:::details Implementation
```dart
final SyncableTable<T> syncTable;
```
:::

### table <Badge type="tip" text="no setter" /> {#prop-table}

<div class="member-signature"><pre><code><span class="type">TableInfo</span>&lt;<span class="type">Table</span>, <span class="type">T</span>&gt; <span class="kw">get</span> <span class="fn">table</span></code></pre></div>

The Drift table for reading/writing.

:::details Implementation
```dart
TableInfo<Table, T> get table => syncTable.table;
```
:::

### writer <Badge type="tip" text="final" /> {#prop-writer}

<div class="member-signature"><pre><code><span class="kw">final</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEntityWriter" class="type-link">SyncEntityWriter</a>&lt;<span class="type">T</span>, <span class="type">DB</span>&gt; <span class="fn">writer</span></code></pre></div>

:::details Implementation
```dart
final SyncEntityWriter<T, DB> writer;
```
:::

## Methods {#section-methods}

### create() {#create}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">create</span>(<span class="type">T</span> <span class="param">entity</span>)</code></pre></div>

Create a new entity: insert locally + enqueue upsert.

:::details Implementation
```dart
Future<void> create(T entity) => writer.insertAndEnqueue(entity);
```
:::

### enqueueDelete() {#enqueuedelete}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">enqueueDelete</span>(<span class="type">String</span> <span class="param">id</span>, {<span class="type">DateTime</span>? <span class="param">baseUpdatedAt</span>})</code></pre></div>

Enqueue delete for an entity id (no local write).

:::details Implementation
```dart
Future<void> enqueueDelete(String id, {DateTime? baseUpdatedAt}) =>
    writer.enqueueDelete(id: id, baseUpdatedAt: baseUpdatedAt);
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

### update() {#update}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">update</span>(
  <span class="type">T</span> <span class="param">entity</span>, {
  <span class="kw">required</span> <span class="type">DateTime</span> <span class="param">baseUpdatedAt</span>,
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">changedFields</span>,
})</code></pre></div>

Update an entity: replace locally + enqueue upsert.

:::details Implementation
```dart
Future<void> update(
  T entity, {
  required DateTime baseUpdatedAt,
  Set<String>? changedFields,
}) => writer.replaceAndEnqueue(
  entity,
  baseUpdatedAt: baseUpdatedAt,
  changedFields: changedFields,
);
```
:::

### upsertFromServer() {#upsertfromserver}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">upsertFromServer</span>(<span class="type">T</span> <span class="param">entity</span>)</code></pre></div>

Apply server state locally without enqueue (used during pull).

:::details Implementation
```dart
Future<void> upsertFromServer(T entity) async {
  await db
      .into(table)
      .insertOnConflictUpdate(syncTable.getInsertable(entity));
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

