import 'dart:async';

import 'package:offline_first_sync_drift/src/config.dart';
import 'package:offline_first_sync_drift/src/sync_engine.dart';

/// Orchestrates sync triggers around [SyncEngine].
///
/// This optional DX layer moves app-flow concerns (startup sync, periodic sync,
/// push debounce) out of [SyncConfig], keeping the engine focused on sync logic.
class SyncCoordinator {
  SyncCoordinator({
    required SyncEngine engine,
    this.pullOnStartup = false,
    this.autoInterval,
    this.pushOnOutboxChanges = false,
    this.pushDebounce = const Duration(seconds: 2),
    @Deprecated('Polling is replaced by outbox streams.')
    this.outboxPollInterval = const Duration(seconds: 1),
  }) : _engine = engine;

  /// Build coordinator behavior from legacy [SyncConfig] flags.
  factory SyncCoordinator.fromLegacyConfig({
    required SyncEngine engine,
    required SyncConfig config,
    Duration? outboxPollInterval,
    Duration? pushDebounce,
  }) {
    return SyncCoordinator(
      engine: engine,
      pullOnStartup: config.pullOnStartup,
      autoInterval: config.reconcileInterval,
      pushOnOutboxChanges: config.pushImmediately,
      outboxPollInterval: outboxPollInterval ?? const Duration(seconds: 1),
      pushDebounce: pushDebounce ?? const Duration(seconds: 2),
    );
  }

  final SyncEngine _engine;

  /// Run pull-only sync once on [start].
  final bool pullOnStartup;

  /// Start periodic full syncs with this interval.
  final Duration? autoInterval;

  /// Poll outbox and push when there are pending operations.
  final bool pushOnOutboxChanges;

  /// Debounce delay before push-only sync.
  final Duration pushDebounce;

  /// Polling interval used when [pushOnOutboxChanges] is enabled.
  @Deprecated('Polling is replaced by outbox streams.')
  final Duration outboxPollInterval;

  StreamSubscription<int>? _outboxSubscription;
  Timer? _pushDebounceTimer;
  bool _started = false;
  bool _disposed = false;

  /// Start coordinator automation.
  Future<void> start() async {
    _ensureNotDisposed();
    if (_started) return;
    _started = true;

    if (pullOnStartup) {
      await _engine.sync(pushKinds: const <String>{});
    }

    if (autoInterval != null) {
      _engine.startAuto(interval: autoInterval!);
    }

    if (pushOnOutboxChanges) {
      _outboxSubscription = _engine.watchPendingPushCount().distinct().listen(
        _onOutboxPendingCountChanged,
      );
    }
  }

  /// Stop coordinator automation.
  void stop() {
    if (!_started) return;
    _started = false;
    _engine.stopAuto();
    _outboxSubscription?.cancel();
    _outboxSubscription = null;
    _pushDebounceTimer?.cancel();
    _pushDebounceTimer = null;
  }

  void _onOutboxPendingCountChanged(int pendingCount) {
    if (!_started || _disposed) return;
    if (pendingCount <= 0) return;

    if (_pushDebounceTimer?.isActive ?? false) {
      return;
    }
    _pushDebounceTimer = Timer(pushDebounce, () {
      if (_disposed || !_started) return;
      unawaited(_pushOnlySync());
    });
  }

  Future<void> _pushOnlySync() async {
    try {
      await _engine.sync(pullKinds: const <String>{});
    } catch (_) {
      // Surface errors via engine events; coordinator stays lightweight.
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('SyncCoordinator is already disposed.');
    }
  }

  /// Dispose coordinator timers. Does not dispose the engine.
  void dispose() {
    if (_disposed) return;
    stop();
    _disposed = true;
  }
}
