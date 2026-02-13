@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_simple_frontend/database/database.dart';
import 'package:todo_simple_frontend/models/todo.dart';
import 'package:todo_simple_frontend/repositories/todo_repository.dart';
import 'package:todo_simple_frontend/sync/todo_sync.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late TodoRepository repository;

  setUp(() {
    db = createTestDatabase();
    repository = TodoRepository(db, todoSyncTable(db));
  });

  tearDown(() async {
    await db.close();
  });

  group('TodoRepository', () {
    final now = DateTime.utc(2025, 1, 15, 10, 30);

    Todo createTestTodo({
      String? id,
      String title = 'Test Todo',
      String? description,
      bool completed = false,
      int priority = 3,
      DateTime? dueDate,
      DateTime? updatedAt,
    }) {
      return Todo(
        id: id ?? 'todo-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        description: description,
        completed: completed,
        priority: priority,
        dueDate: dueDate,
        updatedAt: updatedAt ?? now,
      );
    }

    group('create', () {
      test('creates todo with generated id', () async {
        final todo = await repository.create(title: 'New Todo');

        expect(todo.id, isNotEmpty);
        expect(todo.title, 'New Todo');
        expect(todo.completed, false);
        expect(todo.priority, 3);
      });

      test('creates todo with all fields', () async {
        final dueDate = DateTime.utc(2025, 1, 20);

        final todo = await repository.create(
          title: 'Full Todo',
          description: 'A description',
          completed: true,
          priority: 1,
          dueDate: dueDate,
        );

        expect(todo.title, 'Full Todo');
        expect(todo.description, 'A description');
        expect(todo.completed, true);
        expect(todo.priority, 1);
        expect(todo.dueDate, dueDate);
      });

      test('adds todo to outbox', () async {
        await repository.create(title: 'Test');

        final outbox = await db.takeOutbox();
        expect(outbox.length, 1);
        expect(outbox.first.kind, 'todos');
      });

      test('creates multiple todos', () async {
        await repository.create(title: 'First');
        await repository.create(title: 'Second');
        await repository.create(title: 'Third');

        final todos = await repository.getAll();
        expect(todos.length, 3);
      });
    });

    group('createWithId', () {
      test('creates todo with explicit id', () async {
        final todo = createTestTodo(id: 'explicit-id', title: 'Test');
        await repository.createWithId(todo);

        final result = await repository.getById('explicit-id');
        expect(result, isNotNull);
        expect(result!.title, 'Test');
      });
    });

    group('getAll', () {
      test('returns empty list when no todos', () async {
        final todos = await repository.getAll();
        expect(todos, isEmpty);
      });

      test('excludes soft-deleted todos', () async {
        await repository.create(title: 'Active');
        final toDelete = await repository.create(title: 'Deleted');
        await repository.delete(toDelete);

        final todos = await repository.getAll();
        expect(todos.length, 1);
        expect(todos.first.title, 'Active');
      });

      test('returns todos ordered by priority then title', () async {
        await repository.create(title: 'C Todo', priority: 2);
        await repository.create(title: 'A Todo', priority: 1);
        await repository.create(title: 'B Todo', priority: 1);

        final todos = await repository.getAll();
        expect(todos.length, 3);
        expect(todos[0].title, 'A Todo');
        expect(todos[1].title, 'B Todo');
        expect(todos[2].title, 'C Todo');
      });
    });

    group('getById', () {
      test('returns todo by id', () async {
        final created = await repository.create(title: 'Test');

        final todo = await repository.getById(created.id);
        expect(todo, isNotNull);
        expect(todo!.title, 'Test');
      });

      test('returns null for non-existent id', () async {
        final todo = await repository.getById('non-existent');
        expect(todo, isNull);
      });
    });

    group('update', () {
      test('updates todo title', () async {
        final created = await repository.create(title: 'Original');

        final updated = await repository.update(created, title: 'Updated');

        expect(updated.title, 'Updated');
        final fromDb = await repository.getById(created.id);
        expect(fromDb!.title, 'Updated');
      });

      test('updates todo completed status', () async {
        final created = await repository.create(title: 'Test');

        final updated = await repository.update(created, completed: true);

        expect(updated.completed, true);
      });

      test('updates todo priority', () async {
        final created = await repository.create(title: 'Test', priority: 3);

        final updated = await repository.update(created, priority: 1);

        expect(updated.priority, 1);
      });

      test('adds update to outbox', () async {
        final created = await repository.create(title: 'Test');
        final initialOutbox = await db.takeOutbox();
        await db.ackOutbox(initialOutbox.map((o) => o.opId));

        await repository.update(created, title: 'Updated');

        final outbox = await db.takeOutbox();
        expect(outbox.length, 1);
      });
    });

    group('toggleCompleted', () {
      test('toggles from incomplete to complete', () async {
        final created = await repository.create(title: 'Test');

        final toggled = await repository.toggleCompleted(created);

        expect(toggled.completed, true);
      });

      test('toggles from complete to incomplete', () async {
        final created = await repository.create(title: 'Test', completed: true);

        final toggled = await repository.toggleCompleted(created);

        expect(toggled.completed, false);
      });
    });

    group('delete', () {
      test('soft deletes todo', () async {
        final created = await repository.create(title: 'Test');

        await repository.delete(created);

        final todos = await repository.getAll();
        expect(todos, isEmpty);
      });

      test('deleted todo still exists in db', () async {
        final created = await repository.create(title: 'Test');

        await repository.delete(created);

        final deletedIds = await repository.getDeletedIds();
        expect(deletedIds, contains(created.id));
      });

      test('adds delete to outbox', () async {
        final created = await repository.create(title: 'Test');
        final initialOutbox = await db.takeOutbox();
        await db.ackOutbox(initialOutbox.map((o) => o.opId));

        await repository.delete(created);

        final outbox = await db.takeOutbox();
        expect(outbox.length, 1);
      });
    });

    group('watchAll', () {
      test('emits todos when created', () async {
        final stream = repository.watchAll();

        final expectation = expectLater(
          stream.map((todos) => todos.length),
          emitsInOrder([0, 1, 2]),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));
        await repository.create(title: 'First');
        await repository.create(title: 'Second');

        await expectation;
      });

      test('emits updated list when todo is deleted', () async {
        final created = await repository.create(title: 'Test');

        final stream = repository.watchAll();

        final expectation = expectLater(
          stream.map((todos) => todos.length),
          emitsInOrder([1, 0]),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));
        await repository.delete(created);

        await expectation;
      });
    });

    group('upsertFromServer', () {
      test('inserts new todo from server', () async {
        final serverTodo = createTestTodo(
          id: 'server-todo-1',
          title: 'From Server',
        );

        await repository.upsertFromServer(serverTodo);

        final todo = await repository.getById('server-todo-1');
        expect(todo, isNotNull);
        expect(todo!.title, 'From Server');

        final outbox = await db.takeOutbox();
        expect(outbox, isEmpty);
      });

      test('updates existing todo from server', () async {
        final created = await repository.create(title: 'Local');
        final initialOutbox = await db.takeOutbox();
        await db.ackOutbox(initialOutbox.map((o) => o.opId));

        final serverTodo = created.copyWith(
          title: 'Updated from Server',
          priority: 1,
        );

        await repository.upsertFromServer(serverTodo);

        final todo = await repository.getById(created.id);
        expect(todo!.title, 'Updated from Server');
        expect(todo.priority, 1);

        final outbox = await db.takeOutbox();
        expect(outbox, isEmpty);
      });
    });

    group('hardDeleteFromServer', () {
      test('permanently removes todo', () async {
        final created = await repository.create(title: 'Test');

        await repository.hardDeleteFromServer(created.id);

        final todo = await repository.getById(created.id);
        expect(todo, isNull);
      });

      test('removes soft-deleted todo', () async {
        final created = await repository.create(title: 'Test');
        await repository.delete(created);

        await repository.hardDeleteFromServer(created.id);

        final deleted = await repository.getDeletedIds();
        expect(deleted, isEmpty);
      });
    });

    group('getDeletedIds', () {
      test('returns ids of soft-deleted todos', () async {
        final todo1 = await repository.create(title: 'First');
        final todo2 = await repository.create(title: 'Second');

        await repository.delete(todo1);
        await repository.delete(todo2);

        final deletedIds = await repository.getDeletedIds();
        expect(deletedIds, containsAll([todo1.id, todo2.id]));
      });

      test('returns empty list when no deleted todos', () async {
        await repository.create(title: 'Test');

        final deletedIds = await repository.getDeletedIds();
        expect(deletedIds, isEmpty);
      });
    });

    group('cleanupDeleted', () {
      test('removes soft-deleted todos', () async {
        final todo1 = await repository.create(title: 'First');
        await repository.create(title: 'Second');

        await repository.delete(todo1);

        final count = await repository.cleanupDeleted();
        expect(count, 1);

        final deletedIds = await repository.getDeletedIds();
        expect(deletedIds, isEmpty);
      });
    });
  });
}
