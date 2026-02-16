import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:todo_simple_new_backend/models/todo.dart';
import 'package:todo_simple_new_backend/repositories/todo_repository.dart';

import '../../routes/todos/[id].dart' as todos_id;
import '../../routes/todos/index.dart' as todos_index;

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

  test('GET /todos returns empty list', () async {
    when(() => context.request).thenReturn(Request.get(Uri.parse('http://localhost/todos')));
    final response = await todos_index.onRequest(context);
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;
    expect(response.statusCode, HttpStatus.ok);
    expect(body['items'], isEmpty);
    expect(body['nextPageToken'], isNull);
  });

  test('POST /todos creates item', () async {
    when(() => context.request).thenReturn(
      Request.post(
        Uri.parse('http://localhost/todos'),
        body: jsonEncode({'id': 'test-1', 'title': 'New Todo'}),
      ),
    );
    final response = await todos_index.onRequest(context);
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;
    expect(response.statusCode, HttpStatus.created);
    expect(body['id'], 'test-1');
    expect(body['title'], 'New Todo');
  });

  test('GET /todos/:id returns 404 for unknown id', () async {
    when(() => context.request).thenReturn(Request.get(Uri.parse('http://localhost/todos/missing')));
    final response = await todos_id.onRequest(context, 'missing');
    expect(response.statusCode, HttpStatus.notFound);
  });

  test('PUT /todos/:id updates existing todo', () async {
    final now = DateTime.now().toUtc();
    repo.seed([Todo(id: 'test-1', title: 'Before', updatedAt: now)]);
    when(() => context.request).thenReturn(
      Request.put(
        Uri.parse('http://localhost/todos/test-1'),
        body: jsonEncode({'title': 'After'}),
      ),
    );
    final response = await todos_id.onRequest(context, 'test-1');
    final body = jsonDecode(await response.body()) as Map<String, dynamic>;
    expect(response.statusCode, HttpStatus.ok);
    expect(body['title'], 'After');
  });
}
