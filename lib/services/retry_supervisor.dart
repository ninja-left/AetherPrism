import 'dart:async';

class RetrySignal {
  const RetrySignal({
    required this.shouldRetry,
    required this.reason,
  });

  final bool shouldRetry;
  final String reason;
}

class RetrySupervisor {
  RetrySupervisor({
    this.maxRetries = 10,
    this.baseDelay = const Duration(seconds: 2),
  });

  final int maxRetries;
  final Duration baseDelay;
  final List<String> _recentLogs = <String>[];

  int attempts = 0;
  bool stopRequested = false;

  void reset() {
    attempts = 0;
    stopRequested = false;
    _recentLogs.clear();
  }

  void clearLogs() {
    _recentLogs.clear();
  }

  void recordLog(String line) {
    _recentLogs.add(line);
    if (_recentLogs.length > 200) {
      _recentLogs.removeAt(0);
    }
  }

  void requestStop() {
    stopRequested = true;
  }

  RetrySignal evaluateExit({
    required int? exitCode,
    required bool terminatedByUser,
  }) {
    if (terminatedByUser || stopRequested) {
      return const RetrySignal(
        shouldRetry: false,
        reason: 'Stopped by user',
      );
    }

    if (exitCode == 0 && !_hasFailureLog()) {
      return const RetrySignal(
        shouldRetry: false,
        reason: 'Clean exit',
      );
    }

    if (_hasCleanShutdownLog()) {
      return const RetrySignal(
        shouldRetry: false,
        reason: 'Clean shutdown observed in logs',
      );
    }

    if (!_hasFailureLog() && exitCode == 0) {
      return const RetrySignal(
        shouldRetry: false,
        reason: 'No retry trigger',
      );
    }

    if (attempts >= maxRetries) {
      return const RetrySignal(
        shouldRetry: false,
        reason: 'Retry limit reached',
      );
    }

    attempts += 1;
    return RetrySignal(
      shouldRetry: true,
      reason: 'Connection closed/reset/error detected',
    );
  }

  Duration retryDelay() {
    final int exponent = attempts.clamp(0, 6);
    return Duration(
      milliseconds: baseDelay.inMilliseconds * (1 << exponent),
    );
  }

  bool _hasFailureLog() {
    final patterns = <RegExp>[
      RegExp(r'connection.*(closed|reset)', caseSensitive: false),
      RegExp(r'reset by peer', caseSensitive: false),
      RegExp(r'broken pipe', caseSensitive: false),
      RegExp(r'network error', caseSensitive: false),
      RegExp(r'handshake failed', caseSensitive: false),
      RegExp(r'timeout', caseSensitive: false),
      RegExp(r'error', caseSensitive: false),
      RegExp(r'failed', caseSensitive: false),
      RegExp(r'disconnected', caseSensitive: false),
    ];
    return _recentLogs.any((String line) => patterns.any((RegExp p) => p.hasMatch(line)));
  }

  bool _hasCleanShutdownLog() {
    final patterns = <RegExp>[
      RegExp(r'clean exit', caseSensitive: false),
      RegExp(r'ctrl-?c', caseSensitive: false),
      RegExp(r'kill signal', caseSensitive: false),
      RegExp(r'shutting down gracefully', caseSensitive: false),
      RegExp(r'stopped by user', caseSensitive: false),
      RegExp(r'received signal', caseSensitive: false),
    ];
    return _recentLogs.any((String line) => patterns.any((RegExp p) => p.hasMatch(line)));
  }
}
