import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:todo_simple_new_backend/repositories/todo_repository.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final repo = context.read<TodoRepository>();
  return switch (context.request.method) {
    HttpMethod.get => _handleGet(repo, id),
    HttpMethod.put => await _handlePut(context, repo, id),
    HttpMethod.delete => _handleDelete(repo, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

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

Future<Response> _handlePut(
  RequestContext context,
  TodoRepository repo,
  String id,
) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final existing = repo.getById(id);
    final todo = repo.update(id, body);
    final statusCode = existing == null ? HttpStatus.created : HttpStatus.ok;
    return Response.json(statusCode: statusCode, body: todo.toJson());
  } catch (_) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Invalid request body'},
    );
  }
}

Response _handleDelete(TodoRepository repo, String id) {
  final deleted = repo.delete(id);
  if (deleted == null) {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'error': 'not_found'},
    );
  }
  return Response(statusCode: 204);
}
