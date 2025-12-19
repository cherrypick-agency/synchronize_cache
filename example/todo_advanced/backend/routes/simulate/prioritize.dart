import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:todo_advanced_backend/services/simulation_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final simulationService = context.read<SimulationService>();

  try {
    final body = await context.request.body();
    final json = jsonDecode(body) as Map<String, dynamic>;

    final id = json['id'] as String?;
    final priority = json['priority'] as int?;

    if (id == null || priority == null) {
      return Response(
        statusCode: 400,
        body: jsonEncode({
          'error': 'Missing required fields: id, priority',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    if (priority < 1 || priority > 5) {
      return Response(
        statusCode: 400,
        body: jsonEncode({
          'error': 'Priority must be between 1 and 5',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final todo = simulationService.changePriority(id, priority);

    if (todo == null) {
      return Response(
        statusCode: 404,
        body: jsonEncode({'error': 'Todo not found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response(
      body: jsonEncode({
        'message': 'Priority changed',
        'todo': todo.toJson(),
      }),
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
