import 'package:offline_first_sync_drift/src/conflict_resolution.dart';

/// Synchronization configuration.
///
/// Configures all aspects of the sync engine behavior including:
/// - Pagination and retry logic
/// - Conflict resolution strategies
/// - Background sync intervals
class SyncConfig {
  const SyncConfig({
    this.pageSize = 500,
    this.backoffMin = const Duration(seconds: 1),
    this.backoffMax = const Duration(minutes: 2),
    this.backoffMultiplier = 2.0,
    this.maxPushRetries = 5,
    this.fullResyncInterval = const Duration(days: 7),
    this.pullOnStartup = false,
    this.pushImmediately = true,
    this.reconcileInterval,
    this.lazyReconcileOnMiss = false,
    this.conflictStrategy = ConflictStrategy.autoPreserve,
    this.conflictResolver,
    this.mergeFunction,
    this.maxConflictRetries = 3,
    this.conflictRetryDelay = const Duration(milliseconds: 500),
    this.skipConflictingOps = false,
  });

  /// Page size for pull operations.
  final int pageSize;

  /// Minimum delay for retry backoff.
  final Duration backoffMin;

  /// Maximum delay for retry backoff.
  final Duration backoffMax;

  /// Multiplier for exponential backoff.
  final double backoffMultiplier;

  /// Maximum number of push retry attempts.
  final int maxPushRetries;

  /// Interval for full resynchronization.
  final Duration fullResyncInterval;

  /// Whether to pull on startup.
  final bool pullOnStartup;

  /// Whether to push changes immediately.
  final bool pushImmediately;

  /// Interval for data reconciliation.
  final Duration? reconcileInterval;

  /// Enable lazy reconciliation on cache miss.
  final bool lazyReconcileOnMiss;

  /// Default conflict resolution strategy.
  /// Defaults to [ConflictStrategy.autoPreserve] — automatic merge without data loss.
  final ConflictStrategy conflictStrategy;

  /// Callback for manual conflict resolution.
  /// Used when [conflictStrategy] == [ConflictStrategy.manual].
  final ConflictResolver? conflictResolver;

  /// Data merge function.
  /// Used when [conflictStrategy] == [ConflictStrategy.merge].
  /// If not specified, [ConflictUtils.defaultMerge] is used.
  final MergeFunction? mergeFunction;

  /// Maximum number of conflict resolution attempts.
  final int maxConflictRetries;

  /// Delay between conflict resolution attempts.
  final Duration conflictRetryDelay;

  /// Skip operations with unresolved conflicts.
  /// If true, operation is removed from outbox.
  /// If false, operation remains in outbox for next sync.
  final bool skipConflictingOps;

  /// Create a copy of configuration with modified parameters.
  SyncConfig copyWith({
    int? pageSize,
    Duration? backoffMin,
    Duration? backoffMax,
    double? backoffMultiplier,
    int? maxPushRetries,
    Duration? fullResyncInterval,
    bool? pullOnStartup,
    bool? pushImmediately,
    Duration? reconcileInterval,
    bool? lazyReconcileOnMiss,
    ConflictStrategy? conflictStrategy,
    ConflictResolver? conflictResolver,
    MergeFunction? mergeFunction,
    int? maxConflictRetries,
    Duration? conflictRetryDelay,
    bool? skipConflictingOps,
  }) => SyncConfig(
    pageSize: pageSize ?? this.pageSize,
    backoffMin: backoffMin ?? this.backoffMin,
    backoffMax: backoffMax ?? this.backoffMax,
    backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
    maxPushRetries: maxPushRetries ?? this.maxPushRetries,
    fullResyncInterval: fullResyncInterval ?? this.fullResyncInterval,
    pullOnStartup: pullOnStartup ?? this.pullOnStartup,
    pushImmediately: pushImmediately ?? this.pushImmediately,
    reconcileInterval: reconcileInterval ?? this.reconcileInterval,
    lazyReconcileOnMiss: lazyReconcileOnMiss ?? this.lazyReconcileOnMiss,
    conflictStrategy: conflictStrategy ?? this.conflictStrategy,
    conflictResolver: conflictResolver ?? this.conflictResolver,
    mergeFunction: mergeFunction ?? this.mergeFunction,
    maxConflictRetries: maxConflictRetries ?? this.maxConflictRetries,
    conflictRetryDelay: conflictRetryDelay ?? this.conflictRetryDelay,
    skipConflictingOps: skipConflictingOps ?? this.skipConflictingOps,
  );
}

/// Conflict configuration for a specific table.
/// Allows overriding strategy for individual entity types.
class TableConflictConfig {
  const TableConflictConfig({
    this.strategy,
    this.resolver,
    this.mergeFunction,
    this.timestampField = 'updatedAt',
  });

  /// Strategy for this table. If null, uses global strategy.
  final ConflictStrategy? strategy;

  /// Resolver callback for this table. If null, uses global resolver.
  final ConflictResolver? resolver;

  /// Merge function for this table.
  final MergeFunction? mergeFunction;

  /// Timestamp field name for lastWriteWins strategy.
  final String timestampField;
}
