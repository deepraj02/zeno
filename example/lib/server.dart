import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

void main() async {
  print('🎯 Starting example Dart application...');

  final router = Router();

  router.get('/', (Request request) {
    return Response.ok(
      '''
<!DOCTYPE html>
<html>
<head>
    <title>Zoo Example</title>
</head>
<body>
    <h1>Running server.darttttt</h1> 
</body>
</html>
    ''',
      headers: {'Content-Type': 'text/html'},
    );
  });

  router.get('/api/hello', (Request request) {
    return Response.ok(
      '{"message": "Hello from Dart Air!", "timestamp": "${DateTime.now().toIso8601String()}"}',
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/api/time', (Request request) {
    final now = DateTime.now();
    return Response.ok(
      '{"time": "${now.toIso8601String()}", "unix": ${now.millisecondsSinceEpoch}}',
      headers: {'Content-Type': 'application/json'},
    );
  });
 
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  const port = 3000;
  await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

  print('✅ Server running on http://localhost:$port');
  print('📝 Edit this file and save to see hot reload in action!');
}
