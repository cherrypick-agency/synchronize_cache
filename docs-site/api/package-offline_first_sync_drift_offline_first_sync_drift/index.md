---
title: "offline_first_sync_drift"
description: "API documentation for the offline_first_sync_drift library"
outline: [2, 3]
editLink: false
prev: false
next: false
---

<ApiBreadcrumb />

# offline_first_sync_drift

## Classes {#section-classes}

| Class | Description |
|---|---|
| [AcceptClient](/api/package-offline_first_sync_drift_offline_first_sync_drift/AcceptClient) | Accept client version (retry push with force). |
| [AcceptMerged](/api/package-offline_first_sync_drift_offline_first_sync_drift/AcceptMerged) | Use merged data. |
| [AcceptServer](/api/package-offline_first_sync_drift_offline_first_sync_drift/AcceptServer) | Accept server version. |
| [BatchPushResult](/api/package-offline_first_sync_drift_offline_first_sync_drift/BatchPushResult) | Push result for a batch of operations. |
| [CacheUpdateEvent](/api/package-offline_first_sync_drift_offline_first_sync_drift/CacheUpdateEvent) | Cache update. |
| [ChangedFieldsDiff](/api/package-offline_first_sync_drift_offline_first_sync_drift/ChangedFieldsDiff) | Utilities for automatic changed-fields diffing. |
| [ChangedFieldsTracker](/api/package-offline_first_sync_drift_offline_first_sync_drift/ChangedFieldsTracker) | Helper to track changed fields for conflict-aware updates. |
| [Conflict](/api/package-offline_first_sync_drift_offline_first_sync_drift/Conflict) | Conflict details. |
| [ConflictDetectedEvent](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictDetectedEvent) | Data conflict detected. |
| [ConflictResolution](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictResolution) | Conflict resolution result. |
| [ConflictResolutionResult](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictResolutionResult) | Result of conflict resolution. |
| [ConflictResolvedEvent](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictResolvedEvent) | Conflict resolved. |
| [ConflictService\<DB extends GeneratedDatabase\>](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictService) | Service for sync conflict resolution. |
| [ConflictUnresolvedEvent](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictUnresolvedEvent) | Conflict could not be resolved automatically. |
| [ConflictUtils](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictUtils) | Conflict utility functions. |
| [Cursor](/api/package-offline_first_sync_drift_offline_first_sync_drift/Cursor) | Cursor for stable pagination: `(updatedAt, lastId)`. |
| [CursorKinds](/api/package-offline_first_sync_drift_offline_first_sync_drift/CursorKinds) | Special cursor kinds. |
| [CursorService](/api/package-offline_first_sync_drift_offline_first_sync_drift/CursorService) | Service for synchronization cursors. |
| [DataMergedEvent](/api/package-offline_first_sync_drift_offline_first_sync_drift/DataMergedEvent) | Data was merged during conflict resolution. |
| [DeferResolution](/api/package-offline_first_sync_drift_offline_first_sync_drift/DeferResolution) | Defer resolution (keep operation in outbox). |
| [DeleteOp](/api/package-offline_first_sync_drift_offline_first_sync_drift/DeleteOp) | Delete operation for an entity. |
| [DiscardOperation](/api/package-offline_first_sync_drift_offline_first_sync_drift/DiscardOperation) | Discard operation (remove from outbox). |
| [FetchError](/api/package-offline_first_sync_drift_offline_first_sync_drift/FetchError) | Fetch error. |
| [FetchNotFound](/api/package-offline_first_sync_drift_offline_first_sync_drift/FetchNotFound) | Entity not found. |
| [FetchResult](/api/package-offline_first_sync_drift_offline_first_sync_drift/FetchResult) | Result of fetching a single entity. |
| [FetchSuccess](/api/package-offline_first_sync_drift_offline_first_sync_drift/FetchSuccess) | Entity found. |
| [FullResyncStarted](/api/package-offline_first_sync_drift_offline_first_sync_drift/FullResyncStarted) | Full resync started. |
| [MergeInfo](/api/package-offline_first_sync_drift_offline_first_sync_drift/MergeInfo) | Data merge metadata. |
| [Op](/api/package-offline_first_sync_drift_offline_first_sync_drift/Op) |  |
| [OperationFailedEvent](/api/package-offline_first_sync_drift_offline_first_sync_drift/OperationFailedEvent) | Operation failed. |
| [OperationPushedEvent](/api/package-offline_first_sync_drift_offline_first_sync_drift/OperationPushedEvent) | Operation pushed successfully. |
| [OpPushResult](/api/package-offline_first_sync_drift_offline_first_sync_drift/OpPushResult) | Push result for a single operation. |
| [OpType](/api/package-offline_first_sync_drift_offline_first_sync_drift/OpType) | Operation types in outbox. |
| [OutboxService](/api/package-offline_first_sync_drift_offline_first_sync_drift/OutboxService) | Service for working with the outbox queue. |
| [PreservingMergeResult](/api/package-offline_first_sync_drift_offline_first_sync_drift/PreservingMergeResult) | `preservingMerge` result with field source information. |
| [PullPage](/api/package-offline_first_sync_drift_offline_first_sync_drift/PullPage) | Pull result: list of JSON items and next page pointer. |
| [PullPageProcessedEvent](/api/package-offline_first_sync_drift_offline_first_sync_drift/PullPageProcessedEvent) | Pull page processed. |
| [PullService\<DB extends GeneratedDatabase\>](/api/package-offline_first_sync_drift_offline_first_sync_drift/PullService) | Service for pulling changes from the server. |
| [PullStats](/api/package-offline_first_sync_drift_offline_first_sync_drift/PullStats) |  |
| [PushBatchProcessedEvent](/api/package-offline_first_sync_drift_offline_first_sync_drift/PushBatchProcessedEvent) | Push batch processed. |
| [PushConflict](/api/package-offline_first_sync_drift_offline_first_sync_drift/PushConflict) | Conflict during push. |
| [PushError](/api/package-offline_first_sync_drift_offline_first_sync_drift/PushError) | Push error (not a conflict). |
| [PushNotFound](/api/package-offline_first_sync_drift_offline_first_sync_drift/PushNotFound) | Entity not found on server (for update/delete). |
| [PushResult](/api/package-offline_first_sync_drift_offline_first_sync_drift/PushResult) | Push operation result. |
| [PushService](/api/package-offline_first_sync_drift_offline_first_sync_drift/PushService) | Service for pushing local changes to the server. |
| [PushStats](/api/package-offline_first_sync_drift_offline_first_sync_drift/PushStats) | Push operation statistics. |
| [PushSuccess](/api/package-offline_first_sync_drift_offline_first_sync_drift/PushSuccess) | Operation pushed successfully. |
| [SyncableTable\<T\>](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncableTable) | Configuration for a syncable table. Registered in SyncEngine for automatic synchronization. |
| [SyncCompleted](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncCompleted) | Synchronization completed. |
| [SyncConfig](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncConfig) | Synchronization configuration. |
| [SyncCoordinator](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncCoordinator) | Orchestrates sync triggers around [SyncEngine](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEngine). |
| [SyncCursorData](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncCursorData) |  |
| [SyncCursors](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncCursors) | Cursor table for stable pull pagination. Stores the last sync position for each kind. |
| [SyncCursorsCompanion](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncCursorsCompanion) |  |
| [SyncEngine\<DB extends GeneratedDatabase\>](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEngine) | Synchronization engine: push → pull with pagination and conflict resolution. |
| [SyncEntityWriter\<T, DB extends GeneratedDatabase\>](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEntityWriter) | A typed writer for a single entity kind/table. |
| [SyncErrorEvent](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncErrorEvent) | Synchronization error. |
| [SyncErrorInfo](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncErrorInfo) | Normalized error payload for UI and telemetry. |
| [SyncEvent](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncEvent) | Synchronization events for logging, UI, and metrics. |
| [SyncFields](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncFields) | Field names for serialization/deserialization. |
| [SynchronizableTable](/api/package-offline_first_sync_drift_offline_first_sync_drift/SynchronizableTable) | Marker interface for syncable tables. Allows type-safe checks that a table includes required system fields. |
| [SyncOutbox](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncOutbox) | Outbox table for synchronization operations. Stores local changes until they are sent to the server. |
| [SyncOutboxCompanion](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncOutboxCompanion) |  |
| [SyncOutboxData](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncOutboxData) |  |
| [SyncOutboxMeta](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncOutboxMeta) | Additional metadata for outbox operations. |
| [SyncOutboxMetaCompanion](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncOutboxMetaCompanion) |  |
| [SyncOutboxMetaData](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncOutboxMetaData) |  |
| [SyncProgress](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncProgress) | Synchronization progress. |
| [SyncRepository\<T, DB extends GeneratedDatabase\>](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncRepository) | Base repository for syncable entities. |
| [SyncRunResult](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncRunResult) | Rich result model for a sync run. |
| [SyncStarted](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncStarted) | Synchronization started. |
| [SyncStats](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncStats) | Synchronization statistics. |
| [SyncWriter\<DB extends GeneratedDatabase\>](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncWriter) | High-level DX wrapper for local writes + outbox enqueue. |
| [TableColumns](/api/package-offline_first_sync_drift_offline_first_sync_drift/TableColumns) | Table column names (snake_case for SQL). |
| [TableConflictConfig](/api/package-offline_first_sync_drift_offline_first_sync_drift/TableConflictConfig) | Conflict configuration for a specific table. Allows overriding strategy for individual entity types. |
| [TableNames](/api/package-offline_first_sync_drift_offline_first_sync_drift/TableNames) | Table names. |
| [TransportAdapter](/api/package-offline_first_sync_drift_offline_first_sync_drift/TransportAdapter) | Network transport interface. |
| [UpsertOp](/api/package-offline_first_sync_drift_offline_first_sync_drift/UpsertOp) | Create/update operation for an entity. |

## Exceptions {#section-exceptions}

| Exception | Description |
|---|---|
| [ConflictException](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictException) | Unresolved data conflict. |
| [DatabaseException](/api/package-offline_first_sync_drift_offline_first_sync_drift/DatabaseException) | Database error. |
| [MaxRetriesExceededException](/api/package-offline_first_sync_drift_offline_first_sync_drift/MaxRetriesExceededException) | Maximum retry attempts exceeded. |
| [NetworkException](/api/package-offline_first_sync_drift_offline_first_sync_drift/NetworkException) | Network error (server unavailable, timeout, etc.). |
| [ParseException](/api/package-offline_first_sync_drift_offline_first_sync_drift/ParseException) | Data parsing error. |
| [SyncException](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncException) | Base sync exception. |
| [SyncOperationException](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncOperationException) | Sync operation error (general). |
| [TransportException](/api/package-offline_first_sync_drift_offline_first_sync_drift/TransportException) | Transport error (unexpected server response). |

## Enums {#section-enums}

| Enum | Description |
|---|---|
| [ConflictStrategy](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictStrategy) | Strategies and types for sync conflict resolution. Conflict resolution strategy. |
| [FullResyncReason](/api/package-offline_first_sync_drift_offline_first_sync_drift/FullResyncReason) | Reason for triggering a full resync. |
| [SyncErrorCategory](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncErrorCategory) | High-level category for sync failures. |
| [SyncPhase](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncPhase) | Synchronization phase. |

## Mixins {#section-mixins}

| Mixin | Description |
|---|---|
| [SyncColumns](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncColumns) | Mixin for synchronized tables. Adds standard fields: updatedAt, deletedAt, deletedAtLocal. |
| [SyncDatabaseMixin](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseMixin) | Mixin for databases with synchronization support. |

## Extensions {#section-extensions}

| Extension | on | Description |
|---|---|---|
| [SyncDatabaseDx](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncDatabaseDx) | GeneratedDatabase | One-liner helpers for "local write + enqueue" flows. |
| [SyncTableRegistrationExtension\<T\>](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncTableRegistrationExtension) | TableInfo\<Table, T\> | Sugar for concise table registration. |
| [SyncWriterDatabaseExtension\<DB extends GeneratedDatabase\>](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncWriterDatabaseExtension) | DB | Convenience accessors on Drift databases. |

## Typedefs {#section-typedefs}

| Typedef | Description |
|---|---|
| [ConflictResolver](/api/package-offline_first_sync_drift_offline_first_sync_drift/ConflictResolver) | Callback for manual conflict resolution. |
| [MergeFunction](/api/package-offline_first_sync_drift_offline_first_sync_drift/MergeFunction) | Callback for data merging. |
| [OpIdFactory](/api/package-offline_first_sync_drift_offline_first_sync_drift/OpIdFactory) | Generates ids for outbox operations. |
| [SyncClock](/api/package-offline_first_sync_drift_offline_first_sync_drift/SyncClock) | Returns "now" timestamps for outbox operations. |

