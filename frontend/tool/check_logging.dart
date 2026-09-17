import 'dart:io';

/// Identifiers a log line may not interpolate (FE-CODE-08).
const List<String> _bannedWords = <String>[
  'key',
  'secret',
  'token',
  'password',
  'credential',
  'caption',
  'transcript',
  'value',
];

/// Logger methods that already name a level.
const Set<String> _levels = <String>{
  'trace',
  'debug',
  'info',
  'warn',
  'warning',
  'error',
  'fatal',
};

/// `print(` / `debugPrint(`.
final RegExp _printCall = RegExp(r'\b(?:debugPrint|print)\s*\(');

/// `logger.info(`, `log.warn(`, `Logger.error(`.
final RegExp _loggerCall = RegExp(
  r'(?<![A-Za-z0-9_])(?:logger|log|Logger)\s*\.\s*([A-Za-z_][A-Za-z0-9_]*)\s*\(',
);

/// `$name` or `${name}` inside a log argument.
final RegExp _interpolation = RegExp(
  r'\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)',
);

/// One word of a camel-case name, same split `check_naming.dart` uses.
final RegExp _camelWord = RegExp(r'[A-Z]+(?![a-z])|[A-Z]?[a-z0-9]+');

/// Checks logging calls, printing one line per violation.
///
/// Takes the Dart sources to scan, defaulting to `lib/`. `print` and
/// `debugPrint` are allowed under `tool/` and `test/`. Patterns for literal
/// secrets come from `tool/secret_patterns.yaml`. The matched secret value is
/// never written out.
Future<int> main(List<String> args) async {
  final Directory root = Directory(args.isEmpty ? 'lib' : args.first);
  final List<_Violation> violations = _findViolations(root);
  for (final _Violation violation in violations) {
    stderr.writeln('${violation.file}:${violation.line}: ${violation.message}');
  }
  stdout.writeln(
    violations.isEmpty
        ? 'logging: every call has a level and a tag'
        : 'logging: ${violations.length} violation(s)',
  );
  exitCode = violations.isEmpty ? 0 : 1;
  return exitCode;
}

/// One logging-discipline break.
typedef _Violation = ({String file, int line, String message});

/// A named secret shape loaded from the shared pattern file.
typedef _Pattern = ({String name, RegExp regex});

/// Reports every logging rule [root] breaks. Reports all of them.
List<_Violation> _findViolations(Directory root) {
  if (!root.existsSync()) {
    return <_Violation>[
      (
        file: _displayRoot(root),
        line: 0,
        message: 'there is no directory here to check',
      ),
    ];
  }
  final List<_Pattern> secrets = _loadPatterns(_patternsFile(root));
  final List<_Violation> found = <_Violation>[];
  for (final File file in _sources(root)) {
    final String relative = '${_displayRoot(root)}/${_relative(root, file)}';
    found.addAll(_fileViolations(relative, file.readAsStringSync(), secrets));
  }
  return found;
}

/// The rules one Dart file breaks.
Iterable<_Violation> _fileViolations(
  String path,
  String source,
  List<_Pattern> secrets,
) sync* {
  yield* _printViolations(path, source);
  yield* _loggerViolations(path, source, secrets);
}

/// `print` / `debugPrint` outside `tool/` and `test/` (FE-CODE-08).
Iterable<_Violation> _printViolations(String path, String source) sync* {
  if (_printAllowed(path)) {
    return;
  }
  for (final Match match in _printCall.allMatches(source)) {
    if (_inCommentOrString(source, match.start)) {
      continue;
    }
    final String kind = source.startsWith('debugPrint', match.start)
        ? 'debugPrint'
        : 'print';
    yield (
      file: path,
      line: _lineOf(source, match.start),
      message:
          '$kind is banned here; use the logger with a level and a tag '
          '(FE-CODE-08)',
    );
  }
}

/// Logger calls that omit a level or a tag, interpolate a banned identifier,
/// or pass a secret-shaped literal.
Iterable<_Violation> _loggerViolations(
  String path,
  String source,
  List<_Pattern> secrets,
) sync* {
  for (final Match match in _loggerCall.allMatches(source)) {
    if (_inCommentOrString(source, match.start)) {
      continue;
    }
    final String method = match.group(1)!;
    final int open = match.end - 1;
    final String? args = _argumentList(source, open);
    if (args == null) {
      continue;
    }
    final int line = _lineOf(source, match.start);
    if (!_levels.contains(method)) {
      yield (
        file: path,
        line: line,
        message:
            'a log call must name a level (trace, info, warn, error); '
            '$method is not one (FE-CODE-08)',
      );
    }
    if (!_hasTag(args)) {
      yield (
        file: path,
        line: line,
        message: 'a log call must pass a tag (FE-CODE-08)',
      );
    }
    yield* _interpolationViolations(path, line, args);
    yield* _secretLiteralViolations(path, line, args, secrets);
  }
}

/// `$apiKey` and a message argument that is itself a banned identifier.
Iterable<_Violation> _interpolationViolations(
  String path,
  int line,
  String args,
) sync* {
  final Set<String> seen = <String>{};
  for (final Match match in _interpolation.allMatches(args)) {
    final String name = match.group(1) ?? match.group(2)!;
    final String? banned = _bannedWordIn(name);
    if (banned == null || !seen.add(name)) {
      continue;
    }
    yield (
      file: path,
      line: line,
      message:
          'a log call interpolates $name, which is a $banned; never log a '
          'key, token, caption, transcript or field value (FE-CODE-08)',
    );
  }
  for (final String argument in _splitArgs(args)) {
    final String trimmed = argument.trim();
    if (!_isIdentifier(trimmed)) {
      continue;
    }
    final String? banned = _bannedWordIn(trimmed);
    if (banned == null || !seen.add(trimmed)) {
      continue;
    }
    yield (
      file: path,
      line: line,
      message:
          'a log call passes $trimmed, which is a $banned; never log a '
          'key, token, caption, transcript or field value (FE-CODE-08)',
    );
  }
}

/// A string argument that matches a named secret pattern. The value is not
/// copied into the message.
Iterable<_Violation> _secretLiteralViolations(
  String path,
  int line,
  String args,
  List<_Pattern> secrets,
) sync* {
  final Set<String> seen = <String>{};
  for (final _Pattern pattern in secrets) {
    if (!pattern.regex.hasMatch(args)) {
      continue;
    }
    if (!seen.add(pattern.name)) {
      continue;
    }
    yield (
      file: path,
      line: line,
      message:
          '${pattern.name} matches a log argument; the value is not printed '
          '(FE-CODE-08, FE-SEC-01)',
    );
  }
}

/// Whether the first positional argument, or a `tag:` argument, is present.
bool _hasTag(String args) {
  final List<String> parts = _splitArgs(args);
  for (final String part in parts) {
    final String trimmed = part.trim();
    if (trimmed.startsWith('tag:')) {
      return true;
    }
  }
  return parts.length >= 2;
}

/// Top-level arguments of a call, split on commas that are not inside a
/// string, a pair of brackets or another call.
List<String> _splitArgs(String args) {
  final List<String> parts = <String>[];
  final StringBuffer current = StringBuffer();
  int depth = 0;
  bool inString = false;
  String quote = '';
  for (int index = 0; index < args.length; index++) {
    final String char = args[index];
    if (inString) {
      current.write(char);
      if (char == r'\' && index + 1 < args.length) {
        current.write(args[index + 1]);
        index++;
        continue;
      }
      if (char == quote) {
        inString = false;
      }
      continue;
    }
    if (char == "'" || char == '"') {
      inString = true;
      quote = char;
      current.write(char);
      continue;
    }
    if (char == '(' || char == '[' || char == '{') {
      depth++;
      current.write(char);
      continue;
    }
    if (char == ')' || char == ']' || char == '}') {
      depth--;
      current.write(char);
      continue;
    }
    if (char == ',' && depth == 0) {
      parts.add(current.toString());
      current.clear();
      continue;
    }
    current.write(char);
  }
  if (current.isNotEmpty) {
    parts.add(current.toString());
  }
  return parts;
}

/// The text between the `(` at [open] and its matching `)`, or null.
String? _argumentList(String source, int open) {
  int depth = 0;
  bool inString = false;
  String quote = '';
  for (int index = open; index < source.length; index++) {
    final String char = source[index];
    if (inString) {
      if (char == r'\' && index + 1 < source.length) {
        index++;
        continue;
      }
      if (char == quote) {
        inString = false;
      }
      continue;
    }
    if (char == "'" || char == '"') {
      inString = true;
      quote = char;
      continue;
    }
    if (char == '(') {
      depth++;
    } else if (char == ')') {
      depth--;
      if (depth == 0) {
        return source.substring(open + 1, index);
      }
    }
  }
  return null;
}

/// Whether [index] sits inside a comment or a string literal.
bool _inCommentOrString(String source, int index) {
  int at = 0;
  while (at < index) {
    if (source.startsWith('//', at)) {
      final int newline = source.indexOf('\n', at);
      if (newline == -1 || newline >= index) {
        return true;
      }
      at = newline + 1;
      continue;
    }
    if (source.startsWith('/*', at)) {
      final int end = source.indexOf('*/', at + 2);
      if (end == -1 || end + 2 > index) {
        return true;
      }
      at = end + 2;
      continue;
    }
    if (source[at] == "'" || source[at] == '"') {
      final String quote = source[at];
      int cursor = at + 1;
      while (cursor < source.length) {
        if (source[cursor] == r'\') {
          cursor += 2;
          continue;
        }
        if (source[cursor] == quote) {
          cursor++;
          break;
        }
        cursor++;
      }
      if (index < cursor) {
        return true;
      }
      at = cursor;
      continue;
    }
    at++;
  }
  return false;
}

/// The banned FE-CODE-08 word [name] is built out of, or null.
String? _bannedWordIn(String name) {
  for (final Match match in _camelWord.allMatches(name)) {
    String word = (match.group(0) ?? '').toLowerCase();
    if (word.endsWith('s') && word.length > 1) {
      word = word.substring(0, word.length - 1);
    }
    if (_bannedWords.contains(word)) {
      return word;
    }
  }
  return null;
}

bool _isIdentifier(String text) {
  return RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(text);
}

bool _printAllowed(String path) {
  final String slash = path.replaceAll(r'\', '/');
  return slash.contains('/tool/') ||
      slash.contains('/test/') ||
      slash.startsWith('tool/') ||
      slash.startsWith('test/');
}

int _lineOf(String source, int index) {
  return source.substring(0, index).split('\n').length;
}

List<_Pattern> _loadPatterns(File file) {
  if (!file.existsSync()) {
    return const <_Pattern>[];
  }
  final List<_Pattern> patterns = <_Pattern>[];
  String? current;
  String? expression;
  bool inPatterns = false;
  for (final String raw in file.readAsLinesSync()) {
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

File _patternsFile(Directory root) {
  final File inRoot = File('${root.path}/tool/secret_patterns.yaml');
  if (inRoot.existsSync()) {
    return inRoot;
  }
  final File besideLib = File('${root.path}/../tool/secret_patterns.yaml');
  if (besideLib.existsSync()) {
    return besideLib;
  }
  return File('tool/secret_patterns.yaml');
}

List<File> _sources(Directory root) {
  final List<File> sources = <File>[
    for (final FileSystemEntity entity in root.listSync(recursive: true))
      if (entity is File && _isDart(_basename(entity.uri))) entity,
  ];
  return sources..sort((File a, File b) => a.path.compareTo(b.path));
}

bool _isDart(String name) => name.endsWith('.dart');

String _relative(Directory root, File file) {
  final String from = root.path.replaceAll(r'\', '/');
  final String to = file.path.replaceAll(r'\', '/');
  return to.startsWith('$from/') ? to.substring(from.length + 1) : to;
}

String _displayRoot(Directory root) {
  return _basename(root.uri);
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

String _basename(Uri uri) {
  return uri.pathSegments.where((String segment) => segment.isNotEmpty).last;
}
