import 'package:offline_first_sync_drift/src/tables/sync_data_classes.dart';
import 'package:test/test.dart';

void main() {
  group('SyncOutboxData', () {
    test('creates with required parameters', () {
      const data = SyncOutboxData(
        opId: 'op-123',
        kind: 'users',
        entityId: 'user-456',
        op: 'upsert',
        ts: 1704067200000,
        tryCount: 0,
      );

      expect(data.opId, 'op-123');
      expect(data.kind, 'users');
      expect(data.entityId, 'user-456');
      expect(data.op, 'upsert');
      expect(data.ts, 1704067200000);
      expect(data.tryCount, 0);
      expect(data.payload, isNull);
      expect(data.baseUpdatedAt, isNull);
      expect(data.changedFields, isNull);
    });

    test('creates with all parameters', () {
      const data = SyncOutboxData(
        opId: 'op-789',
        kind: 'posts',
        entityId: 'post-111',
        op: 'delete',
        payload: '{"title":"Test"}',
        ts: 1704067200000,
        tryCount: 3,
        baseUpdatedAt: 1704000000000,
        changedFields: 'title,content',
      );

      expect(data.opId, 'op-789');
      expect(data.kind, 'posts');
      expect(data.entityId, 'post-111');
      expect(data.op, 'delete');
      expect(data.payload, '{"title":"Test"}');
      expect(data.ts, 1704067200000);
      expect(data.tryCount, 3);
      expect(data.baseUpdatedAt, 1704000000000);
      expect(data.changedFields, 'title,content');
    });

    test('can be const', () {
      const data = SyncOutboxData(
        opId: 'const-op',
        kind: 'items',
        entityId: 'item-1',
        op: 'upsert',
        ts: 0,
        tryCount: 0,
      );

      expect(data.opId, 'const-op');
    });
  });

  group('SyncCursorData', () {
    test('creates with required parameters', () {
      const data = SyncCursorData(
        kind: 'users',
        ts: 1704067200000,
        lastId: 'user-999',
      );

      expect(data.kind, 'users');
      expect(data.ts, 1704067200000);
      expect(data.lastId, 'user-999');
    });

    test('can be const', () {
      const data = SyncCursorData(kind: 'posts', ts: 0, lastId: '');

      expect(data.kind, 'posts');
      expect(data.ts, 0);
      expect(data.lastId, '');
    });

    test('handles different kinds', () {
      const usersCursor = SyncCursorData(kind: 'users', ts: 100, lastId: 'u1');

      const postsCursor = SyncCursorData(kind: 'posts', ts: 200, lastId: 'p1');

      expect(usersCursor.kind, isNot(postsCursor.kind));
      expect(usersCursor.ts, isNot(postsCursor.ts));
    });
  });
}
