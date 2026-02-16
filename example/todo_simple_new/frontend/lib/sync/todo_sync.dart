import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';

import '../database/database.dart';

SyncableTable<Todo> todoSyncTable(AppDatabase db) => db.todos.syncTable(
      fromJson: Todo.fromJson,
      toJson: (t) => t.toJson(),
      toInsertable: (t) => t.toInsertable(),
      getId: (t) => t.id,
      getUpdatedAt: (t) => t.updatedAt,
    );
