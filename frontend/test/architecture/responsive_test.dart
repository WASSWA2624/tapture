import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The application's sources: features must not measure the window.
final Directory _lib = Directory('lib');

/// Breakpoint numbers and MediaQuery width reads are legal here.
final Directory _allowed = Directory(
  'test/architecture/fixtures/responsive/allowed/lib',
);

/// The same reads in a feature screen, which must fail.
final Directory _forbidden = Directory(
  'test/architecture/fixtures/responsive/forbidden/lib',
);

/// The only folder that may compare a MediaQuery width (FE-RESP-02).
const String _allowedPrefix = 'core/widgets/responsive/';

/// Compact / medium / expanded boundaries; they exist only on [SizeClass].
const int _compactMax = 600;
const int _expandedMin = 1024;

/// A MediaQuery size or width being read.
final RegExp _mediaQuerySize = RegExp(
  r'MediaQuery\s*\.\s*(?:of\s*\([^)]*\)\s*\.\s*size|sizeOf\s*\()',
);

/// A named width argument with a pixel literal.
final RegExp _pixelWidth = RegExp(
  r'''(?:width|maxWidth|minWidth)\s*:\s*(\d+(?:\.\d+)?)''',
);

void main() {
  group('the shipped sources', () {
    test('never compare MediaQuery size outside the responsive helpers', () {
      expect(_findResponsiveViolations(_lib), isEmpty);
    });
  });

  group('an allowed location', () {
    test('may read MediaQuery width and name 600 and 1024', () {
      expect(_findResponsiveViolations(_allowed), isEmpty);
    });
  });

  group('a forbidden location', () {
    late List<_Violation> found;

    setUpAll(() {
      found = _findResponsiveViolations(_forbidden);
    });

    test('a screen comparing width fails, naming SizeClass', () {
      expect(
        found,
        contains(
          isA<_Violation>()
              .having(
                (_Violation v) => v.file,
                'file',
                'features/records/presentation/records_screen.dart',
              )
              .having(
                (_Violation v) => v.accessor,
                'accessor',
                contains('sizeClass'),
              ),
        ),
      );
    });

    test(
      'a hardcoded width above the token maximum names SizeClass.expanded',
      () {
        expect(
          found,
          contains(
            isA<_Violation>()
                .having((_Violation v) => v.kind, 'kind', 'pixel-width')
                .having(
                  (_Violation v) => v.accessor,
                  'accessor',
                  'SizeClass.expanded',
                ),
          ),
        );
      },
    );

    test('every message names the SizeClass accessor, not just the line', () {
      expect(found, isNotEmpty);
      for (final _Violation violation in found) {
        expect(violation.accessor, isNotEmpty);
        expect(violation.message, contains(violation.accessor));
        expect(violation.line, greaterThan(0));
      }
    });

    test('every violation is reported, not only the first', () {
      expect(found.length, greaterThanOrEqualTo(2));
    });
  });
}

/// One window measurement or breakpoint literal outside SizeClass.
typedef _Violation = ({
  String file,
  int line,
  String kind,
  String accessor,
  String message,
});

/// Reports every MediaQuery size/width comparison, and every feature pixel
/// width at or above the compact breakpoint, under [root].
///
/// Files under `core/widgets/responsive/` are left alone: that is where
/// [SizeClass] lives.
List<_Violation> _findResponsiveViolations(Directory root) {
  if (!root.existsSync()) {
    return const <_Violation>[];
  }
  final List<_Violation> found = <_Violation>[];
  for (final File file in _sources(root)) {
    final String relative = _relative(root, file);
    final bool allowed = relative.startsWith(_allowedPrefix);
    final List<String> lines = _withoutCommentsAndStrings(
      file.readAsStringSync(),
    ).split('\n');
    for (int index = 0; index < lines.length; index++) {
      final String line = lines[index];
      if (!allowed && _mediaQuerySize.hasMatch(line)) {
        const String accessor = 'context.sizeClass';
        found.add((
          file: relative,
          line: index + 1,
          kind: 'media-query',
          accessor: accessor,
          message:
              '$relative:${index + 1}: compare $accessor or '
              'context.responsive(...), never MediaQuery width (FE-RESP-02)',
        ));
      }
      if (allowed) {
        continue;
      }
      for (final Match match in _pixelWidth.allMatches(line)) {
        final double value = double.parse(match.group(1)!);
        if (value < _compactMax) {
          continue;
        }
        final String accessor = _accessorFor(value);
        found.add((
          file: relative,
          line: index + 1,
          kind: 'pixel-width',
          accessor: accessor,
          message:
              '$relative:${index + 1}: ${match.group(0)} is a window width; '
              'use $accessor (FE-RESP-01)',
        ));
      }
    }
  }
  return found;
}

/// The SizeClass member [width] is standing in for.
String _accessorFor(double width) {
  if (width < _compactMax) {
    return 'SizeClass.compact';
  }
  if (width < _expandedMin) {
    return 'SizeClass.medium';
  }
  return 'SizeClass.expanded';
}

/// Hand-written Dart sources under [root].
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

/// [source] with comments and string literals blanked.
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
