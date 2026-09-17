import 'dart:async';

import 'package:tapture/core/constants/app_constants.dart';

import 'logging_stub.dart' if (dart.library.io) 'logging_io.dart' as io;

/// The logger every fallible path writes through (FE-CODE-08).
///
/// [Logger.new] with [persist] off is the in-memory fake. With [persist] on
/// it is the platform implementation: the same ring buffer, written to a
/// rotating file after each accepted line.
abstract interface class Logger {
  /// Creates a logger.
  ///
  /// [minLevel] drops anything quieter. [bufferSize], rotation and retention
  /// default to [AppConstants.logging]. [patternsYaml] overrides
  /// `tool/secret_patterns.yaml` so tests can feed the same file.
  factory Logger({
    LogLevel minLevel = LogLevel.trace,
    int? bufferSize,
    DateTime Function()? clock,
    String deviceId = 'unknown',
    bool persist = false,
    String? directoryPath,
    String? patternsYaml,
  }) {
    return _MemoryLogger(
      minLevel: minLevel,
      bufferSize: bufferSize ?? AppConstants.logging.bufferSize,
      clock: clock ?? DateTime.now,
      deviceId: deviceId,
      persist: persist,
      directoryPath: directoryPath,
      patternsYaml: patternsYaml,
    );
  }

  /// The process-wide logger [exportLog] and bootstrap write through.
  static Logger current = Logger();

  /// A diagnostic line that does not affect the operator.
  void trace(String tag, String message, {Object? error});

  /// A normal event the diagnostics screen may show.
  void info(String tag, String message, {Object? error});

  /// A recoverable problem.
  void warn(String tag, String message, {Object? error});

  /// A failure that already has a typed failure or an unexpected throw.
  void error(String tag, String message, {Object? error});

  /// Accepted lines, oldest first, already redacted.
  List<String> get buffer;

  /// Each newly accepted line, already redacted.
  Stream<String> get entries;

  /// Written into the export file name until device identity exists (023).
  String get deviceId;

  /// `{date}-{deviceId}` export file name, UTC date from this logger's clock.
  String get exportFileName;
}

/// Severity a log line carries. Order is the filter: anything below the
/// configured level is discarded.
enum LogLevel {
  /// Finest; dropped in a production filter.
  trace,

  /// Routine progress.
  info,

  /// Recoverable.
  warn,

  /// Failed.
  error,
}

final class _MemoryLogger implements Logger {
  _MemoryLogger({
    required this._minLevel,
    required this._bufferSize,
    required this._clock,
    required this.deviceId,
    required bool persist,
    required String? directoryPath,
    required String? patternsYaml,
  }) : _directoryPath =
           directoryPath ?? (persist ? io.defaultLogDirectoryPath() : null),
       _persist = persist,
       _patterns = _loadPatterns(patternsYaml) {
    _persist = _persist && _directoryPath != null;
  }

  final LogLevel _minLevel;
  final int _bufferSize;
  final DateTime Function() _clock;
  @override
  final String deviceId;
  final String? _directoryPath;
  final List<({String name, RegExp regex})> _patterns;

  bool _persist;

  final List<String> _buffer = <String>[];
  final StreamController<String> _entries =
      StreamController<String>.broadcast();

  @override
  List<String> get buffer => List<String>.unmodifiable(_buffer);

  @override
  Stream<String> get entries => _entries.stream;

  @override
  String get exportFileName {
    final DateTime at = _clock().toUtc();
    final String date =
        '${at.year.toString().padLeft(4, '0')}-'
        '${at.month.toString().padLeft(2, '0')}-'
        '${at.day.toString().padLeft(2, '0')}';
    final String id = deviceId.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-');
    return 'tapture-log-$date-$id.txt';
  }

  @override
  void trace(String tag, String message, {Object? error}) {
    _record(LogLevel.trace, tag, message, error);
  }

  @override
  void info(String tag, String message, {Object? error}) {
    _record(LogLevel.info, tag, message, error);
  }

  @override
  void warn(String tag, String message, {Object? error}) {
    _record(LogLevel.warn, tag, message, error);
  }

  @override
  void error(String tag, String message, {Object? error}) {
    _record(LogLevel.error, tag, message, error);
  }

  void _record(LogLevel level, String tag, String message, Object? error) {
    if (level.index < _minLevel.index) {
      return;
    }
    final String body = error == null ? message : '$message $error';
    final String line =
        '${_clock().toUtc().toIso8601String()}\t${level.name}\t$tag\t'
        '${_redact(body, _patterns)}';
    var rotate = false;
    while (_buffer.length >= _bufferSize) {
      _buffer.removeAt(0);
      rotate = true;
    }
    _buffer.add(line);
    _entries.add(line);
    _writeFiles(rotate: rotate);
  }

  void _writeFiles({required bool rotate}) {
    final String? directoryPath = _directoryPath;
    if (!_persist || directoryPath == null) {
      return;
    }
    io.persistLogFiles(
      directoryPath: directoryPath,
      lines: _retained(_buffer),
      rotationCount: AppConstants.logging.rotationCount,
      rotate: rotate,
    );
  }

  List<String> _retained(List<String> lines) {
    final DateTime now = _clock().toUtc();
    return lines.where((String line) {
      final DateTime? at = DateTime.tryParse(line.split('\t').first);
      if (at == null) {
        return true;
      }
      return now.difference(at.toUtc()).inDays <=
          AppConstants.logging.retentionDays;
    }).toList();
  }
}

/// Patterns shipped when `tool/secret_patterns.yaml` is not on the device.
///
/// Kept in lock-step with that file; [logger_test] compares the names.
const List<({String name, String pattern})>
_embeddedSecretPatterns = <({String name, String pattern})>[
  (
    name: 'provider_key',
    pattern:
        r'\b(?:sk-[A-Za-z0-9_-]{20,}|AIza[A-Za-z0-9_-]{20,}|AKIA[A-Z0-9]{16})',
  ),
  (name: 'bearer_token', pattern: r'\bbearer\s+[A-Za-z0-9._~+/=-]{16,}'),
  (
    name: 'private_key',
    pattern: r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
  ),
  (
    name: 'connection_string',
    pattern:
        r'\b(?:postgres(?:ql)?|mysql|mongodb|redis|amqp)://[^/\s:]+:[^@\s]+@',
  ),
  (
    name: 'long_base64',
    pattern:
        r'(?:^|[^A-Za-z0-9+/=])[A-Za-z0-9+/]{80,}={0,2}(?:$|[^A-Za-z0-9+/=])',
  ),
];

final RegExp _recordField = RegExp(
  r'\b(caption|transcript|valueRaw|textRaw|transcriptRaw)\s*[:=]\s*\S+',
  caseSensitive: false,
);

List<({String name, RegExp regex})> _loadPatterns(String? patternsYaml) {
  final String? source = patternsYaml ?? io.readSecretPatternsYaml();
  final List<({String name, RegExp regex})> fromFile = source == null
      ? const <({String name, RegExp regex})>[]
      : _parsePatternsYaml(source);
  if (fromFile.isNotEmpty) {
    return fromFile;
  }
  return <({String name, RegExp regex})>[
    for (final ({String name, String pattern}) item in _embeddedSecretPatterns)
      (name: item.name, regex: RegExp(item.pattern, caseSensitive: false)),
  ];
}

List<({String name, RegExp regex})> _parsePatternsYaml(String source) {
  final List<({String name, RegExp regex})> patterns =
      <({String name, RegExp regex})>[];
  String? current;
  String? expression;
  var inPatterns = false;
  for (final String raw in source.split('\n')) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }
    final int indent = raw.length - raw.trimLeft().length;
    if (indent == 0) {
      inPatterns = trimmed == 'patterns:';
      current = null;
      expression = null;
      continue;
    }
    if (!inPatterns) {
      continue;
    }
    final int separator = trimmed.indexOf(':');
    if (separator == -1) {
      continue;
    }
    final String key = trimmed.substring(0, separator).trim();
    final String value = _unquote(trimmed.substring(separator + 1).trim());
    if (indent == 2) {
      if (current != null && expression != null) {
        patterns.add((
          name: current,
          regex: RegExp(expression, caseSensitive: false),
        ));
      }
      current = key;
      expression = null;
    } else if (indent >= 4 && key == 'pattern' && current != null) {
      expression = value;
    }
  }
  if (current != null && expression != null) {
    patterns.add((
      name: current,
      regex: RegExp(expression, caseSensitive: false),
    ));
  }
  return patterns;
}

String _unquote(String value) {
  if (value.length < 2) {
    return value;
  }
  final String first = value.substring(0, 1);
  final String last = value.substring(value.length - 1);
  final bool quoted = first == last && (first == '"' || first == "'");
  return quoted ? value.substring(1, value.length - 1) : value;
}

String _redact(String text, List<({String name, RegExp regex})> patterns) {
  String out = text;
  for (final ({String name, RegExp regex}) pattern in patterns) {
    out = out.replaceAll(pattern.regex, '[redacted:${pattern.name}]');
  }
  out = out.replaceAllMapped(_recordField, (Match match) {
    return '${match.group(1)}=[redacted]';
  });
  return out;
}
