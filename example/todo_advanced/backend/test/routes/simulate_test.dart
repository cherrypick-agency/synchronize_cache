import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:todo_advanced_backend/models/todo.dart';
import 'package:todo_advanced_backend/repositories/todo_repository.dart';
import 'package:todo_advanced_backend/services/simulation_service.dart';

import '../../routes/simulate/complete.dart' as simulate_complete;
import '../../routes/simulate/prioritize.dart' as simulate_prioritize;
import '../../routes/simulate/reminder.dart' as simulate_reminder;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  late TodoRepository repository;
  late SimulationService simulationService;
  late _MockRequestContext context;

  setUp(() {
    repository = TodoRepository();
    simulationService = SimulationService(repository);
    context = _MockRequestContext();
    when(() => context.read<SimulationService>()).thenReturn(simulationService);
  });

  tearDown(() {
    repository.clear();
  });

  group('POST /simulate/reminder', () {
    test('adds reminder to existing todo', () async {
      final now = DateTime.now().toUtc();
      repository.create(Todo(
        id: 'todo-1',
        title: 'Original',
        updatedAt: now,
      ));

      when(() => context.request).thenReturn(
        Request.post(
          Uri.parse('http://localhost/simulate/reminder'),
          body: jsonEncode({
            'id': 'todo-1',
            'text': 'Remember to check this!',
          }),
        ),
      );

      final response = await simulate_reminder.onRequest(context);

      expect(response.statusCode, HttpStatus.ok);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['message'], 'Reminder added');
      expect(body['todo']['description'], contains('Remember to check this!'));
    });

    test('returns 404 for non-existent todo', () async {
      when(() => context.request).thenReturn(
        Request.post(
          Uri.parse('http://localhost/simulate/reminder'),
          body: jsonEncode({
            'id': 'non-existent',
            'text': 'Some reminder',
          }),
        ),
      );

      final response = await simulate_reminder.onRequest(context);

      expect(response.statusCode, HttpStatus.notFound);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['error'], 'Todo not found');
    });

    test('returns 400 when missing required fields', () async {
      when(() => context.request).thenReturn(
        Request.post(
          Uri.parse('http://localhost/simulate/reminder'),
          body: jsonEncode({'id': 'todo-1'}),
        ),
      );

      final response = await simulate_reminder.onRequest(context);

      expect(response.statusCode, HttpStatus.badRequest);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['error'], contains('Missing required fields'));
    });

    test('returns 405 for non-POST methods', () async {
      when(() => context.request).thenReturn(
        Request.get(Uri.parse('http://localhost/simulate/reminder')),
      );

      final response = await simulate_reminder.onRequest(context);

      expect(response.statusCode, 405);
    });
  });

  group('POST /simulate/complete', () {
    test('auto-completes overdue todos', () async {
      final now = DateTime.now().toUtc();
      final yesterday = now.subtract(const Duration(days: 1));

      repository.create(Todo(
        id: 'todo-1',
        title: 'Overdue todo',
        dueDate: yesterday,
        completed: false,
        updatedAt: now,
      ));
      repository.create(Todo(
        id: 'todo-2',
        title: 'Not overdue',
        dueDate: now.add(const Duration(days: 1)),
        completed: false,
        updatedAt: now,
      ));
      repository.create(Todo(
        id: 'todo-3',
        title: 'Already completed',
        dueDate: yesterday,
        completed: true,
        updatedAt: now,
      ));

      when(() => context.request).thenReturn(
        Request.post(Uri.parse('http://localhost/simulate/complete')),
      );

      final response = await simulate_complete.onRequest(context);

      expect(response.statusCode, HttpStatus.ok);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['message'], contains('1'));
      expect(body['todos'], hasLength(1));
      expect(body['todos'][0]['id'], 'todo-1');
      expect(body['todos'][0]['completed'], true);
    });

    test('returns empty list when no overdue todos', () async {
      final now = DateTime.now().toUtc();

      repository.create(Todo(
        id: 'todo-1',
        title: 'Future todo',
        dueDate: now.add(const Duration(days: 1)),
        completed: false,
        updatedAt: now,
      ));

      when(() => context.request).thenReturn(
        Request.post(Uri.parse('http://localhost/simulate/complete')),
      );

      final response = await simulate_complete.onRequest(context);

      expect(response.statusCode, HttpStatus.ok);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['todos'], isEmpty);
    });

    test('returns 405 for non-POST methods', () async {
      when(() => context.request).thenReturn(
        Request.get(Uri.parse('http://localhost/simulate/complete')),
      );

      final response = await simulate_complete.onRequest(context);

      expect(response.statusCode, 405);
    });
  });

  group('POST /simulate/prioritize', () {
    test('changes priority of existing todo', () async {
      final now = DateTime.now().toUtc();
      repository.create(Todo(
        id: 'todo-1',
        title: 'Test',
        priority: 3,
        updatedAt: now,
      ));

      when(() => context.request).thenReturn(
        Request.post(
          Uri.parse('http://localhost/simulate/prioritize'),
          body: jsonEncode({
            'id': 'todo-1',
            'priority': 1,
          }),
        ),
      );

      final response = await simulate_prioritize.onRequest(context);

      expect(response.statusCode, HttpStatus.ok);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['message'], 'Priority changed');
      expect(body['todo']['priority'], 1);
    });

    test('returns 404 for non-existent todo', () async {
      when(() => context.request).thenReturn(
        Request.post(
          Uri.parse('http://localhost/simulate/prioritize'),
          body: jsonEncode({
            'id': 'non-existent',
            'priority': 1,
          }),
        ),
      );

      final response = await simulate_prioritize.onRequest(context);

      expect(response.statusCode, HttpStatus.notFound);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['error'], 'Todo not found');
    });

    test('returns 400 when priority is out of range', () async {
      final now = DateTime.now().toUtc();
      repository.create(Todo(
        id: 'todo-1',
        title: 'Test',
        updatedAt: now,
      ));

      when(() => context.request).thenReturn(
        Request.post(
          Uri.parse('http://localhost/simulate/prioritize'),
          body: jsonEncode({
            'id': 'todo-1',
            'priority': 10,
          }),
        ),
      );

      final response = await simulate_prioritize.onRequest(context);

      expect(response.statusCode, HttpStatus.badRequest);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['error'], contains('Priority must be between 1 and 5'));
    });

    test('returns 400 when missing required fields', () async {
      when(() => context.request).thenReturn(
        Request.post(
          Uri.parse('http://localhost/simulate/prioritize'),
          body: jsonEncode({'id': 'todo-1'}),
        ),
      );

      final response = await simulate_prioritize.onRequest(context);

      expect(response.statusCode, HttpStatus.badRequest);

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['error'], contains('Missing required fields'));
    });

    test('returns 405 for non-POST methods', () async {
      when(() => context.request).thenReturn(
        Request.get(Uri.parse('http://localhost/simulate/prioritize')),
      );

      final response = await simulate_prioritize.onRequest(context);

      expect(response.statusCode, 405);
    });
  });
}
