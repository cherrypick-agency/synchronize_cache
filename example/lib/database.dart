import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:example/models/daily_feeling.dart';
import 'package:example/models/health_record.dart';
import 'package:path/path.dart' as p;
import 'package:synchronize_cache/synchronize_cache.dart';

import 'package:example/database.drift.dart';

/// База данных приложения с поддержкой синхронизации.
@DriftDatabase(
  include: {'package:synchronize_cache/src/sync_tables.drift'},
  tables: [HealthRecords, DailyFeelings],
)
class AppDatabase extends $AppDatabase with SyncDatabaseMixin {
  AppDatabase(super.e);

  AppDatabase._(super.e);

  /// Открыть базу данных в файле.
  static Future<AppDatabase> open({String filename = 'app.db'}) async {
    final dir = Directory.current.path;
    final file = File(p.join(dir, filename));
    final executor = NativeDatabase(file);
    return AppDatabase._(executor);
  }

  /// Создать in-memory базу данных (для тестов).
  static AppDatabase inMemory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA journal_mode=WAL;');
          await customStatement('PRAGMA synchronous=NORMAL;');
        },
      );
}
