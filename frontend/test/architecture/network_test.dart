import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The application's sources: only three folders may speak HTTP.
final Directory _lib = Directory('lib');

/// A backend client, which is allowed to import an HTTP package.
final Directory _allowed = Directory(
  'test/architecture/fixtures/network/allowed/lib',
);

/// Feature code that imports or names a network client.
final Directory _forbidden = Directory(
  'test/architecture/fixtures/network/forbidden/lib',
);

/// The only folders that may import an HTTP client (FE-SEC-03).
const List<String> _allowedPrefixes = <String>[
  'core/ai/',
  'core/cloud/',
  'core/backend/',
];

/// Import URIs that are HTTP clients.
const List<String> _httpPackages = <String>[
  'package:http/',
  'package:dio/',
  'package:chopper/',
  'package:retrofit/',
];

/// A network client type or call a widget or domain file may not name.
final RegExp _clientType = RegExp(
  r'\b(?:HttpClient|IOClient|BrowserClient|Dio|http\.Client|'
  r'http\.(?:get|post|put|patch|delete|read|readBytes))\b',
);

/// An import directive, as `dart format` leaves one.
final RegExp _import = RegExp(r'''^\s*import\s+['"]([^'"]+)['"]''');

void main() {
  group('the shipped sources', () {
    test('import no HTTP client outside the three egress folders', () {
      expect(_findNetworkViolations(_lib), isEmpty);
    });

    test('are actually being read', () {
      expect(Directory('lib/core/ai').existsSync(), isTrue);
      expect(Directory('lib/core/cloud').existsSync(), isTrue);
      expect(Directory('lib/features/capture').existsSync(), isTrue);
    });
  });

  group('an allowed location', () {
    test('may import an HTTP client under core/backend/', () {
      expect(_findNetworkViolations(_allowed), isEmpty);
    });
  });

  group('a forbidden location', () {
    late List<_Violation> found;

    setUpAll(() {
      found = _findNetworkViolations(_forbidden);
    });

    test('an HTTP import in a feature repository fails', () {
      expect(
        found,
        contains(
          isA<_Violation>()
              .having((_Violation v) => v.kind, 'kind', 'http-import')
              .having(
                (_Violation v) => v.file,
                'file',
                'features/records/data/records_repository.dart',
              ),
        ),
      );
    });

    test('the same import under core/backend/ is not among the findings', () {
      expect(
        found,
        isNot(
          contains(
            isA<_Violation>().having(
              (_Violation v) => v.file,
              'file',
              contains('core/backend/'),
            ),
          ),
        ),
      );
    });

    test('a screen naming a network client fails', () {
      expect(
        found,
        contains(
          isA<_Violation>()
              .having((_Violation v) => v.kind, 'kind', 'client-type')
              .having(
                (_Violation v) => v.file,
                'file',
                'features/capture/presentation/capture_screen.dart',
              )
              .having(
                (_Violation v) => v.message,
                'message',
                contains('HttpClient'),
              ),
        ),
      );
    });

    test('a domain file naming a network client fails', () {
      expect(
        found,
        contains(
          isA<_Violation>()
              .having((_Violation v) => v.kind, 'kind', 'client-type')
              .having(
                (_Violation v) => v.file,
                'file',
                'features/capture/domain/capture_session.dart',
              ),
        ),
      );
    });

    test(
      'a capture, records or export file importing a network package fails',
      () {
        expect(
          found,
          contains(
            isA<_Violation>().having(
              (_Violation v) => v.file,
              'file',
              'features/exports/data/export_writer.dart',
            ),
          ),
        );
      },
    );

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
      expect(found.length, greaterThanOrEqualTo(4));
    });
  });
}

/// One network-boundary break.
typedef _Violation = ({String file, int line, String kind, String message});

/// Reports every HTTP import and client-type use under [root] that sits
/// outside the three egress folders.
List<_Violation> _findNetworkViolations(Directory root) {
  if (!root.existsSync()) {
    return const <_Violation>[];
  }
  final List<_Violation> found = <_Violation>[];
  for (final File file in _sources(root)) {
    final String relative = _relative(root, file);
    final String source = file.readAsStringSync();
    found.addAll(_importViolations(relative, source));
    found.addAll(_typeViolations(relative, source));
  }
  return found;
}

/// An HTTP package imported outside `core/ai/`, `core/cloud/` or
/// `core/backend/`.
Iterable<_Violation> _importViolations(String path, String source) sync* {
  if (_isAllowed(path)) {
    return;
  }
  final List<String> lines = source.split('\n');
  for (int index = 0; index < lines.length; index++) {
    final String line = lines[index].trimLeft();
    if (line.startsWith('//')) {
      continue;
    }
    final Match? match = _import.firstMatch(lines[index]);
    if (match == null) {
      continue;
    }
    final String uri = match.group(1)!;
    if (!_isHttpPackage(uri)) {
      continue;
    }
    yield (
      file: path,
      line: index + 1,
      kind: 'http-import',
      message:
          '$path:${index + 1}: HTTP import $uri belongs in core/ai/, '
          'core/cloud/ or core/backend/ (FE-SEC-03)',
    );
  }
}

/// A network client type named from a widget or a domain file.
Iterable<_Violation> _typeViolations(String path, String source) sync* {
  if (!_isWidgetOrDomain(path)) {
    return;
  }
  final List<String> lines = _withoutCommentsAndStrings(source).split('\n');
  for (int index = 0; index < lines.length; index++) {
    final Match? match = _clientType.firstMatch(lines[index]);
    if (match == null) {
      continue;
    }
    final String type = match.group(0)!;
    yield (
      file: path,
      line: index + 1,
      kind: 'client-type',
      message: path.contains('/domain/')
          ? '$path:${index + 1}: $type in domain/; domain imports no HTTP '
                'client (FE-STR-05, FE-SEC-03)'
          : '$path:${index + 1}: $type in a screen; a screen never speaks '
                'to a server (FE-SEC-03)',
    );
  }
}

bool _isAllowed(String path) {
  return _allowedPrefixes.any(path.startsWith);
}

bool _isHttpPackage(String uri) {
  return _httpPackages.any(uri.startsWith);
}

bool _isWidgetOrDomain(String path) {
  return path.contains('/presentation/') || path.contains('/domain/');
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
