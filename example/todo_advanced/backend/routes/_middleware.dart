import 'package:dart_frog/dart_frog.dart';
import 'package:todo_advanced_backend/repositories/todo_repository.dart';
import 'package:todo_advanced_backend/services/simulation_service.dart';

final _todoRepository = TodoRepository();
final _simulationService = SimulationService(_todoRepository);

Handler middleware(Handler handler) {
  return handler
      .use(_corsMiddleware())
      .use(_requestLogger())
      .use(provider<TodoRepository>((_) => _todoRepository))
      .use(provider<SimulationService>((_) => _simulationService));
}

Middleware _corsMiddleware() {
  return (handler) {
    return (context) async {
      if (context.request.method == HttpMethod.options) {
        return Response(
          headers: _corsHeaders,
        );
      }

      final response = await handler(context);
      return response.copyWith(
        headers: {
          ...response.headers,
          ..._corsHeaders,
        },
      );
    };
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers':
      'Origin, Content-Type, Accept, X-Idempotency-Key, X-Force-Update, X-Force-Delete',
  'Access-Control-Expose-Headers': 'X-Next-Page-Token',
};

Middleware _requestLogger() {
  return (handler) {
    return (context) async {
      final method = context.request.method.value;
      final path = context.request.uri.path;
      print('[$method] $path');
      return handler(context);
    };
  };
}
