import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

import '../models/todo.dart';
import 'tables/todos.dart';

export '../models/todo.dart';

part 'database.g.dart';

/// Application database with offline-first sync support.
///
/// Uses [SyncDatabaseMixin] to provide synchronization capabilities:
/// - Outbox for pending operations
/// - Cursors for tracking sync progress
@DriftDatabase(
  include: {'package:offline_first_sync_drift/src/sync_tables.drift'},
  tables: [Todos],
)
class AppDatabase extends _$AppDatabase with SyncDatabaseMixin {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  /// Opens a persistent database for Flutter.
  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'todo_simple');
  }

  /// Opens a persistent database with custom name.
  static AppDatabase open({String name = 'todo_simple'}) {
    return AppDatabase(driftDatabase(name: name));
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
      );
}
