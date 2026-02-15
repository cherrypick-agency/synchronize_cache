// Synchronization constants.

/// Operation types in outbox.
abstract final class OpType {
  static const upsert = 'upsert';
  static const delete = 'delete';
}

/// Field names for serialization/deserialization.
abstract final class SyncFields {
  // ID fields
  static const id = 'id';
  static const idUpper = 'ID';
  static const uuid = 'uuid';

  // Timestamp fields (camelCase)
  static const updatedAt = 'updatedAt';
  static const createdAt = 'createdAt';
  static const deletedAt = 'deletedAt';

  // Timestamp fields (snake_case)
  static const updatedAtSnake = 'updated_at';
  static const createdAtSnake = 'created_at';
  static const deletedAtSnake = 'deleted_at';

  /// All ID fields used for lookup.
  static const idFields = [id, idUpper, uuid];

  /// All updatedAt fields used for lookup.
  static const updatedAtFields = [updatedAt, updatedAtSnake];

  /// All deletedAt fields used for lookup.
  static const deletedAtFields = [deletedAt, deletedAtSnake];
}

/// Table column names (snake_case for SQL).
abstract final class TableColumns {
  static const opId = 'op_id';
  static const kind = 'kind';
  static const entityId = 'entity_id';
  static const op = 'op';
  static const payload = 'payload';
  static const ts = 'ts';
  static const tryCount = 'try_count';
  static const baseUpdatedAt = 'base_updated_at';
  static const changedFields = 'changed_fields';
  static const lastTriedAt = 'last_tried_at';
  static const lastError = 'last_error';
  static const lastId = 'last_id';
}

/// Table names.
abstract final class TableNames {
  static const syncOutbox = 'sync_outbox';
  static const syncOutboxMeta = 'sync_outbox_meta';
  static const syncCursors = 'sync_cursors';
}

/// Special cursor kinds.
abstract final class CursorKinds {
  /// Cursor key for storing timestamp of last full resync.
  static const fullResync = '__full_resync__';
}
