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

/// The local plugin package the shipped pubspec depends on by path, whose
/// own pubspec every throwaway tree needs too (FE-STR-01, rule 5).
const String _whisperPubspec = 'packages/tapture_whisper/pubspec.yaml';

/// One checked-in tree per local-package rule (dev-plan task 102).
const String _localFixtures = 'test/tool/fixtures/dependencies';

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
        _fixture(pubspec: _realPubspecWithout('url_launcher: 6.3.3')).path,
      );
      several = await _check(
        _fixture(
          pubspec: _replaceFirst(
            _realPubspec().replaceAll(
              '  flutter_lints: ^6.0.0',
              '  chopper: ^8.0.0\n  mockito: ^5.4.0',
            ),
            RegExp('  flutter:\\r?\\n    sdk: flutter'),
            '  dio: ^5.0.0',
          ).replaceAll(RegExp('\\n  url_launcher: 6\\.3\\.3\\r?'), ''),
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
            'url_launcher is approved but pubspec.yaml no longer asks for it',
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
          contains('url_launcher is approved but pubspec.yaml no longer asks'),
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
      expect(several.summary, 'dependencies: 3 error(s), 1 warning(s)');
      expect(removed.summary, 'dependencies: 0 error(s), 1 warning(s)');
    });

    test('a local package dependency counts as declared, not as stale', () {
      expect(project.violations, isNot(contains(contains('ffi is approved'))));
      expect(
        several.violations,
        isNot(contains(contains('flutter is approved but'))),
      );
    });
  });

  group('local packages (FE-STR-01)', () {
    late _Run localOk;
    late _Run outside;
    late _Run unpinned;
    late _Run mismatch;
    late _Run hook;
    late _Run unapprovedDependency;
    late _Run together;

    setUpAll(() async {
      localOk = await _check('$_localFixtures/local_ok');
      outside = await _check('$_localFixtures/outside_packages');
      unpinned = await _check('$_localFixtures/unpinned_path');
      mismatch = await _check('$_localFixtures/version_mismatch');
      hook = await _check('$_localFixtures/build_hook');
      unapprovedDependency = await _check('$_localFixtures/package_unapproved');
      together = await _check(_everyLocalViolation().path);
    });

    test('a pinned, approved path dependency under packages/ passes', () {
      expect(localOk.violations, isEmpty);
      expect(localOk.exitCode, 0);
    });

    test('a path outside packages/ fails at its path: line', () {
      expect(
        outside.violations,
        contains(
          allOf(
            startsWith('pubspec.yaml:12: error:'),
            contains('which is not under packages/'),
          ),
        ),
      );
      expect(outside.exitCode, 1);
    });

    test('a path dependency with no nested version: fails', () {
      expect(
        unpinned.violations,
        contains(
          allOf(
            startsWith('pubspec.yaml:11: error:'),
            contains('a path dependency with no nested version:'),
          ),
        ),
      );
      expect(unpinned.exitCode, 1);
    });

    test("a version that is not the package's own fails at version:", () {
      expect(
        mismatch.violations,
        contains(
          allOf(
            startsWith('pubspec.yaml:13: error:'),
            contains('packages/local_plugin/pubspec.yaml:3 declares 1.0.1'),
          ),
        ),
      );
      expect(mismatch.exitCode, 1);
    });

    test('a package with a hook/ folder fails', () {
      expect(
        hook.violations,
        contains(
          allOf(
            startsWith('pubspec.yaml:11: error:'),
            contains('has a Dart build hook (packages/local_plugin/hook/)'),
          ),
        ),
      );
      expect(hook.exitCode, 1);
    });

    test('an unapproved dependency of the package fails in its pubspec', () {
      expect(
        unapprovedDependency.violations,
        contains(
          allOf(
            startsWith('packages/local_plugin/pubspec.yaml:13: error:'),
            contains('http is not on the allowlist'),
          ),
        ),
      );
      expect(unapprovedDependency.exitCode, 1);
    });

    test('every local-package violation is reported in one run', () {
      expect(
        together.violations,
        containsAll(<Matcher>[
          contains('outside_packages is a path dependency on shared/'),
          contains('unpinned_path is a path dependency with no nested'),
          contains('packages/version_mismatch/pubspec.yaml:3 declares 1.0.1'),
          contains('build_hook has a Dart build hook'),
          startsWith(
            'packages/package_unapproved/pubspec.yaml:13: error: http is '
            'not on the allowlist',
          ),
        ]),
      );
      for (final String violation in together.violations) {
        expect(
          violation,
          matches(RegExp('^[a-z_/.]+:[0-9]+: (error|warning):')),
        );
      }
      expect(together.exitCode, 1);
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
    <String>['run', '--verbosity=error', _checker, root],
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
  File('${root.path}/$_whisperPubspec')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(File(_whisperPubspec).readAsStringSync());
  return root;
}

/// The fixture cases that each break one local-package rule, and the folder
/// under the case that holds its package.
const Map<String, String> _brokenLocalCases = <String, String>{
  'outside_packages': 'shared',
  'unpinned_path': 'packages',
  'version_mismatch': 'packages',
  'build_hook': 'packages',
  'package_unapproved': 'packages',
};

/// One throwaway tree that breaks every local-package rule at once: each
/// broken fixture's package copied in under its case name, and one path
/// dependency per case, written the way that case writes it.
Directory _everyLocalViolation() {
  final Directory root = Directory.systemTemp.createTempSync(
    'tapture_dependencies_',
  );
  addTearDown(() => root.deleteSync(recursive: true));
  final StringBuffer pubspec = StringBuffer(
    'name: fixture_app\n'
    'publish_to: none\n'
    '\n'
    'environment:\n'
    '  sdk: ^3.12.2\n'
    '\n'
    'dependencies:\n'
    '  flutter:\n'
    '    sdk: flutter\n',
  );
  final StringBuffer allowlist = StringBuffer(
    'packages:\n'
    '  flutter:\n'
    '    version: sdk\n'
    '  ffi:\n'
    '    version: 2.2.0\n',
  );
  for (final MapEntry<String, String> broken in _brokenLocalCases.entries) {
    final String folder = '${broken.value}/${broken.key}';
    _copyTree(
      Directory('$_localFixtures/${broken.key}/${broken.value}/local_plugin'),
      Directory('${root.path}/$folder'),
    );
    pubspec
      ..write('  ${broken.key}:\n')
      ..write('    path: $folder\n');
    if (broken.key != 'unpinned_path') {
      pubspec.write('    version: 1.0.0+1\n');
    }
    allowlist
      ..write('  ${broken.key}:\n')
      ..write('    version: 1.0.0+1\n');
  }
  File('${root.path}/$_pubspec').writeAsStringSync(pubspec.toString());
  File('${root.path}/$_allowlist')
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(allowlist.toString());
  return root;
}

/// Copies every file under [from] to the same place under [to].
void _copyTree(Directory from, Directory to) {
  final String base = from.absolute.path.replaceAll(r'\', '/');
  for (final FileSystemEntity entity in from.listSync(recursive: true)) {
    if (entity is File) {
      final String relative = entity.absolute.path
          .replaceAll(r'\', '/')
          .substring(base.length + 1);
      File('${to.path}/$relative')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(entity.readAsBytesSync());
    }
  }
}

String _realPubspec() => File(_pubspec).readAsStringSync();

/// Replaces the first match, so a Windows checkout's extra SDK blocks stay.
String _replaceFirst(String source, RegExp from, String to) {
  final Match? match = from.firstMatch(source);
  if (match == null) {
    return source;
  }
  return source.replaceRange(match.start, match.end, to);
}

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
