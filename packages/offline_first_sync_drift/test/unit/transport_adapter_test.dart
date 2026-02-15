import 'package:offline_first_sync_drift/src/conflict_resolution.dart';
import 'package:offline_first_sync_drift/src/transport_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('PullPage', () {
    test('creates with items only', () {
      final page = PullPage(
        items: [
          {'id': '1', 'name': 'Item 1'},
          {'id': '2', 'name': 'Item 2'},
        ],
      );

      expect(page.items, hasLength(2));
      expect(page.nextPageToken, isNull);
    });

    test('creates with items and nextPageToken', () {
      final page = PullPage(
        items: [
          {'id': '1'},
        ],
        nextPageToken: 'token-123',
      );

      expect(page.items, hasLength(1));
      expect(page.nextPageToken, equals('token-123'));
    });

    test('creates with empty items', () {
      final page = PullPage(items: []);

      expect(page.items, isEmpty);
      expect(page.nextPageToken, isNull);
    });

    test('items can contain complex objects', () {
      final page = PullPage(
        items: [
          {
            'id': '1',
            'metadata': {'key': 'value'},
            'tags': ['a', 'b'],
            'count': 42,
            'active': true,
            'nullable': null,
          },
        ],
      );

      final item = page.items.first;
      expect(item['id'], equals('1'));
      expect(item['metadata'], isA<Map<String, dynamic>>());
      expect(item['tags'], isA<List<dynamic>>());
      expect(item['count'], equals(42));
      expect(item['active'], isTrue);
      expect(item['nullable'], isNull);
    });
  });

  group('OpPushResult', () {
    test('creates with success result', () {
      const result = OpPushResult(opId: 'op-123', result: PushSuccess());

      expect(result.opId, equals('op-123'));
      expect(result.result, isA<PushSuccess>());
      expect(result.isSuccess, isTrue);
      expect(result.isConflict, isFalse);
      expect(result.isNotFound, isFalse);
      expect(result.isError, isFalse);
    });

    test('creates with conflict result', () {
      final result = OpPushResult(
        opId: 'op-456',
        result: PushConflict(
          serverData: {'name': 'Server'},
          serverTimestamp: DateTime.utc(2024, 1, 1),
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.isConflict, isTrue);
      expect(result.isNotFound, isFalse);
      expect(result.isError, isFalse);
    });

    test('creates with not found result', () {
      const result = OpPushResult(opId: 'op-789', result: PushNotFound());

      expect(result.isSuccess, isFalse);
      expect(result.isConflict, isFalse);
      expect(result.isNotFound, isTrue);
      expect(result.isError, isFalse);
    });

    test('creates with error result', () {
      const result = OpPushResult(
        opId: 'op-err',
        result: PushError('Network error'),
      );

      expect(result.isSuccess, isFalse);
      expect(result.isConflict, isFalse);
      expect(result.isNotFound, isFalse);
      expect(result.isError, isTrue);
    });
  });

  group('BatchPushResult', () {
    test('creates with empty results', () {
      const result = BatchPushResult(results: []);

      expect(result.results, isEmpty);
      expect(result.allSuccess, isTrue);
      expect(result.hasConflicts, isFalse);
      expect(result.hasErrors, isFalse);
    });

    test('creates with all success results', () {
      const result = BatchPushResult(
        results: [
          OpPushResult(opId: 'op-1', result: PushSuccess()),
          OpPushResult(opId: 'op-2', result: PushSuccess()),
          OpPushResult(opId: 'op-3', result: PushSuccess()),
        ],
      );

      expect(result.allSuccess, isTrue);
      expect(result.hasConflicts, isFalse);
      expect(result.hasErrors, isFalse);
      expect(result.successes.toList(), hasLength(3));
      expect(result.conflicts.toList(), isEmpty);
      expect(result.errors.toList(), isEmpty);
    });

    test('creates with mixed results', () {
      final result = BatchPushResult(
        results: [
          const OpPushResult(opId: 'op-1', result: PushSuccess()),
          OpPushResult(
            opId: 'op-2',
            result: PushConflict(
              serverData: {},
              serverTimestamp: DateTime.utc(2024, 1, 1),
            ),
          ),
          const OpPushResult(opId: 'op-3', result: PushError('Error')),
          const OpPushResult(opId: 'op-4', result: PushNotFound()),
        ],
      );

      expect(result.allSuccess, isFalse);
      expect(result.hasConflicts, isTrue);
      expect(result.hasErrors, isTrue);
      expect(result.successes.toList(), hasLength(1));
      expect(result.conflicts.toList(), hasLength(1));
      expect(result.errors.toList(), hasLength(1));
    });

    test('conflicts returns only conflict results', () {
      final result = BatchPushResult(
        results: [
          const OpPushResult(opId: 'op-1', result: PushSuccess()),
          OpPushResult(
            opId: 'op-2',
            result: PushConflict(
              serverData: {'name': 'Server1'},
              serverTimestamp: DateTime.utc(2024, 1, 1),
            ),
          ),
          OpPushResult(
            opId: 'op-3',
            result: PushConflict(
              serverData: {'name': 'Server2'},
              serverTimestamp: DateTime.utc(2024, 1, 2),
            ),
          ),
        ],
      );

      final conflicts = result.conflicts.toList();
      expect(conflicts, hasLength(2));
      expect(conflicts[0].opId, equals('op-2'));
      expect(conflicts[1].opId, equals('op-3'));
    });

    test('successes returns only success results', () {
      final result = BatchPushResult(
        results: [
          const OpPushResult(opId: 'op-1', result: PushSuccess()),
          OpPushResult(
            opId: 'op-2',
            result: PushConflict(
              serverData: {},
              serverTimestamp: DateTime.utc(2024, 1, 1),
            ),
          ),
          const OpPushResult(opId: 'op-3', result: PushSuccess()),
        ],
      );

      final successes = result.successes.toList();
      expect(successes, hasLength(2));
      expect(successes[0].opId, equals('op-1'));
      expect(successes[1].opId, equals('op-3'));
    });

    test('errors returns only error results', () {
      const result = BatchPushResult(
        results: [
          OpPushResult(opId: 'op-1', result: PushError('Error 1')),
          OpPushResult(opId: 'op-2', result: PushSuccess()),
          OpPushResult(opId: 'op-3', result: PushError('Error 2')),
        ],
      );

      final errors = result.errors.toList();
      expect(errors, hasLength(2));
      expect(errors[0].opId, equals('op-1'));
      expect(errors[1].opId, equals('op-3'));
    });
  });

  group('PushResult sealed class', () {
    group('PushSuccess', () {
      test('creates without data', () {
        const result = PushSuccess();

        expect(result, isA<PushResult>());
        expect(result.serverData, isNull);
        expect(result.serverVersion, isNull);
      });

      test('creates with server data', () {
        const result = PushSuccess(
          serverData: {'id': '1', 'updatedAt': '2024-01-01'},
        );

        expect(result.serverData, isNotNull);
        expect(result.serverData!['id'], equals('1'));
      });

      test('creates with server version', () {
        const result = PushSuccess(serverVersion: 'v2');

        expect(result.serverVersion, equals('v2'));
      });

      test('creates with both data and version', () {
        const result = PushSuccess(
          serverData: {'id': '1'},
          serverVersion: 'v3',
        );

        expect(result.serverData, isNotNull);
        expect(result.serverVersion, equals('v3'));
      });
    });

    group('PushConflict', () {
      test('creates with required parameters', () {
        final timestamp = DateTime.utc(2024, 1, 15);
        final result = PushConflict(
          serverData: {'name': 'Server Name'},
          serverTimestamp: timestamp,
        );

        expect(result, isA<PushResult>());
        expect(result.serverData, equals({'name': 'Server Name'}));
        expect(result.serverTimestamp, equals(timestamp));
        expect(result.serverVersion, isNull);
      });

      test('creates with server version', () {
        final result = PushConflict(
          serverData: {'name': 'Server'},
          serverTimestamp: DateTime.utc(2024, 1, 1),
          serverVersion: 'v5',
        );

        expect(result.serverVersion, equals('v5'));
      });
    });

    group('PushNotFound', () {
      test('creates instance', () {
        const result = PushNotFound();

        expect(result, isA<PushResult>());
      });

      test('can be used as const', () {
        const result1 = PushNotFound();
        const result2 = PushNotFound();

        expect(identical(result1, result2), isTrue);
      });
    });

    group('PushError', () {
      test('creates with error only', () {
        const result = PushError('Network timeout');

        expect(result, isA<PushResult>());
        expect(result.error, equals('Network timeout'));
        expect(result.stackTrace, isNull);
      });

      test('creates with error and stack trace', () {
        final stackTrace = StackTrace.current;
        final result = PushError('Connection failed', stackTrace);

        expect(result.error, equals('Connection failed'));
        expect(result.stackTrace, equals(stackTrace));
      });

      test('error can be any Object', () {
        final exception = Exception('Test error');
        final result = PushError(exception);

        expect(result.error, equals(exception));
      });
    });

    test('pattern matching works', () {
      final results = <PushResult>[
        const PushSuccess(serverData: {'id': '1'}),
        PushConflict(
          serverData: {'id': '2'},
          serverTimestamp: DateTime.utc(2024, 1, 1),
        ),
        const PushNotFound(),
        const PushError('Error'),
      ];

      final labels = <String>[];
      for (final result in results) {
        switch (result) {
          case PushSuccess(:final serverData):
            labels.add('success: ${serverData?['id']}');
          case PushConflict(:final serverData):
            labels.add('conflict: ${serverData['id']}');
          case PushNotFound():
            labels.add('not_found');
          case PushError(:final error):
            labels.add('error: $error');
        }
      }

      expect(
        labels,
        equals(['success: 1', 'conflict: 2', 'not_found', 'error: Error']),
      );
    });
  });

  group('FetchResult sealed class', () {
    group('FetchSuccess', () {
      test('creates with data only', () {
        const result = FetchSuccess(data: {'id': '1', 'name': 'Item'});

        expect(result, isA<FetchResult>());
        expect(result.data, equals({'id': '1', 'name': 'Item'}));
        expect(result.version, isNull);
      });

      test('creates with data and version', () {
        const result = FetchSuccess(data: {'id': '1'}, version: 'v10');

        expect(result.data, isNotNull);
        expect(result.version, equals('v10'));
      });
    });

    group('FetchNotFound', () {
      test('creates instance', () {
        const result = FetchNotFound();

        expect(result, isA<FetchResult>());
      });

      test('can be used as const', () {
        const result1 = FetchNotFound();
        const result2 = FetchNotFound();

        expect(identical(result1, result2), isTrue);
      });
    });

    group('FetchError', () {
      test('creates with error only', () {
        const result = FetchError('Server error');

        expect(result, isA<FetchResult>());
        expect(result.error, equals('Server error'));
        expect(result.stackTrace, isNull);
      });

      test('creates with error and stack trace', () {
        final stackTrace = StackTrace.current;
        final result = FetchError('Timeout', stackTrace);

        expect(result.error, equals('Timeout'));
        expect(result.stackTrace, equals(stackTrace));
      });

      test('error can be any Object', () {
        final exception = Exception('Fetch failed');
        final result = FetchError(exception);

        expect(result.error, equals(exception));
      });
    });

    test('pattern matching works', () {
      final results = <FetchResult>[
        const FetchSuccess(data: {'id': '1'}),
        const FetchNotFound(),
        const FetchError('Error'),
      ];

      final labels = <String>[];
      for (final result in results) {
        switch (result) {
          case FetchSuccess(:final data):
            labels.add('success: ${data['id']}');
          case FetchNotFound():
            labels.add('not_found');
          case FetchError(:final error):
            labels.add('error: $error');
        }
      }

      expect(labels, equals(['success: 1', 'not_found', 'error: Error']));
    });
  });
}
