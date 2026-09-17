import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The application's sources: widgets stay thin and providers stay put.
final Directory _lib = Directory('lib');

/// A controller that exposes intent methods; its provider lives with capture.
final Directory _compliant = Directory(
  'test/architecture/fixtures/state/compliant/lib',
);

/// A widget that writes through a repository, and a provider in the wrong feature.
final Directory _noncompliant = Directory(
  'test/architecture/fixtures/state/noncompliant/lib',
);

/// Feature folders on the shipped tree; a provider named after one of these
/// belongs in that folder.
final Set<String> _features = _featureNames(Directory('lib'));

/// A top-level variable that is a provider (FE-CODE-02, FE-STR-07).
final RegExp _topLevelVariable = RegExp(
  r'^\s*(?:late\s+|const\s+|final\s+|var\s+)+'
  r'(?:[A-Za-z_][\w.<>,\s?]*\s+)?'
  r'([A-Za-z_][A-Za-z0-9_]*)\s*[;=]',
);

/// A StatefulWidget calling setState.
final RegExp _setState = RegExp(r'\bsetState\s*\(');

/// A repository method invoked on a typed port or a `repository` field.
final RegExp _repositoryCall = RegExp(
  r'(?:\b[A-Z][A-Za-z0-9]*Repository|\brepository)\s*\.\s*[A-Za-z]',
);

/// A class that is a controller.
final RegExp _controllerClass = RegExp(
  r'(?:abstract\s+)?class\s+([A-Za-z_][A-Za-z0-9_]*Controller)\b',
);

/// A public instance method: a type, then a lowerCamelCase name and `(`.
final RegExp _publicMethod = RegExp(
  r'^\s+(?:@override\s+)?'
  r'(?:static\s+)?'
  r'(?:Future(?:<[^;]+>)?|Stream(?:<[^;]+>)?|Result(?:<[^;]+>)?|void|bool|'
  r'int|double|num|String|List(?:<[^;]+>)?|Map(?:<[^;]+>)?|'
  r'[A-Z][A-Za-z0-9_]*(?:<[^;]+>)?)\s+'
  r'([a-z][A-Za-z0-9_]*)\s*\(',
  multiLine: true,
);

void main() {
  group('the shipped sources', () {
    test('declare no provider, setState or repository call out of place', () {
      expect(_findStateViolations(_lib), isEmpty);
    });

    test('are actually being read', () {
      expect(Directory('lib/features').listSync(), isNotEmpty);
      expect(_features, contains('capture'));
    });
  });

  group('a compliant controller', () {
    test('exposes intent methods and keeps its provider in capture', () {
      expect(_findStateViolations(_compliant), isEmpty);
    });

    test('lets setState live in core/widgets and in animation code', () {
      final String widgets = File(
        '${_compliant.path}/core/widgets/pressable.dart',
      ).readAsStringSync();
      final String animation = File(
        '${_compliant.path}/features/capture/presentation/shutter_animation.dart',
      ).readAsStringSync();
      expect(widgets, contains('setState'));
      expect(animation, contains('setState'));
    });
  });

  group('a non-compliant controller', () {
    late List<_Violation> found;

    setUpAll(() {
      found = _findStateViolations(_noncompliant);
    });

    test('a widget calling a repository method fails', () {
      expect(
        found,
        contains(
          isA<_Violation>()
              .having((_Violation v) => v.kind, 'kind', 'repository-call')
              .having(
                (_Violation v) => v.file,
                'file',
                'features/capture/presentation/capture_screen.dart',
              )
              .having(
                (_Violation v) => v.message,
                'message',
                contains('intent'),
              ),
        ),
      );
    });

    test('a provider declared outside its feature fails', () {
      expect(
        found,
        contains(
          isA<_Violation>()
              .having((_Violation v) => v.kind, 'kind', 'provider-home')
              .having(
                (_Violation v) => v.file,
                'file',
                'features/records/presentation/capture_providers.dart',
              )
              .having(
                (_Violation v) => v.message,
                'message',
                contains('features/capture/'),
              ),
        ),
      );
    });

    test('setState in a feature screen fails', () {
      expect(
        found,
        contains(
          isA<_Violation>().having(
            (_Violation v) => v.kind,
            'kind',
            'set-state',
          ),
        ),
      );
    });

    test('a controller with no intent method fails', () {
      expect(
        found,
        contains(
          isA<_Violation>()
              .having((_Violation v) => v.kind, 'kind', 'intent')
              .having(
                (_Violation v) => v.message,
                'message',
                contains('intent'),
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
      expect(found.length, greaterThanOrEqualTo(4));
    });
  });
}

/// One state-convention break, with the file and line that broke it.
typedef _Violation = ({String file, int line, String kind, String message});

/// Reports every provider, setState, thin-widget or controller break under
/// [root].
List<_Violation> _findStateViolations(Directory root) {
  if (!root.existsSync()) {
    return const <_Violation>[];
  }
  final List<_Violation> found = <_Violation>[];
  for (final File file in _sources(root)) {
    final String relative = _relative(root, file);
    final String source = _withoutCommentsAndStrings(file.readAsStringSync());
    found.addAll(_providerViolations(relative, source));
    found.addAll(_setStateViolations(relative, source));
    found.addAll(_repositoryCallViolations(relative, source));
    found.addAll(_intentViolations(relative, source));
  }
  return found;
}

/// Providers that are not named `…Provider` or that sit outside the feature
/// their name belongs to (FE-STATE-03).
Iterable<_Violation> _providerViolations(String path, String source) sync* {
  final bool inProviderFile = path.endsWith('_providers.dart');
  final List<String> lines = source.split('\n');
  int depth = 0;
  for (int index = 0; index < lines.length; index++) {
    final String line = lines[index];
    if (depth == 0) {
      final Match? match = _topLevelVariable.firstMatch(line);
      if (match != null) {
        final String name = match.group(1)!;
        if (!name.startsWith('_')) {
          yield* _oneProvider(path, index + 1, name, inProviderFile);
        }
      }
    }
    depth += '{'.allMatches(line).length;
    depth -= '}'.allMatches(line).length;
  }
}

/// The naming and location rules for one public [name] on [path].
Iterable<_Violation> _oneProvider(
  String path,
  int line,
  String name,
  bool inProviderFile,
) sync* {
  final bool claimsToBeOne = name.toLowerCase().endsWith('provider');
  if (!inProviderFile && !claimsToBeOne) {
    return;
  }
  if (!name.endsWith('Provider')) {
    yield (
      file: path,
      line: line,
      kind: 'provider-name',
      message:
          '$path:$line: $name is a provider and must end in Provider '
          '(FE-CODE-02, FE-STATE-03)',
    );
    return;
  }
  final String? claimed = _featureClaimedBy(name);
  if (claimed == null) {
    return;
  }
  final String? home = _featureOfPath(path);
  if (home == claimed) {
    return;
  }
  yield (
    file: path,
    line: line,
    kind: 'provider-home',
    message:
        '$path:$line: $name belongs in features/$claimed/, not '
        '${home == null ? path : 'features/$home/'} (FE-STATE-03)',
  );
}

/// `setState` outside `core/widgets/` and animation code (FE-STATE-01).
Iterable<_Violation> _setStateViolations(String path, String source) sync* {
  if (_setStateAllowed(path)) {
    return;
  }
  final List<String> lines = source.split('\n');
  for (int index = 0; index < lines.length; index++) {
    if (_setState.hasMatch(lines[index])) {
      yield (
        file: path,
        line: index + 1,
        kind: 'set-state',
        message:
            '$path:${index + 1}: setState belongs in core/widgets/ or '
            'animation code (FE-STATE-01)',
      );
    }
  }
}

/// A presentation widget invoking a repository itself (FE-STATE-04).
Iterable<_Violation> _repositoryCallViolations(
  String path,
  String source,
) sync* {
  if (!_isWidgetSource(path)) {
    return;
  }
  final List<String> lines = source.split('\n');
  for (int index = 0; index < lines.length; index++) {
    if (_repositoryCall.hasMatch(lines[index])) {
      yield (
        file: path,
        line: index + 1,
        kind: 'repository-call',
        message:
            '$path:${index + 1}: a widget calls a repository; call an '
            'intent method on the controller instead (FE-STATE-04)',
      );
    }
  }
}

/// A `*Controller` that publishes no public method for a widget to call.
Iterable<_Violation> _intentViolations(String path, String source) sync* {
  for (final Match match in _controllerClass.allMatches(source)) {
    final String name = match.group(1)!;
    final String body = _classBody(source, match.start);
    if (_publicMethod.hasMatch(body)) {
      continue;
    }
    final int line = source.substring(0, match.start).split('\n').length;
    yield (
      file: path,
      line: line,
      kind: 'intent',
      message:
          '$path:$line: $name must expose an intent method; widgets call '
          'those, never the repository (FE-STATE-04)',
    );
  }
}

/// Whether [path] may call `setState`.
bool _setStateAllowed(String path) {
  return path.startsWith('core/widgets/') || path.contains('animation');
}

/// A presentation file that is a widget, not a controller or a provider list.
bool _isWidgetSource(String path) {
  return path.contains('/presentation/') &&
      !path.endsWith('_controller.dart') &&
      !path.endsWith('_providers.dart');
}

/// The feature folder [path] sits in, or null when it is not under features/.
String? _featureOfPath(String path) {
  final Match? match = RegExp(r'^features/([^/]+)/').firstMatch(path);
  return match?.group(1);
}

/// The feature [providerName] is named for, or null when it names none.
String? _featureClaimedBy(String providerName) {
  String stem = providerName;
  if (stem.endsWith('Provider')) {
    stem = stem.substring(0, stem.length - 'Provider'.length);
  }
  final List<String> ordered = _features.toList()
    ..sort((String a, String b) => b.length.compareTo(a.length));
  for (final String feature in ordered) {
    if (_camelStartsWith(stem, feature)) {
      return feature;
    }
  }
  return null;
}

/// Whether [stem] is [feature] or [feature] plus a new camel-case word.
bool _camelStartsWith(String stem, String feature) {
  if (!stem.toLowerCase().startsWith(feature)) {
    return false;
  }
  if (stem.length == feature.length) {
    return true;
  }
  final int next = stem.codeUnitAt(feature.length);
  return next >= 65 && next <= 90;
}

/// The `{…}` that opens at the class starting at [start], or the rest of
/// [source] when the class has no body.
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

/// Feature directory names under [lib].
Set<String> _featureNames(Directory lib) {
  final Directory features = Directory('${lib.path}/features');
  if (!features.existsSync()) {
    return const <String>{};
  }
  return <String>{
    for (final FileSystemEntity entity in features.listSync())
      if (entity is Directory) _basename(entity.uri),
  };
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
