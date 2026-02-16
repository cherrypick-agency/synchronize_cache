import 'dart:async';
import 'dart:io';

class BackendServer {
  BackendServer({required this.backendPath});

  Process? _process;
  int? _port;
  final String backendPath;
  final List<String> _output = [];

  int get port {
    if (_port == null) {
      throw StateError('Server not started yet');
    }
    return _port!;
  }

  Uri get baseUrl => Uri.parse('http://localhost:$port');

  Future<void> start() async {
    _port = await _findAvailablePort();
    final vmServicePort = await _findAvailablePort();

    _process = await Process.start(
      'dart_frog',
      ['dev', '--port', '$_port', '--dart-vm-service-port', '$vmServicePort'],
      workingDirectory: backendPath,
    );

    _process!.stdout.transform(const SystemEncoding().decoder).listen(_output.add);
    _process!.stderr
        .transform(const SystemEncoding().decoder)
        .listen((data) => _output.add('[STDERR] $data'));

    await _waitForReady();
  }

  Future<void> _waitForReady() async {
    for (var i = 0; i < 150; i++) {
      if (_output.any((line) => line.contains('Hot reload is enabled'))) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    for (var i = 0; i < 30; i++) {
      try {
        final request = await client.getUrl(Uri.parse('http://localhost:$_port/health'));
        final response = await request.close();
        await response.drain<void>();
        if (response.statusCode == 200) {
          client.close();
          return;
        }
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    client.close();
    throw Exception('Server failed to start.\nOutput:\n${_output.join()}');
  }

  Future<void> stop() async {
    if (_process != null) {
      _process!.kill(ProcessSignal.sigterm);
      await _process!.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _process!.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
      _process = null;
    }
  }

  Future<int> _findAvailablePort() async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final result = server.port;
    await server.close();
    return result;
  }
}
