---
title: "SyncColumns"
description: "API documentation for SyncColumns mixin from offline_first_sync_drift"
category: "Mixins"
library: "offline_first_sync_drift"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift/lib/src/tables/sync_columns.dart#L14"
outline: [2, 3]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# SyncColumns

<div class="member-signature"><pre><code><span class="kw">mixin</span> <span class="fn">SyncColumns</span> <span class="kw">on</span> <span class="type">Table</span> <span class="kw">implements</span> <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SynchronizableTable" class="type-link">SynchronizableTable</a></code></pre></div>

Mixin for synchronized tables.
Adds standard fields: updatedAt, deletedAt, deletedAtLocal.

:::info Implemented types
- [SynchronizableTable](/api/package-offline_first_sync_drift_offline_first_sync_drift/SynchronizableTable)
:::

:::info Superclass Constraints
- Table
:::

## Properties {#section-properties}

### customConstraints <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-customconstraints}

<div class="member-signature"><pre><code><span class="type">List</span>&lt;<span class="type">String</span>&gt; <span class="kw">get</span> <span class="fn">customConstraints</span></code></pre></div>

Custom table constraints that should be added to the table.

See also:

- [https://www.sqlite.org/syntax/table-constraint.html](https://www.sqlite.org/syntax/table-constraint.html), which defines what
table constraints are supported.

*Inherited from Table.*

:::details Implementation
```dart
List<String> get customConstraints => [];
```
:::

### deletedAt <Badge type="tip" text="no setter" /> <Badge type="info" text="override" /> {#prop-deletedat}

<div class="member-signature"><pre><code><span class="type">DateTimeColumn</span>&lt;<span class="type">DateTime</span>&gt; <span class="kw">get</span> <span class="fn">deletedAt</span></code></pre></div>

Server-side deletion time (UTC), null if not deleted.

:::details Implementation
```dart
@override
DateTimeColumn get deletedAt => dateTime().nullable()();
```
:::

### deletedAtLocal <Badge type="tip" text="no setter" /> <Badge type="info" text="override" /> {#prop-deletedatlocal}

<div class="member-signature"><pre><code><span class="type">DateTimeColumn</span>&lt;<span class="type">DateTime</span>&gt; <span class="kw">get</span> <span class="fn">deletedAtLocal</span></code></pre></div>

Local deletion time (UTC), used for deferred cleanup.

:::details Implementation
```dart
@override
DateTimeColumn get deletedAtLocal => dateTime().nullable()();
```
:::

### dontWriteConstraints <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-dontwriteconstraints}

<div class="member-signature"><pre><code><span class="type">bool</span> <span class="kw">get</span> <span class="fn">dontWriteConstraints</span></code></pre></div>

Drift will write some table constraints automatically, for instance when
you override [primaryKey](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncColumns#prop-primarykey). You can turn this behavior off if you want to.
This is intended to be used by generated code only.

*Inherited from Table.*

:::details Implementation
```dart
bool get dontWriteConstraints => false;
```
:::

### hashCode <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-hashcode}

<div class="member-signature"><pre><code><span class="type">int</span> <span class="kw">get</span> <span class="fn">hashCode</span></code></pre></div>

The hash code for this object.

A hash code is a single integer which represents the state of the object
that affects [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncColumns#operator-equals) comparisons.

All objects have hash codes.
The default hash code implemented by [Object](https://api.flutter.dev/flutter/dart-core/Object-class.html)
represents only the identity of the object,
the same way as the default [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncColumns#operator-equals) implementation only considers objects
equal if they are identical (see [identityHashCode](https://api.flutter.dev/flutter/dart-core/identityHashCode.html)).

If [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncColumns#operator-equals) is overridden to use the object state instead,
the hash code must also be changed to represent that state,
otherwise the object cannot be used in hash based data structures
like the default [Set](https://api.flutter.dev/flutter/dart-core/Set-class.html) and [Map](https://api.flutter.dev/flutter/dart-core/Map-class.html) implementations.

Hash codes must be the same for objects that are equal to each other
according to [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncColumns#operator-equals).
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

If a subclass overrides [hashCode](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncColumns#prop-hashcode), it should override the
[operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncColumns#operator-equals) operator as well to maintain consistency.

*Inherited from Object.*

:::details Implementation
```dart
external int get hashCode;
```
:::

### isStrict <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-isstrict}

<div class="member-signature"><pre><code><span class="type">bool</span> <span class="kw">get</span> <span class="fn">isStrict</span></code></pre></div>

Whether this table is `STRICT`.

Strict tables enforce stronger type constraints for inserts and updates.
Support for strict tables was added in sqlite3 version 37.
This field is intended to be used by generated code only.

*Inherited from Table.*

:::details Implementation
```dart
bool get isStrict => false;
```
:::

### primaryKey <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-primarykey}

<div class="member-signature"><pre><code><span class="type">Set</span>&lt;<span class="type">Column</span>&lt;<span class="type">Object</span>&gt;&gt;? <span class="kw">get</span> <span class="fn">primaryKey</span></code></pre></div>

Override this to specify custom primary keys:

```dart
class IngredientInRecipes extends Table {
 @override
 Set<Column> get primaryKey => {recipe, ingredient};

 IntColumn get recipe => integer()();
 IntColumn get ingredient => integer()();

 IntColumn get amountInGrams => integer().named('amount')();
}
```

The getter must return a set literal using the `=>` syntax so that the
drift generator can understand the code.
Also, please note that it's an error to have an
[BuildIntColumn.autoIncrement](https://pub.dev/documentation/drift/2.28.2/drift/BuildIntColumn/autoIncrement.html) column and a custom primary key.
As an auto-incremented `IntColumn` is recognized by drift to be the
primary key, doing so will result in an exception thrown at runtime.

*Inherited from Table.*

:::details Implementation
```dart
@visibleForOverriding
Set<Column>? get primaryKey => null;
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

### tableName <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-tablename}

<div class="member-signature"><pre><code><span class="type">String</span>? <span class="kw">get</span> <span class="fn">tableName</span></code></pre></div>

The sql table name to be used. By default, drift will use the snake_case
representation of your class name as the sql table name. For instance, a
[Table](https://pub.dev/documentation/drift/2.28.2/drift/Table-class.html) class named `LocalSettings` will be called `local_settings` by
default.
You can change that behavior by overriding this method to use a custom
name. Please note that you must directly return a string literal by using
a getter. For instance `@override String get tableName => 'my_table';` is
valid, whereas `@override final String tableName = 'my_table';` or
`@override String get tableName => createMyTableName();` is not.

*Inherited from Table.*

:::details Implementation
```dart
@visibleForOverriding
String? get tableName => null;
```
:::

### uniqueKeys <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-uniquekeys}

<div class="member-signature"><pre><code><span class="type">List</span>&lt;<span class="type">Set</span>&lt;<span class="type">Column</span>&lt;<span class="type">Object</span>&gt;&gt;&gt;? <span class="kw">get</span> <span class="fn">uniqueKeys</span></code></pre></div>

Unique constraints in this table.

When two rows have the same value in *any*  set specified in [uniqueKeys](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncColumns#prop-uniquekeys),
the database will reject the second row for inserts.

Override this to specify unique keys:

```dart
class IngredientInRecipes extends Table {
 @override
 List<Set<Column>> get uniqueKeys =>
    [{recipe, ingredient}, {recipe, amountInGrams}];

 IntColumn get recipe => integer()();
 IntColumn get ingredient => integer()();

 IntColumn get amountInGrams => integer().named('amount')();
```

The getter must return a list of set literals using the `=>` syntax so
that the drift generator can understand the code.

Note that individual columns can also be marked as unique with
[BuildGeneralColumn.unique](https://pub.dev/documentation/drift/2.28.2/drift/BuildGeneralColumn/unique.html). This is equivalent to adding a single-element
set to this list.

*Inherited from Table.*

:::details Implementation
```dart
@visibleForOverriding
List<Set<Column>>? get uniqueKeys => null;
```
:::

### updatedAt <Badge type="tip" text="no setter" /> <Badge type="info" text="override" /> {#prop-updatedat}

<div class="member-signature"><pre><code><span class="type">DateTimeColumn</span>&lt;<span class="type">DateTime</span>&gt; <span class="kw">get</span> <span class="fn">updatedAt</span></code></pre></div>

Last update time (UTC).

:::details Implementation
```dart
@override
DateTimeColumn get updatedAt => dateTime()();
```
:::

### withoutRowId <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-withoutrowid}

<div class="member-signature"><pre><code><span class="type">bool</span> <span class="kw">get</span> <span class="fn">withoutRowId</span></code></pre></div>

Whether to append a `WITHOUT ROWID` clause in the `CREATE TABLE`
statement. This is intended to be used by generated code only.

*Inherited from Table.*

:::details Implementation
```dart
bool get withoutRowId => false;
```
:::

## Methods {#section-methods}

### blob() <Badge type="info" text="inherited" /> {#blob}

<div class="member-signature"><pre><code><span class="type">ColumnBuilder</span>&lt;<span class="type">Uint8List</span>&gt; <span class="fn">blob</span>()</code></pre></div>

Use this as the body of a getter to declare a column that holds arbitrary
data blobs, stored as an [Uint8List](https://api.flutter.dev/flutter/drift/Uint8List-class.html). Example:

```dart
BlobColumn get payload => blob()();
```

*Inherited from Table.*

:::details Implementation
```dart
@protected
ColumnBuilder<Uint8List> blob() => _isGenerated();
```
:::

### boolean() <Badge type="info" text="inherited" /> {#boolean}

<div class="member-signature"><pre><code><span class="type">ColumnBuilder</span>&lt;<span class="type">bool</span>&gt; <span class="fn">boolean</span>()</code></pre></div>

Use this as the body of a getter to declare a column that holds bools.
Example (inside the body of a table class):

```dart
BoolColumn get isAwesome => boolean()();
```

*Inherited from Table.*

:::details Implementation
```dart
@protected
ColumnBuilder<bool> boolean() => _isGenerated();
```
:::

### customType() <Badge type="info" text="inherited" /> {#customtype}

<div class="member-signature"><pre><code><span class="type">ColumnBuilder</span>&lt;<span class="type">T</span>&gt; <span class="fn">customType&lt;T extends Object&gt;</span>(<span class="type">UserDefinedSqlType</span>&lt;<span class="type">T</span>&gt; <span class="param">type</span>)</code></pre></div>

Defines a column with a custom `type` when used as a getter.

For more information on custom types and when they can be useful, see
[https://drift.simonbinder.eu/docs/sql-api/types/](https://drift.simonbinder.eu/docs/sql-api/types/).

For most users, [TypeConverter](https://pub.dev/documentation/drift/2.28.2/drift/TypeConverter-class.html)s are a more appropriate tool to store
custom values in the database.

*Inherited from Table.*

:::details Implementation
```dart
@protected
ColumnBuilder<T> customType<T extends Object>(UserDefinedSqlType<T> type) =>
    _isGenerated();
```
:::

### dateTime() <Badge type="info" text="inherited" /> {#datetime}

<div class="member-signature"><pre><code><span class="type">ColumnBuilder</span>&lt;<span class="type">DateTime</span>&gt; <span class="fn">dateTime</span>()</code></pre></div>

Use this as the body of a getter to declare a column that holds date and
time values.

Drift supports two modes for storing date times: As unix timestamp with
second accuracy (the default) and as ISO 8601 string with microsecond
accuracy. For more information between the modes, and information on how
to change them, see [the documentation](https://drift.simonbinder.eu/docs/getting-started/advanced_dart_tables/#supported-column-types).

Note that [DateTime](https://api.flutter.dev/flutter/dart-core/DateTime-class.html) values are stored on a second-accuracy.
Example (inside the body of a table class):

```dart
DateTimeColumn get accountCreatedAt => dateTime()();
```

[dateTime](https://pub.dev/documentation/drift/2.28.2/drift/Table/dateTime.html) columns are optimized for SQLite. When using drift with another
database, such as PostgreSQL, use [native datetime columns](https://drift.simonbinder.eu/platforms/postgres/#avoiding-sqlite-specific-drift-apis).

*Inherited from Table.*

:::details Implementation
```dart
@protected
ColumnBuilder<DateTime> dateTime() => _isGenerated();
```
:::

### int64() <Badge type="info" text="inherited" /> {#int64}

<div class="member-signature"><pre><code><span class="type">ColumnBuilder</span>&lt;<span class="type">BigInt</span>&gt; <span class="fn">int64</span>()</code></pre></div>

Use this as the body of a getter to declare a column that holds a 64-big
integer as a [BigInt](https://api.flutter.dev/flutter/dart-core/BigInt-class.html).

The main purpose of this column is to support large integers for web apps
compiled to JavaScript, where using an [int](https://api.flutter.dev/flutter/dart-core/int-class.html) does not reliably work for
numbers larger than 2⁵².
It stores the exact same data as an [integer](https://pub.dev/documentation/drift/2.28.2/drift/Table/integer.html) column (and supports the
same options), but instructs drift to generate a data class with a
[BigInt](https://api.flutter.dev/flutter/dart-core/BigInt-class.html) field and a database conversion aware of large intergers.

**Note**: The use of [int64](https://pub.dev/documentation/drift/2.28.2/drift/Table/int64.html) is only necessary for apps that need to work
on the web **and** use columns that are likely to store values larger than
2⁵². In all other cases, using [integer](https://pub.dev/documentation/drift/2.28.2/drift/Table/integer.html) directly is much more efficient
and recommended.

*Inherited from Table.*

:::details Implementation
```dart
@protected
ColumnBuilder<BigInt> int64() => _isGenerated();
```
:::

### integer() <Badge type="info" text="inherited" /> {#integer}

<div class="member-signature"><pre><code><span class="type">ColumnBuilder</span>&lt;<span class="type">int</span>&gt; <span class="fn">integer</span>()</code></pre></div>

Use this as the body of a getter to declare a column that holds integers.

Example (inside the body of a table class):

```dart
IntColumn get id => integer().autoIncrement()();
```

In sqlite3, an integer column stores 64-big integers. This column maps
values to an [int](https://api.flutter.dev/flutter/dart-core/int-class.html) in Dart, which works well on native platforms. On the
web, be aware that [int](https://api.flutter.dev/flutter/dart-core/int-class.html)s are [double](https://api.flutter.dev/flutter/dart-core/double-class.html)s internally which means that only
integers smaller than 2⁵² can safely be stored.
If you need web support **and** a column that potential stores integers
larger than what fits into 52 bits, consider using a [int64](https://pub.dev/documentation/drift/2.28.2/drift/Table/int64.html) column
instead. That column stores the same value in a database, but makes drift
report the values as a [BigInt](https://api.flutter.dev/flutter/dart-core/BigInt-class.html) in Dart.

*Inherited from Table.*

:::details Implementation
```dart
@protected
ColumnBuilder<int> integer() => _isGenerated();
```
:::

### intEnum() <Badge type="info" text="inherited" /> {#intenum}

<div class="member-signature"><pre><code><span class="type">ColumnBuilder</span>&lt;<span class="type">int</span>&gt; <span class="fn">intEnum&lt;T extends Enum&gt;</span>()</code></pre></div>

Creates a column to store an `enum` class `T`.

In the database, the column will be represented as an integer
corresponding to the enum's index. Note that this can invalidate your data
if you add another value to the enum class.

*Inherited from Table.*

:::details Implementation
```dart
@protected
ColumnBuilder<int> intEnum<T extends Enum>() => _isGenerated();
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

### real() <Badge type="info" text="inherited" /> {#real}

<div class="member-signature"><pre><code><span class="type">ColumnBuilder</span>&lt;<span class="type">double</span>&gt; <span class="fn">real</span>()</code></pre></div>

Use this as the body of a getter to declare a column that holds floating
point numbers. Example

```dart
RealColumn get averageSpeed => real()();
```

*Inherited from Table.*

:::details Implementation
```dart
@protected
ColumnBuilder<double> real() => _isGenerated();
```
:::

### sqliteAny() <Badge type="info" text="inherited" /> {#sqliteany}

<div class="member-signature"><pre><code><span class="type">ColumnBuilder</span>&lt;<span class="type">DriftAny</span>&gt; <span class="fn">sqliteAny</span>()</code></pre></div>

Use this as a the body of a getter to declare a column that holds
arbitrary values not modified by drift at runtime.

The type of this column in the schema is `ANY`, which is particularly
useful for columns with an unknown type in [isStrict](https://pub.dev/documentation/drift/2.28.2/drift/Table/isStrict.html) tables.
This type has no direct equivalent for other database engines.

*Inherited from Table.*

:::details Implementation
```dart
@protected
ColumnBuilder<DriftAny> sqliteAny() => _isGenerated();
```
:::

### text() <Badge type="info" text="inherited" /> {#text}

<div class="member-signature"><pre><code><span class="type">ColumnBuilder</span>&lt;<span class="type">String</span>&gt; <span class="fn">text</span>()</code></pre></div>

Use this as the body of a getter to declare a column that holds strings.
Example (inside the body of a table class):

```dart
TextColumn get name => text()();
```

*Inherited from Table.*

:::details Implementation
```dart
@protected
ColumnBuilder<String> text() => _isGenerated();
```
:::

### textEnum() <Badge type="info" text="inherited" /> {#textenum}

<div class="member-signature"><pre><code><span class="type">ColumnBuilder</span>&lt;<span class="type">String</span>&gt; <span class="fn">textEnum&lt;T extends Enum&gt;</span>()</code></pre></div>

Creates a column to store an `enum` class `T`.

In the database, the column will be represented as text corresponding to
the name of the enum entries. Note that this can invalidate your data if
you rename the entries of the enum class.

*Inherited from Table.*

:::details Implementation
```dart
ColumnBuilder<String> textEnum<T extends Enum>() => _isGenerated();
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

