import 'package:offline_first_sync_drift/src/constants.dart';
import 'package:offline_first_sync_drift/src/cursor.dart';
import 'package:offline_first_sync_drift/src/exceptions.dart';
import 'package:offline_first_sync_drift/src/sync_database.dart';

/// Service for synchronization cursors.
class CursorService {
  CursorService(this._db);

  final SyncDatabaseMixin _db;

  /// Get cursor for an entity kind.
  Future<Cursor?> get(String kind) async {
    try {
      return await _db.getCursor(kind);
    } catch (e, st) {
      throw DatabaseException.fromError(e, st);
    }
  }

  /// Save cursor for an entity kind.
  Future<void> set(String kind, Cursor cursor) async {
    try {
      await _db.setCursor(kind, cursor);
    } catch (e, st) {
      throw DatabaseException.fromError(e, st);
    }
  }

  /// Reset cursor for an entity kind.
  Future<void> reset(String kind) async {
    await set(
      kind,
      Cursor(
        ts: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        lastId: '',
      ),
    );
  }

  /// Reset all cursors (except service cursors).
  Future<void> resetAll(Set<String> kinds) async {
    try {
      await _db.resetAllCursors(kinds);
    } catch (e, st) {
      throw DatabaseException.fromError(e, st);
    }
  }

  /// Get timestamp of the last full resync.
  Future<DateTime?> getLastFullResync() async {
    try {
      final cursor = await _db.getCursor(CursorKinds.fullResync);
      if (cursor == null) return null;
      return cursor.ts;
    } catch (e, st) {
      throw DatabaseException.fromError(e, st);
    }
  }

  /// Save timestamp of the last full resync.
  Future<void> setLastFullResync(DateTime timestamp) async {
    try {
      await _db.setCursor(
        CursorKinds.fullResync,
        Cursor(ts: timestamp.toUtc(), lastId: ''),
      );
    } catch (e, st) {
      throw DatabaseException.fromError(e, st);
    }
  }
}
