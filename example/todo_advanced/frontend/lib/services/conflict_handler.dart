import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

import '../models/todo.dart';

/// Handles conflict resolution for sync operations.
///
/// When a conflict is detected:
/// 1. Stores the conflict for later resolution
/// 2. Notifies listeners (UI shows conflict dialog)
/// 3. User chooses resolution: local, server, or merged
/// 4. Resolution is applied and sync continues
class ConflictHandler extends ChangeNotifier {
  ConflictHandler();

  /// Queue of pending conflicts to resolve.
  final List<ConflictInfo> _pendingConflicts = [];

  /// Currently displayed conflict (if any).
  ConflictInfo? _currentConflict;
  ConflictInfo? get currentConflict => _currentConflict;

  /// Completer for the current conflict resolution.
  Completer<ConflictResolution>? _resolutionCompleter;

  /// Whether there are pending conflicts.
  bool get hasConflicts =>
      _pendingConflicts.isNotEmpty || _currentConflict != null;

  /// Number of pending conflicts.
  int get conflictCount =>
      _pendingConflicts.length + (_currentConflict != null ? 1 : 0);

  /// Sync event log for debugging.
  final List<SyncLogEntry> _log = [];
  List<SyncLogEntry> get log => List.unmodifiable(_log);

  /// Clears the sync log.
  void clearLog() {
    _log.clear();
    notifyListeners();
  }

  /// Logs a sync event.
  void logEvent(String message, {SyncLogLevel level = SyncLogLevel.info}) {
    _log.add(SyncLogEntry(
      timestamp: DateTime.now(),
      message: message,
      level: level,
    ));
    notifyListeners();
  }

  /// The conflict resolver function to pass to SyncConfig.
  ///
  /// This is called by the sync engine when a conflict is detected.
  Future<ConflictResolution> resolve(Conflict conflict) async {
    final info = ConflictInfo(
      conflict: conflict,
      localTodo: Todo.fromJson(conflict.localData.cast<String, dynamic>()),
      serverTodo: Todo.fromJson(conflict.serverData.cast<String, dynamic>()),
    );

    logEvent(
      'Conflict detected for "${info.localTodo.title}"',
      level: SyncLogLevel.warning,
    );

    // Add to queue
    _pendingConflicts.add(info);

    // If no conflict is currently being resolved, start resolution
    if (_currentConflict == null) {
      return _resolveNext();
    }

    // Wait for this conflict to be resolved
    return _waitForResolution(info);
  }

  Future<ConflictResolution> _resolveNext() async {
    if (_pendingConflicts.isEmpty) {
      return const AcceptServer();
    }

    _currentConflict = _pendingConflicts.removeAt(0);
    _resolutionCompleter = Completer<ConflictResolution>();
    notifyListeners();

    return _resolutionCompleter!.future;
  }

  Future<ConflictResolution> _waitForResolution(ConflictInfo info) async {
    // Wait until this conflict becomes current and gets resolved
    while (_pendingConflicts.contains(info) || _currentConflict == info) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    // Resolution was applied
    return info.resolution ?? const AcceptServer();
  }

  /// Resolves the current conflict by keeping local version.
  void resolveWithLocal() {
    if (_currentConflict == null || _resolutionCompleter == null) return;

    final conflict = _currentConflict!;
    conflict.resolution = const AcceptClient();

    logEvent(
      'Resolved with local: "${conflict.localTodo.title}"',
      level: SyncLogLevel.info,
    );

    _completeResolution(const AcceptClient());
  }

  /// Resolves the current conflict by keeping server version.
  void resolveWithServer() {
    if (_currentConflict == null || _resolutionCompleter == null) return;

    final conflict = _currentConflict!;
    conflict.resolution = const AcceptServer();

    logEvent(
      'Resolved with server: "${conflict.serverTodo.title}"',
      level: SyncLogLevel.info,
    );

    _completeResolution(const AcceptServer());
  }

  /// Resolves the current conflict with a merged version.
  void resolveWithMerged(Todo mergedTodo) {
    if (_currentConflict == null || _resolutionCompleter == null) return;

    final conflict = _currentConflict!;
    final mergedData = mergedTodo.toJson();
    final resolution = AcceptMerged(mergedData.cast<String, Object?>());
    conflict.resolution = resolution;

    logEvent(
      'Resolved with merge: "${mergedTodo.title}"',
      level: SyncLogLevel.info,
    );

    _completeResolution(resolution);
  }

  void _completeResolution(ConflictResolution result) {
    final completer = _resolutionCompleter;
    _currentConflict = null;
    _resolutionCompleter = null;

    completer?.complete(result);
    notifyListeners();

    // Process next conflict if any
    if (_pendingConflicts.isNotEmpty) {
      _resolveNext();
    }
  }

  /// Skips the current conflict (uses server version).
  void skipConflict() {
    resolveWithServer();
  }
}

/// Information about a sync conflict.
class ConflictInfo {
  ConflictInfo({
    required this.conflict,
    required this.localTodo,
    required this.serverTodo,
  });

  final Conflict conflict;
  final Todo localTodo;
  final Todo serverTodo;

  ConflictResolution? resolution;

  /// Gets the fields that differ between local and server.
  List<String> get conflictingFields {
    final fields = <String>[];

    if (localTodo.title != serverTodo.title) fields.add('title');
    if (localTodo.description != serverTodo.description) {
      fields.add('description');
    }
    if (localTodo.completed != serverTodo.completed) fields.add('completed');
    if (localTodo.priority != serverTodo.priority) fields.add('priority');
    if (localTodo.dueDate != serverTodo.dueDate) fields.add('dueDate');

    return fields;
  }
}

/// Log entry for sync events.
class SyncLogEntry {
  SyncLogEntry({
    required this.timestamp,
    required this.message,
    required this.level,
  });

  final DateTime timestamp;
  final String message;
  final SyncLogLevel level;
}

/// Log level for sync events.
enum SyncLogLevel {
  info,
  warning,
  error,
}
