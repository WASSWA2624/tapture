import 'dart:io';

import 'paths.dart';

/// Checks the directory layout, printing one line per violation.
///
/// Takes the directory to check, defaulting to the working directory.
Future<int> main(List<String> args) async {
  final Directory root = Directory(
    args.isEmpty ? Directory.current.path : args.first,
  );
  final List<({String file, int line, String message})> violations =
      findStructureViolations(root);
  for (final ({String file, int line, String message}) violation
      in violations) {
    stderr.writeln('${violation.file}:${violation.line}: ${violation.message}');
  }
  stdout.writeln(
    violations.isEmpty
        ? 'structure: ${requiredDirectories.length} directories, all present'
        : 'structure: ${violations.length} violation(s)',
  );
  exitCode = violations.isEmpty ? 0 : 1;
  return exitCode;
}

/// Reports every way the tree under [root] departs from the layout
/// `tool/paths.dart` describes: a directory the architecture requires that is
/// missing, one it does not name that has appeared, and a directory standing
/// without the barrel it owns.
///
/// Reports all of them, so one run says everything that has to change.
List<({String file, int line, String message})> findStructureViolations(
  Directory root,
) {
  return <({String file, int line, String message})>[
    ..._missingDirectories(root),
    ..._missingBarrels(root),
    ..._unexpectedDirectories(root),
    ..._checkerRootLiterals(root),
  ];
}

/// Reports a `tool/check_*.dart` checker that writes a scan root of its own
/// instead of reading it from `tool/paths.dart`: a string literal that is,
/// once any interpolation and edge slash is set aside, exactly one of
/// [checkerRoots]. `'${root.path}/$libRoot'` passes; `'${root.path}/lib'`
/// does not.
Iterable<({String file, int line, String message})> _checkerRootLiterals(
  Directory root,
) sync* {
  final Directory tools = Directory('${root.path}/tool');
  if (!tools.existsSync()) {
    return;
  }
  final Set<String> roots = checkerRoots.toSet();
  final List<File> checkers = <File>[
    for (final FileSystemEntity entity in tools.listSync())
      if (entity is File && _isChecker(_fileName(entity))) entity,
  ]..sort((File a, File b) => a.path.compareTo(b.path));
  for (final File checker in checkers) {
    final List<String> lines = checker.readAsLinesSync();
    for (int index = 0; index < lines.length; index++) {
      final String line = lines[index];
      if (line.trimLeft().startsWith('//')) {
        continue;
      }
      for (final Match match in _stringLiteral.allMatches(line)) {
        final String bare = (match.group(2) ?? '')
            .replaceAll(_interpolation, '')
            .replaceAll(_edgeSlash, '');
        if (!roots.contains(bare)) {
          continue;
        }
        yield (
          file: 'tool/${_fileName(checker)}',
          line: index + 1,
          message:
              "the checker writes the scan root '$bare' itself; read it from "
              'tool/paths.dart so every guardrail agrees on the layout',
        );
      }
    }
  }
}

bool _isChecker(String name) {
  return name.startsWith('check_') && name.endsWith('.dart');
}

String _fileName(File file) {
  return file.uri.pathSegments.where((String part) => part.isNotEmpty).last;
}

/// A single- or double-quoted string on one line; group 2 is its content.
final RegExp _stringLiteral = RegExp(r"""(['"])((?:\\.|(?!\1).)*)\1""");

/// `${expression}` or `$name` inside a string literal.
final RegExp _interpolation = RegExp(r'\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_]*');

/// A slash at either end of a path.
final RegExp _edgeSlash = RegExp(r'^/+|/+$');

Iterable<({String file, int line, String message})> _missingDirectories(
  Directory root,
) sync* {
  for (final String directory in requiredDirectories) {
    if (!Directory('${root.path}/$libRoot/$directory').existsSync()) {
      yield (
        file: '$libRoot/$directory',
        line: 0,
        message:
            'the architecture requires this directory and the tree has no '
            'such folder',
      );
    }
  }
}

Iterable<({String file, int line, String message})> _missingBarrels(
  Directory root,
) sync* {
  for (final String directory in requiredDirectories) {
    final String? barrel = barrelFor(directory);
    if (barrel == null) {
      continue;
    }
    if (!Directory('${root.path}/$libRoot/$directory').existsSync()) {
      continue;
    }
    if (!File('${root.path}/$libRoot/$barrel').existsSync()) {
      yield (
        file: '$libRoot/$barrel',
        line: 0,
        message:
            '$libRoot/$directory has no barrel, so nothing outside it has a '
            'stable name to import',
      );
    }
  }
}

/// Reports a directory nobody named. The layout is canonical, so a folder that
/// appears without an entry in `tool/paths.dart` is either a typo or a
/// decision that was never written down.
Iterable<({String file, int line, String message})> _unexpectedDirectories(
  Directory root,
) sync* {
  final Set<String> expected = requiredDirectories.toSet();
  for (final String parent in <String>['', 'core', 'features']) {
    final String prefix = parent.isEmpty ? '' : '$parent/';
    for (final String child in _childDirectories(root, parent)) {
      if (!expected.contains('$prefix$child')) {
        yield (
          file: '$libRoot/$prefix$child',
          line: 0,
          message:
              'nothing in tool/paths.dart names this directory; add it there '
              'or move the code into one that is named',
        );
      }
    }
  }
  for (final String feature in featureDirectories) {
    final String parent = 'features/$feature';
    for (final String child in _childDirectories(root, parent)) {
      if (!featureLayers.contains(child)) {
        yield (
          file: '$libRoot/$parent/$child',
          line: 0,
          message:
              'a feature is data/, domain/ and presentation/ and nothing else '
              '(FE-STR-03)',
        );
      }
    }
  }
}

/// The directory names directly inside `lib/[parent]`, sorted.
///
/// Skips anything beginning with a dot: the analyzer walks past those, and the
/// guardrail suites write their fixtures there while they run.
List<String> _childDirectories(Directory root, String parent) {
  final String path = parent.isEmpty
      ? '${root.path}/$libRoot'
      : '${root.path}/$libRoot/$parent';
  final Directory directory = Directory(path);
  if (!directory.existsSync()) {
    return <String>[];
  }
  final List<String> names = <String>[
    for (final FileSystemEntity entity in directory.listSync())
      if (entity is Directory) _basename(entity),
  ]..removeWhere((String name) => name.startsWith('.'));
  return names..sort();
}

/// The last segment of a directory's path, taken from its URI so the
/// separator the host platform uses never has to be spelled out.
String _basename(Directory directory) {
  return directory.uri.pathSegments
      .where((String segment) => segment.isNotEmpty)
      .last;
}
