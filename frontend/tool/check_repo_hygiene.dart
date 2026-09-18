import 'dart:io';

/// Build output, signing material and data-bearing paths that `.gitignore`
/// must keep out of git. Each is a sample of the shape it stands for, so a
/// pattern that stops covering it is reported by name.
const List<String> _pathsGitMustIgnore = <String>[
  'build/app/outputs/flutter-apk/app-release.apk',
  'android/app/build/intermediates/merged_manifest/AndroidManifest.xml',
  '.dart_tool/package_config.json',
  'lib/features/projects/data/project_dao.g.dart',
  'lib/features/projects/domain/project.freezed.dart',
  'android/app/upload.keystore',
  'android/key.properties',
  '.env',
  '.env.local',
  'samples/equipment-inventory__deviceA__2026-09-08T1030.zip',
  'projects/site-a/photos/front.jpg',
];

/// EditorConfig settings the repository fixes, by section header. A section
/// inherits from `[*]`, so `[*.dart]` only restates what it narrows.
const Map<String, Map<String, String>> _editorConfigMustFix =
    <String, Map<String, String>>{
      '*': <String, String>{
        'charset': 'utf-8',
        'end_of_line': 'lf',
        'insert_final_newline': 'true',
      },
      '*.dart': <String, String>{'indent_style': 'space', 'indent_size': '2'},
    };

/// Checks the repository hygiene files, printing one line per violation.
///
/// Takes the directory to check, defaulting to the working directory.
Future<int> main(List<String> args) async {
  final Directory root = Directory(
    args.isEmpty ? Directory.current.path : args.first,
  );
  final List<({String file, int line, String message})> violations =
      findRepoHygieneViolations(root);
  for (final ({String file, int line, String message}) violation
      in violations) {
    stderr.writeln('${violation.file}:${violation.line}: ${violation.message}');
  }
  stdout.writeln(
    violations.isEmpty
        ? 'repo hygiene: clean'
        : 'repo hygiene: ${violations.length} violation(s)',
  );
  exitCode = violations.isEmpty ? 0 : 1;
  return exitCode;
}

/// Reports every hygiene rule the tree at [root] breaks, each with the file and
/// the line that has to change to fix it.
List<({String file, int line, String message})> findRepoHygieneViolations(
  Directory root,
) {
  return <({String file, int line, String message})>[
    ..._gitignoreViolations(root),
    ..._editorConfigViolations(root),
  ];
}

Iterable<({String file, int line, String message})> _gitignoreViolations(
  Directory root,
) sync* {
  const String name = '.gitignore';
  final File file = File('${root.path}/$name');
  if (!file.existsSync()) {
    yield (file: name, line: 0, message: 'the repository has no $name');
    return;
  }
  final List<String> lines = file.readAsLinesSync();
  final List<_IgnoreRule> rules = <_IgnoreRule>[
    for (final String line in lines)
      if (_isPattern(line)) _IgnoreRule.parse(line.trim()),
  ];
  for (final String path in _pathsGitMustIgnore) {
    if (!_isIgnored(path, rules)) {
      yield (
        file: name,
        line: lines.length,
        message: 'no pattern ignores $path',
      );
    }
  }
}

bool _isPattern(String line) {
  final String trimmed = line.trim();
  return trimmed.isNotEmpty && !trimmed.startsWith('#');
}

bool _isIgnored(String path, List<_IgnoreRule> rules) {
  bool ignored = false;
  for (final _IgnoreRule rule in rules) {
    if (rule.matcher.hasMatch(path)) {
      ignored = !rule.isNegated;
    }
  }
  return ignored;
}

Iterable<({String file, int line, String message})> _editorConfigViolations(
  Directory root,
) sync* {
  const String name = '.editorconfig';
  final File file = File('${root.path}/$name');
  if (!file.existsSync()) {
    yield (file: name, line: 0, message: 'the repository has no $name');
    return;
  }
  final List<String> lines = file.readAsLinesSync();
  final Map<String, _EditorConfigSection> sections = _parseEditorConfig(lines);
  for (final MapEntry<String, Map<String, String>> expected
      in _editorConfigMustFix.entries) {
    final _EditorConfigSection? section = sections[expected.key];
    if (section == null) {
      yield (
        file: name,
        line: lines.length,
        message: 'no [${expected.key}] section',
      );
      continue;
    }
    for (final MapEntry<String, String> setting in expected.value.entries) {
      final String? actual = section.values[setting.key];
      if (actual == null) {
        yield (
          file: name,
          line: section.headerLine,
          message:
              '[${expected.key}] does not set ${setting.key} = '
              '${setting.value}',
        );
      } else if (actual != setting.value) {
        yield (
          file: name,
          line: section.lines[setting.key] ?? section.headerLine,
          message:
              '[${expected.key}] sets ${setting.key} = $actual, expected '
              '${setting.value}',
        );
      }
    }
  }
}

Map<String, _EditorConfigSection> _parseEditorConfig(List<String> lines) {
  final Map<String, _EditorConfigSection> sections =
      <String, _EditorConfigSection>{};
  _EditorConfigSection? current;
  for (int index = 0; index < lines.length; index++) {
    final String line = lines[index].trim();
    if (line.isEmpty || line.startsWith('#') || line.startsWith(';')) {
      continue;
    }
    if (line.startsWith('[') && line.endsWith(']')) {
      final String header = line.substring(1, line.length - 1);
      current = sections.putIfAbsent(
        header,
        () => _EditorConfigSection(index + 1),
      );
      continue;
    }
    final int separator = line.indexOf('=');
    if (separator == -1 || current == null) {
      continue;
    }
    final String key = line.substring(0, separator).trim().toLowerCase();
    current.values[key] = line.substring(separator + 1).trim().toLowerCase();
    current.lines[key] = index + 1;
  }
  return sections;
}

/// One `[header]` block of an EditorConfig file, with the line each key sits on
/// so a violation can point at it.
class _EditorConfigSection {
  _EditorConfigSection(this.headerLine);

  final int headerLine;
  final Map<String, String> values = <String, String>{};
  final Map<String, int> lines = <String, int>{};
}

/// One `.gitignore` pattern, compiled to the subset of the syntax this
/// repository uses: anchoring, directory suffixes, negation and globs.
class _IgnoreRule {
  const _IgnoreRule(this.matcher, {required this.isNegated});

  factory _IgnoreRule.parse(String line) {
    String pattern = line;
    final bool isNegated = pattern.startsWith('!');
    if (isNegated) {
      pattern = pattern.substring(1);
    }
    if (pattern.endsWith('/')) {
      pattern = pattern.substring(0, pattern.length - 1);
    }
    bool isAnchored = pattern.contains('/');
    if (pattern.startsWith('/')) {
      pattern = pattern.substring(1);
      isAnchored = true;
    }
    final String prefix = isAnchored ? '' : r'(?:.*/)?';
    return _IgnoreRule(
      RegExp('^$prefix${_globToRegExp(pattern)}(?:/.*)?\$'),
      isNegated: isNegated,
    );
  }

  final RegExp matcher;
  final bool isNegated;
}

String _globToRegExp(String glob) {
  final StringBuffer buffer = StringBuffer();
  int index = 0;
  while (index < glob.length) {
    final String character = glob[index];
    if (character == '*' && index + 1 < glob.length && glob[index + 1] == '*') {
      index += 2;
      if (index < glob.length && glob[index] == '/') {
        index++;
        buffer.write(r'(?:.*/)?');
      } else {
        buffer.write('.*');
      }
      continue;
    }
    if (character == '*') {
      buffer.write(r'[^/]*');
    } else if (character == '?') {
      buffer.write(r'[^/]');
    } else {
      buffer.write(RegExp.escape(character));
    }
    index++;
  }
  return buffer.toString();
}
