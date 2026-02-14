/// Outbox operations: upsert/delete with idempotency via opId.
import 'package:offline_first_sync_drift/src/op_id.dart';

sealed class Op {
  Op({
    required this.opId,
    required this.kind,
    required this.id,
    required this.localTimestamp,
  });

  /// Operation UUID used for idempotency.
  final String opId;

  /// Entity kind.
  final String kind;

  /// Entity ID.
  final String id;

  /// Local timestamp when the operation was created.
  final DateTime localTimestamp;
}

/// Create/update operation for an entity.
class UpsertOp extends Op {
  UpsertOp({
    required super.opId,
    required super.kind,
    required super.id,
    required super.localTimestamp,
    required this.payloadJson,
    this.baseUpdatedAt,
    this.changedFields,
  });

  /// Factory helper for DX: generates [opId] and [localTimestamp] by default.
  ///
  /// This is a non-breaking convenience. You can still construct [UpsertOp]
  /// directly to fully control all fields.
  static UpsertOp create({
    required String kind,
    required String id,
    required Map<String, Object?> payloadJson,
    DateTime? baseUpdatedAt,
    Set<String>? changedFields,
    String? opId,
    DateTime? localTimestamp,
  }) {
    final ts = (localTimestamp ?? DateTime.now()).toUtc();
    return UpsertOp(
      opId: opId ?? OpId.v4(),
      kind: kind,
      id: id,
      localTimestamp: ts,
      payloadJson: payloadJson,
      baseUpdatedAt: baseUpdatedAt,
      changedFields: changedFields,
    );
  }

  /// JSON payload sent to the server.
  final Map<String, Object?> payloadJson;

  /// Timestamp when this entity version was last received from the server.
  /// Used for conflict detection.
  /// Null means this is a new record.
  final DateTime? baseUpdatedAt;

  /// Set of fields changed by the user.
  /// Null means all fields are considered changed.
  final Set<String>? changedFields;

  /// Whether this record is new (did not exist on the server).
  bool get isNewRecord => baseUpdatedAt == null;

  /// Creates a copy with modified parameters.
  UpsertOp copyWith({
    String? opId,
    String? kind,
    String? id,
    DateTime? localTimestamp,
    Map<String, Object?>? payloadJson,
    DateTime? baseUpdatedAt,
    Set<String>? changedFields,
  }) => UpsertOp(
    opId: opId ?? this.opId,
    kind: kind ?? this.kind,
    id: id ?? this.id,
    localTimestamp: localTimestamp ?? this.localTimestamp,
    payloadJson: payloadJson ?? this.payloadJson,
    baseUpdatedAt: baseUpdatedAt ?? this.baseUpdatedAt,
    changedFields: changedFields ?? this.changedFields,
  );
}

/// Delete operation for an entity.
class DeleteOp extends Op {
  DeleteOp({
    required super.opId,
    required super.kind,
    required super.id,
    required super.localTimestamp,
    this.baseUpdatedAt,
  });

  /// Factory helper for DX: generates [opId] and [localTimestamp] by default.
  ///
  /// This is a non-breaking convenience. You can still construct [DeleteOp]
  /// directly to fully control all fields.
  static DeleteOp create({
    required String kind,
    required String id,
    DateTime? baseUpdatedAt,
    String? opId,
    DateTime? localTimestamp,
  }) {
    final ts = (localTimestamp ?? DateTime.now()).toUtc();
    return DeleteOp(
      opId: opId ?? OpId.v4(),
      kind: kind,
      id: id,
      localTimestamp: ts,
      baseUpdatedAt: baseUpdatedAt,
    );
  }

  /// Timestamp when this entity version was last received from the server.
  final DateTime? baseUpdatedAt;
}
