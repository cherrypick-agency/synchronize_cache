import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:todo_advanced_backend/models/todo.dart';
import 'package:todo_advanced_backend/repositories/todo_repository.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _get(context),
    HttpMethod.post => await _post(context),
    _ => Response(statusCode: 405),
  };
}

Response _get(RequestContext context) {
  final repository = context.read<TodoRepository>();
  final params = context.request.uri.queryParameters;

  DateTime? updatedSince;
  if (params['updatedSince'] != null) {
    updatedSince = DateTime.tryParse(params['updatedSince']!);
  }

  final limit = int.tryParse(params['limit'] ?? '') ?? 500;
  final pageToken = params['pageToken'];

  final todos = repository.list(
    updatedSince: updatedSince,
    limit: limit + 1,
    pageToken: pageToken,
  );

  String? nextPageToken;
  List<Todo> result;
  if (todos.length > limit) {
    result = todos.sublist(0, limit);
    nextPageToken = result.last.id;
  } else {
    result = todos;
  }

  return Response(
    body: jsonEncode({
      'items': result.map((t) => t.toJson()).toList(),
      if (nextPageToken != null) 'nextPageToken': nextPageToken,
    }),
    headers: {
      'Content-Type': 'application/json',
      if (nextPageToken != null) 'X-Next-Page-Token': nextPageToken,
    },
  );
}

Future<Response> _post(RequestContext context) async {
  final repository = context.read<TodoRepository>();

  try {
    final body = await context.request.body();
    final json = jsonDecode(body) as Map<String, dynamic>;

    final id = json['id'] as String? ?? _uuid.v4();
    final now = DateTime.now().toUtc();

    final todo = Todo(
      id: id,
      title: json['title'] as String,
      description: json['description'] as String?,
      completed: json['completed'] as bool? ?? false,
      priority: json['priority'] as int? ?? 3,
      dueDate:
          json['due_date'] != null
              ? DateTime.parse(json['due_date'] as String)
              : null,
      updatedAt: now,
    );

    final created = repository.create(todo);

    return Response(
      statusCode: 201,
      body: jsonEncode(created.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response(
      statusCode: 400,
      body: jsonEncode({'error': 'Invalid request body', 'details': '$e'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
