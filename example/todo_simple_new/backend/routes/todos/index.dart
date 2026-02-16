import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:todo_simple_new_backend/repositories/todo_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  final repo = context.read<TodoRepository>();
  return switch (context.request.method) {
    HttpMethod.get => _handleList(context, repo),
    HttpMethod.post => await _handleCreate(context, repo),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Response _handleList(RequestContext context, TodoRepository repo) {
  final params = context.request.uri.queryParameters;
  final updatedSince =
      params['updatedSince'] != null ? DateTime.tryParse(params['updatedSince']!) : null;
  final limit = (int.tryParse(params['limit'] ?? '') ?? 500).clamp(1, 1000);
  final pageToken = params['pageToken'];
  final includeDeleted = params['includeDeleted'] != 'false';

  final result = repo.list(
    updatedSince: updatedSince,
    limit: limit,
    pageToken: pageToken,
    includeDeleted: includeDeleted,
  );

  return Response.json(
    body: {
      'items': result.items.map((t) => t.toJson()).toList(),
      'nextPageToken': result.nextPageToken,
    },
  );
}

Future<Response> _handleCreate(
  RequestContext context,
  TodoRepository repo,
) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final todo = repo.create(body);
    return Response.json(statusCode: HttpStatus.created, body: todo.toJson());
  } catch (_) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Invalid request body'},
    );
  }
}
