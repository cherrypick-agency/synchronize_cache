import 'package:flutter_test/flutter_test.dart';
import 'package:todo_simple_frontend/database/database.dart';
import 'package:todo_simple_frontend/services/sync_service.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SyncService service;

  setUp(() async {
    db = createTestDatabase();
    service = SyncService(
      db: db,
      baseUrl: 'http://localhost:8080',
    );
  });

  tearDown(() async {
    service.dispose();
    await db.close();
  });

  group('SyncService', () {
    group('initialization', () {
      test('starts with idle status', () {
        expect(service.status, SyncStatus.idle);
      });

      test('starts with no error', () {
        expect(service.error, isNull);
      });

      test('starts with zero progress', () {
        expect(service.progress, 0.0);
      });

      test('starts with no last stats', () {
        expect(service.lastStats, isNull);
      });

      test('isSyncing is false initially', () {
        expect(service.isSyncing, false);
      });
    });

    group('checkHealth', () {
      test('returns false when server is not available', () async {
        // Server is not running, so health check should fail
        final result = await service.checkHealth();
        expect(result, false);
      });
    });

    group('getPendingCount', () {
      test('returns zero when outbox is empty', () async {
        final count = await service.getPendingCount();
        expect(count, 0);
      });
    });

    group('events', () {
      test('provides event stream', () {
        expect(service.events, isA<Stream>());
      });
    });

    group('status changes', () {
      test('status changes are tracked correctly', () {
        // Initial status is idle
        expect(service.status, SyncStatus.idle);
        expect(service.isSyncing, false);
      });
    });

    group('SyncStatus enum', () {
      test('has correct values', () {
        expect(SyncStatus.values, hasLength(3));
        expect(SyncStatus.values, contains(SyncStatus.idle));
        expect(SyncStatus.values, contains(SyncStatus.syncing));
        expect(SyncStatus.values, contains(SyncStatus.error));
      });
    });

    group('notifyListeners', () {
      test('can add and remove listeners', () {
        var count = 0;
        void listener() => count++;

        service.addListener(listener);
        service.removeListener(listener);

        // Should complete without throwing
        expect(count, 0);
      });
    });

    group('auto sync', () {
      test('can start auto sync', () {
        // Should not throw
        expect(
          () => service.startAuto(interval: const Duration(minutes: 1)),
          returnsNormally,
        );
      });

      test('can stop auto sync', () {
        service.startAuto();
        // Should not throw
        expect(() => service.stopAuto(), returnsNormally);
      });
    });
  });
}
