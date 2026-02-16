import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:todo_simple_new_backend/repositories/todo_repository.dart';

Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  context.read<TodoRepository>().clear();
  return Response.json(body: {'status': 'cleared'});
}
