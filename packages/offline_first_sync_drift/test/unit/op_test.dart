import 'package:offline_first_sync_drift/src/op.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2024, 1, 15, 10, 30, 0);

  group('UpsertOp', () {
    test('creates with required parameters', () {
      final op = UpsertOp(
        opId: 'op-123',
        kind: 'users',
        id: 'user-456',
        localTimestamp: now,
        payloadJson: {'name': 'John'},
      );

      expect(op.opId, equals('op-123'));
      expect(op.kind, equals('users'));
      expect(op.id, equals('user-456'));
      expect(op.localTimestamp, equals(now));
      expect(op.payloadJson, equals({'name': 'John'}));
      expect(op.baseUpdatedAt, isNull);
      expect(op.changedFields, isNull);
    });

    test('creates with baseUpdatedAt', () {
      final baseTime = DateTime.utc(2024, 1, 14);
      final op = UpsertOp(
        opId: 'op-1',
        kind: 'tasks',
        id: 'task-1',
        localTimestamp: now,
        payloadJson: {'title': 'Task'},
        baseUpdatedAt: baseTime,
      );

      expect(op.baseUpdatedAt, equals(baseTime));
    });

    test('creates with changedFields', () {
      final op = UpsertOp(
        opId: 'op-2',
        kind: 'tasks',
        id: 'task-2',
        localTimestamp: now,
        payloadJson: {'title': 'Updated', 'description': 'New desc'},
        changedFields: {'title', 'description'},
      );

      expect(op.changedFields, equals({'title', 'description'}));
    });

    test('isNewRecord returns true when baseUpdatedAt is null', () {
      final op = UpsertOp(
        opId: 'op-new',
        kind: 'items',
        id: 'item-1',
        localTimestamp: now,
        payloadJson: {'data': 'value'},
      );

      expect(op.isNewRecord, isTrue);
    });

    test('isNewRecord returns false when baseUpdatedAt is set', () {
      final op = UpsertOp(
        opId: 'op-update',
        kind: 'items',
        id: 'item-2',
        localTimestamp: now,
        payloadJson: {'data': 'updated'},
        baseUpdatedAt: DateTime.utc(2024, 1, 10),
      );

      expect(op.isNewRecord, isFalse);
    });

    test('copyWith preserves values when null passed', () {
      final original = UpsertOp(
        opId: 'op-orig',
        kind: 'tasks',
        id: 'task-orig',
        localTimestamp: now,
        payloadJson: {'title': 'Original'},
        baseUpdatedAt: DateTime.utc(2024, 1, 1),
        changedFields: {'title'},
      );

      final copied = original.copyWith();

      expect(copied.opId, equals(original.opId));
      expect(copied.kind, equals(original.kind));
      expect(copied.id, equals(original.id));
      expect(copied.localTimestamp, equals(original.localTimestamp));
      expect(copied.payloadJson, equals(original.payloadJson));
      expect(copied.baseUpdatedAt, equals(original.baseUpdatedAt));
      expect(copied.changedFields, equals(original.changedFields));
    });

    test('copyWith updates specified values', () {
      final original = UpsertOp(
        opId: 'op-1',
        kind: 'tasks',
        id: 'task-1',
        localTimestamp: now,
        payloadJson: {'title': 'Old'},
      );

      final newTime = DateTime.utc(2024, 2, 1);
      final copied = original.copyWith(
        opId: 'op-2',
        payloadJson: {'title': 'New'},
        localTimestamp: newTime,
      );

      expect(copied.opId, equals('op-2'));
      expect(copied.payloadJson, equals({'title': 'New'}));
      expect(copied.localTimestamp, equals(newTime));
      expect(copied.kind, equals('tasks'));
      expect(copied.id, equals('task-1'));
    });

    test('copyWith can update all values', () {
      final original = UpsertOp(
        opId: 'op-1',
        kind: 'tasks',
        id: 'task-1',
        localTimestamp: now,
        payloadJson: {'title': 'Old'},
      );

      final newTime = DateTime.utc(2024, 3, 1);
      final newBase = DateTime.utc(2024, 2, 28);
      final copied = original.copyWith(
        opId: 'op-new',
        kind: 'items',
        id: 'item-new',
        localTimestamp: newTime,
        payloadJson: {'name': 'New item'},
        baseUpdatedAt: newBase,
        changedFields: {'name'},
      );

      expect(copied.opId, equals('op-new'));
      expect(copied.kind, equals('items'));
      expect(copied.id, equals('item-new'));
      expect(copied.localTimestamp, equals(newTime));
      expect(copied.payloadJson, equals({'name': 'New item'}));
      expect(copied.baseUpdatedAt, equals(newBase));
      expect(copied.changedFields, equals({'name'}));
    });

    test('is Op', () {
      final op = UpsertOp(
        opId: 'op-1',
        kind: 'test',
        id: 'id-1',
        localTimestamp: now,
        payloadJson: {},
      );

      expect(op, isA<Op>());
    });

    test('handles complex payload', () {
      final op = UpsertOp(
        opId: 'op-complex',
        kind: 'documents',
        id: 'doc-1',
        localTimestamp: now,
        payloadJson: {
          'title': 'Document',
          'metadata': {
            'author': 'John',
            'tags': ['tag1', 'tag2'],
          },
          'content': null,
          'version': 1,
          'active': true,
        },
      );

      expect(op.payloadJson['title'], equals('Document'));
      expect(op.payloadJson['metadata'], isA<Map<String, dynamic>>());
      expect(
        (op.payloadJson['metadata'] as Map<String, dynamic>)['tags'],
        isA<List<dynamic>>(),
      );
      expect(op.payloadJson['content'], isNull);
      expect(op.payloadJson['version'], equals(1));
      expect(op.payloadJson['active'], isTrue);
    });
  });

  group('DeleteOp', () {
    test('creates with required parameters', () {
      final op = DeleteOp(
        opId: 'del-123',
        kind: 'users',
        id: 'user-456',
        localTimestamp: now,
      );

      expect(op.opId, equals('del-123'));
      expect(op.kind, equals('users'));
      expect(op.id, equals('user-456'));
      expect(op.localTimestamp, equals(now));
      expect(op.baseUpdatedAt, isNull);
    });

    test('creates with baseUpdatedAt', () {
      final baseTime = DateTime.utc(2024, 1, 10);
      final op = DeleteOp(
        opId: 'del-1',
        kind: 'tasks',
        id: 'task-1',
        localTimestamp: now,
        baseUpdatedAt: baseTime,
      );

      expect(op.baseUpdatedAt, equals(baseTime));
    });

    test('is Op', () {
      final op = DeleteOp(
        opId: 'del-1',
        kind: 'test',
        id: 'id-1',
        localTimestamp: now,
      );

      expect(op, isA<Op>());
    });
  });

  group('Op sealed class', () {
    test('UpsertOp and DeleteOp are subtypes of Op', () {
      final upsert = UpsertOp(
        opId: 'op-1',
        kind: 'test',
        id: 'id-1',
        localTimestamp: now,
        payloadJson: {},
      );

      final delete = DeleteOp(
        opId: 'op-2',
        kind: 'test',
        id: 'id-2',
        localTimestamp: now,
      );

      expect(upsert, isA<Op>());
      expect(delete, isA<Op>());
    });

    test('can be used in pattern matching', () {
      final ops = <Op>[
        UpsertOp(
          opId: 'op-1',
          kind: 'users',
          id: 'user-1',
          localTimestamp: now,
          payloadJson: {'name': 'John'},
        ),
        DeleteOp(
          opId: 'op-2',
          kind: 'users',
          id: 'user-2',
          localTimestamp: now,
        ),
      ];

      final results = <String>[];
      for (final op in ops) {
        switch (op) {
          case UpsertOp(:final payloadJson):
            results.add('upsert: ${payloadJson['name']}');
          case DeleteOp():
            results.add('delete: ${op.id}');
        }
      }

      expect(results, equals(['upsert: John', 'delete: user-2']));
    });
  });
}
