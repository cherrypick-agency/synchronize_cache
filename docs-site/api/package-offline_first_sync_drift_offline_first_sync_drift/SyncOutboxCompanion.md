---
title: "SyncOutboxCompanion"
description: "API documentation for SyncOutboxCompanion class from offline_first_sync_drift"
category: "Classes"
library: "offline_first_sync_drift"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift/lib/src/tables/outbox.drift.dart#L561"
outline: [2, 3]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# SyncOutboxCompanion

<div class="member-signature"><pre><code><span class="kw">class</span> <span class="fn">SyncOutboxCompanion</span> <span class="kw">extends</span> <span class="type">UpdateCompanion</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncOutboxData" class="type-link">SyncOutboxData</a>&gt;</code></pre></div>

:::info Inheritance
Object → UpdateCompanion\<D\> → **SyncOutboxCompanion**
:::

## Constructors {#section-constructors}

### SyncOutboxCompanion() <Badge type="tip" text="const" /> {#ctor-syncoutboxcompanion}

<div class="member-signature"><pre><code><span class="kw">const</span> <span class="fn">SyncOutboxCompanion</span>({
  <span class="type">Value</span>&lt;<span class="type">String</span>&gt; <span class="param">opId</span> = const i0.Value.absent(),
  <span class="type">Value</span>&lt;<span class="type">String</span>&gt; <span class="param">kind</span> = const i0.Value.absent(),
  <span class="type">Value</span>&lt;<span class="type">String</span>&gt; <span class="param">entityId</span> = const i0.Value.absent(),
  <span class="type">Value</span>&lt;<span class="type">String</span>&gt; <span class="param">op</span> = const i0.Value.absent(),
  <span class="type">Value</span>&lt;<span class="type">String</span>?&gt; <span class="param">payload</span> = const i0.Value.absent(),
  <span class="type">Value</span>&lt;<span class="type">int</span>&gt; <span class="param">ts</span> = const i0.Value.absent(),
  <span class="type">Value</span>&lt;<span class="type">int</span>&gt; <span class="param">tryCount</span> = const i0.Value.absent(),
  <span class="type">Value</span>&lt;<span class="type">int</span>?&gt; <span class="param">baseUpdatedAt</span> = const i0.Value.absent(),
  <span class="type">Value</span>&lt;<span class="type">String</span>?&gt; <span class="param">changedFields</span> = const i0.Value.absent(),
  <span class="type">Value</span>&lt;<span class="type">int</span>&gt; <span class="param">rowid</span> = const i0.Value.absent(),
})</code></pre></div>

:::details Implementation
```dart
const SyncOutboxCompanion({
  this.opId = const i0.Value.absent(),
  this.kind = const i0.Value.absent(),
  this.entityId = const i0.Value.absent(),
  this.op = const i0.Value.absent(),
  this.payload = const i0.Value.absent(),
  this.ts = const i0.Value.absent(),
  this.tryCount = const i0.Value.absent(),
  this.baseUpdatedAt = const i0.Value.absent(),
  this.changedFields = const i0.Value.absent(),
  this.rowid = const i0.Value.absent(),
});
```
:::

### SyncOutboxCompanion.insert() {#insert}

<div class="member-signature"><pre><code><span class="fn">SyncOutboxCompanion.insert</span>({
  <span class="kw">required</span> <span class="type">String</span> <span class="param">opId</span>,
  <span class="kw">required</span> <span class="type">String</span> <span class="param">kind</span>,
  <span class="kw">required</span> <span class="type">String</span> <span class="param">entityId</span>,
  <span class="kw">required</span> <span class="type">String</span> <span class="param">op</span>,
  <span class="type">Value</span>&lt;<span class="type">String</span>?&gt; <span class="param">payload</span> = const i0.Value.absent(),
  <span class="kw">required</span> <span class="type">int</span> <span class="param">ts</span>,
  <span class="type">Value</span>&lt;<span class="type">int</span>&gt; <span class="param">tryCount</span> = const i0.Value.absent(),
  <span class="type">Value</span>&lt;<span class="type">int</span>?&gt; <span class="param">baseUpdatedAt</span> = const i0.Value.absent(),
  <span class="type">Value</span>&lt;<span class="type">String</span>?&gt; <span class="param">changedFields</span> = const i0.Value.absent(),
  <span class="type">Value</span>&lt;<span class="type">int</span>&gt; <span class="param">rowid</span> = const i0.Value.absent(),
})</code></pre></div>

:::details Implementation
```dart
SyncOutboxCompanion.insert({
  required String opId,
  required String kind,
  required String entityId,
  required String op,
  this.payload = const i0.Value.absent(),
  required int ts,
  this.tryCount = const i0.Value.absent(),
  this.baseUpdatedAt = const i0.Value.absent(),
  this.changedFields = const i0.Value.absent(),
  this.rowid = const i0.Value.absent(),
}) : opId = i0.Value(opId),
     kind = i0.Value(kind),
     entityId = i0.Value(entityId),
     op = i0.Value(op),
     ts = i0.Value(ts);
```
:::

## Properties {#section-properties}

### baseUpdatedAt <Badge type="tip" text="final" /> {#prop-baseupdatedat}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Value</span>&lt;<span class="type">int</span>?&gt; <span class="fn">baseUpdatedAt</span></code></pre></div>

:::details Implementation
```dart
final i0.Value<int?> baseUpdatedAt;
```
:::

### changedFields <Badge type="tip" text="final" /> {#prop-changedfields}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Value</span>&lt;<span class="type">String</span>?&gt; <span class="fn">changedFields</span></code></pre></div>

:::details Implementation
```dart
final i0.Value<String?> changedFields;
```
:::

### entityId <Badge type="tip" text="final" /> {#prop-entityid}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Value</span>&lt;<span class="type">String</span>&gt; <span class="fn">entityId</span></code></pre></div>

:::details Implementation
```dart
final i0.Value<String> entityId;
```
:::

### hashCode <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-hashcode}

<div class="member-signature"><pre><code><span class="type">int</span> <span class="kw">get</span> <span class="fn">hashCode</span></code></pre></div>

The hash code for this object.

A hash code is a single integer which represents the state of the object
that affects [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncOutboxCompanion#operator-equals) comparisons.

All objects have hash codes.
The default hash code implemented by [Object](https://api.flutter.dev/flutter/dart-core/Object-class.html)
represents only the identity of the object,
the same way as the default [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncOutboxCompanion#operator-equals) implementation only considers objects
equal if they are identical (see [identityHashCode](https://api.flutter.dev/flutter/dart-core/identityHashCode.html)).

If [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncOutboxCompanion#operator-equals) is overridden to use the object state instead,
the hash code must also be changed to represent that state,
otherwise the object cannot be used in hash based data structures
like the default [Set](https://api.flutter.dev/flutter/dart-core/Set-class.html) and [Map](https://api.flutter.dev/flutter/dart-core/Map-class.html) implementations.

Hash codes must be the same for objects that are equal to each other
according to [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncOutboxCompanion#operator-equals).
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

If a subclass overrides [hashCode](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncOutboxCompanion#prop-hashcode), it should override the
[operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncOutboxCompanion#operator-equals) operator as well to maintain consistency.

*Inherited from UpdateCompanion.*

:::details Implementation
```dart
@override
int get hashCode {
  return _mapEquality.hash(toColumns(false));
}
```
:::

### kind <Badge type="tip" text="final" /> {#prop-kind}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Value</span>&lt;<span class="type">String</span>&gt; <span class="fn">kind</span></code></pre></div>

:::details Implementation
```dart
final i0.Value<String> kind;
```
:::

### op <Badge type="tip" text="final" /> {#prop-op}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Value</span>&lt;<span class="type">String</span>&gt; <span class="fn">op</span></code></pre></div>

:::details Implementation
```dart
final i0.Value<String> op;
```
:::

### opId <Badge type="tip" text="final" /> {#prop-opid}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Value</span>&lt;<span class="type">String</span>&gt; <span class="fn">opId</span></code></pre></div>

:::details Implementation
```dart
final i0.Value<String> opId;
```
:::

### payload <Badge type="tip" text="final" /> {#prop-payload}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Value</span>&lt;<span class="type">String</span>?&gt; <span class="fn">payload</span></code></pre></div>

:::details Implementation
```dart
final i0.Value<String?> payload;
```
:::

### rowid <Badge type="tip" text="final" /> {#prop-rowid}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Value</span>&lt;<span class="type">int</span>&gt; <span class="fn">rowid</span></code></pre></div>

:::details Implementation
```dart
final i0.Value<int> rowid;
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

### tryCount <Badge type="tip" text="final" /> {#prop-trycount}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Value</span>&lt;<span class="type">int</span>&gt; <span class="fn">tryCount</span></code></pre></div>

:::details Implementation
```dart
final i0.Value<int> tryCount;
```
:::

### ts <Badge type="tip" text="final" /> {#prop-ts}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Value</span>&lt;<span class="type">int</span>&gt; <span class="fn">ts</span></code></pre></div>

:::details Implementation
```dart
final i0.Value<int> ts;
```
:::

## Methods {#section-methods}

### copyWith() {#copywith}

<div class="member-signature"><pre><code><a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncOutboxCompanion" class="type-link">SyncOutboxCompanion</a> <span class="fn">copyWith</span>({
  <span class="type">Value</span>&lt;<span class="type">String</span>&gt;? <span class="param">opId</span>,
  <span class="type">Value</span>&lt;<span class="type">String</span>&gt;? <span class="param">kind</span>,
  <span class="type">Value</span>&lt;<span class="type">String</span>&gt;? <span class="param">entityId</span>,
  <span class="type">Value</span>&lt;<span class="type">String</span>&gt;? <span class="param">op</span>,
  <span class="type">Value</span>&lt;<span class="type">String</span>?&gt;? <span class="param">payload</span>,
  <span class="type">Value</span>&lt;<span class="type">int</span>&gt;? <span class="param">ts</span>,
  <span class="type">Value</span>&lt;<span class="type">int</span>&gt;? <span class="param">tryCount</span>,
  <span class="type">Value</span>&lt;<span class="type">int</span>?&gt;? <span class="param">baseUpdatedAt</span>,
  <span class="type">Value</span>&lt;<span class="type">String</span>?&gt;? <span class="param">changedFields</span>,
  <span class="type">Value</span>&lt;<span class="type">int</span>&gt;? <span class="param">rowid</span>,
})</code></pre></div>

:::details Implementation
```dart
i2.SyncOutboxCompanion copyWith({
  i0.Value<String>? opId,
  i0.Value<String>? kind,
  i0.Value<String>? entityId,
  i0.Value<String>? op,
  i0.Value<String?>? payload,
  i0.Value<int>? ts,
  i0.Value<int>? tryCount,
  i0.Value<int?>? baseUpdatedAt,
  i0.Value<String?>? changedFields,
  i0.Value<int>? rowid,
}) {
  return i2.SyncOutboxCompanion(
    opId: opId ?? this.opId,
    kind: kind ?? this.kind,
    entityId: entityId ?? this.entityId,
    op: op ?? this.op,
    payload: payload ?? this.payload,
    ts: ts ?? this.ts,
    tryCount: tryCount ?? this.tryCount,
    baseUpdatedAt: baseUpdatedAt ?? this.baseUpdatedAt,
    changedFields: changedFields ?? this.changedFields,
    rowid: rowid ?? this.rowid,
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

### toColumns() <Badge type="info" text="override" /> {#tocolumns}

<div class="member-signature"><pre><code><span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">Expression</span>&lt;<span class="type">Object</span>&gt;&gt; <span class="fn">toColumns</span>(<span class="type">bool</span> <span class="param">nullToAbsent</span>)</code></pre></div>

Converts this object into a map of column names to expressions to insert
or update.

Note that the keys in the map are the raw column names, they're not
escaped.

The `nullToAbsent` can be used on [DataClass](https://pub.dev/documentation/drift/2.28.2/drift/DataClass-class.html)es to control whether null
fields should be set to a null constant in sql or absent from the map.
Other implementations ignore that `nullToAbsent`, it mainly exists for
legacy reasons.

:::details Implementation
```dart
@override
Map<String, i0.Expression> toColumns(bool nullToAbsent) {
  final map = <String, i0.Expression>{};
  if (opId.present) {
    map['op_id'] = i0.Variable<String>(opId.value);
  }
  if (kind.present) {
    map['kind'] = i0.Variable<String>(kind.value);
  }
  if (entityId.present) {
    map['entity_id'] = i0.Variable<String>(entityId.value);
  }
  if (op.present) {
    map['op'] = i0.Variable<String>(op.value);
  }
  if (payload.present) {
    map['payload'] = i0.Variable<String>(payload.value);
  }
  if (ts.present) {
    map['ts'] = i0.Variable<int>(ts.value);
  }
  if (tryCount.present) {
    map['try_count'] = i0.Variable<int>(tryCount.value);
  }
  if (baseUpdatedAt.present) {
    map['base_updated_at'] = i0.Variable<int>(baseUpdatedAt.value);
  }
  if (changedFields.present) {
    map['changed_fields'] = i0.Variable<String>(changedFields.value);
  }
  if (rowid.present) {
    map['rowid'] = i0.Variable<int>(rowid.value);
  }
  return map;
}
```
:::

### toString() <Badge type="info" text="override" /> {#tostring}

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

:::details Implementation
```dart
@override
String toString() {
  return (StringBuffer('SyncOutboxCompanion(')
        ..write('opId: $opId, ')
        ..write('kind: $kind, ')
        ..write('entityId: $entityId, ')
        ..write('op: $op, ')
        ..write('payload: $payload, ')
        ..write('ts: $ts, ')
        ..write('tryCount: $tryCount, ')
        ..write('baseUpdatedAt: $baseUpdatedAt, ')
        ..write('changedFields: $changedFields, ')
        ..write('rowid: $rowid')
        ..write(')'))
      .toString();
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
the [hashCode](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncOutboxCompanion#prop-hashcode) method as well to maintain consistency.

*Inherited from UpdateCompanion.*

:::details Implementation
```dart
@override
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  if (other is! UpdateCompanion<D>) return false;

  return _mapEquality.equals(other.toColumns(false), toColumns(false));
}
```
:::

## Static Methods {#section-static-methods}

### custom() {#custom}

<div class="member-signature"><pre><code><span class="type">Insertable</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncOutboxData" class="type-link">SyncOutboxData</a>&gt; <span class="fn">custom</span>({
  <span class="type">Expression</span>&lt;<span class="type">String</span>&gt;? <span class="param">opId</span>,
  <span class="type">Expression</span>&lt;<span class="type">String</span>&gt;? <span class="param">kind</span>,
  <span class="type">Expression</span>&lt;<span class="type">String</span>&gt;? <span class="param">entityId</span>,
  <span class="type">Expression</span>&lt;<span class="type">String</span>&gt;? <span class="param">op</span>,
  <span class="type">Expression</span>&lt;<span class="type">String</span>&gt;? <span class="param">payload</span>,
  <span class="type">Expression</span>&lt;<span class="type">int</span>&gt;? <span class="param">ts</span>,
  <span class="type">Expression</span>&lt;<span class="type">int</span>&gt;? <span class="param">tryCount</span>,
  <span class="type">Expression</span>&lt;<span class="type">int</span>&gt;? <span class="param">baseUpdatedAt</span>,
  <span class="type">Expression</span>&lt;<span class="type">String</span>&gt;? <span class="param">changedFields</span>,
  <span class="type">Expression</span>&lt;<span class="type">int</span>&gt;? <span class="param">rowid</span>,
})</code></pre></div>

:::details Implementation
```dart
static i0.Insertable<i1.SyncOutboxData> custom({
  i0.Expression<String>? opId,
  i0.Expression<String>? kind,
  i0.Expression<String>? entityId,
  i0.Expression<String>? op,
  i0.Expression<String>? payload,
  i0.Expression<int>? ts,
  i0.Expression<int>? tryCount,
  i0.Expression<int>? baseUpdatedAt,
  i0.Expression<String>? changedFields,
  i0.Expression<int>? rowid,
}) {
  return i0.RawValuesInsertable({
    if (opId != null) 'op_id': opId,
    if (kind != null) 'kind': kind,
    if (entityId != null) 'entity_id': entityId,
    if (op != null) 'op': op,
    if (payload != null) 'payload': payload,
    if (ts != null) 'ts': ts,
    if (tryCount != null) 'try_count': tryCount,
    if (baseUpdatedAt != null) 'base_updated_at': baseUpdatedAt,
    if (changedFields != null) 'changed_fields': changedFields,
    if (rowid != null) 'rowid': rowid,
  });
}
```
:::

