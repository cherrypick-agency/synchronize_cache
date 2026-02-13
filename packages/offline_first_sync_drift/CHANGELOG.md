# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.2] - 2026-02-13

### Added

- DX sugar for outbox ops:
  - `UpsertOp.create(...)` and `DeleteOp.create(...)` auto-generate `opId` and UTC timestamps
- High-level write helpers:
  - `SyncWriter` and typed `SyncEntityWriter<T>` for atomic "local write + enqueue"
  - `SyncDatabaseDx` extension one-liners (`insertAndEnqueue`, `replaceAndEnqueue`, `enqueueDelete`, `writeAndEnqueueDelete`)
- `ChangedFieldsTracker` helper to reduce mistakes with `changedFields`
- `SyncRepository` base class for common CRUD patterns

### Changed

- `SyncableTable<T>` can derive `id` / `updatedAt` via `toJson` fallback (recommended to still pass `getId` / `getUpdatedAt`)

## [0.1.1] - 2025-01-27

### Fixed

- Fixed modular generation compatibility for Drift databases
- Improved code examples in documentation

### Documentation

- Updated README with complete model examples including `@JsonSerializable`
- Fixed import statements for modular generation (`import` instead of `part`)
- Added missing dependencies (`json_annotation`, `json_serializable`) to installation guide
- Improved conflict resolution examples with proper `switch` expression

## [0.1.0] - 2024-11-27

### Added

- Initial release
- `SyncEngine` for push/pull synchronization with conflict resolution
- `SyncDatabaseMixin` for Drift database integration
- `SyncColumns` mixin for syncable tables (adds `updatedAt`, `deletedAt`, `deletedAtLocal`)
- `SyncableTable<T>` registration for entities
- Conflict resolution strategies:
  - `autoPreserve` (default) - smart merge preserving all data
  - `serverWins` - server version wins
  - `clientWins` - client version wins with force push
  - `lastWriteWins` - latest timestamp wins
  - `merge` - custom merge function
  - `manual` - manual resolution via callback
- `TransportAdapter` interface for custom transports
- Outbox pattern for offline-first operations
- Cursor-based pagination for incremental sync
- Full resync support with configurable intervals
- Events stream for UI integration and monitoring
- `SyncStats` for sync operation statistics

