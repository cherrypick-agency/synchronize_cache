import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:todo_advanced_backend/services/simulation_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  final simulationService = context.read<SimulationService>();

  final completed = simulationService.autoCompleteOverdue();

  return Response(
    body: jsonEncode({
      'message': 'Auto-completed ${completed.length} overdue todos',
      'todos': completed.map((t) => t.toJson()).toList(),
    }),
    headers: {'Content-Type': 'application/json'},
  );
}
