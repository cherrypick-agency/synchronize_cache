import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:todo_advanced_backend/models/todo.dart';
import 'package:todo_advanced_backend/repositories/todo_repository.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    HttpMethod.put => await _put(context, id),
    HttpMethod.delete => await _delete(context, id),
    _ => Response(statusCode: 405),
  };
}

Response _get(RequestContext context, String id) {
  final repository = context.read<TodoRepository>();
  final todo = repository.get(id);

  if (todo == null || todo.deletedAt != null) {
    return Response(
      statusCode: 404,
      body: jsonEncode({'error': 'Todo not found'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  return Response(
    body: jsonEncode(todo.toJson()),
    headers: {'Content-Type': 'application/json'},
  );
}

Future<Response> _put(RequestContext context, String id) async {
  final repository = context.read<TodoRepository>();
  final headers = context.request.headers;

  final idempotencyKey = headers['x-idempotency-key'];
  final forceUpdate = headers['x-force-update']?.toLowerCase() == 'true';

  try {
    final body = await context.request.body();
    final json = jsonDecode(body) as Map<String, dynamic>;
    final now = DateTime.now().toUtc();

    DateTime? baseUpdatedAt;
    if (json['_base_updated_at'] != null) {
      baseUpdatedAt = DateTime.parse(json['_base_updated_at'] as String);
    }

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

    final result = repository.update(
      id,
      todo,
      baseUpdatedAt: baseUpdatedAt,
      forceUpdate: forceUpdate,
      idempotencyKey: idempotencyKey,
    );

    return switch (result) {
      OperationSuccess(:final todo) => Response(
        body: jsonEncode(todo?.toJson()),
        headers: {'Content-Type': 'application/json'},
      ),
      OperationConflict(:final current) => Response(
        statusCode: 409,
        body: jsonEncode({
          'error': 'conflict',
          'current': current.toJson(),
        }),
        headers: {'Content-Type': 'application/json'},
      ),
      OperationNotFound() => Response(
        statusCode: 404,
        body: jsonEncode({'error': 'Todo not found'}),
        headers: {'Content-Type': 'application/json'},
      ),
    };
  } catch (e) {
    return Response(
      statusCode: 400,
      body: jsonEncode({'error': 'Invalid request body', 'details': '$e'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

Future<Response> _delete(RequestContext context, String id) async {
  final repository = context.read<TodoRepository>();
  final headers = context.request.headers;

  final idempotencyKey = headers['x-idempotency-key'];
  final forceDelete = headers['x-force-delete']?.toLowerCase() == 'true';

  DateTime? baseUpdatedAt;
  final baseUpdatedAtHeader = headers['x-base-updated-at'];
  if (baseUpdatedAtHeader != null) {
    baseUpdatedAt = DateTime.tryParse(baseUpdatedAtHeader);
  }

  final result = repository.delete(
    id,
    baseUpdatedAt: baseUpdatedAt,
    forceDelete: forceDelete,
    idempotencyKey: idempotencyKey,
  );

  return switch (result) {
    OperationSuccess() => Response(statusCode: 204),
    OperationConflict(:final current) => Response(
      statusCode: 409,
      body: jsonEncode({
        'error': 'conflict',
        'current': current.toJson(),
      }),
      headers: {'Content-Type': 'application/json'},
    ),
    OperationNotFound() => Response(
      statusCode: 404,
      body: jsonEncode({'error': 'Todo not found'}),
      headers: {'Content-Type': 'application/json'},
    ),
  };
}
