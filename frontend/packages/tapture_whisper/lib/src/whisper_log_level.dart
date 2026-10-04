/// The severity of a library log line: `tw_log_level`, equal to ggml's 1..4.
enum WhisperLogLevel {
  /// Diagnostic detail; the library never keeps it.
  debug(1),

  /// Normal progress, such as a model load.
  info(2),

  /// Something unexpected that the library recovered from.
  warn(3),

  /// A failed operation.
  error(4);

  const WhisperLogLevel(this.code);

  /// The native level.
  final int code;

  /// The level for a native [code]; an unknown code reads as [warn].
  static WhisperLogLevel fromCode(int code) {
    for (final WhisperLogLevel level in values) {
      if (level.code == code) {
        return level;
      }
    }
    return warn;
  }
}
