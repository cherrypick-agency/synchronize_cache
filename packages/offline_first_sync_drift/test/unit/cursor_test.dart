import 'package:offline_first_sync_drift/src/cursor.dart';
import 'package:test/test.dart';

void main() {
  group('Cursor', () {
    test('creates with ts and lastId', () {
      final timestamp = DateTime.utc(2024, 1, 15, 10, 30);
      final cursor = Cursor(ts: timestamp, lastId: 'item-123');

      expect(cursor.ts, equals(timestamp));
      expect(cursor.lastId, equals('item-123'));
    });

    test('creates two cursors with same values', () {
      final ts = DateTime.utc(2024, 1, 1);
      final cursor1 = Cursor(ts: ts, lastId: 'id');
      final cursor2 = Cursor(ts: ts, lastId: 'id');

      expect(cursor1.ts, equals(cursor2.ts));
      expect(cursor1.lastId, equals(cursor2.lastId));
    });

    test('handles empty lastId', () {
      final cursor = Cursor(ts: DateTime.utc(2024, 1, 1), lastId: '');

      expect(cursor.lastId, isEmpty);
    });

    test('handles epoch timestamp', () {
      final cursor = Cursor(ts: DateTime.utc(1970, 1, 1), lastId: 'first');

      expect(cursor.ts.millisecondsSinceEpoch, equals(0));
    });

    test('handles future timestamp', () {
      final future = DateTime.utc(2050, 12, 31, 23, 59, 59);
      final cursor = Cursor(ts: future, lastId: 'future-id');

      expect(cursor.ts, equals(future));
    });

    test('ts is preserved in UTC', () {
      final utcTime = DateTime.utc(2024, 6, 15, 12, 0, 0);
      final cursor = Cursor(ts: utcTime, lastId: 'test');

      expect(cursor.ts.isUtc, isTrue);
      expect(cursor.ts, equals(utcTime));
    });

    test('handles various lastId formats', () {
      final ts = DateTime.utc(2024, 1, 1);

      final cursorUuid = Cursor(
        ts: ts,
        lastId: '123e4567-e89b-12d3-a456-426614174000',
      );
      expect(cursorUuid.lastId, contains('-'));

      final cursorNumeric = Cursor(ts: ts, lastId: '12345');
      expect(cursorNumeric.lastId, equals('12345'));

      final cursorComplex = Cursor(ts: ts, lastId: 'prefix_123_suffix');
      expect(cursorComplex.lastId, equals('prefix_123_suffix'));
    });
  });
}
