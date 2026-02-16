import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';
import 'package:offline_first_sync_drift_rest/offline_first_sync_drift_rest.dart';

import '../database/database.dart';

String _sanitizeError(Object error) {
  final message = error.toString();
  if (message.contains('SocketException')) {
    return 'Network connection failed. Check your internet connection.';
  }
  if (message.contains('TimeoutException')) {
    return 'Request timed out. Server may be slow or unavailable.';
  }
  if (message.contains('HandshakeException')) {
    return 'Secure connection failed. Check server certificate.';
  }
  if (message.contains('FormatException')) {
    return 'Server returned invalid data.';
  }
  if (message.length > 100) {
    return 'Sync failed. Please try again.';
  }
  return message;
}

class SyncService extends ChangeNotifier {
  SyncService({
    required AppDatabase db,
    required String baseUrl,
    required SyncableTable<Todo> todoSync,
    this.pushOnOutboxChanges = true,
    this.pullOnStartup = true,
    this.autoInterval = const Duration(minutes: 5),
    this.pushDebounce = const Duration(seconds: 2),
    http.Client? httpClient,
    int maxRetries = 5,
    int maxPushRetries = 5,
  })  : _db = db,
        _baseUri = Uri.parse(baseUrl),
        _httpClient = httpClient ?? http.Client() {
    final config = SyncConfig(
      conflictStrategy: ConflictStrategy.autoPreserve,
      pageSize: 500,
      maxPushRetries: maxPushRetries,
      maxOutboxTryCount: 5,
      retryTransportErrorsInEngine: false,
    );
    _maxOutboxTryCount = config.maxOutboxTryCount;

    _engine = createRestSyncEngine<AppDatabase>(
      db: db,
      base: _baseUri,
      token: () async => '',
      tables: [todoSync],
      config: config,
      client: _httpClient,
      maxRetries: maxRetries,
    );

    _coordinator = SyncCoordinator(
      engine: _engine,
      pullOnStartup: pullOnStartup,
      autoInterval: autoInterval,
      pushOnOutboxChanges: pushOnOutboxChanges,
      pushDebounce: pushDebounce,
    );

    _subscription = _engine.events.listen(_handleEvent);
  }

  final AppDatabase _db;
  final Uri _baseUri;
  final http.Client _httpClient;
  final bool pushOnOutboxChanges;
  final bool pullOnStartup;
  final Duration? autoInterval;
  final Duration pushDebounce;
  late final int _maxOutboxTryCount;

  late final SyncEngine<AppDatabase> _engine;
  late final SyncCoordinator _coordinator;
  late final StreamSubscription<SyncEvent> _subscription;

  SyncEngine<AppDatabase> get engine => _engine;

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  String? _error;
  String? get error => _error;

  SyncStats? _lastStats;
  SyncStats? get lastStats => _lastStats;

  SyncRunResult? _lastRun;
  SyncRunResult? get lastRun => _lastRun;

  double _progress = 0.0;
  double get progress => _progress;

  bool get isSyncing => _status == SyncStatus.syncing;
  Stream<SyncEvent> get events => _engine.events;

  Stream<int> get pendingCountStream => _engine.watchPendingPushCount();

  Future<void> start() async {
    await _coordinator.start();
  }

  Future<SyncStats> sync() async {
    _status = SyncStatus.syncing;
    _error = null;
    _progress = 0.0;
    notifyListeners();

    try {
      final run = await _engine.syncRun();
      _lastRun = run;
      _lastStats = run.stats;
      _status = SyncStatus.idle;
      notifyListeners();
      return run.stats;
    } catch (e) {
      _error = _sanitizeError(e);
      _status = SyncStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> checkHealth() async {
    try {
      final response = await _httpClient.get(_baseUri.resolve('/health'));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  void startAuto({Duration interval = const Duration(minutes: 5)}) {
    _engine.startAuto(interval: interval);
  }

  void stopAuto() {
    _engine.stopAuto();
  }

  Future<int> getPendingCount() async {
    final ops = await _db.takeOutbox(maxTryCountExclusive: _maxOutboxTryCount);
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
      case SyncErrorEvent(:final errorInfo):
        _error = errorInfo.message ?? 'Sync failed';
        _status = SyncStatus.error;
        notifyListeners();
      case OperationFailedEvent(:final errorInfo):
        if (_error == null) {
          _error = errorInfo.message ?? 'Operation failed';
          _status = SyncStatus.error;
          notifyListeners();
        }
      case PullPageProcessedEvent():
      case PushBatchProcessedEvent():
        if (kDebugMode) {
          debugPrint('SyncEvent: $event');
        }
      default:
        if (kDebugMode) {
          debugPrint('SyncEvent: $event');
        }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _coordinator.dispose();
    _engine.dispose();
    _httpClient.close();
    super.dispose();
  }
}

enum SyncStatus {
  idle,
  syncing,
  error,
}
