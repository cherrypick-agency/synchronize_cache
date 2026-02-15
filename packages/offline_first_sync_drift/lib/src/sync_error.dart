import 'package:offline_first_sync_drift/src/exceptions.dart';

/// High-level category for sync failures.
enum SyncErrorCategory {
  network,
  auth,
  server,
  parse,
  database,
  conflict,
  unknown,
}

/// Normalized error payload for UI and telemetry.
class SyncErrorInfo {
  const SyncErrorInfo({
    required this.category,
    required this.retryable,
    this.statusCode,
    this.message,
  });

  final SyncErrorCategory category;
  final bool retryable;
  final int? statusCode;
  final String? message;

  static SyncErrorInfo fromError(Object error) {
    if (error is TransportException) {
      final code = error.statusCode;
      if (code == 401 || code == 403) {
        return SyncErrorInfo(
          category: SyncErrorCategory.auth,
          retryable: false,
          statusCode: code,
          message: error.message,
        );
      }
      final isServer = code != null && code >= 500;
      return SyncErrorInfo(
        category:
            isServer ? SyncErrorCategory.server : SyncErrorCategory.unknown,
        retryable: isServer,
        statusCode: code,
        message: error.message,
      );
    }

    if (error is NetworkException || error is MaxRetriesExceededException) {
      return SyncErrorInfo(
        category: SyncErrorCategory.network,
        retryable: true,
        message: error.toString(),
      );
    }
    if (error is ParseException) {
      return SyncErrorInfo(
        category: SyncErrorCategory.parse,
        retryable: false,
        message: error.message,
      );
    }
    if (error is DatabaseException) {
      return SyncErrorInfo(
        category: SyncErrorCategory.database,
        retryable: false,
        message: error.message,
      );
    }
    if (error is ConflictException) {
      return SyncErrorInfo(
        category: SyncErrorCategory.conflict,
        retryable: true,
        message: error.message,
      );
    }

    return SyncErrorInfo(
      category: SyncErrorCategory.unknown,
      retryable: false,
      message: error.toString(),
    );
  }
}
