import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/src/op.dart';
import 'package:offline_first_sync_drift/src/op_id.dart';
import 'package:offline_first_sync_drift/src/sync_database.dart';
import 'package:offline_first_sync_drift/src/syncable_table.dart';

/// Generates ids for outbox operations.
typedef OpIdFactory = String Function();

/// Returns "now" timestamps for outbox operations.
typedef SyncClock = DateTime Function();

/// High-level DX wrapper for local writes + outbox enqueue.
///
/// Keeps the low-level escape hatch (`db.enqueue(Op)`) intact, but removes
/// boilerplate like opId/now/kind/toJson from typical CRUD flows.
class SyncWriter<DB extends GeneratedDatabase> {
  SyncWriter(
    this.db, {
    OpIdFactory? opIdFactory,
    SyncClock? clock,
  }) : opIdFactory = opIdFactory ?? OpId.v4,
       clock = clock ?? (() => DateTime.now().toUtc()),
       _syncDb = _requireSyncDb(db);

  final DB db;
  final OpIdFactory opIdFactory;
  final SyncClock clock;
  final SyncDatabaseMixin _syncDb;

  /// Create a typed writer bound to a registered [SyncableTable].
  SyncEntityWriter<T, DB> forTable<T>(SyncableTable<T> table) {
    return SyncEntityWriter<T, DB>._(
      db: db,
      syncDb: _syncDb,
      table: table,
      opIdFactory: opIdFactory,
      clock: clock,
    );
  }

  static SyncDatabaseMixin _requireSyncDb(GeneratedDatabase db) {
    if (db is SyncDatabaseMixin) return db;
    throw ArgumentError(
      'Database must implement SyncDatabaseMixin. '
      'Add "with SyncDatabaseMixin" to your database class.',
    );
  }
}

/// A typed writer for a single entity kind/table.
class SyncEntityWriter<T, DB extends GeneratedDatabase> {
  SyncEntityWriter._({
    required DB db,
    required SyncDatabaseMixin syncDb,
    required SyncableTable<T> table,
    required OpIdFactory opIdFactory,
    required SyncClock clock,
  }) : _db = db,
       _syncDb = syncDb,
       _table = table,
       _opIdFactory = opIdFactory,
       _clock = clock;

  final DB _db;
  final SyncDatabaseMixin _syncDb;
  final SyncableTable<T> _table;
  final OpIdFactory _opIdFactory;
  final SyncClock _clock;

  String _entityId(T entity) => _table.idOf(entity);

  Map<String, Object?> _payload(T entity) =>
      _table.toJson(entity).cast<String, Object?>();

  /// Run a local write and enqueue [op] atomically.
  Future<void> writeAndEnqueueOp({
    required Future<void> Function() localWrite,
    required Op op,
  }) async {
    await _db.transaction(() async {
      await localWrite();
      await _syncDb.enqueue(op);
    });
  }

  /// Insert [entity] into local DB and enqueue an upsert operation.
  Future<void> insertAndEnqueue(
    T entity, {
    String? opId,
    DateTime? localTimestamp,
  }) async {
    final ts = (localTimestamp ?? _clock()).toUtc();
    final id = _entityId(entity);
    final op = UpsertOp.create(
      kind: _table.kind,
      id: id,
      localTimestamp: ts,
      opId: opId ?? _opIdFactory(),
      payloadJson: _payload(entity),
    );

    await writeAndEnqueueOp(
      localWrite: () async {
        await _db.into(_table.table).insert(_table.getInsertable(entity));
      },
      op: op,
    );
  }

  /// Replace [entity] in local DB and enqueue an upsert operation.
  ///
  /// [baseUpdatedAt] is required for conflict detection for updates.
  /// [changedFields] should include only fields changed by the user.
  Future<void> replaceAndEnqueue(
    T entity, {
    required DateTime baseUpdatedAt,
    Set<String>? changedFields,
    String? opId,
    DateTime? localTimestamp,
  }) async {
    final ts = (localTimestamp ?? _clock()).toUtc();
    final id = _entityId(entity);
    final op = UpsertOp.create(
      kind: _table.kind,
      id: id,
      localTimestamp: ts,
      opId: opId ?? _opIdFactory(),
      payloadJson: _payload(entity),
      baseUpdatedAt: baseUpdatedAt,
      changedFields: changedFields,
    );

    await writeAndEnqueueOp(
      localWrite: () async {
        await _db.update(_table.table).replace(_table.getInsertable(entity));
      },
      op: op,
    );
  }

  /// Enqueue a delete operation (no local write).
  Future<void> enqueueDelete({
    required String id,
    DateTime? baseUpdatedAt,
    String? opId,
    DateTime? localTimestamp,
  }) async {
    final op = DeleteOp.create(
      kind: _table.kind,
      id: id,
      baseUpdatedAt: baseUpdatedAt,
      opId: opId ?? _opIdFactory(),
      localTimestamp: (localTimestamp ?? _clock()).toUtc(),
    );
    await _syncDb.enqueue(op);
  }

  /// Run a custom local write and enqueue a delete operation atomically.
  Future<void> writeAndEnqueueDelete({
    required Future<void> Function() localWrite,
    required String id,
    DateTime? baseUpdatedAt,
    String? opId,
    DateTime? localTimestamp,
  }) async {
    final op = DeleteOp.create(
      kind: _table.kind,
      id: id,
      baseUpdatedAt: baseUpdatedAt,
      opId: opId ?? _opIdFactory(),
      localTimestamp: (localTimestamp ?? _clock()).toUtc(),
    );
    await writeAndEnqueueOp(localWrite: localWrite, op: op);
  }
}

/// Convenience accessors on Drift databases.
extension SyncWriterDatabaseExtension<DB extends GeneratedDatabase> on DB {
  /// Create a [SyncWriter] for this database.
  ///
  /// Throws if the database does not implement [SyncDatabaseMixin].
  SyncWriter<DB> syncWriter({
    OpIdFactory? opIdFactory,
    SyncClock? clock,
  }) => SyncWriter<DB>(
    this,
    opIdFactory: opIdFactory,
    clock: clock,
  );
}

