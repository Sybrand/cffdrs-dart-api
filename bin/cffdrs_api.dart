import 'dart:io';
import 'dart:isolate';

void _startServer(List args) async {
  var server =
      await HttpServer.bind(InternetAddress.loopbackIPv4, 8080, shared: true);
  print('Isolate ${args[0]} Listening on localhost:8080');
  await for (HttpRequest request in server) {
    // Fake delay
    await Future.delayed(Duration(seconds: 1));
    print(request.uri);

    if (request.uri.path == '/api') {
      request.response.headers.contentType = ContentType.json;
      request.response.headers
          .add('Access-Control-Allow-Origin', '*', preserveHeaderCase: true);
      request.response.write('{"message": "Hello, world! ${args[0]}"}');
    } else {
      request.response.statusCode = HttpStatus.notFound;
    }
    await request.response.close();
  }
}

void main(List<String> arguments) async {
  // https://stackoverflow.com/questions/16703631/dart-handle-incoming-http-requests-in-parallel
  print('main: starting server');
  print('processors ${Platform.numberOfProcessors}');
  // Seems reasonable to only create as many isolates as we have processors.
  int isolates = Platform.numberOfProcessors;
  for (var i = 1; i < isolates; i++) {
    Isolate.spawn(_startServer, [i]);
  }

  _startServer([0]);

  await ProcessSignal.sigterm.watch().first;
}
