import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:todo_simple_backend/repositories/todo_repository.dart';

/// Handles GET, PUT, DELETE for /todos/:id.
Future<Response> onRequest(RequestContext context, String id) async {
  final repo = context.read<TodoRepository>();

  return switch (context.request.method) {
    HttpMethod.get => _handleGet(repo, id),
    HttpMethod.put => await _handlePut(context, repo, id),
    HttpMethod.delete => _handleDelete(repo, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

/// GET /todos/:id - Get a single todo.
Response _handleGet(TodoRepository repo, String id) {
  final todo = repo.getById(id);

  if (todo == null) {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'error': 'not_found'},
    );
  }

  return Response.json(body: todo.toJson());
}

/// PUT /todos/:id - Update or create (upsert) a todo.
///
/// In simplified flow, `_baseUpdatedAt` is ignored (no conflict check).
Future<Response> _handlePut(
  RequestContext context,
  TodoRepository repo,
  String id,
) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final existing = repo.getById(id);
    final todo = repo.update(id, body);

    // Return 201 if created, 200 if updated
    final statusCode = existing == null ? HttpStatus.created : HttpStatus.ok;

    return Response.json(
      statusCode: statusCode,
      body: todo.toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Invalid request body: $e'},
    );
  }
}

/// DELETE /todos/:id - Delete a todo.
///
/// In simplified flow, `_baseUpdatedAt` query param is ignored.
Response _handleDelete(TodoRepository repo, String id) {
  final deleted = repo.delete(id);

  if (!deleted) {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'error': 'not_found'},
    );
  }

  return Response(statusCode: HttpStatus.noContent);
}
