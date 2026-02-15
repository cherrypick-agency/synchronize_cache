import 'package:drift/drift.dart' show Value;
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';
import 'package:test/test.dart';

import '../sync_engine_test.dart';
import '../sync_engine_test.drift.dart';

void main() {
  group('Op factories', () {
    test('UpsertOp.create generates opId and utc timestamp', () {
      final op = UpsertOp.create(
        kind: 'todos',
        id: '1',
        payloadJson: const {'title': 'x'},
      );

      expect(op.opId, isNotEmpty);
      expect(op.localTimestamp.isUtc, isTrue);
      expect(op.kind, 'todos');
      expect(op.id, '1');
      expect(op.payloadJson, {'title': 'x'});
    });

    test('DeleteOp.create generates opId and utc timestamp', () {
      final op = DeleteOp.create(kind: 'todos', id: '1');
      expect(op.opId, isNotEmpty);
      expect(op.localTimestamp.isUtc, isTrue);
      expect(op.kind, 'todos');
      expect(op.id, '1');
    });
  });

  group('ChangedFieldsTracker', () {
    test('tracks differences and returns null when empty', () {
      final t = ChangedFieldsTracker();
      expect(t.fieldsOrNull, isNull);

      final res = t.changed('title', from: 'a', to: 'b');
      expect(res, 'b');
      expect(t.fields, {'title'});
      expect(t.fieldsOrNull, {'title'});
    });

    test('ChangedFieldsDiff computes nested differences', () {
      final before = <String, Object?>{
        'title': 'old',
        'meta': {
          'a': 1,
          'b': [1, 2],
        },
        'updated_at': '2024-01-01T00:00:00Z',
      };
      final after = <String, Object?>{
        'title': 'new',
        'meta': {
          'a': 1,
          'b': [1, 2, 3],
        },
        'updated_at': '2024-01-02T00:00:00Z',
      };

      final diff = ChangedFieldsDiff.diffMaps(before, after);
      expect(diff, {'title', 'meta'});
      expect(diff.contains('updated_at'), isFalse);
    });
  });

  group('SyncWriter', () {
    test('insertAndEnqueue writes local row and outbox entry', () async {
      final db = TestDatabase();
      addTearDown(db.close);

      final table = SyncableTable<TestItem>(
        kind: 'test_items',
        table: db.testItems,
        fromJson: TestItem.fromJson,
        toJson: (e) => e.toJson(),
        toInsertable:
            (e) => TestItemsCompanion.insert(
              updatedAt: e.updatedAt,
              deletedAt: Value(e.deletedAt),
              deletedAtLocal: Value(e.deletedAtLocal),
              id: e.id,
              name: e.name,
            ),
        getId: (e) => e.id,
        getUpdatedAt: (e) => e.updatedAt,
      );

      final fixedNow = DateTime.utc(2024, 1, 1, 0, 0, 0);

      final writer = db
          .syncWriter(opIdFactory: () => 'op-fixed', clock: () => fixedNow)
          .forTable(table);

      final item = TestItem(id: 'id-1', updatedAt: fixedNow, name: 'Hello');

      await writer.insertAndEnqueue(item);

      final rows = await db.select(db.testItems).get();
      expect(rows, hasLength(1));
      expect(rows.first.id, 'id-1');

      final outbox = await db.takeOutbox();
      expect(outbox, hasLength(1));
      final op = outbox.first as UpsertOp;
      expect(op.opId, 'op-fixed');
      expect(op.kind, 'test_items');
      expect(op.id, 'id-1');
      expect(op.localTimestamp, fixedNow);
    });

    test('replaceAndEnqueue stores changedFields', () async {
      final db = TestDatabase();
      addTearDown(db.close);

      final table = SyncableTable<TestItem>(
        kind: 'test_items',
        table: db.testItems,
        fromJson: TestItem.fromJson,
        toJson: (e) => e.toJson(),
        toInsertable:
            (e) => TestItemsCompanion.insert(
              updatedAt: e.updatedAt,
              deletedAt: Value(e.deletedAt),
              deletedAtLocal: Value(e.deletedAtLocal),
              id: e.id,
              name: e.name,
            ),
        getId: (e) => e.id,
        getUpdatedAt: (e) => e.updatedAt,
      );

      final fixedNow = DateTime.utc(2024, 1, 2, 0, 0, 0);
      final writer = db
          .syncWriter(opIdFactory: () => 'op-2', clock: () => fixedNow)
          .forTable(table);

      // Seed initial row.
      final base = DateTime.utc(2024, 1, 1, 0, 0, 0);
      final item = TestItem(id: 'id-1', updatedAt: base, name: 'A');
      await db
          .into(db.testItems)
          .insert(
            TestItemsCompanion.insert(
              updatedAt: item.updatedAt,
              deletedAt: Value(item.deletedAt),
              deletedAtLocal: Value(item.deletedAtLocal),
              id: item.id,
              name: item.name,
            ),
          );

      final updated = TestItem(id: 'id-1', updatedAt: fixedNow, name: 'B');
      await writer.replaceAndEnqueue(
        updated,
        baseUpdatedAt: base,
        changedFields: {'name'},
      );

      final outbox = await db.takeOutbox();
      expect(outbox, hasLength(1));
      final op = outbox.first as UpsertOp;
      expect(op.changedFields, {'name'});
      expect(op.baseUpdatedAt, base);
    });

    test('replaceAndEnqueueDiff auto-computes changedFields', () async {
      final db = TestDatabase();
      addTearDown(db.close);

      final table = db.testItems.syncTable(
        kind: 'test_items',
        fromJson: TestItem.fromJson,
        toJson: (e) => e.toJson(),
        toInsertable:
            (e) => TestItemsCompanion.insert(
              updatedAt: e.updatedAt,
              deletedAt: Value(e.deletedAt),
              deletedAtLocal: Value(e.deletedAtLocal),
              id: e.id,
              name: e.name,
            ),
        getId: (e) => e.id,
        getUpdatedAt: (e) => e.updatedAt,
      );

      final base = DateTime.utc(2024, 1, 1, 0, 0, 0);
      final before = TestItem(id: 'id-1', updatedAt: base, name: 'A');
      await db
          .into(db.testItems)
          .insert(
            TestItemsCompanion.insert(
              updatedAt: before.updatedAt,
              deletedAt: Value(before.deletedAt),
              deletedAtLocal: Value(before.deletedAtLocal),
              id: before.id,
              name: before.name,
            ),
          );

      final after = TestItem(id: 'id-1', updatedAt: base, name: 'B');
      await db
          .syncWriter(opIdFactory: () => 'op-diff')
          .forTable(table)
          .replaceAndEnqueueDiff(
            before: before,
            after: after,
            baseUpdatedAt: base,
          );

      final outbox = await db.takeOutbox();
      final op = outbox.single as UpsertOp;
      expect(op.changedFields, {'name'});
      expect(op.opId, 'op-diff');
    });
  });

  group('syncTable sugar', () {
    test('uses actual table name when kind is omitted', () {
      final db = TestDatabase();
      addTearDown(db.close);

      final table = db.testItems.syncTable(
        fromJson: TestItem.fromJson,
        toJson: (e) => e.toJson(),
        toInsertable: (e) => e.toInsertable(),
        getId: (e) => e.id,
        getUpdatedAt: (e) => e.updatedAt,
      );

      expect(table.kind, 'test_items');
    });

    test('throws for empty kind', () {
      final db = TestDatabase();
      addTearDown(db.close);

      expect(
        () => db.testItems.syncTable(
          kind: '   ',
          fromJson: TestItem.fromJson,
          toJson: (e) => e.toJson(),
          toInsertable: (e) => e.toInsertable(),
          getId: (e) => e.id,
          getUpdatedAt: (e) => e.updatedAt,
        ),
        throwsArgumentError,
      );
    });
  });
}
