import 'package:offline_first_sync_drift/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('NetworkException', () {
    test('creates with message only', () {
      const exception = NetworkException('Connection timeout');

      expect(exception.message, equals('Connection timeout'));
      expect(exception.cause, isNull);
      expect(exception.stackTrace, isNull);
    });

    test('creates with message and cause', () {
      final cause = Exception('Socket error');
      final exception = NetworkException('Network failed', cause);

      expect(exception.message, equals('Network failed'));
      expect(exception.cause, equals(cause));
      expect(exception.stackTrace, isNull);
    });

    test('creates with message, cause and stack trace', () {
      final cause = Exception('DNS error');
      final stackTrace = StackTrace.current;
      final exception = NetworkException(
        'DNS lookup failed',
        cause,
        stackTrace,
      );

      expect(exception.message, equals('DNS lookup failed'));
      expect(exception.cause, equals(cause));
      expect(exception.stackTrace, equals(stackTrace));
    });

    test('fromError factory creates exception from error', () {
      final error = Exception('Connection refused');
      final exception = NetworkException.fromError(error);

      expect(exception.message, contains('Network request failed'));
      expect(exception.message, contains('Connection refused'));
      expect(exception.cause, equals(error));
    });

    test('fromError factory with stack trace', () {
      final error = Exception('Timeout');
      final stackTrace = StackTrace.current;
      final exception = NetworkException.fromError(error, stackTrace);

      expect(exception.cause, equals(error));
      expect(exception.stackTrace, equals(stackTrace));
    });

    test('toString without cause', () {
      const exception = NetworkException('Connection failed');

      expect(
        exception.toString(),
        equals('NetworkException: Connection failed'),
      );
    });

    test('toString with cause', () {
      final exception = NetworkException(
        'Network error',
        Exception('Socket closed'),
      );

      expect(exception.toString(), contains('NetworkException: Network error'));
      expect(exception.toString(), contains('Caused by:'));
      expect(exception.toString(), contains('Socket closed'));
    });

    test('is SyncException', () {
      const exception = NetworkException('Test');

      expect(exception, isA<SyncException>());
    });
  });

  group('TransportException', () {
    test('creates with message only', () {
      const exception = TransportException('Invalid response');

      expect(exception.message, equals('Invalid response'));
      expect(exception.statusCode, isNull);
      expect(exception.responseBody, isNull);
      expect(exception.cause, isNull);
    });

    test('creates with status code', () {
      const exception = TransportException('Server error', statusCode: 500);

      expect(exception.message, equals('Server error'));
      expect(exception.statusCode, equals(500));
    });

    test('creates with response body', () {
      const exception = TransportException(
        'Bad request',
        statusCode: 400,
        responseBody: '{"error": "validation failed"}',
      );

      expect(exception.statusCode, equals(400));
      expect(exception.responseBody, equals('{"error": "validation failed"}'));
    });

    test('creates with cause and stack trace', () {
      final cause = Exception('Parse error');
      final stackTrace = StackTrace.current;
      final exception = TransportException(
        'Failed',
        cause: cause,
        stackTrace: stackTrace,
      );

      expect(exception.cause, equals(cause));
      expect(exception.stackTrace, equals(stackTrace));
    });

    test('httpError factory creates from status code', () {
      final exception = TransportException.httpError(404);

      expect(exception.message, equals('HTTP error 404'));
      expect(exception.statusCode, equals(404));
      expect(exception.responseBody, isNull);
    });

    test('httpError factory with body', () {
      final exception = TransportException.httpError(500, 'Internal error');

      expect(exception.message, equals('HTTP error 500'));
      expect(exception.statusCode, equals(500));
      expect(exception.responseBody, equals('Internal error'));
    });

    test('toString without status code', () {
      const exception = TransportException('Parse failed');

      expect(exception.toString(), equals('TransportException: Parse failed'));
    });

    test('toString with status code', () {
      const exception = TransportException('Server error', statusCode: 503);

      expect(
        exception.toString(),
        equals('TransportException: Server error (status: 503)'),
      );
    });

    test('is SyncException', () {
      const exception = TransportException('Test');

      expect(exception, isA<SyncException>());
    });
  });

  group('DatabaseException', () {
    test('creates with message only', () {
      const exception = DatabaseException('Query failed');

      expect(exception.message, equals('Query failed'));
      expect(exception.cause, isNull);
    });

    test('creates with message and cause', () {
      final cause = Exception('Constraint violation');
      final exception = DatabaseException('Insert failed', cause);

      expect(exception.message, equals('Insert failed'));
      expect(exception.cause, equals(cause));
    });

    test('fromError factory creates exception from error', () {
      final error = Exception('Unique constraint');
      final exception = DatabaseException.fromError(error);

      expect(exception.message, contains('Database operation failed'));
      expect(exception.cause, equals(error));
    });

    test('fromError factory with stack trace', () {
      final error = Exception('Foreign key');
      final stackTrace = StackTrace.current;
      final exception = DatabaseException.fromError(error, stackTrace);

      expect(exception.stackTrace, equals(stackTrace));
    });

    test('toString', () {
      const exception = DatabaseException('DB error');

      expect(exception.toString(), contains('DatabaseException'));
      expect(exception.toString(), contains('DB error'));
    });

    test('is SyncException', () {
      const exception = DatabaseException('Test');

      expect(exception, isA<SyncException>());
    });
  });

  group('ConflictException', () {
    test('creates with required parameters', () {
      const exception = ConflictException(
        'Version mismatch',
        kind: 'users',
        entityId: 'user-123',
      );

      expect(exception.message, equals('Version mismatch'));
      expect(exception.kind, equals('users'));
      expect(exception.entityId, equals('user-123'));
      expect(exception.localData, isNull);
      expect(exception.serverData, isNull);
    });

    test('creates with local and server data', () {
      const localData = {'name': 'Local Name'};
      const serverData = {'name': 'Server Name'};

      const exception = ConflictException(
        'Conflict detected',
        kind: 'tasks',
        entityId: 'task-456',
        localData: localData,
        serverData: serverData,
      );

      expect(exception.localData, equals(localData));
      expect(exception.serverData, equals(serverData));
    });

    test('creates with cause and stack trace', () {
      final cause = Exception('Original error');
      final stackTrace = StackTrace.current;

      final exception = ConflictException(
        'Conflict',
        kind: 'items',
        entityId: 'item-1',
        cause: cause,
        stackTrace: stackTrace,
      );

      expect(exception.cause, equals(cause));
      expect(exception.stackTrace, equals(stackTrace));
    });

    test('toString includes kind and entityId', () {
      const exception = ConflictException(
        'Data conflict',
        kind: 'orders',
        entityId: 'order-789',
      );

      expect(
        exception.toString(),
        equals('ConflictException: Data conflict (orders/order-789)'),
      );
    });

    test('is SyncException', () {
      const exception = ConflictException('Test', kind: 'test', entityId: 'id');

      expect(exception, isA<SyncException>());
    });
  });

  group('SyncOperationException', () {
    test('creates with message only', () {
      const exception = SyncOperationException('Sync failed');

      expect(exception.message, equals('Sync failed'));
      expect(exception.phase, isNull);
      expect(exception.opId, isNull);
    });

    test('creates with phase', () {
      const exception = SyncOperationException('Push error', phase: 'push');

      expect(exception.phase, equals('push'));
    });

    test('creates with opId', () {
      const exception = SyncOperationException(
        'Operation failed',
        opId: 'op-123',
      );

      expect(exception.opId, equals('op-123'));
    });

    test('creates with all parameters', () {
      final cause = Exception('Network error');
      final stackTrace = StackTrace.current;

      final exception = SyncOperationException(
        'Sync operation failed',
        phase: 'pull',
        opId: 'op-456',
        cause: cause,
        stackTrace: stackTrace,
      );

      expect(exception.phase, equals('pull'));
      expect(exception.opId, equals('op-456'));
      expect(exception.cause, equals(cause));
      expect(exception.stackTrace, equals(stackTrace));
    });

    test('toString without phase and opId', () {
      const exception = SyncOperationException('Error');

      expect(exception.toString(), equals('SyncOperationException: Error'));
    });

    test('toString with phase only', () {
      const exception = SyncOperationException('Error', phase: 'push');

      expect(
        exception.toString(),
        equals('SyncOperationException: Error (phase: push)'),
      );
    });

    test('toString with opId only', () {
      const exception = SyncOperationException('Error', opId: 'op-1');

      expect(
        exception.toString(),
        equals('SyncOperationException: Error (opId: op-1)'),
      );
    });

    test('toString with phase and opId', () {
      const exception = SyncOperationException(
        'Error',
        phase: 'pull',
        opId: 'op-2',
      );

      expect(
        exception.toString(),
        equals('SyncOperationException: Error (phase: pull) (opId: op-2)'),
      );
    });

    test('is SyncException', () {
      const exception = SyncOperationException('Test');

      expect(exception, isA<SyncException>());
    });
  });

  group('MaxRetriesExceededException', () {
    test('creates with required parameters', () {
      const exception = MaxRetriesExceededException(
        'Too many retries',
        attempts: 5,
        maxRetries: 5,
      );

      expect(exception.message, equals('Too many retries'));
      expect(exception.attempts, equals(5));
      expect(exception.maxRetries, equals(5));
    });

    test('creates with cause and stack trace', () {
      final cause = Exception('Last error');
      final stackTrace = StackTrace.current;

      final exception = MaxRetriesExceededException(
        'Retries exceeded',
        attempts: 3,
        maxRetries: 3,
        cause: cause,
        stackTrace: stackTrace,
      );

      expect(exception.cause, equals(cause));
      expect(exception.stackTrace, equals(stackTrace));
    });

    test('toString includes attempts info', () {
      const exception = MaxRetriesExceededException(
        'Failed after retries',
        attempts: 10,
        maxRetries: 10,
      );

      expect(
        exception.toString(),
        equals(
          'MaxRetriesExceededException: Failed after retries (attempts: 10/10)',
        ),
      );
    });

    test('is SyncException', () {
      const exception = MaxRetriesExceededException(
        'Test',
        attempts: 1,
        maxRetries: 1,
      );

      expect(exception, isA<SyncException>());
    });
  });

  group('ParseException', () {
    test('creates with message only', () {
      const exception = ParseException('Invalid JSON');

      expect(exception.message, equals('Invalid JSON'));
      expect(exception.cause, isNull);
    });

    test('creates with message and cause', () {
      const cause = FormatException('Unexpected character');
      const exception = ParseException('Parse error', cause);

      expect(exception.message, equals('Parse error'));
      expect(exception.cause, equals(cause));
    });

    test('fromError factory creates exception from error', () {
      const error = FormatException('Invalid format');
      final exception = ParseException.fromError(error);

      expect(exception.message, contains('Failed to parse data'));
      expect(exception.cause, equals(error));
    });

    test('fromError factory with stack trace', () {
      const error = FormatException('Bad data');
      final stackTrace = StackTrace.current;
      final exception = ParseException.fromError(error, stackTrace);

      expect(exception.stackTrace, equals(stackTrace));
    });

    test('toString', () {
      const exception = ParseException('JSON parse error');

      expect(exception.toString(), contains('ParseException'));
      expect(exception.toString(), contains('JSON parse error'));
    });

    test('is SyncException', () {
      const exception = ParseException('Test');

      expect(exception, isA<SyncException>());
    });
  });

  group('SyncException sealed class', () {
    test('all exceptions are subtypes of SyncException', () {
      const exceptions = <SyncException>[
        NetworkException('test'),
        TransportException('test'),
        DatabaseException('test'),
        ConflictException('test', kind: 'k', entityId: 'id'),
        SyncOperationException('test'),
        MaxRetriesExceededException('test', attempts: 1, maxRetries: 1),
        ParseException('test'),
      ];

      for (final exception in exceptions) {
        expect(exception, isA<SyncException>());
        expect(exception, isA<Exception>());
      }
    });
  });
}
