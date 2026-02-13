import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

import '../database/database.dart';
import '../models/todo.dart';

/// Single source of truth for Todo sync wiring.
SyncableTable<Todo> todoSyncTable(AppDatabase db) => SyncableTable<Todo>(
  kind: 'todos',
  table: db.todos,
  fromJson: Todo.fromJson,
  toJson: (t) => t.toJson(),
  toInsertable: (t) => t.toInsertable(),
  getId: (t) => t.id,
  getUpdatedAt: (t) => t.updatedAt,
);

