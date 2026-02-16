import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';

class TodoRepository {
  TodoRepository(this._db, syncTable)
      : _writer = SyncWriter<AppDatabase>(_db).forTable(syncTable);

  final AppDatabase _db;
  final _uuid = const Uuid();
  final SyncEntityWriter<Todo, AppDatabase> _writer;

  Stream<List<Todo>> watchAll() {
    return (_db.select(_db.todos)
          ..where((t) => t.deletedAt.isNull() & t.deletedAtLocal.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.priority),
            (t) => OrderingTerm(expression: t.title),
          ]))
        .watch();
  }

  Future<List<Todo>> getAll() {
    return (_db.select(_db.todos)
          ..where((t) => t.deletedAt.isNull() & t.deletedAtLocal.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.priority),
            (t) => OrderingTerm(expression: t.title),
          ]))
        .get();
  }

  Future<Todo?> getById(String id) {
    return (_db.select(_db.todos)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Todo> create({
    required String title,
    String? description,
    bool completed = false,
    int priority = 3,
    DateTime? dueDate,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final validPriority = priority.clamp(1, 5);

    final todo = Todo(
      id: id,
      title: title,
      description: description,
      completed: completed,
      priority: validPriority,
      dueDate: dueDate,
      updatedAt: now,
    );

    await _writer.insertAndEnqueue(todo, localTimestamp: now);
    return todo;
  }

  Future<Todo> update(
    Todo todo, {
    String? title,
    String? description,
    bool? completed,
    int? priority,
    DateTime? dueDate,
  }) async {
    final now = DateTime.now().toUtc();
    final validPriority = priority?.clamp(1, 5);

    final updated = todo.copyWith(
      title: title ?? todo.title,
      description: description,
      completed: completed ?? todo.completed,
      priority: validPriority ?? todo.priority,
      dueDate: dueDate,
      updatedAt: now,
    );

    await _writer.replaceAndEnqueueDiff(
      before: todo,
      after: updated,
      baseUpdatedAt: todo.updatedAt,
      localTimestamp: now,
    );

    return updated;
  }

  Future<Todo> toggleCompleted(Todo todo) {
    return update(todo, completed: !todo.completed);
  }

  Future<void> delete(Todo todo) async {
    final now = DateTime.now().toUtc();
    final deleted = todo.copyWith(deletedAtLocal: now);
    await _writer.writeAndEnqueueDelete(
      localWrite: () async {
        await _db.update(_db.todos).replace(deleted.toInsertable());
      },
      id: todo.id,
      baseUpdatedAt: todo.updatedAt,
      localTimestamp: now,
    );
  }

  Future<int> cleanupDeleted() {
    return (_db.delete(_db.todos)
          ..where((t) => t.deletedAt.isNotNull() | t.deletedAtLocal.isNotNull()))
        .go();
  }

  Future<void> upsertFromServer(Todo todo) async {
    await _db.into(_db.todos).insertOnConflictUpdate(todo.toInsertable());
  }

  Future<void> hardDeleteFromServer(String id) async {
    await (_db.delete(_db.todos)..where((t) => t.id.equals(id))).go();
  }

  Future<List<String>> getDeletedIds() async {
    final rows = await (_db.select(_db.todos)
          ..where((t) => t.deletedAt.isNotNull() | t.deletedAtLocal.isNotNull()))
        .get();
    return rows.map((t) => t.id).toList();
  }

  Future<Todo> createWithId(Todo todo) async {
    final now = DateTime.now().toUtc();
    final todoWithTime = todo.copyWith(updatedAt: now);
    await _writer.insertAndEnqueue(todoWithTime, localTimestamp: now);
    return todoWithTime;
  }
}
