// Custom exceptions for synchronization.

/// Base sync exception.
///
/// All sync-related exceptions extend this sealed class.
/// Use pattern matching to handle specific exception types.
sealed class SyncException implements Exception {
  const SyncException(this.message, [this.cause, this.stackTrace]);

  /// Error description.
  final String message;

  /// Original cause of the error.
  final Object? cause;

  /// Stack trace of the original error.
  final StackTrace? stackTrace;

  @override
  String toString() =>
      cause == null
          ? '$runtimeType: $message'
          : '$runtimeType: $message\nCaused by: $cause';
}

/// Network error (server unavailable, timeout, etc.).
class NetworkException extends SyncException {
  const NetworkException(super.message, [super.cause, super.stackTrace]);

  /// Create from network error.
  factory NetworkException.fromError(Object error, [StackTrace? stackTrace]) =>
      NetworkException('Network request failed: $error', error, stackTrace);
}

/// Transport error (unexpected server response).
class TransportException extends SyncException {
  const TransportException(
    String message, {
    this.statusCode,
    this.responseBody,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause, stackTrace);

  /// HTTP status code.
  final int? statusCode;

  /// Response body.
  final String? responseBody;

  /// Create for unsuccessful HTTP response.
  factory TransportException.httpError(int statusCode, [String? body]) =>
      TransportException(
        'HTTP error $statusCode',
        statusCode: statusCode,
        responseBody: body,
      );

  @override
  String toString() =>
      statusCode == null
          ? 'TransportException: $message'
          : 'TransportException: $message (status: $statusCode)';
}

/// Database error.
class DatabaseException extends SyncException {
  const DatabaseException(super.message, [super.cause, super.stackTrace]);

  /// Create from database error.
  factory DatabaseException.fromError(Object error, [StackTrace? stackTrace]) =>
      DatabaseException('Database operation failed: $error', error, stackTrace);
}

/// Unresolved data conflict.
class ConflictException extends SyncException {
  const ConflictException(
    String message, {
    required this.kind,
    required this.entityId,
    this.localData,
    this.serverData,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause, stackTrace);

  /// Entity type.
  final String kind;

  /// Entity ID.
  final String entityId;

  /// Local data.
  final Map<String, Object?>? localData;

  /// Server data.
  final Map<String, Object?>? serverData;

  @override
  String toString() => 'ConflictException: $message ($kind/$entityId)';
}

/// Sync operation error (general).
class SyncOperationException extends SyncException {
  const SyncOperationException(
    String message, {
    this.phase,
    this.opId,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause, stackTrace);

  /// Sync phase (push/pull).
  final String? phase;

  /// Operation ID.
  final String? opId;

  @override
  String toString() =>
      'SyncOperationException: $message'
      '${phase == null ? '' : ' (phase: $phase)'}'
      '${opId == null ? '' : ' (opId: $opId)'}';
}

/// Maximum retry attempts exceeded.
class MaxRetriesExceededException extends SyncException {
  const MaxRetriesExceededException(
    String message, {
    required this.attempts,
    required this.maxRetries,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause, stackTrace);

  /// Number of attempts made.
  final int attempts;

  /// Maximum number of attempts allowed.
  final int maxRetries;

  @override
  String toString() =>
      'MaxRetriesExceededException: $message (attempts: $attempts/$maxRetries)';
}

/// Data parsing error.
class ParseException extends SyncException {
  const ParseException(super.message, [super.cause, super.stackTrace]);

  /// Create from parsing error.
  factory ParseException.fromError(Object error, [StackTrace? stackTrace]) =>
      ParseException('Failed to parse data: $error', error, stackTrace);
}
