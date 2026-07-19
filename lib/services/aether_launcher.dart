import 'dart:async';

class LaunchRequest {
  const LaunchRequest({
    required this.executablePath,
    required this.environment,
    required this.workingDirectory,
  });

  final String executablePath;
  final Map<String, String> environment;
  final String workingDirectory;
}

enum ProcessEventType { exited, error, info }

class ProcessEvent {
  const ProcessEvent(this.type, {this.message});

  final ProcessEventType type;
  final String? message;
}

class LaunchResult {
  const LaunchResult({
    required this.pid,
    required this.logs,
    required this.events,
    required this.stop,
  });

  final int pid;
  final Stream<String> logs;
  final Stream<ProcessEvent> events;
  final Future<void> Function({bool force}) stop;
}

abstract class AetherLauncher {
  Future<LaunchResult> start(LaunchRequest request);
  Future<void> stop({bool force = false});
}
