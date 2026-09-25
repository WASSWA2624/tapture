import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The application's sources.
final Directory _lib = Directory('lib');

/// Where a glyph is chosen for a concept.
final Directory _allowed = Directory(
  'test/architecture/fixtures/icons/allowed/lib',
);

/// A screen that chooses its own glyphs, which must fail.
final Directory _forbidden = Directory(
  'test/architecture/fixtures/icons/forbidden/lib',
);

/// The only file, relative to a lib root, that may name an `Icons` glyph
/// (FE-CONS-08, FE-THEME-08).
const String _vocabulary = 'core/widgets/app_icons.dart';

/// A raw glyph; `AppIcons.` does not match.
final RegExp _rawGlyph = RegExp(r'(?<![A-Za-z0-9_])Icons\.([a-z][a-z0-9_]*)');

void main() {
  group('the shipped tree', () {
    test('names every icon through AppIcons', () {
      final List<_Violation> found = _findIconViolations(_lib);
      expect(found.map((_Violation v) => v.message), isEmpty);
    });

    test('is actually being read', () {
      expect(File('lib/$_vocabulary').existsSync(), isTrue);
      expect(Directory('lib/features').listSync(), isNotEmpty);
    });
  });

  group('the vocabulary file', () {
    test('may name Icons glyphs', () {
      expect(_findIconViolations(_allowed), isEmpty);
    });
  });

  group('a screen that picks its own glyphs', () {
    late List<_Violation> found;

    setUpAll(() {
      found = _findIconViolations(_forbidden);
    });

    test('fails once for every glyph, with file, line and the fix', () {
      expect(found, hasLength(2));
      expect(found.map((_Violation v) => v.glyph).toSet(), <String>{
        'fiber_manual_record',
        'output',
      });
      for (final _Violation violation in found) {
        expect(
          violation.file,
          'features/capture/presentation/capture_screen.dart',
        );
        expect(violation.line, greaterThan(0));
        expect(violation.message, contains('AppIcons'));
      }
    });
  });
}

/// One raw glyph outside the vocabulary.
typedef _Violation = ({String file, int line, String glyph, String message});

List<_Violation> _findIconViolations(Directory root) {
  final String base = root.absolute.path.replaceAll(r'\', '/');
  final List<_Violation> found = <_Violation>[];
  for (final FileSystemEntity entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final String relative = entity.absolute.path
        .replaceAll(r'\', '/')
        .substring(base.length + 1);
    if (relative == _vocabulary || relative.endsWith('.g.dart')) {
      continue;
    }
    final List<String> lines = entity.readAsLinesSync();
    for (int index = 0; index < lines.length; index++) {
      final String line = lines[index];
      if (line.trimLeft().startsWith('//')) {
        continue;
      }
      for (final RegExpMatch match in _rawGlyph.allMatches(line)) {
        final String glyph = match.group(1)!;
        if (glyph == 'adaptive') {
          continue;
        }
        found.add((
          file: relative,
          line: index + 1,
          glyph: glyph,
          message:
              '$relative:${index + 1} uses Icons.$glyph; name the concept '
              'in AppIcons ($_vocabulary) instead (FE-CONS-08).',
        ));
      }
    }
  }
  return found;
}
