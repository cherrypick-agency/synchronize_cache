import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';
import 'package:offline_first_sync_drift_rest/offline_first_sync_drift_rest.dart';

import '../database/database.dart';
import '../models/todo.dart';
import 'conflict_handler.dart';

/// Service for synchronizing todos with the server.
///
/// Uses [SyncEngine] with [RestTransport] for HTTP communication.
/// Uses manual conflict resolution strategy.
class SyncService extends ChangeNotifier {
  SyncService({
    required AppDatabase db,
    required String baseUrl,
    required ConflictHandler conflictHandler,
  })  : _db = db,
        _conflictHandler = conflictHandler {
    _transport = RestTransport(
      base: Uri.parse(baseUrl),
      // No auth for demo
      token: () async => '',
    );

    _engine = SyncEngine(
      db: db,
      transport: _transport,
      tables: [
        SyncableTable<Todo>(
          kind: 'todos',
          table: db.todos,
          fromJson: Todo.fromJson,
          toJson: (t) => t.toJson(),
          toInsertable: (t) => t.toInsertable(),
        ),
      ],
      config: SyncConfig(
        // Use manual strategy for conflict resolution UI
        conflictStrategy: ConflictStrategy.manual,
        pageSize: 500,
        // Connect conflict resolver function
        conflictResolver: conflictHandler.resolve,
      ),
    );

    // Listen to sync events
    _subscription = _engine.events.listen(_handleEvent);
  }

  final AppDatabase _db;
  final ConflictHandler _conflictHandler;
  late final RestTransport _transport;
  late final SyncEngine _engine;
  late final StreamSubscription<SyncEvent> _subscription;

  /// Current sync status.
  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  /// Last sync error, if any.
  String? _error;
  String? get error => _error;

  /// Last sync statistics.
  SyncStats? _lastStats;
  SyncStats? get lastStats => _lastStats;

  /// Sync progress (0.0 to 1.0).
  double _progress = 0.0;
  double get progress => _progress;

  /// Whether currently syncing.
  bool get isSyncing => _status == SyncStatus.syncing;

  /// Stream of sync events.
  Stream<SyncEvent> get events => _engine.events;

  /// Gets the conflict handler for UI access.
  ConflictHandler get conflictHandler => _conflictHandler;

  /// Performs a full sync (push + pull).
  Future<SyncStats> sync() async {
    _status = SyncStatus.syncing;
    _error = null;
    _progress = 0.0;
    notifyListeners();

    _conflictHandler.logEvent('Starting sync...');

    try {
      final stats = await _engine.sync();
      _lastStats = stats;
      _status = SyncStatus.idle;

      _conflictHandler.logEvent(
        'Sync completed: ${stats.pushed} pushed, ${stats.pulled} pulled',
      );

      notifyListeners();
      return stats;
    } catch (e) {
      _error = e.toString();
      _status = SyncStatus.error;

      _conflictHandler.logEvent(
        'Sync failed: $e',
        level: SyncLogLevel.error,
      );

      notifyListeners();
      rethrow;
    }
  }

  /// Checks server health.
  Future<bool> checkHealth() async {
    try {
      return await _transport.health();
    } catch (e) {
      return false;
    }
  }

  /// Starts automatic sync at the given interval.
  void startAuto({Duration interval = const Duration(minutes: 5)}) {
    _engine.startAuto(interval: interval);
    _conflictHandler.logEvent('Auto-sync started (interval: $interval)');
  }

  /// Stops automatic sync.
  void stopAuto() {
    _engine.stopAuto();
    _conflictHandler.logEvent('Auto-sync stopped');
  }

  /// Gets pending operation count.
  Future<int> getPendingCount() async {
    final ops = await _db.takeOutbox();
    return ops.length;
  }

  /// Triggers server-side simulation endpoint.
  Future<void> triggerServerSimulation(String endpoint, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('${_transport.base}$endpoint');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode >= 400) {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }

      _conflictHandler.logEvent(
        'Server simulation triggered: $endpoint',
        level: SyncLogLevel.warning,
      );
    } catch (e) {
      _conflictHandler.logEvent(
        'Simulation failed: $e',
        level: SyncLogLevel.error,
      );
      rethrow;
    }
  }

  void _handleEvent(SyncEvent event) {
    switch (event) {
      case SyncStarted(:final phase):
        _status = SyncStatus.syncing;
        _progress = 0.0;
        _conflictHandler.logEvent('Sync $phase started...');
        notifyListeners();

      case SyncProgress(:final done, :final total):
        if (total > 0) {
          _progress = done / total;
          notifyListeners();
        }

      case SyncCompleted(:final stats):
        _lastStats = stats;
        _status = SyncStatus.idle;
        _progress = 1.0;
        notifyListeners();

      case SyncErrorEvent(:final error):
        _error = error.toString();
        _status = SyncStatus.error;
        notifyListeners();

      case OperationPushedEvent(:final kind, :final entityId, :final operationType):
        _conflictHandler.logEvent('$operationType $kind: $entityId');

      case CacheUpdateEvent(:final kind, :final upserts, :final deletes):
        _conflictHandler.logEvent('Cache: $kind - $upserts upserts, $deletes deletes');

      case ConflictDetectedEvent(:final conflict):
        _conflictHandler.logEvent(
          'Conflict: ${conflict.kind}/${conflict.entityId}',
          level: SyncLogLevel.warning,
        );

      case ConflictResolvedEvent(:final conflict, :final resolution):
        _conflictHandler.logEvent(
          'Resolved: ${conflict.kind}/${conflict.entityId} -> ${resolution.runtimeType}',
        );

      default:
        // Other events - just log in debug mode
        if (kDebugMode) {
          debugPrint('SyncEvent: $event');
        }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _engine.dispose();
    super.dispose();
  }
}

/// Sync status states.
enum SyncStatus {
  /// Not syncing, ready for sync.
  idle,

  /// Currently syncing.
  syncing,

  /// Last sync failed.
  error,
}
