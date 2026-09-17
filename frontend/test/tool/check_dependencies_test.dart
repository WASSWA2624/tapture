@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The checker under test, driven as a process.
///
/// Its contract is one function — `Future<int> main(List<String> args)` — so a
/// test that imported something to call would be testing an API the task says
/// must not exist. Running it is also what the build does, which makes the
/// exit code part of what these tests cover rather than an implementation
/// detail behind them.
const String _checker = 'tool/check_dependencies.dart';

/// The two files the checker compares, in the throwaway tree each case builds.
const String _pubspec = 'pubspec.yaml';
const String _allowlist = 'tool/allowlist.yaml';

void main() {
  group('the dependency allowlist', () {
    late _Run project;
    late _Run approved;
    late _Run unapproved;
    late _Run drifted;
    late _Run removed;
    late _Run several;
    late _Run bare;

    setUpAll(() async {
      project = await _check(Directory.current.path);
      approved = await _check(_fixture().path);
      unapproved = await _check(
        _fixture(
          pubspec: _realPubspec().replaceAll(
            '  flutter_lints: ^6.0.0',
            '  flutter_lints: ^6.0.0\n  chopper: ^8.0.0',
          ),
        ).path,
      );
      drifted = await _check(
        _fixture(
          pubspec: _realPubspec().replaceAll(
            'flutter_lints: ^6.0.0',
            'flutter_lints: ^5.0.0',
          ),
        ).path,
      );
      removed = await _check(
        _fixture(pubspec: _realPubspecWithout('flutter_lints: ^6.0.0')).path,
      );
      several = await _check(
        _fixture(
          pubspec: _realPubspec()
              .replaceAll(
                '  flutter_lints: ^6.0.0',
                '  chopper: ^8.0.0\n  mockito: ^5.4.0',
              )
              .replaceAll('  flutter:\n    sdk: flutter', '  dio: ^5.0.0'),
        ).path,
      );
      bare = await _check(
        Directory.systemTemp.createTempSync('tapture_dependencies_').path,
      );
    });

    test('the checked-in pubspec is approved', () {
      expect(project.violations, isEmpty);
      expect(project.exitCode, 0);
    });

    test('a tree holding the shipped files is approved', () {
      expect(approved.violations, isEmpty);
      expect(approved.exitCode, 0);
    });

    test('a package nobody approved fails the check', () {
      expect(
        unapproved.violations,
        contains(contains('chopper is not on the allowlist')),
      );
      expect(unapproved.exitCode, 1);
    });

    test('an unapproved package is told which rule it broke', () {
      expect(
        unapproved.violations,
        contains(
          contains('FE-FLOW-06: adding a package requires its own task'),
        ),
      );
    });

    test('a version that drifted from the allowlist fails the check', () {
      expect(
        drifted.violations,
        contains(
          contains(
            'flutter_lints asks for ^5.0.0; tool/allowlist.yaml approves '
            '^6.0.0',
          ),
        ),
      );
      expect(drifted.exitCode, 1);
    });

    test('a package that was removed is a warning, not an error', () {
      expect(
        removed.violations,
        contains(
          contains(
            'flutter_lints is approved but pubspec.yaml no longer asks for it',
          ),
        ),
      );
      expect(removed.violations, everyElement(contains(': warning: ')));
      expect(removed.exitCode, 0);
    });

    test('every violation is reported, not only the first', () {
      expect(
        several.violations,
        containsAll(<Matcher>[
          contains('chopper is not on the allowlist'),
          contains('mockito is not on the allowlist'),
          contains('dio is not on the allowlist'),
          contains('flutter is approved but pubspec.yaml no longer asks'),
        ]),
      );
      expect(several.exitCode, 1);
    });

    test('a tree with neither file is reported for both', () {
      expect(
        bare.violations,
        containsAll(<Matcher>[
          contains('pubspec.yaml:0: error: the project has no pubspec.yaml'),
          contains(
            'tool/allowlist.yaml:0: error: the project has no '
            'tool/allowlist.yaml',
          ),
        ]),
      );
      expect(bare.exitCode, 1);
    });

    test('every violation names the file and the line that must change', () {
      for (final String violation in <String>[
        ...unapproved.violations,
        ...drifted.violations,
        ...removed.violations,
        ...several.violations,
      ]) {
        expect(
          violation,
          matches(RegExp('^[a-z_/.]+:[0-9]+: (error|warning):')),
        );
      }
    });

    test('a violation says how hard it complains', () {
      expect(unapproved.violations, everyElement(contains(': error: ')));
      expect(drifted.violations, everyElement(contains(': error: ')));
    });

    test('a clean run says so rather than saying nothing', () {
      expect(
        project.summary,
        'dependencies: every direct dependency is approved and pinned',
      );
    });

    test('a run that found things counts them by severity', () {
      expect(several.summary, 'dependencies: 3 error(s), 2 warning(s)');
      expect(removed.summary, 'dependencies: 0 error(s), 1 warning(s)');
    });
  });
}

/// What one run of the checker reported.
class _Run {
  const _Run(this.exitCode, this.violations, this.summary);

  /// The exit code: 0 when nothing but a warning was found, 1 on any error.
  final int exitCode;

  /// One line per violation, as the checker wrote them.
  final List<String> violations;

  /// The closing line saying what the run concluded.
  final String summary;
}

/// Runs the checker over [root] and reads back what it found.
///
/// The output is decoded as UTF-8 rather than as whatever the host's console
/// codepage is, so a message carrying a character outside ASCII arrives as the
/// checker wrote it.
Future<_Run> _check(String root) async {
  final ProcessResult result = await Process.run(
    _dartExecutable(),
    <String>['run', _checker, root],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  final Object? errors = result.stderr;
  final Object? output = result.stdout;
  final List<String> violations = <String>[
    for (final String line in (errors is String ? errors : '').split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];
  return _Run(
    result.exitCode,
    violations,
    (output is String ? output : '').trim(),
  );
}

/// Builds a throwaway tree holding the two files the checker compares, each
/// defaulting to the copy this project actually ships, so a case proves the
/// checker notices a real entry changing rather than an invented one.
Directory _fixture({String? pubspec, String? allowlist}) {
  final Directory root = Directory.systemTemp.createTempSync(
    'tapture_dependencies_',
  );
  addTearDown(() => root.deleteSync(recursive: true));
  File('${root.path}/$_pubspec').writeAsStringSync(pubspec ?? _realPubspec());
  Directory('${root.path}/tool').createSync();
  File(
    '${root.path}/$_allowlist',
  ).writeAsStringSync(allowlist ?? _realAllowlist());
  return root;
}

String _realPubspec() => File(_pubspec).readAsStringSync();

String _realAllowlist() => File(_allowlist).readAsStringSync();

/// The shipped pubspec with one line deleted.
String _realPubspecWithout(String line) {
  return _realPubspec()
      .split('\n')
      .where((String each) => each.trim() != line)
      .join('\n');
}

/// The Dart command line, which is not the executable running this test:
/// `flutter test` runs it inside the Flutter tester.
String _dartExecutable() {
  final String suffix = Platform.isWindows ? '.exe' : '';
  final String running = Platform.resolvedExecutable;
  if (Uri.file(running).pathSegments.last == 'dart$suffix') {
    return running;
  }
  final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
  return flutterRoot == null
      ? 'dart$suffix'
      : '$flutterRoot/bin/cache/dart-sdk/bin/dart$suffix';
}
