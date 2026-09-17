import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The application's sources: raw evidence is append-only.
final Directory _lib = Directory('lib');

/// A create-path write, a tombstone, and a purge-job file delete.
final Directory _allowed = Directory(
  'test/architecture/fixtures/data_safety/allowed/lib',
);

/// A refinement overwrite, a hard row delete, and a file delete in capture.
final Directory _forbidden = Directory(
  'test/architecture/fixtures/data_safety/forbidden/lib',
);

/// Raw columns that are written once (FE-SEC-08).
const List<String> _rawFields = <String>[
  'valueRaw',
  'textRaw',
  'transcriptRaw',
];

/// A property write (`row.valueRaw =`) or a named argument (`valueRaw:`).
final String _rawFieldPattern = _rawFields.join('|');
final RegExp _rawWrite = RegExp(
  '(?:\\.($_rawFieldPattern)\\s*=|\\b($_rawFieldPattern)\\s*:)',
);

/// A hard row delete, not `softDelete` or `writeTombstone`.
final RegExp _hardDelete = RegExp(
  r'(?:\.delete\s*\(|\bdeleteWhere\s*\(|\bdelete\s*\(\s*\w)',
);

/// A `dart:io` file removal.
final RegExp _fileDelete = RegExp(
  r'''(?:\bFile\s*\([^)]*\)\s*\.\s*delete(?:Sync)?\s*\(|\bdeleteSync\s*\()''',
);

/// Methods that create a row, which may write a raw column.
bool _isCreateMethod(String name) {
  return name.startsWith('insert') ||
      name.startsWith('create') ||
      name.startsWith('add');
}

void main() {
  group('the shipped sources', () {
    test('do not overwrite raw columns, hard-delete rows or delete files', () {
      expect(_findSafetyViolations(_lib), isEmpty);
    });

    test('are actually being read', () {
      expect(Directory('lib/features/records').existsSync(), isTrue);
      expect(Directory('lib/features/capture').existsSync(), isTrue);
    });
  });

  group('a compliant tree', () {
    test(
      'lets a repository insert write valueRaw and the purge job delete a file',
      () {
        expect(_findSafetyViolations(_allowed), isEmpty);
      },
    );
  });

  group('a non-compliant tree', () {
    late List<_Violation> found;

    setUpAll(() {
      found = _findSafetyViolations(_forbidden);
    });

    test('an update to valueRaw in a refinement service fails', () {
      expect(
        found,
        contains(
          isA<_Violation>()
              .having((_Violation v) => v.kind, 'kind', 'raw-write')
              .having(
                (_Violation v) => v.file,
                'file',
                'features/processing/domain/refinement_service.dart',
              )
              .having(
                (_Violation v) => v.message,
                'message',
                contains('valueRaw'),
              ),
        ),
      );
    });

    test('a hard row delete in a repository fails', () {
      expect(
        found,
        contains(
          isA<_Violation>()
              .having((_Violation v) => v.kind, 'kind', 'hard-delete')
              .having(
                (_Violation v) => v.file,
                'file',
                'features/records/data/records_repository.dart',
              )
              .having(
                (_Violation v) => v.message,
                'message',
                contains('writeTombstone'),
              ),
        ),
      );
    });

    test('a file delete outside the purge job fails', () {
      expect(
        found,
        contains(
          isA<_Violation>()
              .having((_Violation v) => v.kind, 'kind', 'file-delete')
              .having(
                (_Violation v) => v.file,
                'file',
                'features/capture/data/photo_store.dart',
              )
              .having(
                (_Violation v) => v.message,
                'message',
                contains('purge'),
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

/// One raw-evidence break.
typedef _Violation = ({String file, int line, String kind, String message});

/// Reports every illegal raw-column write, hard row delete and file delete
/// under [root].
List<_Violation> _findSafetyViolations(Directory root) {
  if (!root.existsSync()) {
    return const <_Violation>[];
  }
  final List<_Violation> found = <_Violation>[];
  for (final File file in _sources(root)) {
    final String relative = _relative(root, file);
    final String source = _withoutCommentsAndStrings(file.readAsStringSync());
    found.addAll(_rawWriteViolations(relative, source));
    found.addAll(_hardDeleteViolations(relative, source));
    found.addAll(_fileDeleteViolations(relative, source));
  }
  return found;
}

/// A write to [valueRaw], [textRaw] or [transcriptRaw] that is not the
/// repository create path.
Iterable<_Violation> _rawWriteViolations(String path, String source) sync* {
  final List<String> lines = source.split('\n');
  for (int index = 0; index < lines.length; index++) {
    final Match? match = _rawWrite.firstMatch(lines[index]);
    if (match == null) {
      continue;
    }
    final String field = match.group(1) ?? match.group(2)!;
    final String? function = _enclosingFunction(lines, index);
    if (_isRepository(path) && function != null && _isCreateMethod(function)) {
      continue;
    }
    yield (
      file: path,
      line: index + 1,
      kind: 'raw-write',
      message:
          '$path:${index + 1}: $field is written once at insert; refinement '
          'writes a separate column (FE-SEC-08)',
    );
  }
}

/// `delete` / `deleteWhere` in a repository file.
Iterable<_Violation> _hardDeleteViolations(String path, String source) sync* {
  if (!_isRepository(path)) {
    return;
  }
  final List<String> lines = source.split('\n');
  for (int index = 0; index < lines.length; index++) {
    if (!_hardDelete.hasMatch(lines[index])) {
      continue;
    }
    yield (
      file: path,
      line: index + 1,
      kind: 'hard-delete',
      message:
          '$path:${index + 1}: hard row delete; use writeTombstone '
          '(FE-SEC-08)',
    );
  }
}

/// `File(...).delete` outside the purge job.
Iterable<_Violation> _fileDeleteViolations(String path, String source) sync* {
  if (_isPurgeJob(path)) {
    return;
  }
  final List<String> lines = source.split('\n');
  for (int index = 0; index < lines.length; index++) {
    if (!_fileDelete.hasMatch(lines[index])) {
      continue;
    }
    yield (
      file: path,
      line: index + 1,
      kind: 'file-delete',
      message:
          '$path:${index + 1}: File.delete belongs in the purge job '
          '(FE-SEC-08)',
    );
  }
}

/// The nearest function whose `{` opened before [index].
String? _enclosingFunction(List<String> lines, int index) {
  final RegExp signature = RegExp(
    r'(?:^|\s)([A-Za-z_][A-Za-z0-9_]*)\s*\([^;{]*\)\s*(?:async\s*)?\{',
  );
  for (int at = index; at >= 0; at--) {
    final Match? match = signature.firstMatch(lines[at]);
    if (match != null) {
      return match.group(1);
    }
  }
  return null;
}

bool _isRepository(String path) {
  return _basenameFromPath(path).contains('repository');
}

bool _isPurgeJob(String path) {
  return _basenameFromPath(path).contains('purge');
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

String _basenameFromPath(String path) {
  final int slash = path.lastIndexOf('/');
  return slash == -1 ? path : path.substring(slash + 1);
}

String _basename(Uri uri) {
  return uri.pathSegments.where((String segment) => segment.isNotEmpty).last;
}
