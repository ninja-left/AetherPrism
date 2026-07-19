import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'aether_launcher.dart';

class LocalProcessLauncher implements AetherLauncher {
  Process? _process;
  final StreamController<String> _logs = StreamController<String>.broadcast();
  final StreamController<ProcessEvent> _events =
      StreamController<ProcessEvent>.broadcast();
  Completer<void>? _stopCompleter;

  @override
  Future<LaunchResult> start(LaunchRequest request) async {
    if (_process != null) {
      throw StateError('Aether is already running.');
    }

    final Map<String, String> env = <String, String>{...Platform.environment};
    env.addAll(request.environment);

    final Process process = await Process.start(
      request.executablePath,
      <String>[],
      workingDirectory: request.workingDirectory,
      environment: env,
      includeParentEnvironment: true,
      runInShell: false,
    );

    _process = process;
    _stopCompleter = Completer<void>();

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_logs.add);

    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
      _logs.add(line);
      _events.add(ProcessEvent(ProcessEventType.info, message: line));
    });

    unawaited(process.exitCode.then((int code) {
      _events.add(ProcessEvent(
        ProcessEventType.exited,
        message: 'Process exited with code $code',
      ));
      _process = null;
      if (!(_stopCompleter?.isCompleted ?? true)) {
        _stopCompleter!.complete();
      }
    }));

    return LaunchResult(
      pid: process.pid,
      logs: _logs.stream,
      events: _events.stream,
      stop: ({bool force = false}) => stop(force: force),
    );
  }

  @override
  Future<void> stop({bool force = false}) async {
    final Process? process = _process;
    if (process == null) {
      return;
    }

    if (!force) {
      process.kill(ProcessSignal.sigint);
      await Future<void>.delayed(const Duration(seconds: 2));
      if (_process != null) {
        process.kill(ProcessSignal.sigterm);
      }
    } else {
      process.kill(ProcessSignal.sigkill);
    }

    final Completer<void>? stopCompleter = _stopCompleter;
    if (stopCompleter != null && !stopCompleter.isCompleted) {
      await stopCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {},
      );
    }

    _process = null;
  }
}
