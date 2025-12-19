import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:todo_simple_backend/repositories/todo_repository.dart';

/// Handles GET /todos (list) and POST /todos (create).
Future<Response> onRequest(RequestContext context) async {
  final repo = context.read<TodoRepository>();

  return switch (context.request.method) {
    HttpMethod.get => _handleList(context, repo),
    HttpMethod.post => await _handleCreate(context, repo),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

/// GET /todos - List todos with pagination.
///
/// Query parameters:
/// - updatedSince: ISO8601 timestamp to filter by update time
/// - limit: Maximum items per page (default: 500)
/// - pageToken: Pagination token for next page
/// - includeDeleted: Include soft-deleted items (default: true)
Response _handleList(RequestContext context, TodoRepository repo) {
  final params = context.request.uri.queryParameters;

  final updatedSince = params['updatedSince'] != null
      ? DateTime.tryParse(params['updatedSince']!)
      : null;
  final limit = int.tryParse(params['limit'] ?? '') ?? 500;
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

/// POST /todos - Create a new todo.
///
/// Request body should contain todo fields.
/// Server sets id (if not provided) and updated_at.
Future<Response> _handleCreate(
  RequestContext context,
  TodoRepository repo,
) async {
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final todo = repo.create(body);

    return Response.json(
      statusCode: HttpStatus.created,
      body: todo.toJson(),
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Invalid request body: $e'},
    );
  }
}
