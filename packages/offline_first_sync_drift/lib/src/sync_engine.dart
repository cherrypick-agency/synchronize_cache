import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/src/config.dart';
import 'package:offline_first_sync_drift/src/exceptions.dart';
import 'package:offline_first_sync_drift/src/services/conflict_service.dart';
import 'package:offline_first_sync_drift/src/services/cursor_service.dart';
import 'package:offline_first_sync_drift/src/services/outbox_service.dart';
import 'package:offline_first_sync_drift/src/services/pull_service.dart';
import 'package:offline_first_sync_drift/src/services/push_service.dart';
import 'package:offline_first_sync_drift/src/sync_database.dart';
import 'package:offline_first_sync_drift/src/sync_events.dart';
import 'package:offline_first_sync_drift/src/syncable_table.dart';
import 'package:offline_first_sync_drift/src/transport_adapter.dart';

/// Synchronization engine: push → pull with pagination and conflict resolution.
///
/// The core engine that orchestrates the sync process between local database
/// and remote server. Handles:
/// - Pushing local changes from outbox to server
/// - Pulling remote changes with cursor-based pagination
/// - Conflict resolution with multiple strategies
/// - Automatic background sync
///
/// Example:
/// ```dart
/// final engine = SyncEngine(
///   db: database,
///   transport: RestTransport(base: Uri.parse('https://api.example.com')),
///   tables: [
///     SyncableTable<Todo>(
///       kind: 'todos',
///       table: database.todos,
///       fromJson: Todo.fromJson,
///       toJson: (t) => t.toJson(),
///       toInsertable: (t) => t.toInsertable(),
///     ),
///   ],
/// );
///
/// await engine.sync();
/// ```
class SyncEngine<DB extends GeneratedDatabase> {
  SyncEngine({
    required DB db,
    required TransportAdapter transport,
    required List<SyncableTable<dynamic>> tables,
    SyncConfig config = const SyncConfig(),
    Map<String, TableConflictConfig>? tableConflictConfigs,
  }) : _db = db,
       _transport = transport,
       _tables = {for (final t in tables) t.kind: t},
       _config = config,
       _tableConflictConfigs = tableConflictConfigs ?? {} {
    if (db is! SyncDatabaseMixin) {
      throw ArgumentError(
        'Database must implement SyncDatabaseMixin. '
        'Add "with SyncDatabaseMixin" to your database class.',
      );
    }

    _initServices();
  }

  final DB _db;
  final TransportAdapter _transport;
  final Map<String, SyncableTable<dynamic>> _tables;
  final SyncConfig _config;
  final Map<String, TableConflictConfig> _tableConflictConfigs;

  final _events = StreamController<SyncEvent>.broadcast();

  late final OutboxService _outboxService;
  late final CursorService _cursorService;
  late final ConflictService<DB> _conflictService;
  late final PushService _pushService;
  late final PullService<DB> _pullService;

  SyncDatabaseMixin get _syncDb => _db as SyncDatabaseMixin;

  void _initServices() {
    _outboxService = OutboxService(_syncDb);
    _cursorService = CursorService(_syncDb);
    _conflictService = ConflictService<DB>(
      db: _db,
      transport: _transport,
      tables: _tables,
      config: _config,
      tableConflictConfigs: _tableConflictConfigs,
      events: _events,
    );
    _pushService = PushService(
      outbox: _outboxService,
      transport: _transport,
      conflictService: _conflictService,
      config: _config,
      events: _events,
    );
    _pullService = PullService<DB>(
      db: _db,
      transport: _transport,
      tables: _tables,
      cursorService: _cursorService,
      config: _config,
      events: _events,
    );
  }

  /// Stream of sync events for monitoring progress and errors.
  Stream<SyncEvent> get events => _events.stream;

  /// Service for managing outbox operations.
  OutboxService get outbox => _outboxService;

  /// Service for managing sync cursors.
  CursorService get cursors => _cursorService;

  Timer? _autoTimer;

  /// Current sync Future.
  /// Allows concurrent callers to share the same Future instead of
  /// silently returning empty stats.
  Future<SyncStats>? _syncFuture;

  /// Current full resync Future.
  Future<SyncStats>? _fullResyncFuture;

  /// Start automatic periodic synchronization.
  ///
  /// [interval] — time between sync attempts (default: 5 minutes).
  void startAuto({Duration interval = const Duration(minutes: 5)}) {
    stopAuto();
    _autoTimer = Timer.periodic(interval, (_) => sync());
  }

  /// Stop automatic synchronization.
  void stopAuto() {
    _autoTimer?.cancel();
    _autoTimer = null;
  }

  /// Perform synchronization.
  ///
  /// [kinds] — if specified, synchronize only these entity types.
  ///
  /// If a sync is already in progress, concurrent callers will receive
  /// the same Future and share the result, avoiding duplicate operations.
  Future<SyncStats> sync({Set<String>? kinds}) {
    // If sync is already running, share the existing Future
    if (_syncFuture != null) {
      return _syncFuture!;
    }

    _syncFuture = _doSync(kinds: kinds);
    return _syncFuture!.whenComplete(() => _syncFuture = null);
  }

  /// Internal sync implementation.
  Future<SyncStats> _doSync({Set<String>? kinds}) async {
    final started = DateTime.now();
    var stats = const SyncStats();

    try {
      final lastFullResync = await _cursorService.getLastFullResync();
      final needsFullResync =
          lastFullResync == null ||
          started.difference(lastFullResync) >= _config.fullResyncInterval;

      if (needsFullResync) {
        return _doFullResync(
          reason: FullResyncReason.scheduled,
          clearData: false,
          started: started,
        );
      }

      _events.add(SyncStarted(SyncPhase.push));
      final pushStats = await _pushService.pushAll();
      stats = stats.copyWith(
        pushed: pushStats.pushed,
        conflicts: pushStats.conflicts,
        conflictsResolved: pushStats.conflictsResolved,
        errors: pushStats.errors,
      );
      _events.add(SyncStarted(SyncPhase.pull));
      final targetKinds = kinds ?? _tables.keys.toSet();
      final pulled = await _pullService.pullKinds(targetKinds);
      stats = stats.copyWith(pulled: pulled);

      _events.add(
        SyncCompleted(
          DateTime.now().difference(started),
          DateTime.now(),
          stats: stats,
        ),
      );

      return stats;
    } on SyncException catch (e, st) {
      _events.add(SyncErrorEvent(SyncPhase.pull, e, st));
      rethrow;
    } catch (e, st) {
      final exception = SyncOperationException(
        'Sync failed',
        phase: 'sync',
        cause: e,
        stackTrace: st,
      );
      _events.add(SyncErrorEvent(SyncPhase.pull, exception, st));
      throw exception;
    }
  }

  /// Perform a full resynchronization.
  ///
  /// [clearData] — if true, clears local data before pull.
  /// Default is false — data remains, cursors are reset,
  /// then pull applies data on top (insertOrReplace).
  ///
  /// If a full resync is already in progress, concurrent callers will
  /// receive the same Future and share the result.
  Future<SyncStats> fullResync({bool clearData = false}) {
    // If full resync is already running, share the existing Future
    if (_fullResyncFuture != null) {
      return _fullResyncFuture!;
    }

    _fullResyncFuture = _doFullResync(
      reason: FullResyncReason.manual,
      clearData: clearData,
      started: DateTime.now(),
    );
    return _fullResyncFuture!.whenComplete(() => _fullResyncFuture = null);
  }

  Future<SyncStats> _doFullResync({
    required FullResyncReason reason,
    required bool clearData,
    required DateTime started,
  }) async {
    var stats = const SyncStats();

    try {
      _events
        ..add(FullResyncStarted(reason))
        ..add(SyncStarted(SyncPhase.push));
      final pushStats = await _pushService.pushAll();
      stats = stats.copyWith(
        pushed: pushStats.pushed,
        conflicts: pushStats.conflicts,
        conflictsResolved: pushStats.conflictsResolved,
        errors: pushStats.errors,
      );

      await _cursorService.resetAll(_tables.keys.toSet());

      if (clearData) {
        final tableNames =
            _tables.values.map((t) => t.table.actualTableName).toList();
        await _syncDb.clearSyncableTables(tableNames);
      }

      _events.add(SyncStarted(SyncPhase.pull));
      final pulled = await _pullService.pullKinds(_tables.keys.toSet());
      stats = stats.copyWith(pulled: pulled);

      await _cursorService.setLastFullResync(DateTime.now());

      _events.add(
        SyncCompleted(
          DateTime.now().difference(started),
          DateTime.now(),
          stats: stats,
        ),
      );

      return stats;
    } on SyncException catch (e, st) {
      _events.add(SyncErrorEvent(SyncPhase.pull, e, st));
      rethrow;
    } catch (e, st) {
      final exception = SyncOperationException(
        'Full resync failed',
        phase: 'fullResync',
        cause: e,
        stackTrace: st,
      );
      _events.add(SyncErrorEvent(SyncPhase.pull, exception, st));
      throw exception;
    }
  }

  /// Release resources.
  ///
  /// IMPORTANT: Always call this method when done using the engine
  /// to prevent memory leaks from the event stream controller.
  void dispose() {
    stopAuto();
    _events.close();
  }
}
