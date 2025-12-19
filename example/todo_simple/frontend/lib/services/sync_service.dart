import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';
import 'package:offline_first_sync_drift_rest/offline_first_sync_drift_rest.dart';

import '../database/database.dart';
import '../models/todo.dart';

/// Service for synchronizing todos with the server.
///
/// Uses [SyncEngine] with [RestTransport] for HTTP communication.
class SyncService extends ChangeNotifier {
  SyncService({
    required AppDatabase db,
    required String baseUrl,
  }) : _db = db {
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
      config: const SyncConfig(
        // Use autoPreserve for simple flow - merges without conflicts
        conflictStrategy: ConflictStrategy.autoPreserve,
        pageSize: 500,
      ),
    );

    // Listen to sync events
    _subscription = _engine.events.listen(_handleEvent);
  }

  final AppDatabase _db;
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

  /// Performs a full sync (push + pull).
  Future<SyncStats> sync() async {
    _status = SyncStatus.syncing;
    _error = null;
    _progress = 0.0;
    notifyListeners();

    try {
      final stats = await _engine.sync();
      _lastStats = stats;
      _status = SyncStatus.idle;
      notifyListeners();
      return stats;
    } catch (e) {
      _error = e.toString();
      _status = SyncStatus.error;
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
  }

  /// Stops automatic sync.
  void stopAuto() {
    _engine.stopAuto();
  }

  /// Gets pending operation count.
  Future<int> getPendingCount() async {
    final ops = await _db.takeOutbox();
    return ops.length;
  }

  void _handleEvent(SyncEvent event) {
    switch (event) {
      case SyncStarted():
        _status = SyncStatus.syncing;
        _progress = 0.0;
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
