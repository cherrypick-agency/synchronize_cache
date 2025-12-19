import 'package:flutter_test/flutter_test.dart';
import 'package:todo_advanced_frontend/database/database.dart';
import 'package:todo_advanced_frontend/models/todo.dart';
import 'package:todo_advanced_frontend/repositories/todo_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late TodoRepository repo;

  setUp(() async {
    db = createTestDatabase();
    repo = TodoRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TodoRepository', () {
    group('create', () {
      test('creates todo with generated id', () async {
        final todo = await repo.create(title: 'Test Todo');

        expect(todo.id, isNotEmpty);
        expect(todo.title, 'Test Todo');
        expect(todo.completed, false);
        expect(todo.priority, 3);
      });

      test('creates todo with all fields', () async {
        final dueDate = DateTime.utc(2025, 1, 20);

        final todo = await repo.create(
          title: 'Test Todo',
          description: 'Test description',
          completed: true,
          priority: 1,
          dueDate: dueDate,
        );

        expect(todo.title, 'Test Todo');
        expect(todo.description, 'Test description');
        expect(todo.completed, true);
        expect(todo.priority, 1);
        expect(todo.dueDate, dueDate);
      });

      test('enqueues sync operation', () async {
        await repo.create(title: 'Test Todo');

        final outbox = await db.takeOutbox();
        expect(outbox, hasLength(1));
        expect(outbox.first.kind, 'todos');
      });
    });

    group('getAll', () {
      test('returns empty list when no todos', () async {
        final todos = await repo.getAll();
        expect(todos, isEmpty);
      });

      test('returns all non-deleted todos', () async {
        await repo.create(title: 'Todo 1');
        await repo.create(title: 'Todo 2');

        final todos = await repo.getAll();
        expect(todos, hasLength(2));
      });

      test('excludes soft-deleted todos', () async {
        final todo = await repo.create(title: 'Test Todo');
        await repo.delete(todo);

        final todos = await repo.getAll();
        expect(todos, isEmpty);
      });
    });

    group('getById', () {
      test('returns todo when exists', () async {
        final created = await repo.create(title: 'Test Todo');

        final found = await repo.getById(created.id);
        expect(found, isNotNull);
        expect(found!.id, created.id);
      });

      test('returns null when not exists', () async {
        final found = await repo.getById('non-existent');
        expect(found, isNull);
      });
    });

    group('watchAll', () {
      test('emits updates when todos change', () async {
        // Clear initial outbox
        final initialOutbox = await db.takeOutbox();
        await db.ackOutbox(initialOutbox.map((o) => o.opId));

        // Wait for stream to be ready
        await Future<void>.delayed(const Duration(milliseconds: 10));

        final stream = repo.watchAll();
        final results = <List<Todo>>[];

        final subscription = stream.listen(results.add);

        // Create a todo
        await repo.create(title: 'Test Todo');

        // Wait for stream update
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();

        expect(results.length, greaterThanOrEqualTo(1));
        expect(results.last, hasLength(1));
      });
    });

    group('update', () {
      test('updates todo fields', () async {
        final todo = await repo.create(title: 'Original');

        final updated = await repo.update(
          todo,
          title: 'Updated',
          completed: true,
        );

        expect(updated.title, 'Updated');
        expect(updated.completed, true);
      });

      test('tracks changed fields', () async {
        final todo = await repo.create(title: 'Original');

        // Clear create operation
        final initialOutbox = await db.takeOutbox();
        await db.ackOutbox(initialOutbox.map((o) => o.opId));

        await repo.update(todo, title: 'Updated');

        final outbox = await db.takeOutbox();
        expect(outbox, hasLength(1));
      });
    });

    group('toggleCompleted', () {
      test('toggles from false to true', () async {
        final todo = await repo.create(title: 'Test', completed: false);

        final toggled = await repo.toggleCompleted(todo);
        expect(toggled.completed, true);
      });

      test('toggles from true to false', () async {
        final todo = await repo.create(title: 'Test', completed: true);

        final toggled = await repo.toggleCompleted(todo);
        expect(toggled.completed, false);
      });
    });

    group('delete', () {
      test('soft deletes todo locally', () async {
        final todo = await repo.create(title: 'Test Todo');

        await repo.delete(todo);

        final found = await repo.getById(todo.id);
        expect(found!.deletedAtLocal, isNotNull);
      });

      test('todo not visible in getAll after delete', () async {
        final todo = await repo.create(title: 'Test Todo');

        await repo.delete(todo);

        final todos = await repo.getAll();
        expect(todos, isEmpty);
      });

      test('enqueues delete operation', () async {
        final todo = await repo.create(title: 'Test Todo');

        // Clear create operation
        final initialOutbox = await db.takeOutbox();
        await db.ackOutbox(initialOutbox.map((o) => o.opId));

        await repo.delete(todo);

        final outbox = await db.takeOutbox();
        expect(outbox, hasLength(1));
      });
    });

    group('upsertFromServer', () {
      test('inserts new todo', () async {
        final now = DateTime.now().toUtc();
        final todo = Todo(
          id: 'server-id',
          title: 'Server Todo',
          updatedAt: now,
        );

        await repo.upsertFromServer(todo);

        final found = await repo.getById('server-id');
        expect(found, isNotNull);
        expect(found!.title, 'Server Todo');
      });

      test('updates existing todo', () async {
        final now = DateTime.now().toUtc();
        final todo = await repo.create(title: 'Original');

        final serverTodo = Todo(
          id: todo.id,
          title: 'Updated from Server',
          updatedAt: now,
        );

        await repo.upsertFromServer(serverTodo);

        final found = await repo.getById(todo.id);
        expect(found!.title, 'Updated from Server');
      });

      test('does not enqueue sync operation', () async {
        final now = DateTime.now().toUtc();

        // Clear any existing operations
        final initialOutbox = await db.takeOutbox();
        await db.ackOutbox(initialOutbox.map((o) => o.opId));

        final todo = Todo(
          id: 'server-id',
          title: 'Server Todo',
          updatedAt: now,
        );

        await repo.upsertFromServer(todo);

        final outbox = await db.takeOutbox();
        expect(outbox, isEmpty);
      });
    });

    group('hardDeleteFromServer', () {
      test('removes todo completely', () async {
        final todo = await repo.create(title: 'Test Todo');

        await repo.hardDeleteFromServer(todo.id);

        final found = await repo.getById(todo.id);
        expect(found, isNull);
      });
    });

    group('getDeletedIds', () {
      test('returns ids of deleted todos', () async {
        final todo1 = await repo.create(title: 'Todo 1');
        await repo.create(title: 'Todo 2');

        await repo.delete(todo1);

        final deletedIds = await repo.getDeletedIds();
        expect(deletedIds, contains(todo1.id));
        expect(deletedIds, hasLength(1));
      });
    });

    group('cleanupDeleted', () {
      test('removes all soft-deleted todos', () async {
        final todo1 = await repo.create(title: 'Todo 1');
        final todo2 = await repo.create(title: 'Todo 2');

        await repo.delete(todo1);
        await repo.delete(todo2);

        final deleted = await repo.cleanupDeleted();
        expect(deleted, 2);

        final found1 = await repo.getById(todo1.id);
        final found2 = await repo.getById(todo2.id);
        expect(found1, isNull);
        expect(found2, isNull);
      });
    });
  });
}
