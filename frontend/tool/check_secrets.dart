import 'dart:io';

/// Folders that may hold a compiled-in key (FE-SEC-02).
const List<String> _scanFolders = <String>['lib', 'android', 'ios', 'assets'];

/// Extensions that are never text, so they are not decoded.
const Set<String> _binaryExtensions = <String>{
  'png',
  'jpg',
  'jpeg',
  'webp',
  'gif',
  'ico',
  'jar',
  'aar',
  'so',
  'dll',
  'exe',
  'apk',
  'aab',
  'class',
  'dex',
  'bin',
  'ttf',
  'otf',
  'woff',
};

/// A documented placeholder is allowed only inside a test fixture.
final RegExp _placeholder = RegExp(
  r'your|placeholder|replace|example|dummy|xxx|<[^>]+>',
  caseSensitive: false,
);

/// Checks the tree for keys and credentials, printing one line per match.
///
/// Takes the project directory to scan, defaulting to the working directory.
/// Patterns come from `tool/secret_patterns.yaml`. Exits 0 when nothing
/// matches and 1 on any match. The matched text is never written out.
Future<int> main(List<String> args) async {
  final Directory root = Directory(
    args.isEmpty ? Directory.current.path : args.first,
  );
  final List<_Violation> violations = _findViolations(root);
  for (final _Violation violation in violations) {
    stderr.writeln('${violation.file}:${violation.line}: ${violation.message}');
  }
  stdout.writeln(
    violations.isEmpty
        ? 'secrets: no compiled-in keys'
        : 'secrets: ${violations.length} violation(s)',
  );
  exitCode = violations.isEmpty ? 0 : 1;
  return exitCode;
}

/// One match, named so the report can be read without opening the pattern file.
typedef _Violation = ({String file, int line, String message});

/// A named regular expression from `secret_patterns.yaml`.
typedef _Pattern = ({String name, RegExp regex});

/// Reports every secret-shaped value under [root], with the file, the line
/// and the pattern name. Never includes the matched text.
List<_Violation> _findViolations(Directory root) {
  if (!root.existsSync()) {
    return <_Violation>[
      (
        file: _slash(root.path),
        line: 0,
        message: 'there is no directory here to check',
      ),
    ];
  }
  final File patternsFile = _patternsFile(root);
  if (!patternsFile.existsSync()) {
    return <_Violation>[
      (
        file: 'tool/secret_patterns.yaml',
        line: 0,
        message: 'there is no pattern file here to check',
      ),
    ];
  }
  final List<_Pattern> patterns = _loadPatterns(patternsFile);
  if (patterns.isEmpty) {
    return <_Violation>[
      (
        file: _display(root, patternsFile),
        line: 0,
        message: 'every pattern must be named; this file declares none',
      ),
    ];
  }
  final List<_Violation> found = <_Violation>[];
  for (final File file in _sources(root)) {
    final String relative = _display(root, file);
    final List<String> lines = file.readAsStringSync().split('\n');
    for (int index = 0; index < lines.length; index++) {
      for (final _Pattern pattern in patterns) {
        for (final Match match in pattern.regex.allMatches(lines[index])) {
          if (_isAllowedPlaceholder(relative, match.group(0) ?? '')) {
            continue;
          }
          found.add((
            file: relative,
            line: index + 1,
            message:
                '${pattern.name} matches here; the value is not printed '
                '(FE-SEC-02)',
          ));
        }
      }
    }
  }
  return found;
}

/// Whether [matched] is a documented placeholder sitting in a test fixture.
bool _isAllowedPlaceholder(String path, String matched) {
  final String slash = _slash(path);
  final bool fixture =
      slash.contains('/test/') ||
      slash.contains('/fixtures/') ||
      slash.startsWith('test/') ||
      slash.startsWith('fixtures/');
  return fixture && _placeholder.hasMatch(matched);
}

/// Named patterns from [file]. A pattern without a name is skipped so a
/// report never has to point at an anonymous regex.
List<_Pattern> _loadPatterns(File file) {
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

/// The pattern file: next to the tree when tests copy it, otherwise the one
/// this package ships.
File _patternsFile(Directory root) {
  final File inRoot = File('${root.path}/tool/secret_patterns.yaml');
  if (inRoot.existsSync()) {
    return inRoot;
  }
  return File('tool/secret_patterns.yaml');
}

/// Text files under the folders that may not hold a key.
List<File> _sources(Directory root) {
  final List<File> sources = <File>[];
  for (final String name in _scanFolders) {
    final Directory folder = Directory('${root.path}/$name');
    if (!folder.existsSync()) {
      continue;
    }
    for (final FileSystemEntity entity in folder.listSync(recursive: true)) {
      if (entity is File && _isText(entity)) {
        sources.add(entity);
      }
    }
  }
  return sources..sort((File a, File b) => a.path.compareTo(b.path));
}

/// Whether [file] can be decoded as text and is not a known binary type.
bool _isText(File file) {
  final String name = _basename(file.uri);
  final int dot = name.lastIndexOf('.');
  if (dot != -1) {
    final String ext = name.substring(dot + 1).toLowerCase();
    if (_binaryExtensions.contains(ext)) {
      return false;
    }
  }
  final List<int> bytes = file.readAsBytesSync();
  return !bytes.contains(0);
}

String _display(Directory root, File file) {
  final String relative = _relative(root, file);
  return relative;
}

String _relative(Directory root, File file) {
  final String from = _slash(root.path);
  final String to = _slash(file.path);
  return to.startsWith('$from/') ? to.substring(from.length + 1) : to;
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

String _slash(String path) => path.replaceAll(r'\', '/');

String _basename(Uri uri) {
  return uri.pathSegments.where((String segment) => segment.isNotEmpty).last;
}
