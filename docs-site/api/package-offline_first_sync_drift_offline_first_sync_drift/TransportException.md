---
title: "TransportException"
description: "API documentation for TransportException class from offline_first_sync_drift"
category: "Exceptions"
library: "offline_first_sync_drift"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift/lib/src/exceptions.dart#L36"
outline: [2, 3]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# TransportException

<div class="member-signature"><pre><code><span class="kw">class</span> <span class="fn">TransportException</span> <span class="kw">extends</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncException" class="type-link">SyncException</a></code></pre></div>

Transport error (unexpected server response).

:::info Inheritance
Object → [SyncException](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncException) → **TransportException**
:::

## Constructors {#section-constructors}

### TransportException() <Badge type="tip" text="const" /> {#ctor-transportexception}

<div class="member-signature"><pre><code><span class="kw">const</span> <span class="fn">TransportException</span>(
  <span class="type">String</span> <span class="param">message</span>, {
  <span class="type">int</span>? <span class="param">statusCode</span>,
  <span class="type">String</span>? <span class="param">responseBody</span>,
  <span class="type">Object</span>? <span class="param">cause</span>,
  <span class="type">StackTrace</span>? <span class="param">stackTrace</span>,
})</code></pre></div>

:::details Implementation
```dart
const TransportException(
  String message, {
  this.statusCode,
  this.responseBody,
  Object? cause,
  StackTrace? stackTrace,
}) : super(message, cause, stackTrace);
```
:::

### TransportException.httpError() <Badge type="tip" text="factory" /> {#httperror}

<div class="member-signature"><pre><code><span class="kw">factory</span> <span class="fn">TransportException.httpError</span>(<span class="type">int</span> <span class="param">statusCode</span>, [<span class="type">String</span>? <span class="param">body</span>])</code></pre></div>

Create for unsuccessful HTTP response.

:::details Implementation
```dart
factory TransportException.httpError(int statusCode, [String? body]) =>
    TransportException(
      'HTTP error $statusCode',
      statusCode: statusCode,
      responseBody: body,
    );
```
:::

## Properties {#section-properties}

### cause <Badge type="tip" text="final" /> <Badge type="info" text="inherited" /> {#prop-cause}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">Object</span>? <span class="fn">cause</span></code></pre></div>

Original cause of the error.

*Inherited from SyncException.*

:::details Implementation
```dart
final Object? cause;
```
:::

### hashCode <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-hashcode}

<div class="member-signature"><pre><code><span class="type">int</span> <span class="kw">get</span> <span class="fn">hashCode</span></code></pre></div>

The hash code for this object.

A hash code is a single integer which represents the state of the object
that affects [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/TransportException#operator-equals) comparisons.

All objects have hash codes.
The default hash code implemented by [Object](https://api.flutter.dev/flutter/dart-core/Object-class.html)
represents only the identity of the object,
the same way as the default [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/TransportException#operator-equals) implementation only considers objects
equal if they are identical (see [identityHashCode](https://api.flutter.dev/flutter/dart-core/identityHashCode.html)).

If [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/TransportException#operator-equals) is overridden to use the object state instead,
the hash code must also be changed to represent that state,
otherwise the object cannot be used in hash based data structures
like the default [Set](https://api.flutter.dev/flutter/dart-core/Set-class.html) and [Map](https://api.flutter.dev/flutter/dart-core/Map-class.html) implementations.

Hash codes must be the same for objects that are equal to each other
according to [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/TransportException#operator-equals).
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

If a subclass overrides [hashCode](/api/package-offline_first_sync_drift_offline_first_sync_drift/TransportException#prop-hashcode), it should override the
[operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/TransportException#operator-equals) operator as well to maintain consistency.

*Inherited from Object.*

:::details Implementation
```dart
external int get hashCode;
```
:::

### message <Badge type="tip" text="final" /> <Badge type="info" text="inherited" /> {#prop-message}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">String</span> <span class="fn">message</span></code></pre></div>

Error description.

*Inherited from SyncException.*

:::details Implementation
```dart
final String message;
```
:::

### responseBody <Badge type="tip" text="final" /> {#prop-responsebody}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">String</span>? <span class="fn">responseBody</span></code></pre></div>

Response body.

:::details Implementation
```dart
final String? responseBody;
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

### stackTrace <Badge type="tip" text="final" /> <Badge type="info" text="inherited" /> {#prop-stacktrace}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">StackTrace</span>? <span class="fn">stackTrace</span></code></pre></div>

Stack trace of the original error.

*Inherited from SyncException.*

:::details Implementation
```dart
final StackTrace? stackTrace;
```
:::

### statusCode <Badge type="tip" text="final" /> {#prop-statuscode}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">int</span>? <span class="fn">statusCode</span></code></pre></div>

HTTP status code.

:::details Implementation
```dart
final int? statusCode;
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
String toString() =>
    statusCode == null
        ? 'TransportException: $message'
        : 'TransportException: $message (status: $statusCode)';
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

