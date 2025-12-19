import 'package:dart_frog/dart_frog.dart';
import 'package:todo_simple_backend/repositories/todo_repository.dart';

/// Global TodoRepository instance.
final _todoRepository = TodoRepository();

/// Middleware that provides dependencies and handles CORS.
Handler middleware(Handler handler) {
  return handler
      .use(_corsMiddleware())
      .use(requestLogger())
      .use(provider<TodoRepository>((_) => _todoRepository));
}

/// CORS middleware for browser access.
Middleware _corsMiddleware() {
  return (handler) {
    return (context) async {
      // Handle preflight requests
      if (context.request.method == HttpMethod.options) {
        return Response(
          statusCode: 204,
          headers: _corsHeaders,
        );
      }

      final response = await handler(context);
      return response.copyWith(
        headers: {...response.headers, ..._corsHeaders},
      );
    };
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Idempotency-Key',
  'Access-Control-Max-Age': '86400',
};
