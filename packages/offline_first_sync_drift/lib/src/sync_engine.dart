import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/src/config.dart';
import 'package:offline_first_sync_drift/src/exceptions.dart';
import 'package:offline_first_sync_drift/src/op.dart';
import 'package:offline_first_sync_drift/src/services/conflict_service.dart';
import 'package:offline_first_sync_drift/src/services/cursor_service.dart';
import 'package:offline_first_sync_drift/src/services/outbox_service.dart';
import 'package:offline_first_sync_drift/src/services/pull_service.dart';
import 'package:offline_first_sync_drift/src/services/push_service.dart';
import 'package:offline_first_sync_drift/src/sync_database.dart';
import 'package:offline_first_sync_drift/src/sync_error.dart';
import 'package:offline_first_sync_drift/src/sync_events.dart';
import 'package:offline_first_sync_drift/src/syncable_table.dart';
import 'package:offline_first_sync_drift/src/transport_adapter.dart';

/// Rich result model for a sync run.
class SyncRunResult {
  const SyncRunResult({
    required this.push,
    required this.pull,
    required this.stats,
    required this.duration,
    required this.kindsPushed,
    required this.kindsPulled,
    required this.stuckOpsCount,
    this.firstError,
  });

  final PushStats push;
  final PullStats pull;
  final SyncStats stats;
  final Duration duration;
  final Set<String> kindsPushed;
  final Set<String> kindsPulled;
  final int stuckOpsCount;
  final SyncErrorInfo? firstError;

  bool get hadErrors => stats.errors > 0 || firstError != null;
}

class PullStats {
  const PullStats({required this.pulled});

  final int pulled;
}

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
       _tables = _buildTablesMap(tables),
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

  static Map<String, SyncableTable<dynamic>> _buildTablesMap(
    List<SyncableTable<dynamic>> tables,
  ) {
    final map = <String, SyncableTable<dynamic>>{};
    for (final table in tables) {
      final kind = table.kind.trim();
      if (kind.isEmpty) {
        throw ArgumentError.value(
          table.kind,
          'tables.kind',
          'kind must not be empty',
        );
      }
      if (map.containsKey(kind)) {
        throw ArgumentError(
          'Duplicate table kind "$kind". Each SyncableTable kind must be unique.',
        );
      }
      map[kind] = table;
    }
    return map;
  }

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

  /// Return operations that reached stuck threshold.
  Future<List<Op>> getStuckOperations({Set<String>? kinds}) {
    return _outboxService.getStuck(
      minTryCount: _config.maxOutboxTryCount,
      kinds: kinds,
    );
  }

  /// Reset retry counters for stuck operations.
  Future<void> retryStuckOperations({Set<String>? kinds}) async {
    final stuck = await getStuckOperations(kinds: kinds);
    await _outboxService.resetTryCount(stuck.map((op) => op.opId));
  }

  /// Drop stuck operations from outbox.
  Future<void> dropStuckOperations({Set<String>? kinds}) async {
    final stuck = await getStuckOperations(kinds: kinds);
    await _outboxService.ack(stuck.map((op) => op.opId));
  }

  Timer? _autoTimer;

  /// Current sync Future.
  /// Allows concurrent callers to share the same Future instead of
  /// silently returning empty stats.
  Future<SyncRunResult>? _syncRunFuture;

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
  /// [pushKinds] — if specified, push only these entity kinds.
  /// [pullKinds] — if specified, pull only these entity kinds.
  ///
  /// [kinds] is a legacy alias that applies the same filter to push and pull.
  /// Use [pushKinds]/[pullKinds] for explicit behavior.
  ///
  /// If a sync is already in progress, concurrent callers will receive
  /// the same Future and share the result, avoiding duplicate operations.
  Future<SyncStats> sync({
    @Deprecated('Use pushKinds/pullKinds instead.') Set<String>? kinds,
    Set<String>? pushKinds,
    Set<String>? pullKinds,
  }) {
    if (kinds != null && (pushKinds != null || pullKinds != null)) {
      throw ArgumentError(
        'Do not combine legacy "kinds" with "pushKinds"/"pullKinds".',
      );
    }

    final targetPushKinds = pushKinds ?? kinds;
    final targetPullKinds = pullKinds ?? kinds;

    final runFuture = _ensureSyncRun(
      pushKinds: targetPushKinds,
      pullKinds: targetPullKinds,
    );
    return runFuture.then((r) => r.stats);
  }

  /// Perform synchronization and return structured run metadata.
  Future<SyncRunResult> syncRun({
    @Deprecated('Use pushKinds/pullKinds instead.') Set<String>? kinds,
    Set<String>? pushKinds,
    Set<String>? pullKinds,
  }) async {
    if (kinds != null && (pushKinds != null || pullKinds != null)) {
      throw ArgumentError(
        'Do not combine legacy "kinds" with "pushKinds"/"pullKinds".',
      );
    }
    final targetPushKinds = pushKinds ?? kinds;
    final targetPullKinds = pullKinds ?? kinds;
    return _ensureSyncRun(
      pushKinds: targetPushKinds,
      pullKinds: targetPullKinds,
    );
  }

  Future<SyncRunResult> _ensureSyncRun({
    Set<String>? pushKinds,
    Set<String>? pullKinds,
  }) {
    // If sync is already running, share the existing Future.
    if (_syncRunFuture != null) return _syncRunFuture!;

    final created = _doSyncRun(pushKinds: pushKinds, pullKinds: pullKinds);
    _syncRunFuture = created;
    return created.whenComplete(() {
      if (identical(_syncRunFuture, created)) {
        _syncRunFuture = null;
      }
    });
  }

  /// Internal sync implementation.
  Future<SyncRunResult> _doSyncRun({
    Set<String>? pushKinds,
    Set<String>? pullKinds,
  }) async {
    final started = DateTime.now();
    var stats = const SyncStats();
    var pushStats = const PushStats();
    var pullStats = const PullStats(pulled: 0);

    SyncErrorInfo? firstError;
    final sub = events.listen((event) {
      if (firstError != null) return;
      if (event is SyncErrorEvent) {
        firstError = event.errorInfo;
      } else if (event is OperationFailedEvent) {
        firstError = event.errorInfo;
      }
    });

    try {
      final lastFullResync = await _cursorService.getLastFullResync();
      final needsFullResync =
          lastFullResync == null ||
          started.difference(lastFullResync) >= _config.fullResyncInterval;

      if (needsFullResync) {
        final run = await _doFullResyncRun(
          reason: FullResyncReason.scheduled,
          clearData: false,
          started: started,
        );
        return run;
      }

      _events.add(SyncStarted(SyncPhase.push));
      final targetPushKinds = pushKinds ?? _tables.keys.toSet();
      pushStats = await _pushService.pushAll(kinds: targetPushKinds);
      stats = stats.copyWith(
        pushed: pushStats.pushed,
        conflicts: pushStats.conflicts,
        conflictsResolved: pushStats.conflictsResolved,
        errors: pushStats.errors,
      );
      _events.add(SyncStarted(SyncPhase.pull));
      final targetPullKinds = pullKinds ?? _tables.keys.toSet();
      final pulled = await _pullService.pullKinds(targetPullKinds);
      pullStats = PullStats(pulled: pulled);
      stats = stats.copyWith(pulled: pullStats.pulled);

      _events.add(
        SyncCompleted(
          DateTime.now().difference(started),
          DateTime.now(),
          stats: stats,
        ),
      );

      return SyncRunResult(
        push: pushStats,
        pull: pullStats,
        stats: stats,
        duration: DateTime.now().difference(started),
        kindsPushed: targetPushKinds,
        kindsPulled: targetPullKinds,
        stuckOpsCount: await _outboxService.countStuck(
          minTryCount: _config.maxOutboxTryCount,
        ),
        firstError: firstError,
      );
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
    } finally {
      await sub.cancel();
    }
  }

  /// Reactive count of pending operations (excluding stuck by default).
  Stream<int> watchPendingPushCount({
    Set<String>? kinds,
    bool includeStuck = false,
  }) {
    return _outboxService.watchPendingCount(
      kinds: kinds,
      maxTryCountExclusive: includeStuck ? null : _config.maxOutboxTryCount,
    );
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
    final run = await _doFullResyncRun(
      reason: reason,
      clearData: clearData,
      started: started,
    );
    return run.stats;
  }

  Future<SyncRunResult> _doFullResyncRun({
    required FullResyncReason reason,
    required bool clearData,
    required DateTime started,
  }) async {
    var stats = const SyncStats();
    var pushStats = const PushStats();
    var pullStats = const PullStats(pulled: 0);

    SyncErrorInfo? firstError;
    final sub = events.listen((event) {
      if (firstError != null) return;
      if (event is SyncErrorEvent) {
        firstError = event.errorInfo;
      } else if (event is OperationFailedEvent) {
        firstError = event.errorInfo;
      }
    });

    try {
      _events
        ..add(FullResyncStarted(reason))
        ..add(SyncStarted(SyncPhase.push));

      pushStats = await _pushService.pushAll();
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
      pullStats = PullStats(pulled: pulled);
      stats = stats.copyWith(pulled: pullStats.pulled);

      await _cursorService.setLastFullResync(DateTime.now());

      _events.add(
        SyncCompleted(
          DateTime.now().difference(started),
          DateTime.now(),
          stats: stats,
        ),
      );

      return SyncRunResult(
        push: pushStats,
        pull: pullStats,
        stats: stats,
        duration: DateTime.now().difference(started),
        kindsPushed: _tables.keys.toSet(),
        kindsPulled: _tables.keys.toSet(),
        stuckOpsCount: await _outboxService.countStuck(
          minTryCount: _config.maxOutboxTryCount,
        ),
        firstError: firstError,
      );
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
    } finally {
      await sub.cancel();
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
