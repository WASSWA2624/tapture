import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The application's sources: failures stay typed at every boundary.
final Directory _lib = Directory('lib');

/// A repository that returns Result, and a Failure that carries a message.
final Directory _compliant = Directory(
  'test/architecture/fixtures/errors/compliant/lib',
);

/// A bare Future, a Failure with no message, and a thrown Exception.
final Directory _noncompliant = Directory(
  'test/architecture/fixtures/errors/noncompliant/lib',
);

/// A class declaration, with optional extends / implements lists.
final RegExp _classDeclaration = RegExp(
  r'(?:(?:abstract|base|final|interface|sealed|mixin)\s+)*'
  r'class\s+([A-Za-z_][A-Za-z0-9_]*)'
  r'(?:\s+extends\s+([A-Za-z_][A-Za-z0-9_]*))?'
  r'(?:\s+implements\s+([A-Za-z_][A-Za-z0-9_,\s]*))?',
);

/// A public instance method sitting directly in a class body.
final RegExp _publicMethod = RegExp(
  r'^\s+(?:@override\s+)?'
  r'(?:static\s+)?'
  r'(Future(?:<[^;]+>)?|Stream(?:<[^;]+>)?|Result(?:<[^;]+>)?|void|bool|'
  r'int|double|num|String|List(?:<[^;]+>)?|Map(?:<[^;]+>)?|'
  r'[A-Z][A-Za-z0-9_]*(?:<[^;]+>)?)\s+'
  r'([a-z][A-Za-z0-9_]*)\s*\(',
  multiLine: true,
);

/// `throw SomeType` — a Failure type is the only legal SomeType.
final RegExp _throw = RegExp(
  r'\bthrow\s+(?:const\s+)?([A-Za-z_][A-Za-z0-9_]*)',
);

/// A user-facing message field or getter on a Failure.
final RegExp _messageField = RegExp(
  r'(?:\b(?:final|const)\s+)?String\??\s+message\b|'
  r'String\??\s+get\s+message\b|'
  r'\bthis\.message\b',
);

void main() {
  group('the shipped sources', () {
    test('throw no raw exception and declare no untyped repository method', () {
      expect(_findErrorViolations(_lib), isEmpty);
    });

    test('are actually being read', () {
      expect(Directory('lib/features/capture/domain').existsSync(), isTrue);
      expect(Directory('lib/core/errors').existsSync(), isTrue);
    });
  });

  group('a compliant repository and Failure', () {
    test('return Result and declare a message field', () {
      expect(_findErrorViolations(_compliant), isEmpty);
    });
  });

  group('a non-compliant repository and Failure', () {
    late List<_Violation> found;

    setUpAll(() {
      found = _findErrorViolations(_noncompliant);
    });

    test('a repository method returning a bare Future fails', () {
      expect(
        found,
        contains(
          isA<_Violation>()
              .having((_Violation v) => v.kind, 'kind', 'result')
              .having(
                (_Violation v) => v.file,
                'file',
                'features/capture/domain/capture_repository.dart',
              )
              .having(
                (_Violation v) => v.message,
                'message',
                contains('Result'),
              ),
        ),
      );
    });

    test('a Failure subclass with no message field fails', () {
      expect(
        found,
        contains(
          isA<_Violation>()
              .having((_Violation v) => v.kind, 'kind', 'message')
              .having(
                (_Violation v) => v.file,
                'file',
                'core/errors/storage_failure.dart',
              )
              .having(
                (_Violation v) => v.message,
                'message',
                contains('message'),
              ),
        ),
      );
    });

    test('a domain or data file throwing a non-Failure fails', () {
      expect(
        found,
        contains(
          isA<_Violation>()
              .having((_Violation v) => v.kind, 'kind', 'throw')
              .having(
                (_Violation v) => v.file,
                'file',
                'features/capture/data/capture_repository_impl.dart',
              )
              .having(
                (_Violation v) => v.message,
                'message',
                contains('Failure'),
              ),
        ),
      );
    });

    test('every message names the file and the line', () {
      expect(found, isNotEmpty);
      for (final _Violation violation in found) {
        expect(violation.file, isNotEmpty);
        expect(violation.line, greaterThan(0));
        expect(
          violation.message,
          contains('${violation.file}:${violation.line}'),
        );
      }
    });

    test('every violation is reported, not only the first', () {
      expect(found.length, greaterThanOrEqualTo(3));
    });
  });
}

/// One error-convention break, with the file and line that broke it.
typedef _Violation = ({String file, int line, String kind, String message});

/// Reports every untyped throw, untyped repository method and silent Failure
/// under [root].
List<_Violation> _findErrorViolations(Directory root) {
  if (!root.existsSync()) {
    return const <_Violation>[];
  }
  final List<_Violation> found = <_Violation>[];
  for (final File file in _sources(root)) {
    final String relative = _relative(root, file);
    final String source = _withoutCommentsAndStrings(file.readAsStringSync());
    found.addAll(_throwViolations(relative, source));
    found.addAll(_repositoryResultViolations(relative, source));
    found.addAll(_failureMessageViolations(relative, source));
  }
  return found;
}

/// `throw Exception` (and the like) under `domain/` or `data/` (FE-CODE-06).
Iterable<_Violation> _throwViolations(String path, String source) sync* {
  if (!path.contains('/domain/') && !path.contains('/data/')) {
    return;
  }
  final List<String> lines = source.split('\n');
  for (int index = 0; index < lines.length; index++) {
    for (final Match match in _throw.allMatches(lines[index])) {
      final String type = match.group(1)!;
      if (type == 'Failure' || type.endsWith('Failure')) {
        continue;
      }
      yield (
        file: path,
        line: index + 1,
        kind: 'throw',
        message:
            '$path:${index + 1}: throw $type crosses a layer; return or '
            'throw a Failure (FE-CODE-06)',
      );
    }
  }
}

/// A public repository method whose return type is not Result (FE-CODE-06).
Iterable<_Violation> _repositoryResultViolations(
  String path,
  String source,
) sync* {
  for (final Match match in _classDeclaration.allMatches(source)) {
    final String name = match.group(1)!;
    if (!_isRepository(name, match.group(2), match.group(3))) {
      continue;
    }
    final String body = _classBody(source, match.start);
    for (final Match method in _publicMethod.allMatches(body)) {
      final String returns = method.group(1)!.replaceAll(RegExp(r'\s+'), '');
      final String methodName = method.group(2)!;
      if (_isResultReturn(returns)) {
        continue;
      }
      final int line = source
          .substring(0, match.start + method.start)
          .split('\n')
          .length;
      yield (
        file: path,
        line: line,
        kind: 'result',
        message:
            '$path:$line: $name.$methodName returns $returns; a public '
            'repository method returns Result or Future<Result> (FE-CODE-06)',
      );
    }
  }
}

/// A Failure type that never names a `message` field (FE-CODE-06).
Iterable<_Violation> _failureMessageViolations(
  String path,
  String source,
) sync* {
  for (final Match match in _classDeclaration.allMatches(source)) {
    final String name = match.group(1)!;
    if (!_isFailure(name, match.group(2), match.group(3))) {
      continue;
    }
    final String body = _classBody(source, match.start);
    if (_messageField.hasMatch(body)) {
      continue;
    }
    final int line = source.substring(0, match.start).split('\n').length;
    yield (
      file: path,
      line: line,
      kind: 'message',
      message:
          '$path:$line: $name is a Failure and must declare a user-facing '
          'message field (FE-CODE-06)',
    );
  }
}

/// Whether [name] (and its heritage) is a repository port or implementation.
bool _isRepository(String name, String? extendsType, String? implementsList) {
  if (name.endsWith('Repository')) {
    return true;
  }
  if (extendsType != null && extendsType.endsWith('Repository')) {
    return true;
  }
  if (implementsList == null) {
    return false;
  }
  return implementsList
      .split(',')
      .map((String type) => type.trim())
      .any((String type) => type.endsWith('Repository'));
}

/// Whether [name] (and its heritage) is a Failure variant.
bool _isFailure(String name, String? extendsType, String? implementsList) {
  if (name == 'Failure' || name.endsWith('Failure')) {
    return true;
  }
  if (extendsType == 'Failure' || (extendsType?.endsWith('Failure') ?? false)) {
    return true;
  }
  if (implementsList == null) {
    return false;
  }
  return implementsList
      .split(',')
      .map((String type) => type.trim())
      .any((String type) => type == 'Failure' || type.endsWith('Failure'));
}

/// Whether [type] is `Result`, `Result<…>`, `Future<Result>` or
/// `Future<Result<…>>`.
bool _isResultReturn(String type) {
  return type == 'Result' ||
      type.startsWith('Result<') ||
      type == 'Future<Result>' ||
      type.startsWith('Future<Result<');
}

/// The `{…}` that opens at the class starting at [start].
String _classBody(String source, int start) {
  final int open = source.indexOf('{', start);
  if (open == -1) {
    return '';
  }
  int depth = 0;
  for (int index = open; index < source.length; index++) {
    final String char = source[index];
    if (char == '{') {
      depth++;
    } else if (char == '}') {
      depth--;
      if (depth == 0) {
        return source.substring(open, index + 1);
      }
    }
  }
  return source.substring(open);
}

List<File> _sources(Directory root) {
  final List<File> sources = <File>[
    for (final FileSystemEntity entity in root.listSync(recursive: true))
      if (entity is File && _isHandWrittenDart(_basename(entity.uri))) entity,
  ];
  return sources..sort((File a, File b) => a.path.compareTo(b.path));
}

bool _isHandWrittenDart(String name) {
  return name.endsWith('.dart') && name.split('.').length == 2;
}

String _withoutCommentsAndStrings(String source) {
  final StringBuffer buffer = StringBuffer();
  int index = 0;
  while (index < source.length) {
    if (source.startsWith('//', index)) {
      final int newline = source.indexOf('\n', index);
      index = newline == -1 ? source.length : newline;
      continue;
    }
    if (source.startsWith('/*', index)) {
      final int end = source.indexOf('*/', index + 2);
      index = end == -1 ? source.length : end + 2;
      continue;
    }
    if (index < source.length &&
        (source[index] == "'" || source[index] == '"')) {
      final String quote = source[index];
      final bool triple = source.startsWith(quote * 3, index);
      final String delimiter = triple ? quote * 3 : quote;
      int at = index + delimiter.length;
      while (at < source.length) {
        if (source[at] == r'\') {
          at += 2;
          continue;
        }
        if (source.startsWith(delimiter, at)) {
          at += delimiter.length;
          break;
        }
        at++;
      }
      index = at;
      continue;
    }
    buffer.write(source[index]);
    index++;
  }
  return buffer.toString();
}

String _relative(Directory root, File file) {
  final String from = root.path.replaceAll(r'\', '/');
  final String to = file.path.replaceAll(r'\', '/');
  return to.startsWith('$from/') ? to.substring(from.length + 1) : to;
}

String _basename(Uri uri) {
  return uri.pathSegments.where((String segment) => segment.isNotEmpty).last;
}
