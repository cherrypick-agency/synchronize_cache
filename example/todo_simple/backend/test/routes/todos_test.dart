import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:todo_simple_backend/models/todo.dart';
import 'package:todo_simple_backend/repositories/todo_repository.dart';

import '../../routes/todos/index.dart' as todos_index;
import '../../routes/todos/[id].dart' as todos_id;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  late TodoRepository repo;
  late RequestContext context;

  setUp(() {
    repo = TodoRepository();
    context = _MockRequestContext();
    when(() => context.read<TodoRepository>()).thenReturn(repo);
  });

  tearDown(() {
    repo.clear();
  });

  group('GET /todos', () {
    test('returns empty list when no todos', () async {
      when(() => context.request).thenReturn(
        Request.get(Uri.parse('http://localhost/todos')),
      );

      final response = await todos_index.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['items'], isEmpty);
      expect(body['nextPageToken'], isNull);
    });

    test('returns all todos', () async {
      // Seed some data
      final now = DateTime.now().toUtc();
      repo.seed([
        Todo(id: '1', title: 'Todo 1', updatedAt: now),
        Todo(id: '2', title: 'Todo 2', updatedAt: now),
      ]);

      when(() => context.request).thenReturn(
        Request.get(Uri.parse('http://localhost/todos')),
      );

      final response = await todos_index.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final items = body['items'] as List;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(items.length, equals(2));
    });

    test('filters by updatedSince', () async {
      final old = DateTime.utc(2025, 1, 1);
      final recent = DateTime.utc(2025, 1, 15);

      repo.seed([
        Todo(id: '1', title: 'Old Todo', updatedAt: old),
        Todo(id: '2', title: 'Recent Todo', updatedAt: recent),
      ]);

      when(() => context.request).thenReturn(
        Request.get(
          Uri.parse('http://localhost/todos?updatedSince=2025-01-10T00:00:00Z'),
        ),
      );

      final response = await todos_index.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      final items = body['items'] as List;

      expect(items.length, equals(1));
      expect(items[0]['id'], equals('2'));
    });

    test('paginates correctly', () async {
      final now = DateTime.now().toUtc();
      repo.seed([
        for (var i = 1; i <= 5; i++)
          Todo(id: '$i', title: 'Todo $i', updatedAt: now),
      ]);

      // First page
      when(() => context.request).thenReturn(
        Request.get(Uri.parse('http://localhost/todos?limit=2')),
      );

      var response = await todos_index.onRequest(context);
      var body = jsonDecode(await response.body()) as Map<String, dynamic>;
      var items = body['items'] as List;

      expect(items.length, equals(2));
      expect(body['nextPageToken'], equals('2'));

      // Second page
      when(() => context.request).thenReturn(
        Request.get(Uri.parse('http://localhost/todos?limit=2&pageToken=2')),
      );

      response = await todos_index.onRequest(context);
      body = jsonDecode(await response.body()) as Map<String, dynamic>;
      items = body['items'] as List;

      expect(items.length, equals(2));
      expect(body['nextPageToken'], equals('4'));
    });
  });

  group('POST /todos', () {
    test('creates a new todo', () async {
      when(() => context.request).thenReturn(
        Request.post(
          Uri.parse('http://localhost/todos'),
          body: jsonEncode({'id': 'test-1', 'title': 'New Todo'}),
        ),
      );

      final response = await todos_index.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.created));
      expect(body['id'], equals('test-1'));
      expect(body['title'], equals('New Todo'));
      expect(body['completed'], isFalse);
      expect(body['priority'], equals(3));
      expect(body['updated_at'], isNotNull);
    });

    test('creates todo with all fields', () async {
      when(() => context.request).thenReturn(
        Request.post(
          Uri.parse('http://localhost/todos'),
          body: jsonEncode({
            'id': 'test-2',
            'title': 'Full Todo',
            'description': 'Description here',
            'completed': true,
            'priority': 1,
            'due_date': '2025-12-31T23:59:59Z',
          }),
        ),
      );

      final response = await todos_index.onRequest(context);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.created));
      expect(body['title'], equals('Full Todo'));
      expect(body['description'], equals('Description here'));
      expect(body['completed'], isTrue);
      expect(body['priority'], equals(1));
      expect(body['due_date'], contains('2025-12-31'));
    });
  });

  group('GET /todos/:id', () {
    test('returns 404 when not found', () async {
      when(() => context.request).thenReturn(
        Request.get(Uri.parse('http://localhost/todos/nonexistent')),
      );

      final response = await todos_id.onRequest(context, 'nonexistent');

      expect(response.statusCode, equals(HttpStatus.notFound));
    });

    test('returns todo when found', () async {
      final now = DateTime.now().toUtc();
      repo.seed([Todo(id: 'test-1', title: 'Test', updatedAt: now)]);

      when(() => context.request).thenReturn(
        Request.get(Uri.parse('http://localhost/todos/test-1')),
      );

      final response = await todos_id.onRequest(context, 'test-1');
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['id'], equals('test-1'));
      expect(body['title'], equals('Test'));
    });
  });

  group('PUT /todos/:id', () {
    test('creates todo when not exists (upsert)', () async {
      when(() => context.request).thenReturn(
        Request.put(
          Uri.parse('http://localhost/todos/new-todo'),
          body: jsonEncode({'title': 'Upserted Todo'}),
        ),
      );

      final response = await todos_id.onRequest(context, 'new-todo');
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.created));
      expect(body['id'], equals('new-todo'));
      expect(body['title'], equals('Upserted Todo'));
    });

    test('updates existing todo', () async {
      final now = DateTime.now().toUtc();
      repo.seed([Todo(id: 'test-1', title: 'Original', updatedAt: now)]);

      when(() => context.request).thenReturn(
        Request.put(
          Uri.parse('http://localhost/todos/test-1'),
          body: jsonEncode({'title': 'Updated'}),
        ),
      );

      final response = await todos_id.onRequest(context, 'test-1');
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body['title'], equals('Updated'));
    });

    test('ignores _baseUpdatedAt in simplified flow', () async {
      final now = DateTime.now().toUtc();
      repo.seed([Todo(id: 'test-1', title: 'Original', updatedAt: now)]);

      when(() => context.request).thenReturn(
        Request.put(
          Uri.parse('http://localhost/todos/test-1'),
          body: jsonEncode({
            'title': 'Updated',
            '_baseUpdatedAt': '2020-01-01T00:00:00Z',
          }),
        ),
      );

      final response = await todos_id.onRequest(context, 'test-1');

      // Should succeed even with old baseUpdatedAt
      expect(response.statusCode, equals(HttpStatus.ok));
    });
  });

  group('DELETE /todos/:id', () {
    test('returns 404 when not found', () async {
      when(() => context.request).thenReturn(
        Request.delete(Uri.parse('http://localhost/todos/nonexistent')),
      );

      final response = await todos_id.onRequest(context, 'nonexistent');

      expect(response.statusCode, equals(HttpStatus.notFound));
    });

    test('deletes existing todo', () async {
      final now = DateTime.now().toUtc();
      repo.seed([Todo(id: 'test-1', title: 'To Delete', updatedAt: now)]);

      when(() => context.request).thenReturn(
        Request.delete(Uri.parse('http://localhost/todos/test-1')),
      );

      final response = await todos_id.onRequest(context, 'test-1');

      expect(response.statusCode, equals(HttpStatus.noContent));
      expect(repo.getById('test-1'), isNull);
    });
  });

  group('TodoRepository', () {
    test('list sorts by updatedAt and id', () {
      final t1 = DateTime.utc(2025, 1, 1);
      final t2 = DateTime.utc(2025, 1, 2);

      repo.seed([
        Todo(id: 'b', title: 'B', updatedAt: t1),
        Todo(id: 'a', title: 'A', updatedAt: t1),
        Todo(id: 'c', title: 'C', updatedAt: t2),
      ]);

      final result = repo.list();
      final ids = result.items.map((t) => t.id).toList();

      expect(ids, equals(['a', 'b', 'c']));
    });

    test('list excludes deleted when includeDeleted is false', () {
      final now = DateTime.now().toUtc();

      repo.seed([
        Todo(id: '1', title: 'Active', updatedAt: now),
        Todo(id: '2', title: 'Deleted', updatedAt: now, deletedAt: now),
      ]);

      final result = repo.list(includeDeleted: false);

      expect(result.items.length, equals(1));
      expect(result.items[0].id, equals('1'));
    });
  });
}
