import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The application's sources: features must not invent style values.
final Directory _lib = Directory('lib');

/// Token literals are legal here — this is where they are defined.
final Directory _allowed = Directory(
  'test/architecture/fixtures/tokens/allowed/lib',
);

/// The same literals in a feature widget, which must fail.
final Directory _forbidden = Directory(
  'test/architecture/fixtures/tokens/forbidden/lib',
);

/// Paths, relative to a lib root, that may contain token literals (FE-THEME-01).
const List<String> _allowedPrefixes = <String>['app/theme/', 'core/widgets/'];

/// A style construct and the token a feature should have used instead.
final List<({RegExp pattern, String Function(Match match) token})> _rules =
    <({RegExp pattern, String Function(Match match) token})>[
      (
        pattern: RegExp(r'\bColor\s*\('),
        token: (Match _) => 'context.colors (AppColors)',
      ),
      (
        pattern: RegExp(r'(?<!App)Colors\.'),
        token: (Match _) => 'context.colors — a semantic role, never Colors.*',
      ),
      (
        pattern: RegExp(r'EdgeInsets\.all\(\s*(\d+(?:\.\d+)?)\s*\)'),
        token: (Match match) => _spaceToken(match.group(1)!),
      ),
      (
        pattern: RegExp(r'BorderRadius\.circular\(\s*(\d+(?:\.\d+)?)\s*\)'),
        token: (Match match) => _radiusToken(match.group(1)!),
      ),
      (
        pattern: RegExp(r'\bDuration\s*\('),
        token: (Match _) => 'a duration token from app/theme/ (FE-THEME-09)',
      ),
      (
        pattern: RegExp(r'\bTextStyle\s*\('),
        token: (Match _) =>
            'AppText (the matching role: body, label, caption…)',
      ),
    ];

void main() {
  group('the shipped features', () {
    test('contain no token literals', () {
      expect(_findTokenViolations(Directory('lib/features')), isEmpty);
    });

    test('are actually being read', () {
      expect(Directory('lib/features').listSync(), isNotEmpty);
    });
  });

  group('an allowed location', () {
    test(
      'may contain Color, Colors, EdgeInsets, radius, Duration and TextStyle',
      () {
        expect(_findTokenViolations(_allowed), isEmpty);
      },
    );
  });

  group('a forbidden location', () {
    late List<_Violation> found;

    setUpAll(() {
      found = _findTokenViolations(_forbidden);
    });

    test('a literal colour fails, naming context.colors', () {
      expect(
        found,
        contains(
          isA<_Violation>()
              .having(
                (_Violation v) => v.file,
                'file',
                'features/capture/presentation/capture_screen.dart',
              )
              .having(
                (_Violation v) => v.token,
                'token',
                contains('context.colors'),
              ),
        ),
      );
    });

    test(
      'Colors.*, EdgeInsets.all, BorderRadius.circular, Duration and TextStyle each fail',
      () {
        expect(found.map((_Violation v) => v.construct).toSet(), <String>{
          'Color(',
          'Colors.',
          'EdgeInsets.all(',
          'BorderRadius.circular(',
          'Duration(',
          'TextStyle(',
        });
      },
    );

    test('every message names the replacement token, not just the line', () {
      expect(found, isNotEmpty);
      for (final _Violation violation in found) {
        expect(violation.token, isNotEmpty);
        expect(violation.message, contains(violation.token));
        expect(violation.file, isNotEmpty);
        expect(violation.line, greaterThan(0));
      }
    });

    test('every violation is reported, not only the first', () {
      expect(found.length, greaterThanOrEqualTo(6));
    });
  });

  group('the shipped tree as a whole', () {
    test('lets app/theme and core/widgets keep their literals', () {
      expect(_findTokenViolations(_lib), isEmpty);
    });
  });
}

/// One token literal in a place that may not invent style.
typedef _Violation = ({
  String file,
  int line,
  String construct,
  String token,
  String message,
});

/// Reports every token literal under [root] that sits outside `app/theme/`
/// and `core/widgets/`.
///
/// Reports all of them, with the token that should have been used.
List<_Violation> _findTokenViolations(Directory root) {
  if (!root.existsSync()) {
    return const <_Violation>[];
  }
  final List<_Violation> found = <_Violation>[];
  for (final File file in _sources(root)) {
    final String relative = _relative(root, file);
    if (_isAllowed(relative)) {
      continue;
    }
    final List<String> lines = _withoutCommentsAndStrings(
      file.readAsStringSync(),
    ).split('\n');
    for (int index = 0; index < lines.length; index++) {
      for (final ({RegExp pattern, String Function(Match match) token}) rule
          in _rules) {
        for (final Match match in rule.pattern.allMatches(lines[index])) {
          final String token = rule.token(match);
          found.add((
            file: relative,
            line: index + 1,
            construct: _constructOf(match),
            token: token,
            message:
                '$relative:${index + 1}: ${match.group(0)} belongs in a token '
                'file; use $token (FE-THEME-01)',
          ));
        }
      }
    }
  }
  return found;
}

/// Whether [path] is a token or catalogue file, which may hold literals.
bool _isAllowed(String path) {
  return _allowedPrefixes.any(path.startsWith);
}

/// A short name for the construct [match] caught, for assertions.
String _constructOf(Match match) {
  final String text = match.group(0)!;
  if (text.startsWith('Colors')) {
    return 'Colors.';
  }
  if (text.startsWith('Color')) {
    return 'Color(';
  }
  if (text.startsWith('EdgeInsets')) {
    return 'EdgeInsets.all(';
  }
  if (text.startsWith('BorderRadius')) {
    return 'BorderRadius.circular(';
  }
  if (text.startsWith('Duration')) {
    return 'Duration(';
  }
  return 'TextStyle(';
}

/// The Space token [raw] is a literal stand-in for, or the scale itself.
String _spaceToken(String raw) {
  switch (double.parse(raw).round()) {
    case 4:
      return 'Space.x1';
    case 8:
      return 'Space.x2';
    case 12:
      return 'Space.x3';
    case 16:
      return 'Space.x4';
    case 24:
      return 'Space.x6';
    case 32:
      return 'Space.x8';
    default:
      return 'Space (4-point scale)';
  }
}

/// The Radii token [raw] is a literal stand-in for, or the scale itself.
String _radiusToken(String raw) {
  final double value = double.parse(raw);
  if (value <= 8) {
    return 'Radii.sm';
  }
  if (value <= 12) {
    return 'Radii.md';
  }
  if (value <= 16) {
    return 'Radii.lg';
  }
  return 'Radii.pill';
}

/// Hand-written Dart sources under [root].
List<File> _sources(Directory root) {
  final List<File> sources = <File>[
    for (final FileSystemEntity entity in root.listSync(recursive: true))
      if (entity is File && _isHandWrittenDart(_basename(entity.uri))) entity,
  ];
  return sources..sort((File a, File b) => a.path.compareTo(b.path));
}

/// Whether [name] is a Dart file somebody wrote rather than generated.
bool _isHandWrittenDart(String name) {
  return name.endsWith('.dart') && name.split('.').length == 2;
}

/// [source] with comments and string literals blanked, so a `Color` in a
/// comment is not a violation.
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
    final String? quote = _quoteAt(source, index);
    if (quote != null) {
      index = _stringEnd(source, index, quote);
      continue;
    }
    buffer.write(source[index]);
    index++;
  }
  return buffer.toString();
}

/// The quote starting at [index], or null.
String? _quoteAt(String source, int index) {
  if (index < source.length && (source[index] == "'" || source[index] == '"')) {
    return source[index];
  }
  return null;
}

/// Index just past the string that starts at [index] with [quote].
int _stringEnd(String source, int index, String quote) {
  final bool triple = source.startsWith(quote * 3, index);
  final String delimiter = triple ? quote * 3 : quote;
  int at = index + delimiter.length;
  while (at < source.length) {
    if (source[at] == r'\') {
      at += 2;
      continue;
    }
    if (source.startsWith(delimiter, at)) {
      return at + delimiter.length;
    }
    at++;
  }
  return source.length;
}

/// Where [file] sits under [root], with forward slashes.
String _relative(Directory root, File file) {
  final String from = _slash(root.path);
  final String to = _slash(file.path);
  return to.startsWith('$from/') ? to.substring(from.length + 1) : to;
}

String _slash(String path) => path.replaceAll(r'\', '/');

String _basename(Uri uri) {
  return uri.pathSegments.where((String segment) => segment.isNotEmpty).last;
}
