import 'package:drift/drift.dart';
import 'package:offline_first_sync_drift/offline_first_sync_drift.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../models/todo.dart';
import '../sync/todo_sync.dart';

/// Repository for managing todos with offline-first sync support.
///
/// All CRUD operations:
/// 1. Update local database immediately
/// 2. Enqueue operation for sync to server
class TodoRepository {
  TodoRepository(this._db, this._syncTable)
      : _writer = SyncWriter<AppDatabase>(_db).forTable(_syncTable);

  final AppDatabase _db;
  final _uuid = const Uuid();
  final SyncableTable<Todo> _syncTable;
  final SyncEntityWriter<Todo, AppDatabase> _writer;

  /// Watches all non-deleted todos, ordered by priority and title.
  Stream<List<Todo>> watchAll() {
    return (_db.select(_db.todos)
          ..where((t) => t.deletedAt.isNull() & t.deletedAtLocal.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.priority),
            (t) => OrderingTerm(expression: t.title),
          ]))
        .watch();
  }

  /// Gets all non-deleted todos.
  Future<List<Todo>> getAll() {
    return (_db.select(_db.todos)
          ..where((t) => t.deletedAt.isNull() & t.deletedAtLocal.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.priority),
            (t) => OrderingTerm(expression: t.title),
          ]))
        .get();
  }

  /// Gets a todo by ID.
  Future<Todo?> getById(String id) {
    return (_db.select(_db.todos)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Creates a new todo.
  ///
  /// Generates a UUID for the id and enqueues for sync.
  Future<Todo> create({
    required String title,
    String? description,
    bool completed = false,
    int priority = 3,
    DateTime? dueDate,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();

    // Validate priority range (1-5)
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

  /// Updates an existing todo.
  ///
  /// Tracks changed fields for efficient merge on conflict.
  Future<Todo> update(
    Todo todo, {
    String? title,
    String? description,
    bool? completed,
    int? priority,
    DateTime? dueDate,
  }) async {
    final now = DateTime.now().toUtc();
    final changedFields = <String>{};

    // Track which fields changed
    if (title != null && title != todo.title) changedFields.add('title');
    if (description != todo.description) changedFields.add('description');
    if (completed != null && completed != todo.completed) {
      changedFields.add('completed');
    }
    // Validate priority range (1-5)
    final validPriority = priority?.clamp(1, 5);
    if (validPriority != null && validPriority != todo.priority) {
      changedFields.add('priority');
    }
    if (dueDate != todo.dueDate) changedFields.add('dueDate');

    final updated = todo.copyWith(
      title: title ?? todo.title,
      description: description,
      completed: completed ?? todo.completed,
      priority: validPriority ?? todo.priority,
      dueDate: dueDate,
      updatedAt: now,
    );

    // Update local database
    await _writer.replaceAndEnqueue(
      updated,
      baseUpdatedAt: todo.updatedAt,
      changedFields: changedFields.isNotEmpty ? changedFields : null,
      localTimestamp: now,
    );

    return updated;
  }

  /// Toggles the completed status of a todo.
  Future<Todo> toggleCompleted(Todo todo) {
    return update(todo, completed: !todo.completed);
  }

  /// Deletes a todo (soft delete locally, enqueue for sync).
  Future<void> delete(Todo todo) async {
    final now = DateTime.now().toUtc();

    // Soft delete locally
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

  /// Hard deletes all soft-deleted todos (cleanup after sync).
  Future<int> cleanupDeleted() async {
    return (_db.delete(_db.todos)
          ..where(
            (t) => t.deletedAt.isNotNull() | t.deletedAtLocal.isNotNull(),
          ))
        .go();
  }

  /// Upserts a todo from server (no outbox enqueue).
  ///
  /// Used during sync pull to update local database.
  Future<void> upsertFromServer(Todo todo) async {
    await _db.into(_db.todos).insertOnConflictUpdate(todo.toInsertable());
  }

  /// Hard deletes a todo from server (no outbox enqueue).
  ///
  /// Used when server confirms a delete operation.
  Future<void> hardDeleteFromServer(String id) async {
    await (_db.delete(_db.todos)..where((t) => t.id.equals(id))).go();
  }

  /// Gets IDs of all soft-deleted todos.
  Future<List<String>> getDeletedIds() async {
    final rows = await (_db.select(_db.todos)
          ..where(
            (t) => t.deletedAt.isNotNull() | t.deletedAtLocal.isNotNull(),
          ))
        .get();
    return rows.map((t) => t.id).toList();
  }

  /// Creates a todo with explicit ID (for testing).
  Future<Todo> createWithId(Todo todo) async {
    final now = DateTime.now().toUtc();
    final todoWithTime = todo.copyWith(updatedAt: now);

    await _writer.insertAndEnqueue(todoWithTime, localTimestamp: now);

    return todoWithTime;
  }
}
