import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

import '../models/todo.dart';
import 'tables/todos.dart';

export '../models/todo.dart';

part 'database.g.dart';

@DriftDatabase(
  include: {'package:offline_first_sync_drift/src/sync_tables.drift'},
  tables: [Todos],
)
class AppDatabase extends _$AppDatabase with SyncDatabaseMixin {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'todo_simple_new');
  }

  static AppDatabase open({String name = 'todo_simple_new'}) {
    return AppDatabase(driftDatabase(name: name));
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(syncOutboxMeta);
          }
        },
      );
}
