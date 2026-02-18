---
title: "SyncDatabaseMixin"
description: "API documentation for SyncDatabaseMixin mixin from offline_first_sync_drift"
category: "Mixins"
library: "offline_first_sync_drift"
sourceUrl: "https://github.com/cherrypick-agency/synchronize_cache/blob/main/packages/offline_first_sync_drift/lib/src/sync_database.dart#L20"
outline: [2, 2]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# SyncDatabaseMixin

<div class="member-signature"><pre><code><span class="kw">mixin</span> <span class="fn">SyncDatabaseMixin</span> <span class="kw">on</span> <span class="type">GeneratedDatabase</span></code></pre></div>

Mixin for databases with synchronization support.

Usage:

1. Add to `@DriftDatabase`:
`include: {'package:offline_first_sync_drift/src/sync_tables.drift'}`
2. Add `with SyncDatabaseMixin` to your database class.

Drift will automatically include the `sync_outbox` and `sync_cursors` tables.

:::info Available Extensions
- ComputeWithDriftIsolate\<DB extends DatabaseConnectionUser\>
- DestructiveMigrationExtension
- ReadDatabaseContainer
- [SyncDatabaseDx](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseDx)
- [SyncWriterDatabaseExtension\<DB extends GeneratedDatabase\>](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncWriterDatabaseExtension)
:::

:::info Superclass Constraints
- GeneratedDatabase
:::

## Properties {#section-properties}

### allSchemaEntities <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-allschemaentities}

<div class="member-signature"><pre><code><span class="type">Iterable</span>&lt;<span class="type">DatabaseSchemaEntity</span>&gt; <span class="kw">get</span> <span class="fn">allSchemaEntities</span></code></pre></div>

A list of all `DatabaseSchemaEntity` that are specified in this database.

This contains [allTables](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseMixin#prop-alltables), but also advanced entities like triggers.

*Inherited from GeneratedDatabase.*

:::details Implementation
```dart
&#47;&#47; return allTables for backwards compatibility
Iterable<DatabaseSchemaEntity> get allSchemaEntities => allTables;
```
:::

### allTables <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-alltables}

<div class="member-signature"><pre><code><span class="type">Iterable</span>&lt;<span class="type">TableInfo</span>&lt;<span class="type">Table</span>, <span class="type">dynamic</span>&gt;&gt; <span class="kw">get</span> <span class="fn">allTables</span></code></pre></div>

A list of tables specified in this database.

*Inherited from GeneratedDatabase.*

:::details Implementation
```dart
Iterable<TableInfo> get allTables;
```
:::

### attachedDatabase <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-attacheddatabase}

<div class="member-signature"><pre><code><span class="type">GeneratedDatabase</span> <span class="kw">get</span> <span class="fn">attachedDatabase</span></code></pre></div>

The database class that this user is attached to.

*Inherited from GeneratedDatabase.*

:::details Implementation
```dart
@override
GeneratedDatabase get attachedDatabase => this;
```
:::

### connection <Badge type="tip" text="final" /> <Badge type="info" text="inherited" /> {#prop-connection}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="type">DatabaseConnection</span> <span class="fn">connection</span></code></pre></div>

The database connection used by this [DatabaseConnectionUser](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser-class.html).

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
@protected
final DatabaseConnection connection;
```
:::

### destructiveFallback <Badge type="info" text="extension" /> <Badge type="tip" text="no setter" /> {#prop-destructivefallback}

<div class="member-signature"><pre><code><span class="type">MigrationStrategy</span> <span class="kw">get</span> <span class="fn">destructiveFallback</span></code></pre></div>

Provides a destructive [MigrationStrategy](https://pub.dev/documentation/drift/2.28.2/drift/MigrationStrategy-class.html) that will delete and then
re-create all tables, triggers and indices.

To use this behavior, override the `migration` getter in your database:

```dart
@DriftDatabase(...)
class MyDatabase extends _$MyDatabase {
  @override
  MigrationStrategy get migration => destructiveFallback;
}
```

*Available on GeneratedDatabase, provided by the DestructiveMigrationExtension extension*

:::details Implementation
```dart
MigrationStrategy get destructiveFallback {
  return MigrationStrategy(
    onCreate: _defaultOnCreate,
    onUpgrade: (m, from, to) async {
      &#47;&#47; allSchemaEntities are sorted topologically references between them.
      &#47;&#47; Reverse order for deletion in order to not break anything.
      final reversedEntities = m._allSchemaEntities.toList().reversed;

      for (final entity in reversedEntities) {
        await m.drop(entity);
      }

      &#47;&#47; Re-create them now
      await m.createAll();
    },
  );
}
```
:::

### executor <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-executor}

<div class="member-signature"><pre><code><span class="type">QueryExecutor</span> <span class="kw">get</span> <span class="fn">executor</span></code></pre></div>

The executor to use when queries are executed.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
QueryExecutor get executor => connection.executor;
```
:::

### hashCode <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-hashcode}

<div class="member-signature"><pre><code><span class="type">int</span> <span class="kw">get</span> <span class="fn">hashCode</span></code></pre></div>

The hash code for this object.

A hash code is a single integer which represents the state of the object
that affects [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseMixin#operator-equals) comparisons.

All objects have hash codes.
The default hash code implemented by [Object](https://api.flutter.dev/flutter/dart-core/Object-class.html)
represents only the identity of the object,
the same way as the default [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseMixin#operator-equals) implementation only considers objects
equal if they are identical (see [identityHashCode](https://api.flutter.dev/flutter/dart-core/identityHashCode.html)).

If [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseMixin#operator-equals) is overridden to use the object state instead,
the hash code must also be changed to represent that state,
otherwise the object cannot be used in hash based data structures
like the default [Set](https://api.flutter.dev/flutter/dart-core/Set-class.html) and [Map](https://api.flutter.dev/flutter/dart-core/Map-class.html) implementations.

Hash codes must be the same for objects that are equal to each other
according to [operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseMixin#operator-equals).
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

If a subclass overrides [hashCode](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseMixin#prop-hashcode), it should override the
[operator ==](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseMixin#operator-equals) operator as well to maintain consistency.

*Inherited from Object.*

:::details Implementation
```dart
external int get hashCode;
```
:::

### migration <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-migration}

<div class="member-signature"><pre><code><span class="type">MigrationStrategy</span> <span class="kw">get</span> <span class="fn">migration</span></code></pre></div>

Defines the migration strategy that will determine how to deal with an
increasing [schemaVersion](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseMixin#prop-schemaversion). The default value only supports creating the
database by creating all tables known in this database. When you have
changes in your schema, you'll need a custom migration strategy to create
the new tables or change the columns.

*Inherited from GeneratedDatabase.*

:::details Implementation
```dart
MigrationStrategy get migration => MigrationStrategy();
```
:::

### options <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-options}

<div class="member-signature"><pre><code><span class="type">DriftDatabaseOptions</span> <span class="kw">get</span> <span class="fn">options</span></code></pre></div>

The [DriftDatabaseOptions](https://pub.dev/documentation/drift/2.28.2/drift/DriftDatabaseOptions-class.html) to use for this database instance.

Mainly, these options describe how values are mapped from Dart to SQL
values. In the future, they could be expanded to dialect-specific options.

*Inherited from GeneratedDatabase.*

:::details Implementation
```dart
@override
DriftDatabaseOptions get options => const DriftDatabaseOptions();
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

### schemaVersion <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-schemaversion}

<div class="member-signature"><pre><code><span class="type">int</span> <span class="kw">get</span> <span class="fn">schemaVersion</span></code></pre></div>

Specify the schema version of your database. Whenever you change or add
tables, you should bump this field and provide a [migration](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseMixin#prop-migration) strategy.

The [schemaVersion](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseMixin#prop-schemaversion) must be positive. Typically, one starts with a value
of `1` and increments the value for each modification to the schema.

*Inherited from GeneratedDatabase.*

:::details Implementation
```dart
@override
int get schemaVersion;
```
:::

### streamQueries <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-streamqueries}

<div class="member-signature"><pre><code><span class="type">StreamQueryStore</span> <span class="kw">get</span> <span class="fn">streamQueries</span></code></pre></div>

Manages active streams from select statements.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
@visibleForTesting
@protected
StreamQueryStore get streamQueries => connection.streamQueries;
```
:::

### streamUpdateRules <Badge type="tip" text="no setter" /> <Badge type="info" text="inherited" /> {#prop-streamupdaterules}

<div class="member-signature"><pre><code><span class="type">StreamQueryUpdateRules</span> <span class="kw">get</span> <span class="fn">streamUpdateRules</span></code></pre></div>

The collection of update rules contains information on how updates on
tables result in other updates, for instance due to a trigger.

There should be no need to overwrite this field, drift will generate an
appropriate implementation automatically.

*Inherited from GeneratedDatabase.*

:::details Implementation
```dart
StreamQueryUpdateRules get streamUpdateRules =>
    const StreamQueryUpdateRules.none();
```
:::

### typeMapping <Badge type="warning" text="late" /> <Badge type="tip" text="final" /> <Badge type="info" text="inherited" /> {#prop-typemapping}

<div class="member-signature"><pre><code><span class="kw">final</span> <span class="kw">late</span> <span class="type">SqlTypes</span> <span class="fn">typeMapping</span></code></pre></div>

A [SqlTypes](https://pub.dev/documentation/drift/2.28.2/drift/SqlTypes-class.html) mapping configuration to use when mapping values between Dart
and SQL.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
late final SqlTypes typeMapping = options.createTypeMapping(executor.dialect);
```
:::

## Methods {#section-methods}

### $expandVar() <Badge type="info" text="inherited" /> {#$expandvar}

<div class="member-signature"><pre><code><span class="type">String</span> <span class="fn">$expandVar</span>(<span class="type">int</span> <span class="param">start</span>, <span class="type">int</span> <span class="param">amount</span>)</code></pre></div>

Used by generated code to expand array variables.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
String $expandVar(int start, int amount) {
  final buffer = StringBuffer();

  final variableSymbol = switch (executor.dialect) {
    SqlDialect.postgres => r'$',
    _ => '?',
  };
  final supportsIndexedParameters =
      executor.dialect.supportsIndexedParameters;

  for (var x = 0; x < amount; x++) {
    if (supportsIndexedParameters) {
      buffer.write('$variableSymbol${start + x}');
    } else {
      buffer.write(variableSymbol);
    }

    if (x != amount - 1) {
      buffer.write(', ');
    }
  }

  return buffer.toString();
}
```
:::

### $write() <Badge type="info" text="inherited" /> {#$write}

<div class="member-signature"><pre><code><span class="type">GenerationContext</span> <span class="fn">$write</span>(
  <span class="type">Component</span> <span class="param">component</span>, {
  <span class="type">bool</span>? <span class="param">hasMultipleTables</span>,
  <span class="type">int</span>? <span class="param">startIndex</span>,
})</code></pre></div>

Will be used by generated code to resolve inline Dart components in sql by
writing the `component`.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
@protected
GenerationContext $write(Component component,
    {bool? hasMultipleTables, int? startIndex}) {
  final context = GenerationContext.fromDb(this)
    ..explicitVariableIndex = startIndex
    ..hasMultipleTables = hasMultipleTables ?? false;
  component.writeInto(context);

  return context;
}
```
:::

### $writeInsertable() <Badge type="info" text="inherited" /> {#$writeinsertable}

<div class="member-signature"><pre><code><span class="type">GenerationContext</span> <span class="fn">$writeInsertable</span>(
  <span class="type">TableInfo</span>&lt;<span class="type">Table</span>, <span class="type">dynamic</span>&gt; <span class="param">table</span>,
  <span class="type">Insertable</span>&lt;<span class="type">dynamic</span>&gt; <span class="param">insertable</span>, {
  <span class="type">int</span>? <span class="param">startIndex</span>,
})</code></pre></div>

Writes column names and `VALUES` for an insert statement.

Used by generated code.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
@protected
GenerationContext $writeInsertable(TableInfo table, Insertable insertable,
    {int? startIndex}) {
  final context = GenerationContext.fromDb(this)
    ..explicitVariableIndex = startIndex;

  table.validateIntegrity(insertable, isInserting: true);
  InsertStatement(this, table)
      .writeInsertable(context, insertable.toColumns(true));

  return context;
}
```
:::

### accessor() <Badge type="info" text="extension" /> {#accessor}

<div class="member-signature"><pre><code><span class="type">T</span> <span class="fn">accessor&lt;T extends DatabaseAccessor&lt;GeneratedDatabase&gt;&gt;</span>(
  <span class="type">T</span> <span class="type">Function</span>(<span class="type">GeneratedDatabase</span>) <span class="param">create</span>,
)</code></pre></div>

Find an accessor by its `name` in the database, or create it with
`create`. The result will be cached.

*Available on GeneratedDatabase, provided by the ReadDatabaseContainer extension*

:::details Implementation
```dart
T accessor<T extends DatabaseAccessor>(T Function(GeneratedDatabase) create) {
  final cache = _cache.knownAccessors;

  return cache.putIfAbsent(T, () => create(attachedDatabase)) as T;
}
```
:::

### ackOutbox() {#ackoutbox}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">ackOutbox</span>(<span class="type">Iterable</span>&lt;<span class="type">String</span>&gt; <span class="param">opIds</span>)</code></pre></div>

Acknowledge sent operations (remove from queue).

:::details Implementation
```dart
Future<void> ackOutbox(Iterable<String> opIds) async {
  if (opIds.isEmpty) return;
  final ids = opIds.toList();
  final placeholders = List.filled(ids.length, '?').join(', ');

  await customStatement(
    'DELETE FROM ${TableNames.syncOutbox} WHERE ${TableColumns.opId} IN ($placeholders)',
    ids,
  );

  &#47;&#47; Best-effort cleanup for metadata.
  try {
    await customStatement(
      'DELETE FROM ${TableNames.syncOutboxMeta} '
      'WHERE ${TableColumns.opId} IN ($placeholders)',
      ids,
    );
  } catch (_) {}
}
```
:::

### alias() <Badge type="info" text="inherited" /> {#alias}

<div class="member-signature"><pre><code><span class="type">T</span> <span class="fn">alias&lt;T, D&gt;</span>(<span class="type">ResultSetImplementation</span>&lt;<span class="type">T</span>, <span class="type">D</span>&gt; <span class="param">table</span>, <span class="type">String</span> <span class="param">alias</span>)</code></pre></div>

Creates a copy of the table with an alias so that it can be used in the
same query more than once.

Example which uses the same table (here: points) more than once to
differentiate between the start and end point of a route:

```dart
var source = alias(points, 'source');
var destination = alias(points, 'dest');

select(routes).join([
  innerJoin(source, routes.startPoint.equalsExp(source.id)),
  innerJoin(destination, routes.startPoint.equalsExp(destination.id)),
]);
```

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
T alias<T, D>(ResultSetImplementation<T, D> table, String alias) {
  return table.createAlias(alias).asDslTable;
}
```
:::

### batch() <Badge type="info" text="inherited" /> {#batch}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">batch</span>(<span class="type">FutureOr</span>&lt;<span class="type">void</span>&gt; <span class="type">Function</span>(<span class="type">Batch</span> <span class="param">batch</span>) <span class="param">runInBatch</span>)</code></pre></div>

Runs statements inside a batch.

A batch can only run a subset of statements, and those statements must be
called on the [Batch](https://pub.dev/documentation/drift/2.28.2/drift/Batch-class.html) instance. The statements aren't executed with a call
to [Batch](https://pub.dev/documentation/drift/2.28.2/drift/Batch-class.html). Instead, all generated queries are queued up and are then run
and executed atomically in a transaction.
If [batch](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/batch.html) is called outside of a [transaction](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/transaction.html) call, it will implicitly
start a transaction. Otherwise, the batch will re-use the transaction,
and will have an effect when the transaction completes.
Typically, running bulk updates (so a lot of similar statements) over a
[Batch](https://pub.dev/documentation/drift/2.28.2/drift/Batch-class.html) is much faster than running them via the [GeneratedDatabase](https://pub.dev/documentation/drift/2.28.2/drift/GeneratedDatabase-class.html)
directly.

An example that inserts users in a batch:

```dart
 await batch((b) {
   b.insertAll(
     todos,
     [
       TodosCompanion.insert(content: 'Use batches'),
       TodosCompanion.insert(content: 'Have fun'),
     ],
   );
 });
```

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
Future<void> batch(FutureOr<void> Function(Batch batch) runInBatch) {
  final engine = resolvedEngine;

  final batch = Batch._(engine, engine is! Transaction);
  final result = runInBatch(batch);

  if (result is Future) {
    return result.then((_) => batch._commit());
  } else {
    return batch._commit();
  }
}
```
:::

### beforeOpen() <Badge type="info" text="inherited" /> {#beforeopen}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">beforeOpen</span>(<span class="type">QueryExecutor</span> <span class="param">executor</span>, <span class="type">OpeningDetails</span> <span class="param">details</span>)</code></pre></div>

A callbacks that runs after the database connection has been established,
but before any other query is sent.

The query executor will wait for this future to complete before running
any other query. Queries running on the `executor` are an exception to
this, they can be used to run migrations.
No matter how often [QueryExecutor.ensureOpen](https://pub.dev/documentation/drift/2.28.2/drift/QueryExecutor/ensureOpen.html) is called, this method will
not be called more than once.

*Inherited from GeneratedDatabase.*

:::details Implementation
```dart
@override
@nonVirtual
Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) {
  return _runConnectionZoned(BeforeOpenRunner(this, executor), () async {
    if (schemaVersion <= 0) {
      throw StateError(
        'The schemaVersion of your database must be positive. \n'
        "A value of zero can't be distinguished from an uninitialized "
        'database, which causes issues in the migrator',
      );
    }

    if (details.wasCreated) {
      final migrator = createMigrator();
      await _resolvedMigration.onCreate(migrator);
    } else if (details.hadUpgrade) {
      final migrator = createMigrator();
      await _resolvedMigration.onUpgrade(
          migrator, details.versionBefore!, details.versionNow);
    }

    await _resolvedMigration.beforeOpen?.call(details);
  });
}
```
:::

### clearSyncableTables() {#clearsyncabletables}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">clearSyncableTables</span>(<span class="type">List</span>&lt;<span class="type">String</span>&gt; <span class="param">tableNames</span>)</code></pre></div>

Clear data from syncable tables.
`tableNames` - table names to clear.

:::details Implementation
```dart
Future<void> clearSyncableTables(List<String> tableNames) async {
  for (final tableName in tableNames) {
    await customStatement('DELETE FROM "$tableName"');
  }
}
```
:::

### close() <Badge type="info" text="inherited" /> {#close}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">close</span>()</code></pre></div>

Closes this database and releases associated resources.

*Inherited from GeneratedDatabase.*

:::details Implementation
```dart
@override
Future<void> close() async {
  await super.close();
  devtools.handleClosed(this);

  assert(() {
    if (_openedDbCount[runtimeType] != null) {
      _openedDbCount[runtimeType] = _openedDbCount[runtimeType]! - 1;
    }
    return true;
  }());
}
```
:::

### computeWithDatabase() <Badge type="info" text="extension" /> {#computewithdatabase}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">Ret</span>&gt; <span class="fn">computeWithDatabase&lt;Ret&gt;</span>({
  <span class="kw">required</span> <span class="type">FutureOr</span>&lt;<span class="type">Ret</span>&gt; <span class="type">Function</span>(<span class="type">DB</span>) <span class="param">computation</span>,
  <span class="kw">required</span> <span class="type">DB</span> <span class="type">Function</span>(<span class="type">DatabaseConnection</span>) <span class="param">connect</span>,
})</code></pre></div>

Spawns a short-lived isolate to run the `computation` with a drift
database.

Essentially, this is a variant of [Isolate.run](https://api.flutter.dev/flutter/dart-isolate/Isolate/run.html) for computations that also
need to share a drift database between them. As drift databases are
stateful objects, they can't be send across isolates (and thus used in
[Isolate.run](https://api.flutter.dev/flutter/dart-isolate/Isolate/run.html) or Flutter's `compute`) without special setup.

This method will extract the underlying database connection of `this`
database into a form that can be serialized across isolates. Then,
[Isolate.run](https://api.flutter.dev/flutter/dart-isolate/Isolate/run.html) will be called to invoke `computation`. The `connect`
function is responsible for creating an instance of your database class
from the low-level connection.

As an example, consider a database class:

```dart
class MyDatabase extends $MyDatabase {
  MyDatabase(QueryExecutor executor): super(executor);
}
```

[computeWithDatabase](https://pub.dev/documentation/drift/2.28.2/isolate/ComputeWithDriftIsolate/computeWithDatabase.html) can then be used to access an instance of
`MyDatabase` in a new isolate, even though `MyDatabase` is not generally
sharable between isolates:

```dart
Future<void> loadBulkData(MyDatabase db) async {
  await db.computeWithDatabase(
    connect: MyDatabase.new,
    computation: (db) async {
      // This computation has access to a second `db` that is internally
      // linked to the original database.
      final data = await fetchRowsFromNetwork();
      await db.batch((batch) {
        // More expensive work like inserting data
      });
    },
  );
}
```

Note that with the recommended setup of `NativeDatabase.createInBackground`,
drift will already use an isolate to run your SQL statements. Using
[computeWithDatabase](https://pub.dev/documentation/drift/2.28.2/isolate/ComputeWithDriftIsolate/computeWithDatabase.html) is beneficial when an an expensive work unit needs
to use the database, or when creating the SQL statements itself is
expensive.
In particular, note that [computeWithDatabase](https://pub.dev/documentation/drift/2.28.2/isolate/ComputeWithDriftIsolate/computeWithDatabase.html) does not create a second
database connection to sqlite3 - the current one is re-used. So if you're
using a synchronous database connection, using this method is unlikely to
take significant loads off the main isolate. For that reason, the use of
`NativeDatabase.createInBackground` is encouraged.

*Available on DB extends DatabaseConnectionUser, provided by the ComputeWithDriftIsolate\<DB extends DatabaseConnectionUser\> extension*

:::details Implementation
```dart
@experimental
Future<Ret> computeWithDatabase<Ret>({
  required FutureOr<Ret> Function(DB) computation,
  required DB Function(DatabaseConnection) connect,
}) async {
  final connection = await serializableConnection();

  return await Isolate.run(() async {
    final database = connect(await connection.connect());
    try {
      return await computation(database);
    } finally {
      await database.close();
    }
  });
}
```
:::

### countStuckOutbox() {#countstuckoutbox}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">int</span>&gt; <span class="fn">countStuckOutbox</span>({<span class="kw">required</span> <span class="type">int</span> <span class="param">minTryCount</span>, <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">kinds</span>})</code></pre></div>

Count stuck operations by try-count threshold.

:::details Implementation
```dart
Future<int> countStuckOutbox({
  required int minTryCount,
  Set<String>? kinds,
}) async {
  final hasKindsFilter = kinds != null;
  if (hasKindsFilter && kinds.isEmpty) return 0;

  final whereParts = <String>['${TableColumns.tryCount} >= ?'];
  final variables = <Variable<Object>>[Variable.withInt(minTryCount)];

  if (hasKindsFilter) {
    final kindList = kinds.toList()..sort();
    final placeholders = List.filled(kindList.length, '?').join(', ');
    whereParts.add('${TableColumns.kind} IN ($placeholders)');
    variables.addAll(kindList.map(Variable.withString));
  }

  final whereClause = 'WHERE ${whereParts.join(' AND ')}';
  final rows =
      await customSelect(
        'SELECT COUNT(*) as c FROM ${TableNames.syncOutbox} $whereClause',
        variables: variables,
        readsFrom: {_outbox},
      ).get();
  return rows.first.read<int>('c');
}
```
:::

### createMigrator() <Badge type="info" text="inherited" /> {#createmigrator}

<div class="member-signature"><pre><code><span class="type">Migrator</span> <span class="fn">createMigrator</span>()</code></pre></div>

Creates a [Migrator](https://pub.dev/documentation/drift/2.28.2/drift/Migrator-class.html) with the provided query executor. Migrators generate
sql statements to create or drop tables.

This api is mainly used internally in drift, especially to implement the
[beforeOpen](https://pub.dev/documentation/drift/2.28.2/drift/GeneratedDatabase/beforeOpen.html) callback from the database site.
However, it can also be used if you need to create tables manually and
outside of a [MigrationStrategy](https://pub.dev/documentation/drift/2.28.2/drift/MigrationStrategy-class.html). For almost all use cases, overriding
[migration](https://pub.dev/documentation/drift/2.28.2/drift/GeneratedDatabase/migration.html) should suffice.

*Inherited from GeneratedDatabase.*

:::details Implementation
```dart
@protected
@visibleForTesting
Migrator createMigrator() => Migrator(this);
```
:::

### createStream() <Badge type="info" text="inherited" /> {#createstream}

<div class="member-signature"><pre><code><span class="type">Stream</span>&lt;<span class="type">T</span>&gt; <span class="fn">createStream&lt;T extends Object&gt;</span>(<span class="type">QueryStreamFetcher</span>&lt;<span class="type">T</span>&gt; <span class="param">stmt</span>)</code></pre></div>

Creates and auto-updating stream from the given select statement. This
method should not be used directly.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
Stream<T> createStream<T extends Object>(QueryStreamFetcher<T> stmt) =>
    resolvedEngine.streamQueries.registerStream(stmt, this);
```
:::

### customInsert() <Badge type="info" text="inherited" /> {#custominsert}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">int</span>&gt; <span class="fn">customInsert</span>(
  <span class="type">String</span> <span class="param">query</span>, {
  <span class="type">List</span>&lt;<span class="type">Variable</span>&lt;<span class="type">Object</span>&gt;&gt; <span class="param">variables</span> = const [],
  <span class="type">Set</span>&lt;<span class="type">ResultSetImplementation</span>&lt;<span class="type">dynamic</span>, <span class="type">dynamic</span>&gt;&gt;? <span class="param">updates</span>,
})</code></pre></div>

Executes a custom insert statement and returns the last inserted rowid.

You can tell drift which tables your query is going to affect by using the
`updates` parameter. Query-streams running on any of these tables will
then be re-run.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
Future<int> customInsert(String query,
    {List<Variable> variables = const [],
    Set<ResultSetImplementation>? updates}) {
  return _customWrite(
    query,
    variables,
    updates,
    UpdateKind.insert,
    (executor, sql, vars) {
      return executor.runInsert(sql, vars);
    },
  );
}
```
:::

### customSelect() <Badge type="info" text="inherited" /> {#customselect}

<div class="member-signature"><pre><code><span class="type">Selectable</span>&lt;<span class="type">QueryRow</span>&gt; <span class="fn">customSelect</span>(
  <span class="type">String</span> <span class="param">query</span>, {
  <span class="type">List</span>&lt;<span class="type">Variable</span>&lt;<span class="type">Object</span>&gt;&gt; <span class="param">variables</span> = const [],
  <span class="type">Set</span>&lt;<span class="type">ResultSetImplementation</span>&lt;<span class="type">dynamic</span>, <span class="type">dynamic</span>&gt;&gt; <span class="param">readsFrom</span> = const {},
})</code></pre></div>

Creates a custom select statement from the given sql `query`.

The query can be run once by calling [Selectable.get](https://pub.dev/documentation/drift/2.28.2/drift/Selectable/get.html).

For an auto-updating query stream, the `readsFrom` parameter needs to be
set to the tables the SQL statement reads from - drift can't infer it
automatically like for other queries constructed with its Dart API.
When, [Selectable.watch](https://pub.dev/documentation/drift/2.28.2/drift/Selectable/watch.html) can be used to construct an updating stream.

For queries that are known to only return a single row,
[Selectable.getSingle](https://pub.dev/documentation/drift/2.28.2/drift/Selectable/getSingle.html) and [Selectable.watchSingle](https://pub.dev/documentation/drift/2.28.2/drift/Selectable/watchSingle.html) can be used as well.

If you use variables in your query (for instance with "?"), they will be
bound to the `variables` you specify on this query.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
Selectable<QueryRow> customSelect(String query,
    {List<Variable> variables = const [],
    Set<ResultSetImplementation> readsFrom = const {}}) {
  return CustomSelectStatement(query, variables, readsFrom, this);
}
```
:::

### <Badge type="warning" text="deprecated" /> ~~customSelectQuery()~~ <Badge type="info" text="inherited" /> {#customselectquery}

<div class="member-signature"><pre><code><span class="type">Selectable</span>&lt;<span class="type">QueryRow</span>&gt; <span class="fn">customSelectQuery</span>(
  <span class="type">String</span> <span class="param">query</span>, {
  <span class="type">List</span>&lt;<span class="type">Variable</span>&lt;<span class="type">Object</span>&gt;&gt; <span class="param">variables</span> = const [],
  <span class="type">Set</span>&lt;<span class="type">ResultSetImplementation</span>&lt;<span class="type">dynamic</span>, <span class="type">dynamic</span>&gt;&gt; <span class="param">readsFrom</span> = const {},
})</code></pre></div>

:::warning DEPRECATED
Renamed to customSelect
:::

Creates a custom select statement from the given sql `query`. To run the
query once, use [Selectable.get](https://pub.dev/documentation/drift/2.28.2/drift/Selectable/get.html). For an auto-updating streams, set the
set of tables the ready `readsFrom` and use [Selectable.watch](https://pub.dev/documentation/drift/2.28.2/drift/Selectable/watch.html). If you
know the query will never emit more than one row, you can also use
`getSingle` and `watchSingle` which return the item directly without
wrapping it into a list.

If you use variables in your query (for instance with "?"), they will be
bound to the `variables` you specify on this query.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
@Deprecated('Renamed to customSelect')
Selectable<QueryRow> customSelectQuery(String query,
    {List<Variable> variables = const [],
    Set<ResultSetImplementation> readsFrom = const {}}) {
  return customSelect(query, variables: variables, readsFrom: readsFrom);
}
```
:::

### customStatement() <Badge type="info" text="inherited" /> {#customstatement}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">customStatement</span>(<span class="type">String</span> <span class="param">statement</span>, [<span class="type">List</span>&lt;<span class="type">dynamic</span>&gt;? <span class="param">args</span>])</code></pre></div>

Executes the custom sql `statement` on the database.

`statement` should contain exactly one SQL statement. Attempting to run
multiple statements with a single [customStatement](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/customStatement.html) may not be fully
supported on all platforms.

This method does not update stream queries on this drift database. To run
custom statements that update data, please use [customInsert](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/customInsert.html) or
[customUpdate](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/customUpdate.html) instead. You can also call [markTablesUpdated](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/markTablesUpdated.html) manually
after awaiting [customStatement](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/customStatement.html).

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
Future<void> customStatement(String statement, [List<dynamic>? args]) {
  final engine = resolvedEngine;

  return engine.doWhenOpened((executor) {
    return executor.runCustom(statement, args);
  });
}
```
:::

### customUpdate() <Badge type="info" text="inherited" /> {#customupdate}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">int</span>&gt; <span class="fn">customUpdate</span>(
  <span class="type">String</span> <span class="param">query</span>, {
  <span class="type">List</span>&lt;<span class="type">Variable</span>&lt;<span class="type">Object</span>&gt;&gt; <span class="param">variables</span> = const [],
  <span class="type">Set</span>&lt;<span class="type">ResultSetImplementation</span>&lt;<span class="type">dynamic</span>, <span class="type">dynamic</span>&gt;&gt;? <span class="param">updates</span>,
  <span class="type">UpdateKind</span>? <span class="param">updateKind</span>,
})</code></pre></div>

Executes a custom delete or update statement and returns the amount of
rows that have been changed.
You can use the `updates` parameter so that drift knows which tables are
affected by your query. All select streams that depend on a table
specified there will then update their data. For more accurate results,
you can also set the `updateKind` parameter to [UpdateKind.delete](https://pub.dev/documentation/drift/2.28.2/drift/UpdateKind.html) or
[UpdateKind.update](https://pub.dev/documentation/drift/2.28.2/drift/UpdateKind.html). This is optional, but can improve the accuracy of
query updates, especially when using triggers.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
Future<int> customUpdate(
  String query, {
  List<Variable> variables = const [],
  Set<ResultSetImplementation>? updates,
  UpdateKind? updateKind,
}) async {
  return _customWrite(
    query,
    variables,
    updates,
    updateKind,
    (executor, sql, vars) {
      return executor.runUpdate(sql, vars);
    },
  );
}
```
:::

### customWriteReturning() <Badge type="info" text="inherited" /> {#customwritereturning}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">List</span>&lt;<span class="type">QueryRow</span>&gt;&gt; <span class="fn">customWriteReturning</span>(
  <span class="type">String</span> <span class="param">query</span>, {
  <span class="type">List</span>&lt;<span class="type">Variable</span>&lt;<span class="type">Object</span>&gt;&gt; <span class="param">variables</span> = const [],
  <span class="type">Set</span>&lt;<span class="type">ResultSetImplementation</span>&lt;<span class="type">dynamic</span>, <span class="type">dynamic</span>&gt;&gt;? <span class="param">updates</span>,
  <span class="type">UpdateKind</span>? <span class="param">updateKind</span>,
})</code></pre></div>

Runs a `INSERT`, `UPDATE` or `DELETE` statement returning rows.

You can use the `updates` parameter so that drift knows which tables are
affected by your query. All select streams that depend on a table
specified there will then update their data. For more accurate results,
you can also set the `updateKind` parameter.
This is optional, but can improve the accuracy of query updates,
especially when using triggers.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
Future<List<QueryRow>> customWriteReturning(
  String query, {
  List<Variable> variables = const [],
  Set<ResultSetImplementation>? updates,
  UpdateKind? updateKind,
}) {
  return _customWrite(query, variables, updates, updateKind,
      (executor, sql, vars) async {
    final rows = await executor.runSelect(sql, vars);
    return [for (final row in rows) QueryRow(row, attachedDatabase)];
  });
}
```
:::

### delete() <Badge type="info" text="inherited" /> {#delete}

<div class="member-signature"><pre><code><span class="type">DeleteStatement</span>&lt;<span class="type">T</span>, <span class="type">D</span>&gt; <span class="fn">delete&lt;T extends Table, D&gt;</span>(<span class="type">TableInfo</span>&lt;<span class="type">T</span>, <span class="type">D</span>&gt; <span class="param">table</span>)</code></pre></div>

Starts a [DeleteStatement](https://pub.dev/documentation/drift/2.28.2/drift/DeleteStatement-class.html) that can be used to delete rows from a table.

See the [documentation](https://drift.simonbinder.eu/docs/dart-api/writes/#updates-and-deletes)
for more details and example on how delete statements work.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
DeleteStatement<T, D> delete<T extends Table, D>(TableInfo<T, D> table) {
  return DeleteStatement<T, D>(this, table);
}
```
:::

### deleteOutboxMeta() {#deleteoutboxmeta}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">deleteOutboxMeta</span>(<span class="type">Iterable</span>&lt;<span class="type">String</span>&gt; <span class="param">opIds</span>)</code></pre></div>

Remove outbox metadata for the specified operations.

:::details Implementation
```dart
Future<void> deleteOutboxMeta(Iterable<String> opIds) async {
  if (opIds.isEmpty) return;
  final ids = opIds.toList();
  final placeholders = List.filled(ids.length, '?').join(', ');
  await customStatement(
    'DELETE FROM ${TableNames.syncOutboxMeta} '
    'WHERE ${TableColumns.opId} IN ($placeholders)',
    ids,
  );
}
```
:::

### doWhenOpened() <Badge type="info" text="inherited" /> {#dowhenopened}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">T</span>&gt; <span class="fn">doWhenOpened&lt;T&gt;</span>(<span class="type">FutureOr</span>&lt;<span class="type">T</span>&gt; <span class="type">Function</span>(<span class="type">QueryExecutor</span> <span class="param">e</span>) <span class="param">fn</span>)</code></pre></div>

Performs the async `fn` after this executor is ready, or directly if it's
already ready.

Calling this method directly might circumvent the current transaction. For
that reason, it should only be called inside drift.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
Future<T> doWhenOpened<T>(FutureOr<T> Function(QueryExecutor e) fn) {
  return executor.ensureOpen(attachedDatabase).then((_) {
    _isOpen = true;
    return fn(executor);
  });
}
```
:::

### enqueue() {#enqueue}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">enqueue</span>(<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/Op" class="type-link">Op</a> <span class="param">op</span>)</code></pre></div>

Add operation to the outbox queue.

:::details Implementation
```dart
Future<void> enqueue(Op op) async {
  final ts = op.localTimestamp.toUtc().millisecondsSinceEpoch;

  if (op is UpsertOp) {
    final baseTs = op.baseUpdatedAt?.toUtc().millisecondsSinceEpoch;
    final changedFieldsJson =
        op.changedFields != null
            ? jsonEncode(op.changedFields!.toList())
            : null;

    await into(_outbox).insertOnConflictUpdate(
      SyncOutboxCompanion.insert(
        opId: op.opId,
        kind: op.kind,
        entityId: op.id,
        op: OpType.upsert,
        ts: ts,
        payload: Value(jsonEncode(op.payloadJson)),
        tryCount: const Value(0),
        baseUpdatedAt: Value(baseTs),
        changedFields: Value(changedFieldsJson),
      ),
    );
  } else if (op is DeleteOp) {
    final baseTs = op.baseUpdatedAt?.toUtc().millisecondsSinceEpoch;

    await into(_outbox).insertOnConflictUpdate(
      SyncOutboxCompanion.insert(
        opId: op.opId,
        kind: op.kind,
        entityId: op.id,
        op: OpType.delete,
        ts: ts,
        tryCount: const Value(0),
        baseUpdatedAt: Value(baseTs),
      ),
    );
  }
}
```
:::

### enqueueDelete() <Badge type="info" text="extension" /> {#enqueuedelete}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">enqueueDelete&lt;T&gt;</span>(
  <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable" class="type-link">SyncableTable</a>&lt;<span class="type">T</span>&gt; <span class="param">table</span>, {
  <span class="kw">required</span> <span class="type">String</span> <span class="param">id</span>,
  <span class="type">DateTime</span>? <span class="param">baseUpdatedAt</span>,
  (<span class="type">String</span> <span class="type">Function</span>())? <span class="param">opIdFactory</span>,
  (<span class="type">DateTime</span> <span class="type">Function</span>())? <span class="param">clock</span>,
  <span class="type">String</span>? <span class="param">opId</span>,
  <span class="type">DateTime</span>? <span class="param">localTimestamp</span>,
})</code></pre></div>

Enqueue a delete (without touching local DB).

*Available on GeneratedDatabase, provided by the [SyncDatabaseDx](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseDx) extension*

:::details Implementation
```dart
Future<void> enqueueDelete<T>(
  SyncableTable<T> table, {
  required String id,
  DateTime? baseUpdatedAt,
  OpIdFactory? opIdFactory,
  SyncClock? clock,
  String? opId,
  DateTime? localTimestamp,
}) => syncWriter(opIdFactory: opIdFactory, clock: clock)
    .forTable(table)
    .enqueueDelete(
      id: id,
      baseUpdatedAt: baseUpdatedAt,
      opId: opId,
      localTimestamp: localTimestamp,
    );
```
:::

### exclusively() <Badge type="info" text="inherited" /> {#exclusively}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">T</span>&gt; <span class="fn">exclusively&lt;T&gt;</span>(<span class="type">Future</span>&lt;<span class="type">T</span>&gt; <span class="type">Function</span>() <span class="param">action</span>)</code></pre></div>

Obtains an exclusive lock on the current database context, runs `action`
in it and then releases the lock.

This obtains a local lock on the underlying [executor](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/executor.html) without starting a
transaction or coordinating with other processes on the same database.
It is possible to start a [transaction](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/transaction.html) within an [exclusively](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/exclusively.html) block.
When [exclusively](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/exclusively.html) is called on a database connected to a remote isolate
or a shared web worker, other isolates and tabs will be blocked on the
database until the returned future completes.

With sqlite3, [exclusively](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/exclusively.html) is useful to set certain pragmas like
`foreign_keys` which can't be done in a transaction for a limited scope.
For instance, some migrations may look like this:

```dart
await exclusively(() async {
  await customStatement('pragma foreign_keys = OFF;');
  await transaction(() async {
    // complex updates or migrations temporarily breaking foreign
    // references...
  });
  await customStatement('pragma foreign_keys = OFF;');
});
```

If the [exclusively](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/exclusively.html) block had been omitted from the previous snippet,
it would have been possible for other concurrent database calls to occur
between the transaction and the `pragma` statements.

Outside of blocks requiring exclusive access to set pragmas not supported
in transactions, consider using [transaction](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/transaction.html) instead of [exclusively](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/exclusively.html).
Transactions also take exclusive control over the database, but they also
are atomic (either all statements in a transaction complete or none at
all), whereas an error in an [exclusively](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/exclusively.html) block does not roll back
earlier statements.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
Future<T> exclusively<T>(Future<T> Function() action) async {
  return await resolvedEngine.doWhenOpened((executor) {
    final exclusive = executor.beginExclusive();

    return _runConnectionZoned(
      _ExclusiveExecutor(this, executor: exclusive),
      () async {
        await exclusive.ensureOpen(attachedDatabase);

        try {
          return await action();
        } finally {
          exclusive.close();
        }
      },
    );
  });
}
```
:::

### getCursor() {#getcursor}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/Cursor" class="type-link">Cursor</a>?&gt; <span class="fn">getCursor</span>(<span class="type">String</span> <span class="param">kind</span>)</code></pre></div>

Get cursor for an entity kind.

:::details Implementation
```dart
Future<Cursor?> getCursor(String kind) async {
  final rows =
      await customSelect(
        'SELECT ${TableColumns.ts}, ${TableColumns.lastId} '
        'FROM ${TableNames.syncCursors} WHERE ${TableColumns.kind} = ?',
        variables: [Variable.withString(kind)],
        readsFrom: {_cursors},
      ).get();

  if (rows.isEmpty) return null;

  final row = rows.first;
  return Cursor(
    ts: DateTime.fromMillisecondsSinceEpoch(
      row.read<int>(TableColumns.ts),
      isUtc: true,
    ),
    lastId: row.read<String>(TableColumns.lastId),
  );
}
```
:::

### getStuckOutbox() {#getstuckoutbox}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">List</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/Op" class="type-link">Op</a>&gt;&gt; <span class="fn">getStuckOutbox</span>({
  <span class="kw">required</span> <span class="type">int</span> <span class="param">minTryCount</span>,
  <span class="type">int</span> <span class="param">limit</span> = <span class="num-lit">100</span>,
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">kinds</span>,
})</code></pre></div>

Get operations considered stuck by try-count threshold.

:::details Implementation
```dart
Future<List<Op>> getStuckOutbox({
  required int minTryCount,
  int limit = 100,
  Set<String>? kinds,
}) async {
  if (minTryCount <= 0) {
    throw ArgumentError.value(minTryCount, 'minTryCount', 'must be > 0');
  }
  final hasKindsFilter = kinds != null;
  if (hasKindsFilter && kinds.isEmpty) return const <Op>[];

  final whereParts = <String>['${TableColumns.tryCount} >= ?'];
  final variables = <Variable<Object>>[Variable.withInt(minTryCount)];

  if (hasKindsFilter) {
    final kindList = kinds.toList()..sort();
    final placeholders = List.filled(kindList.length, '?').join(', ');
    whereParts.add('${TableColumns.kind} IN ($placeholders)');
    variables.addAll(kindList.map(Variable.withString));
  }

  final whereClause = whereParts.join(' AND ');
  variables.add(Variable.withInt(limit));
  final rows =
      await customSelect(
        'SELECT * FROM ${TableNames.syncOutbox} '
        'WHERE $whereClause '
        'ORDER BY ${TableColumns.ts} LIMIT ?',
        variables: variables,
        readsFrom: {_outbox},
      ).get();
  return _rowsToOps(rows);
}
```
:::

### incrementOutboxTryCount() {#incrementoutboxtrycount}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">incrementOutboxTryCount</span>(<span class="type">Iterable</span>&lt;<span class="type">String</span>&gt; <span class="param">opIds</span>)</code></pre></div>

Increment try count for operations.

:::details Implementation
```dart
Future<void> incrementOutboxTryCount(Iterable<String> opIds) async {
  if (opIds.isEmpty) return;
  final ids = opIds.toList();
  final placeholders = List.filled(ids.length, '?').join(', ');
  await customStatement(
    'UPDATE ${TableNames.syncOutbox} '
    'SET ${TableColumns.tryCount} = ${TableColumns.tryCount} + 1 '
    'WHERE ${TableColumns.opId} IN ($placeholders)',
    ids,
  );
}
```
:::

### insertAndEnqueue() <Badge type="info" text="extension" /> {#insertandenqueue}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">insertAndEnqueue&lt;T&gt;</span>(
  <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable" class="type-link">SyncableTable</a>&lt;<span class="type">T</span>&gt; <span class="param">table</span>,
  <span class="type">T</span> <span class="param">entity</span>, {
  (<span class="type">String</span> <span class="type">Function</span>())? <span class="param">opIdFactory</span>,
  (<span class="type">DateTime</span> <span class="type">Function</span>())? <span class="param">clock</span>,
  <span class="type">String</span>? <span class="param">opId</span>,
  <span class="type">DateTime</span>? <span class="param">localTimestamp</span>,
})</code></pre></div>

Insert `entity` and enqueue an upsert.

*Available on GeneratedDatabase, provided by the [SyncDatabaseDx](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseDx) extension*

:::details Implementation
```dart
Future<void> insertAndEnqueue<T>(
  SyncableTable<T> table,
  T entity, {
  OpIdFactory? opIdFactory,
  SyncClock? clock,
  String? opId,
  DateTime? localTimestamp,
}) => syncWriter(opIdFactory: opIdFactory, clock: clock)
    .forTable(table)
    .insertAndEnqueue(entity, opId: opId, localTimestamp: localTimestamp);
```
:::

### into() <Badge type="info" text="inherited" /> {#into}

<div class="member-signature"><pre><code><span class="type">InsertStatement</span>&lt;<span class="type">T</span>, <span class="type">D</span>&gt; <span class="fn">into&lt;T extends Table, D&gt;</span>(<span class="type">TableInfo</span>&lt;<span class="type">T</span>, <span class="type">D</span>&gt; <span class="param">table</span>)</code></pre></div>

Starts an [InsertStatement](https://pub.dev/documentation/drift/2.28.2/drift/InsertStatement-class.html) for a given table. You can use that statement
to write data into the `table` by using [InsertStatement.insert](https://pub.dev/documentation/drift/2.28.2/drift/InsertStatement/insert.html).

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
InsertStatement<T, D> into<T extends Table, D>(TableInfo<T, D> table) {
  return InsertStatement<T, D>(this, table);
}
```
:::

### markTablesUpdated() <Badge type="info" text="inherited" /> {#marktablesupdated}

<div class="member-signature"><pre><code><span class="type">void</span> <span class="fn">markTablesUpdated</span>(<span class="type">Iterable</span>&lt;<span class="type">TableInfo</span>&lt;<span class="type">Table</span>, <span class="type">dynamic</span>&gt;&gt; <span class="param">tables</span>)</code></pre></div>

Marks the `tables` as updated.

In response to calling this method, all streams listening on any of the
`tables` will load their data again.

Primarily, this method is meant to be used by drift-internal code. Higher-
level drift APIs will call this method to dispatch stream updates.
Of course, you can also call it yourself to manually dispatch table
updates. To obtain a [TableInfo](https://pub.dev/documentation/drift/2.28.2/drift/TableInfo-mixin.html), use the corresponding getter on the
database class.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
void markTablesUpdated(Iterable<TableInfo> tables) {
  notifyUpdates(
    {for (final table in tables) TableUpdate(table.actualTableName)},
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

### notifyUpdates() <Badge type="info" text="inherited" /> {#notifyupdates}

<div class="member-signature"><pre><code><span class="type">void</span> <span class="fn">notifyUpdates</span>(<span class="type">Set</span>&lt;<span class="type">TableUpdate</span>&gt; <span class="param">updates</span>)</code></pre></div>

Dispatches the set of `updates` to the stream query manager.

This method is more specific than [markTablesUpdated](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/markTablesUpdated.html) in the presence of
triggers or foreign key constraints. Drift needs to support both when
calculating which streams to update. For instance, consider a simple
database with two tables (`a` and `b`) and a trigger inserting into `b`
after a delete on `a`).
Now, an insert on `a` should not update a stream listening on table `b`,
but a delete should! This additional information is not available with
[markTablesUpdated](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/markTablesUpdated.html), so [notifyUpdates](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/notifyUpdates.html) can be used to more efficiently
calculate stream updates in some instances.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
void notifyUpdates(Set<TableUpdate> updates) {
  final withRulesApplied = attachedDatabase.streamUpdateRules.apply(updates);
  resolvedEngine.streamQueries.handleTableUpdates(withRulesApplied);
}
```
:::

### purgeOutboxOlderThan() {#purgeoutboxolderthan}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">int</span>&gt; <span class="fn">purgeOutboxOlderThan</span>(<span class="type">DateTime</span> <span class="param">threshold</span>)</code></pre></div>

Purge operations older than threshold.

:::details Implementation
```dart
Future<int> purgeOutboxOlderThan(DateTime threshold) async {
  final th = threshold.toUtc().millisecondsSinceEpoch;
  return customUpdate(
    'DELETE FROM ${TableNames.syncOutbox} WHERE ${TableColumns.ts} <= ?',
    variables: [Variable.withInt(th)],
    updateKind: UpdateKind.delete,
  );
}
```
:::

### recordOutboxFailures() {#recordoutboxfailures}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">recordOutboxFailures</span>(
  <span class="type">Map</span>&lt;<span class="type">String</span>, <span class="type">String</span>&gt; <span class="param">errors</span>, {
  <span class="type">DateTime</span>? <span class="param">triedAt</span>,
})</code></pre></div>

Record outbox failures: increment tryCount and store last error metadata.

:::details Implementation
```dart
Future<void> recordOutboxFailures(
  Map<String, String> errors, {
  DateTime? triedAt,
}) async {
  if (errors.isEmpty) return;
  final ts = (triedAt ?? DateTime.now().toUtc()).millisecondsSinceEpoch;

  await transaction(() async {
    await incrementOutboxTryCount(errors.keys);

    try {
      for (final entry in errors.entries) {
        await into(_outboxMeta).insertOnConflictUpdate(
          SyncOutboxMetaCompanion.insert(
            opId: entry.key,
            lastTriedAt: Value(ts),
            lastError: Value(entry.value),
          ),
        );
      }
    } catch (_) {
      &#47;&#47; Metadata is optional; ignore if table is unavailable.
    }
  });
}
```
:::

### replaceAndEnqueue() <Badge type="info" text="extension" /> {#replaceandenqueue}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">replaceAndEnqueue&lt;T&gt;</span>(
  <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable" class="type-link">SyncableTable</a>&lt;<span class="type">T</span>&gt; <span class="param">table</span>,
  <span class="type">T</span> <span class="param">entity</span>, {
  <span class="kw">required</span> <span class="type">DateTime</span> <span class="param">baseUpdatedAt</span>,
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">changedFields</span>,
  (<span class="type">String</span> <span class="type">Function</span>())? <span class="param">opIdFactory</span>,
  (<span class="type">DateTime</span> <span class="type">Function</span>())? <span class="param">clock</span>,
  <span class="type">String</span>? <span class="param">opId</span>,
  <span class="type">DateTime</span>? <span class="param">localTimestamp</span>,
})</code></pre></div>

Replace `entity` and enqueue an upsert.

*Available on GeneratedDatabase, provided by the [SyncDatabaseDx](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseDx) extension*

:::details Implementation
```dart
Future<void> replaceAndEnqueue<T>(
  SyncableTable<T> table,
  T entity, {
  required DateTime baseUpdatedAt,
  Set<String>? changedFields,
  OpIdFactory? opIdFactory,
  SyncClock? clock,
  String? opId,
  DateTime? localTimestamp,
}) => syncWriter(opIdFactory: opIdFactory, clock: clock)
    .forTable(table)
    .replaceAndEnqueue(
      entity,
      baseUpdatedAt: baseUpdatedAt,
      changedFields: changedFields,
      opId: opId,
      localTimestamp: localTimestamp,
    );
```
:::

### replaceAndEnqueueDiff() <Badge type="info" text="extension" /> {#replaceandenqueuediff}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">replaceAndEnqueueDiff&lt;T&gt;</span>(
  <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable" class="type-link">SyncableTable</a>&lt;<span class="type">T</span>&gt; <span class="param">table</span>, {
  <span class="kw">required</span> <span class="type">T</span> <span class="param">before</span>,
  <span class="kw">required</span> <span class="type">T</span> <span class="param">after</span>,
  <span class="kw">required</span> <span class="type">DateTime</span> <span class="param">baseUpdatedAt</span>,
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt; <span class="param">ignoredFields</span> = ChangedFieldsDiff.defaultIgnoredFields,
  (<span class="type">String</span> <span class="type">Function</span>())? <span class="param">opIdFactory</span>,
  (<span class="type">DateTime</span> <span class="type">Function</span>())? <span class="param">clock</span>,
  <span class="type">String</span>? <span class="param">opId</span>,
  <span class="type">DateTime</span>? <span class="param">localTimestamp</span>,
})</code></pre></div>

Replace `after` and enqueue an upsert with auto-diff `changedFields`.

*Available on GeneratedDatabase, provided by the [SyncDatabaseDx](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseDx) extension*

:::details Implementation
```dart
Future<void> replaceAndEnqueueDiff<T>(
  SyncableTable<T> table, {
  required T before,
  required T after,
  required DateTime baseUpdatedAt,
  Set<String> ignoredFields = ChangedFieldsDiff.defaultIgnoredFields,
  OpIdFactory? opIdFactory,
  SyncClock? clock,
  String? opId,
  DateTime? localTimestamp,
}) => syncWriter(opIdFactory: opIdFactory, clock: clock)
    .forTable(table)
    .replaceAndEnqueueDiff(
      before: before,
      after: after,
      baseUpdatedAt: baseUpdatedAt,
      ignoredFields: ignoredFields,
      opId: opId,
      localTimestamp: localTimestamp,
    );
```
:::

### resetAllCursors() {#resetallcursors}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">resetAllCursors</span>(<span class="type">Set</span>&lt;<span class="type">String</span>&gt; <span class="param">kinds</span>)</code></pre></div>

Reset all cursors for the specified kinds.

:::details Implementation
```dart
Future<void> resetAllCursors(Set<String> kinds) async {
  if (kinds.isEmpty) return;

  final placeholders = List.filled(kinds.length, '?').join(', ');
  await customStatement(
    'DELETE FROM ${TableNames.syncCursors} WHERE ${TableColumns.kind} IN ($placeholders)',
    kinds.toList(),
  );
}
```
:::

### resetOutboxTryCount() {#resetoutboxtrycount}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">resetOutboxTryCount</span>(<span class="type">Iterable</span>&lt;<span class="type">String</span>&gt; <span class="param">opIds</span>)</code></pre></div>

Reset try count for operations.

:::details Implementation
```dart
Future<void> resetOutboxTryCount(Iterable<String> opIds) async {
  if (opIds.isEmpty) return;
  final ids = opIds.toList();
  final placeholders = List.filled(ids.length, '?').join(', ');
  await customStatement(
    'UPDATE ${TableNames.syncOutbox} '
    'SET ${TableColumns.tryCount} = 0 '
    'WHERE ${TableColumns.opId} IN ($placeholders)',
    ids,
  );
}
```
:::

### resultSet() <Badge type="info" text="extension" /> {#resultset}

<div class="member-signature"><pre><code><span class="type">T</span> <span class="fn">resultSet&lt;T extends ResultSetImplementation&gt;</span>(<span class="type">String</span> <span class="param">name</span>)</code></pre></div>

Find a result set by its `name` in the database. The result is cached.

*Available on GeneratedDatabase, provided by the ReadDatabaseContainer extension*

:::details Implementation
```dart
T resultSet<T extends ResultSetImplementation>(String name) {
  return _cache.knownEntities[name]! as T;
}
```
:::

### runWithInterceptor() <Badge type="info" text="inherited" /> {#runwithinterceptor}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">T</span>&gt; <span class="fn">runWithInterceptor&lt;T&gt;</span>(
  <span class="type">Future</span>&lt;<span class="type">T</span>&gt; <span class="type">Function</span>() <span class="param">action</span>, {
  <span class="kw">required</span> <span class="type">QueryInterceptor</span> <span class="param">interceptor</span>,
})</code></pre></div>

Executes `action` with calls intercepted by the given `interceptor`

This can be used to, for instance, write a custom statement logger or to
retry failing statements automatically.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
Future<T> runWithInterceptor<T>(Future<T> Function() action,
    {required QueryInterceptor interceptor}) async {
  return await resolvedEngine.doWhenOpened((executor) {
    final inner = _ExclusiveExecutor(this,
        executor: executor.interceptWith(interceptor));
    return _runConnectionZoned(inner, action);
  });
}
```
:::

### select() <Badge type="info" text="inherited" /> {#select}

<div class="member-signature"><pre><code><span class="type">SimpleSelectStatement</span>&lt;<span class="type">T</span>, <span class="type">R</span>&gt; <span class="fn">select&lt;T extends HasResultSet, R&gt;</span>(
  <span class="type">ResultSetImplementation</span>&lt;<span class="type">T</span>, <span class="type">R</span>&gt; <span class="param">table</span>, {
  <span class="type">bool</span> <span class="param">distinct</span> = <span class="kw">false</span>,
})</code></pre></div>

Starts a query on the given table.

In drift, queries are commonly used as a builder by chaining calls on them
using the `..` syntax from Dart. For instance, to load the 10 oldest users
with an 'S' in their name, you could use:

```dart
Future<List<User>> oldestUsers() {
  return (
    select(users)
      ..where((u) => u.name.like('%S%'))
      ..orderBy([(u) => OrderingTerm(
        expression: u.id,
        mode: OrderingMode.asc
      )])
      ..limit(10)
  ).get();
}
```

The `distinct` parameter (defaults to false) can be used to remove
duplicate rows from the result set.

For more information on queries, see the
[documentation](https://drift.simonbinder.eu/docs/getting-started/writing_queries/).

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
SimpleSelectStatement<T, R> select<T extends HasResultSet, R>(
    ResultSetImplementation<T, R> table,
    {bool distinct = false}) {
  return SimpleSelectStatement<T, R>(this, table, distinct: distinct);
}
```
:::

### selectExpressions() <Badge type="info" text="inherited" /> {#selectexpressions}

<div class="member-signature"><pre><code><span class="type">BaseSelectStatement</span>&lt;<span class="type">TypedResult</span>&gt; <span class="fn">selectExpressions</span>(
  <span class="type">Iterable</span>&lt;<span class="type">Expression</span>&lt;<span class="type">Object</span>&gt;&gt; <span class="param">columns</span>,
)</code></pre></div>

Creates a select statement without a `FROM` clause selecting `columns`.

In SQL, select statements without a table will return a single row where
all the `columns` are evaluated. Of course, columns cannot refer to
columns from a table as these are unavailable without a `FROM` clause.

To run or watch the select statement, call [Selectable.get](https://pub.dev/documentation/drift/2.28.2/drift/Selectable/get.html) or
[Selectable.watch](https://pub.dev/documentation/drift/2.28.2/drift/Selectable/watch.html). Each returns a list of [TypedResult](https://pub.dev/documentation/drift/2.28.2/drift/TypedResult-class.html) rows, for which
a column can be read with [TypedResult.read](https://pub.dev/documentation/drift/2.28.2/drift/TypedResult/read.html).

This example uses [selectExpressions](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/selectExpressions.html) to query the current time set on the
database server:

```dart
final row = await selectExpressions([currentDateAndTime]).getSingle();
final databaseTime = row.read(currentDateAndTime)!;
```

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
BaseSelectStatement<TypedResult> selectExpressions(
    Iterable<Expression> columns) {
  return SelectWithoutTables(this, columns);
}
```
:::

### selectOnly() <Badge type="info" text="inherited" /> {#selectonly}

<div class="member-signature"><pre><code><span class="type">JoinedSelectStatement</span>&lt;<span class="type">T</span>, <span class="type">R</span>&gt; <span class="fn">selectOnly&lt;T extends HasResultSet, R&gt;</span>(
  <span class="type">ResultSetImplementation</span>&lt;<span class="type">T</span>, <span class="type">R</span>&gt; <span class="param">table</span>, {
  <span class="type">bool</span> <span class="param">distinct</span> = <span class="kw">false</span>,
})</code></pre></div>

Starts a complex statement on `table` that doesn't necessarily use all of
`table`'s columns.

Unlike [select](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/select.html), which automatically selects all columns of `table`, this
method is suitable for more advanced queries that can use `table` without
using their column. As an example, assuming we have a table `comments`
with a `TextColumn content`, this query would report the average length of
a comment:

```dart
Stream<num> watchAverageCommentLength() {
  final avgLength = comments.content.length.avg();
  final query = selectOnly(comments)
    ..addColumns([avgLength]);

  return query.map((row) => row.read(avgLength)).watchSingle();
}
```

While this query reads from `comments`, it doesn't use all of it's columns
(in fact, it uses none of them!). This makes it suitable for
[selectOnly](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/selectOnly.html) instead of [select](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/select.html).

The `distinct` parameter (defaults to false) can be used to remove
duplicate rows from the result set.

For simple queries, use [select](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/select.html).

See also:

- the documentation on [aggregate expressions](https://drift.simonbinder.eu/docs/getting-started/expressions/#aggregate)
- the documentation on [group by](https://drift.simonbinder.eu/docs/advanced-features/joins/#group-by)

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
JoinedSelectStatement<T, R> selectOnly<T extends HasResultSet, R>(
    ResultSetImplementation<T, R> table,
    {bool distinct = false}) {
  return JoinedSelectStatement<T, R>(this, table, [], distinct, false, false);
}
```
:::

### serializableConnection() <Badge type="info" text="extension" /> {#serializableconnection}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">DriftIsolate</span>&gt; <span class="fn">serializableConnection</span>()</code></pre></div>

Creates a [DriftIsolate](https://pub.dev/documentation/drift/2.28.2/isolate/DriftIsolate-class.html) that, when connected to, will run queries on the
database already opened by `this`.

This can be used to share existing database across isolates, as instances
of generated database classes can't be sent across isolates by default. A
[DriftIsolate](https://pub.dev/documentation/drift/2.28.2/isolate/DriftIsolate-class.html) can be sent over ports though, which enables a concise way
to open a temporary isolate that is using an existing database:

```dart
Future<void> main() async {
  final database = MyDatabase(...);

  // This is illegal - MyDatabase is not serializable
  await Isolate.run(() async {
    await database.batch(...);
  });

  // This will work. Only the `connection` is sent to the new isolate. By
  // creating a new database instance based on the connection, the same
  // logical database can be shared across isolates.
  final connection = await database.serializableConnection();
  await Isolate.run(() async {
     final database = MyDatabase(await connection.connect());
     await database.batch(...);
  });
}
```

The example of running a short-lived database for a single task unit
requiring a database is also available through [computeWithDatabase](https://pub.dev/documentation/drift/2.28.2/isolate/ComputeWithDriftIsolate/computeWithDatabase.html).

*Available on DB extends DatabaseConnectionUser, provided by the ComputeWithDriftIsolate\<DB extends DatabaseConnectionUser\> extension*

:::details Implementation
```dart
@experimental
Future<DriftIsolate> serializableConnection() async {
  final currentlyInRootConnection = resolvedEngine is GeneratedDatabase;
  &#47;&#47; ignore: invalid_use_of_protected_member
  final localConnection = resolvedEngine.connection;
  final data = await localConnection.connectionData;

  &#47;&#47; If we're connected to an isolate already, we can use that one directly
  &#47;&#47; instead of starting a short-lived drift server.
  &#47;&#47; However, this does not work if [serializableConnection] is called in a
  &#47;&#47; transaction zone, since the top-level connection could be blocked waiting
  &#47;&#47; for the transaction (as transactions can't be concurrent in sqlite3).
  if (data is DriftIsolate && currentlyInRootConnection) {
    return data;
  } else {
    &#47;&#47; Set up a drift server acting as a proxy to the existing database
    &#47;&#47; connection.
    final server = RunningDriftServer(
      Isolate.current,
      localConnection,
      onlyAcceptSingleConnection: true,
      closeConnectionAfterShutdown: false,
      killIsolateWhenDone: false,
    );

    &#47;&#47; Since the existing database didn't use an isolate server, we need to
    &#47;&#47; manually forward stream query updates.
    final forwardToServer = tableUpdates().listen((localUpdates) {
      server.server.dispatchTableUpdateNotification(
          NotifyTablesUpdated(localUpdates.toList()));
    });
    final forwardToLocal =
        server.server.tableUpdateNotifications.listen((remoteUpdates) {
      notifyUpdates(remoteUpdates.updates.toSet());
    });
    server.server.done.whenComplete(() {
      forwardToServer.cancel();
      forwardToLocal.cancel();
    });

    return DriftIsolate.fromConnectPort(
      server.portToOpenConnection,
      serialize: false,
    );
  }
}
```
:::

### setCursor() {#setcursor}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">setCursor</span>(<span class="type">String</span> <span class="param">kind</span>, <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/Cursor" class="type-link">Cursor</a> <span class="param">cursor</span>)</code></pre></div>

Save cursor for an entity kind.

:::details Implementation
```dart
Future<void> setCursor(String kind, Cursor cursor) async {
  await into(_cursors).insertOnConflictUpdate(
    SyncCursorsCompanion.insert(
      kind: kind,
      ts: cursor.ts.toUtc().millisecondsSinceEpoch,
      lastId: cursor.lastId,
    ),
  );
}
```
:::

### syncWriter() <Badge type="info" text="extension" /> {#syncwriter}

<div class="member-signature"><pre><code><a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncWriter" class="type-link">SyncWriter</a>&lt;<span class="type">DB</span>&gt; <span class="fn">syncWriter</span>({
  (<span class="type">String</span> <span class="type">Function</span>())? <span class="param">opIdFactory</span>,
  (<span class="type">DateTime</span> <span class="type">Function</span>())? <span class="param">clock</span>,
})</code></pre></div>

Create a [SyncWriter](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncWriter) for this database.

Throws if the database does not implement [SyncDatabaseMixin](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseMixin).

*Available on DB extends GeneratedDatabase, provided by the [SyncWriterDatabaseExtension\<DB extends GeneratedDatabase\>](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncWriterDatabaseExtension) extension*

:::details Implementation
```dart
SyncWriter<DB> syncWriter({OpIdFactory? opIdFactory, SyncClock? clock}) =>
    SyncWriter<DB>(this, opIdFactory: opIdFactory, clock: clock);
```
:::

### tableUpdates() <Badge type="info" text="inherited" /> {#tableupdates}

<div class="member-signature"><pre><code><span class="type">Stream</span>&lt;<span class="type">Set</span>&lt;<span class="type">TableUpdate</span>&gt;&gt; <span class="fn">tableUpdates</span>([
  <span class="type">TableUpdateQuery</span> <span class="param">query</span> = const TableUpdateQuery.any(),
])</code></pre></div>

Listen for table updates reported through [notifyUpdates](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/notifyUpdates.html).

By default, this listens to every table update. Table updates are reported
as a set of individual updates that happened atomically.
An optional filter can be provided in the `query` parameter. When set,
only updates matching the query will be reported in the stream.

When called inside a transaction, the stream will close when the
transaction completes or is rolled back. Otherwise, the stream will
complete as the database is closed.

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
Stream<Set<TableUpdate>> tableUpdates(
    [TableUpdateQuery query = const TableUpdateQuery.any()]) {
  &#47;&#47; The stream should refer to the transaction active when tableUpdates was
  &#47;&#47; called, not the one when a listener attaches.
  final engine = resolvedEngine;

  &#47;&#47; We're wrapping updatesForSync in a stream controller to make it async.
  return Stream.multi(
    (controller) {
      final source = engine.streamQueries.updatesForSync(query);
      source.pipe(controller);
    },
    isBroadcast: true,
  );
}
```
:::

### takeOutbox() {#takeoutbox}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">List</span>&lt;<a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/Op" class="type-link">Op</a>&gt;&gt; <span class="fn">takeOutbox</span>({
  <span class="type">int</span> <span class="param">limit</span> = <span class="num-lit">100</span>,
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">kinds</span>,
  <span class="type">int</span>? <span class="param">maxTryCountExclusive</span>,
})</code></pre></div>

Get queued operations for sending.

If `kinds` is provided, only operations for those entity kinds are returned.
If `maxTryCountExclusive` is set, only operations with smaller tryCount
are returned.

:::details Implementation
```dart
Future<List<Op>> takeOutbox({
  int limit = 100,
  Set<String>? kinds,
  int? maxTryCountExclusive,
}) async {
  final rows = await _selectOutboxRows(
    limit: limit,
    kinds: kinds,
    maxTryCountExclusive: maxTryCountExclusive,
  );
  return _rowsToOps(rows);
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

### transaction() <Badge type="info" text="inherited" /> {#transaction}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">T</span>&gt; <span class="fn">transaction&lt;T&gt;</span>(<span class="type">Future</span>&lt;<span class="type">T</span>&gt; <span class="type">Function</span>() <span class="param">action</span>, {<span class="type">bool</span> <span class="param">requireNew</span> = <span class="kw">false</span>})</code></pre></div>

Executes `action` in a transaction, which means that all its queries and
updates will be called atomically.

Returns the value of `action`.
When `action` throws an exception, the transaction will be reset and no
changes will be applied to the databases. The exception will be rethrown
by [transaction](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/transaction.html).

The behavior of stream queries in transactions depends on where the stream
was created:

- streams created outside of a [transaction](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/transaction.html) block: The stream will update
with the tables modified in the transaction after it completes
successfully. If the transaction fails, the stream will not update.
- streams created inside a [transaction](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/transaction.html) block: The stream will update for
each write in the transaction. When the transaction completes,
successful or not, streams created in it will close. Writes happening
outside of this transaction will not affect the stream.

Starting from drift version 2.0, nested transactions are supported on most
database implementations (including `NativeDatabase`, `WebDatabase`,
`WasmDatabase`, `SqfliteQueryExecutor`, databases relayed through
isolates or web workers).
When calling [transaction](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/transaction.html) inside a [transaction](https://pub.dev/documentation/drift/2.28.2/drift/DatabaseConnectionUser/transaction.html) block on supported
database implementations, a new transaction will be started.
For backwards-compatibility, the current transaction will be re-used if
a nested transaction is started with a database implementation not
supporting nested transactions. The `requireNew` parameter can be set to
instead turn this case into a runtime error.

Nested transactions are conceptionally similar to regular, top-level
transactions in the sense that their writes are not seen by users outside
of the transaction until it is commited. However, their behavior around
completions is different:

- When a nested transaction completes, nothing is being persisted right
away. The parent transaction can now see changes from the child
transaction and continues to run. When the outermost transaction
completes, its changes (including changes from child transactions) are
written to the database.
- When a nested transaction is aborted (which happens due to exceptions),
only changes in that inner transaction are reverted. The outer
transaction can continue to run if it catched the exception thrown by
the inner transaction when it aborted.

See also:

- the docs on [transactions](https://drift.simonbinder.eu/docs/transactions/)

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
Future<T> transaction<T>(Future<T> Function() action,
    {bool requireNew = false}) async {
  final resolved = resolvedEngine;

  &#47;&#47; Are we about to start a nested transaction?
  if (resolved is Transaction) {
    final executor = resolved.executor as TransactionExecutor;
    if (!executor.supportsNestedTransactions) {
      if (requireNew) {
        throw UnsupportedError('The current database implementation does '
            'not support nested transactions.');
      } else {
        &#47;&#47; Just run the block in the current transaction zone.
        return action();
      }
    }
  }

  return await resolved.doWhenOpened((executor) {
    final transactionExecutor = executor.beginTransaction();
    final transaction = Transaction(this, transactionExecutor);

    return _runConnectionZoned(transaction, () async {
      var success = false;

      await transactionExecutor.ensureOpen(attachedDatabase);
      try {
        final result = await action();
        success = true;
        return result;
      } catch (e, s) {
        await transactionExecutor.rollbackAfterException(e, s);

        &#47;&#47; pass the exception on to the one who called transaction()
        rethrow;
      } finally {
        if (success) {
          try {
            await transaction.complete();
          } catch (e, s) {
            &#47;&#47; Couldn't commit -> roll back then.
            await transactionExecutor.rollbackAfterException(e, s);
            rethrow;
          }
        }
        await transaction.disposeChildStreams();
      }
    });
  });
}
```
:::

### update() <Badge type="info" text="inherited" /> {#update}

<div class="member-signature"><pre><code><span class="type">UpdateStatement</span>&lt;<span class="type">Tbl</span>, <span class="type">R</span>&gt; <span class="fn">update&lt;Tbl extends Table, R&gt;</span>(<span class="type">TableInfo</span>&lt;<span class="type">Tbl</span>, <span class="type">R</span>&gt; <span class="param">table</span>)</code></pre></div>

Starts an [UpdateStatement](https://pub.dev/documentation/drift/2.28.2/drift/UpdateStatement-class.html) for the given table. You can use that
statement to update individual rows in that table by setting a where
clause on that table and then use [UpdateStatement.write](https://pub.dev/documentation/drift/2.28.2/drift/UpdateStatement/write.html).

*Inherited from DatabaseConnectionUser.*

:::details Implementation
```dart
UpdateStatement<Tbl, R> update<Tbl extends Table, R>(
        TableInfo<Tbl, R> table) =>
    UpdateStatement(this, table);
```
:::

### watchOutboxCount() {#watchoutboxcount}

<div class="member-signature"><pre><code><span class="type">Stream</span>&lt;<span class="type">int</span>&gt; <span class="fn">watchOutboxCount</span>({<span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">kinds</span>, <span class="type">int</span>? <span class="param">maxTryCountExclusive</span>})</code></pre></div>

Watch pending outbox count as a stream.

:::details Implementation
```dart
Stream<int> watchOutboxCount({
  Set<String>? kinds,
  int? maxTryCountExclusive,
}) {
  final hasKindsFilter = kinds != null;
  final hasTryFilter = maxTryCountExclusive != null;
  if (hasKindsFilter && kinds.isEmpty) {
    return Stream<int>.value(0);
  }

  final whereParts = <String>[];
  final variables = <Variable<Object>>[];

  if (hasKindsFilter) {
    final kindList = kinds.toList()..sort();
    final placeholders = List.filled(kindList.length, '?').join(', ');
    whereParts.add('${TableColumns.kind} IN ($placeholders)');
    variables.addAll(kindList.map(Variable.withString));
  }

  if (hasTryFilter) {
    whereParts.add('${TableColumns.tryCount} < ?');
    variables.add(Variable.withInt(maxTryCountExclusive));
  }

  final whereClause =
      whereParts.isEmpty ? '' : 'WHERE ${whereParts.join(' AND ')}';
  return customSelect(
    'SELECT COUNT(*) as c FROM ${TableNames.syncOutbox} $whereClause',
    variables: variables,
    readsFrom: {_outbox},
  ).watch().map((rows) => rows.first.read<int>('c'));
}
```
:::

### watchStuckOutboxCount() {#watchstuckoutboxcount}

<div class="member-signature"><pre><code><span class="type">Stream</span>&lt;<span class="type">int</span>&gt; <span class="fn">watchStuckOutboxCount</span>({
  <span class="kw">required</span> <span class="type">int</span> <span class="param">minTryCount</span>,
  <span class="type">Set</span>&lt;<span class="type">String</span>&gt;? <span class="param">kinds</span>,
})</code></pre></div>

Watch stuck operations count.

:::details Implementation
```dart
Stream<int> watchStuckOutboxCount({
  required int minTryCount,
  Set<String>? kinds,
}) {
  final hasKindsFilter = kinds != null;
  if (hasKindsFilter && kinds.isEmpty) {
    return Stream<int>.value(0);
  }

  final whereParts = <String>['${TableColumns.tryCount} >= ?'];
  final variables = <Variable<Object>>[Variable.withInt(minTryCount)];

  if (hasKindsFilter) {
    final kindList = kinds.toList()..sort();
    final placeholders = List.filled(kindList.length, '?').join(', ');
    whereParts.add('${TableColumns.kind} IN ($placeholders)');
    variables.addAll(kindList.map(Variable.withString));
  }

  final whereClause = 'WHERE ${whereParts.join(' AND ')}';
  return customSelect(
    'SELECT COUNT(*) as c FROM ${TableNames.syncOutbox} $whereClause',
    variables: variables,
    readsFrom: {_outbox},
  ).watch().map((rows) => rows.first.read<int>('c'));
}
```
:::

### writeAndEnqueueDelete() <Badge type="info" text="extension" /> {#writeandenqueuedelete}

<div class="member-signature"><pre><code><span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="fn">writeAndEnqueueDelete&lt;T&gt;</span>(
  <a href="/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable" class="type-link">SyncableTable</a>&lt;<span class="type">T</span>&gt; <span class="param">table</span>, {
  <span class="kw">required</span> <span class="type">Future</span>&lt;<span class="type">void</span>&gt; <span class="type">Function</span>() <span class="param">localWrite</span>,
  <span class="kw">required</span> <span class="type">String</span> <span class="param">id</span>,
  <span class="type">DateTime</span>? <span class="param">baseUpdatedAt</span>,
  (<span class="type">String</span> <span class="type">Function</span>())? <span class="param">opIdFactory</span>,
  (<span class="type">DateTime</span> <span class="type">Function</span>())? <span class="param">clock</span>,
  <span class="type">String</span>? <span class="param">opId</span>,
  <span class="type">DateTime</span>? <span class="param">localTimestamp</span>,
})</code></pre></div>

Run `localWrite` and enqueue delete atomically.

*Available on GeneratedDatabase, provided by the [SyncDatabaseDx](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseDx) extension*

:::details Implementation
```dart
Future<void> writeAndEnqueueDelete<T>(
  SyncableTable<T> table, {
  required Future<void> Function() localWrite,
  required String id,
  DateTime? baseUpdatedAt,
  OpIdFactory? opIdFactory,
  SyncClock? clock,
  String? opId,
  DateTime? localTimestamp,
}) => syncWriter(opIdFactory: opIdFactory, clock: clock)
    .forTable(table)
    .writeAndEnqueueDelete(
      localWrite: localWrite,
      id: id,
      baseUpdatedAt: baseUpdatedAt,
      opId: opId,
      localTimestamp: localTimestamp,
    );
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

