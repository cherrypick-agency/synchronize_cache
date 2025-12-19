import 'package:dart_frog/dart_frog.dart';

/// Health check endpoint.
///
/// Returns 200 OK with status if the server is running.
Response onRequest(RequestContext context) {
  return Response.json(body: {'status': 'ok'});
}
