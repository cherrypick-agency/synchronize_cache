import 'package:offline_first_sync_drift/src/exceptions.dart';
import 'package:offline_first_sync_drift/src/op.dart';
import 'package:offline_first_sync_drift/src/sync_database.dart';

/// Service for working with the outbox queue.
class OutboxService {
  OutboxService(this._db);

  final SyncDatabaseMixin _db;

  /// Add operation to the send queue.
  Future<void> enqueue(Op op) async {
    try {
      await _db.enqueue(op);
    } catch (e, st) {
      throw DatabaseException.fromError(e, st);
    }
  }

  /// Get operations from queue for sending.
  Future<List<Op>> take({int limit = 100}) async {
    try {
      return await _db.takeOutbox(limit: limit);
    } catch (e, st) {
      throw DatabaseException.fromError(e, st);
    }
  }

  /// Acknowledge sent operations (remove from queue).
  Future<void> ack(Iterable<String> opIds) async {
    if (opIds.isEmpty) return;
    try {
      await _db.ackOutbox(opIds);
    } catch (e, st) {
      throw DatabaseException.fromError(e, st);
    }
  }

  /// Purge operations older than threshold.
  Future<int> purgeOlderThan(DateTime threshold) async {
    try {
      return await _db.purgeOutboxOlderThan(threshold);
    } catch (e, st) {
      throw DatabaseException.fromError(e, st);
    }
  }

  /// Check whether queue contains operations.
  Future<bool> hasOperations() async {
    final ops = await take(limit: 1);
    return ops.isNotEmpty;
  }
}
