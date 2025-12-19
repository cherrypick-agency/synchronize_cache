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
    final text = json['text'] as String?;

    if (id == null || text == null) {
      return Response(
        statusCode: 400,
        body: jsonEncode({
          'error': 'Missing required fields: id, text',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final todo = simulationService.addReminder(id, text);

    if (todo == null) {
      return Response(
        statusCode: 404,
        body: jsonEncode({'error': 'Todo not found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response(
      body: jsonEncode({
        'message': 'Reminder added',
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
