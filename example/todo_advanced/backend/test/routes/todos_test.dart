import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:todo_advanced_backend/models/todo.dart';
import 'package:todo_advanced_backend/repositories/todo_repository.dart';

import '../../routes/todos/index.dart' as todos_index;
import '../../routes/todos/[id].dart' as todos_id;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  late TodoRepository repository;
  late _MockRequestContext context;

  setUp(() {
    repository = TodoRepository();
    context = _MockRequestContext();
    when(() => context.read<TodoRepository>()).thenReturn(repository);
  });

  tearDown(() {
    repository.clear();
  });

  group('POST /todos', () {
    test('creates a todo with generated id', () async {
      when(() => context.request).thenReturn(
        Request.post(
          Uri.parse('http://localhost/todos'),
          body: jsonEncode({'title': 'Test Todo'}),
        ),
      );

      final response = await todos_index.onRequest(context);

      expect(response.statusCode, HttpStatus.created);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['id'], isNotEmpty);
      expect(body['title'], 'Test Todo');
      expect(body['completed'], false);
      expect(body['priority'], 3);
    });

    test('creates a todo with client-provided id', () async {
      when(() => context.request).thenReturn(
        Request.post(
          Uri.parse('http://localhost/todos'),
          body: jsonEncode({
            'id': 'custom-id',
            'title': 'Test Todo',
          }),
        ),
      );

      final response = await todos_index.onRequest(context);

      expect(response.statusCode, HttpStatus.created);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['id'], 'custom-id');
    });
  });

  group('GET /todos', () {
    test('returns empty list when no todos', () async {
      when(() => context.request).thenReturn(
        Request.get(Uri.parse('http://localhost/todos')),
      );

      final response = await todos_index.onRequest(context);

      expect(response.statusCode, HttpStatus.ok);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['items'], isEmpty);
    });

    test('returns list of todos', () async {
      repository.create(Todo(
        id: 'todo-1',
        title: 'First',
        updatedAt: DateTime.now().toUtc(),
      ));
      repository.create(Todo(
        id: 'todo-2',
        title: 'Second',
        updatedAt: DateTime.now().toUtc(),
      ));

      when(() => context.request).thenReturn(
        Request.get(Uri.parse('http://localhost/todos')),
      );

      final response = await todos_index.onRequest(context);

      expect(response.statusCode, HttpStatus.ok);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['items'], hasLength(2));
    });
  });

  group('GET /todos/:id', () {
    test('returns todo by id', () async {
      final now = DateTime.now().toUtc();
      repository.create(Todo(
        id: 'todo-1',
        title: 'Test',
        updatedAt: now,
      ));

      when(() => context.request).thenReturn(
        Request.get(Uri.parse('http://localhost/todos/todo-1')),
      );

      final response = await todos_id.onRequest(context, 'todo-1');

      expect(response.statusCode, HttpStatus.ok);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['id'], 'todo-1');
      expect(body['title'], 'Test');
    });

    test('returns 404 for non-existent todo', () async {
      when(() => context.request).thenReturn(
        Request.get(Uri.parse('http://localhost/todos/non-existent')),
      );

      final response = await todos_id.onRequest(context, 'non-existent');

      expect(response.statusCode, HttpStatus.notFound);
    });
  });

  group('PUT /todos/:id', () {
    test('updates todo without conflict check', () async {
      final now = DateTime.now().toUtc();
      repository.create(Todo(
        id: 'todo-1',
        title: 'Original',
        updatedAt: now,
      ));

      when(() => context.request).thenReturn(
        Request.put(
          Uri.parse('http://localhost/todos/todo-1'),
          body: jsonEncode({'title': 'Updated'}),
          headers: {},
        ),
      );

      final response = await todos_id.onRequest(context, 'todo-1');

      expect(response.statusCode, HttpStatus.ok);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['title'], 'Updated');
    });

    test('returns 409 conflict when base_updated_at mismatch', () async {
      final now = DateTime.now().toUtc();
      repository.create(Todo(
        id: 'todo-1',
        title: 'Original',
        updatedAt: now,
      ));

      final oldTimestamp = now.subtract(const Duration(hours: 1));

      when(() => context.request).thenReturn(
        Request.put(
          Uri.parse('http://localhost/todos/todo-1'),
          body: jsonEncode({
            'title': 'Updated',
            '_base_updated_at': oldTimestamp.toIso8601String(),
          }),
          headers: {},
        ),
      );

      final response = await todos_id.onRequest(context, 'todo-1');

      expect(response.statusCode, HttpStatus.conflict);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['error'], 'conflict');
      expect(body['current'], isNotNull);
      expect(body['current']['title'], 'Original');
    });

    test('updates with X-Force-Update header ignoring conflict', () async {
      final now = DateTime.now().toUtc();
      repository.create(Todo(
        id: 'todo-1',
        title: 'Original',
        updatedAt: now,
      ));

      final oldTimestamp = now.subtract(const Duration(hours: 1));

      when(() => context.request).thenReturn(
        Request.put(
          Uri.parse('http://localhost/todos/todo-1'),
          body: jsonEncode({
            'title': 'Force Updated',
            '_base_updated_at': oldTimestamp.toIso8601String(),
          }),
          headers: {'x-force-update': 'true'},
        ),
      );

      final response = await todos_id.onRequest(context, 'todo-1');

      expect(response.statusCode, HttpStatus.ok);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['title'], 'Force Updated');
    });

    test('respects idempotency key', () async {
      final now = DateTime.now().toUtc();
      repository.create(Todo(
        id: 'todo-1',
        title: 'Original',
        updatedAt: now,
      ));

      when(() => context.request).thenReturn(
        Request.put(
          Uri.parse('http://localhost/todos/todo-1'),
          body: jsonEncode({'title': 'First Update'}),
          headers: {'x-idempotency-key': 'idem-key-1'},
        ),
      );

      final response1 = await todos_id.onRequest(context, 'todo-1');
      expect(response1.statusCode, HttpStatus.ok);

      when(() => context.request).thenReturn(
        Request.put(
          Uri.parse('http://localhost/todos/todo-1'),
          body: jsonEncode({'title': 'Second Update'}),
          headers: {'x-idempotency-key': 'idem-key-1'},
        ),
      );

      final response2 = await todos_id.onRequest(context, 'todo-1');
      expect(response2.statusCode, HttpStatus.ok);

      final body = jsonDecode(await response2.body()) as Map<String, dynamic>;
      expect(body['title'], 'First Update');
    });
  });

  group('DELETE /todos/:id', () {
    test('soft deletes todo', () async {
      final now = DateTime.now().toUtc();
      repository.create(Todo(
        id: 'todo-1',
        title: 'Test',
        updatedAt: now,
      ));

      when(() => context.request).thenReturn(
        Request.delete(
          Uri.parse('http://localhost/todos/todo-1'),
          headers: {},
        ),
      );

      final response = await todos_id.onRequest(context, 'todo-1');

      expect(response.statusCode, HttpStatus.noContent);

      final todo = repository.get('todo-1');
      expect(todo!.deletedAt, isNotNull);
    });

    test('returns 404 for non-existent todo', () async {
      when(() => context.request).thenReturn(
        Request.delete(
          Uri.parse('http://localhost/todos/non-existent'),
          headers: {},
        ),
      );

      final response = await todos_id.onRequest(context, 'non-existent');

      expect(response.statusCode, HttpStatus.notFound);
    });

    test('returns 409 conflict with X-Base-Updated-At mismatch', () async {
      final now = DateTime.now().toUtc();
      repository.create(Todo(
        id: 'todo-1',
        title: 'Test',
        updatedAt: now,
      ));

      final oldTimestamp = now.subtract(const Duration(hours: 1));

      when(() => context.request).thenReturn(
        Request.delete(
          Uri.parse('http://localhost/todos/todo-1'),
          headers: {'x-base-updated-at': oldTimestamp.toIso8601String()},
        ),
      );

      final response = await todos_id.onRequest(context, 'todo-1');

      expect(response.statusCode, HttpStatus.conflict);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['error'], 'conflict');
      expect(body['current'], isNotNull);
    });

    test('deletes with X-Force-Delete header ignoring conflict', () async {
      final now = DateTime.now().toUtc();
      repository.create(Todo(
        id: 'todo-1',
        title: 'Test',
        updatedAt: now,
      ));

      final oldTimestamp = now.subtract(const Duration(hours: 1));

      when(() => context.request).thenReturn(
        Request.delete(
          Uri.parse('http://localhost/todos/todo-1'),
          headers: {
            'x-base-updated-at': oldTimestamp.toIso8601String(),
            'x-force-delete': 'true',
          },
        ),
      );

      final response = await todos_id.onRequest(context, 'todo-1');

      expect(response.statusCode, HttpStatus.noContent);
    });
  });
}
