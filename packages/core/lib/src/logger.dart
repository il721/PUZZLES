/// UI-agnostic logging seam used throughout the puzzle_core services.
abstract class AppLogger {
  /// Logs [message], optionally with an associated [error] and
  /// [stackTrace]. Implementations must not throw.
  void log(String message, {Object? error, StackTrace? stackTrace});
}

/// An [AppLogger] that writes to standard output via `print`.
///
/// Suitable for CLI tools and as a simple default in tests. The Flutter app
/// shell may substitute a richer implementation (e.g. one that forwards to
/// a crash-reporting service) starting at milestone M2.
class ConsoleLogger implements AppLogger {
  /// Creates a console-backed logger.
  const ConsoleLogger();

  @override
  void log(String message, {Object? error, StackTrace? stackTrace}) {
    final buffer = StringBuffer(message);
    if (error != null) {
      buffer.write(' | error: $error');
    }
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }
    // ignore: avoid_print
    print(buffer.toString());
  }
}
