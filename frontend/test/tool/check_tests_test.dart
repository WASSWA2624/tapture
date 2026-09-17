@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The checker under test, driven as a process.
const String _checker = 'tool/check_tests.dart';

/// A dart file that is enough for the checker to see it.
const String _source = 'class CaptureSession {}\n';

/// A test file that is enough to count as coverage.
const String _test = 'void main() {}\n';

void main() {
  group('the shipped sources', () {
    test('owe no missing test under --strict', () async {
      final _Run run = await _check(<String>['--strict']);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
      expect(run.summary, contains('every owed file has a test'));
    });

    test(
      'a directory that is not there is said so rather than passing',
      () async {
        final _Run run = await _check(<String>[
          '--strict',
          'no_such_directory',
        ]);

        expect(
          run.violations,
          contains(contains('there is no directory here to check')),
        );
        expect(run.exitCode, 1);
      },
    );
  });

  group(
    'a fixture with one exempt, one covered and one uncovered file per layer',
    () {
      late Directory root;

      setUp(() {
        root = _layersTree();
      });

      test(
        'a domain service without a test fails --strict and names the path',
        () async {
          final _Run run = await _check(<String>['--strict', root.path]);

          expect(
            run.violations,
            contains(
              contains(
                'lib/features/capture/domain/session_clock.dart:0: missing '
                'test/features/capture/domain/session_clock_test.dart',
              ),
            ),
          );
          expect(run.exitCode, 1);
        },
      );

      test(
        'without --strict the same missing file is reported and the run passes',
        () async {
          final _Run run = await _check(<String>[root.path]);

          expect(run.violations, contains(contains('session_clock.dart')));
          expect(run.exitCode, 0);
        },
      );

      test('a barrel produces no finding', () async {
        final _Run run = await _check(<String>['--strict', root.path]);

        expect(
          run.violations.join('\n'),
          isNot(contains('domain/domain.dart')),
        );
        expect(run.violations.join('\n'), isNot(contains('data/data.dart')));
        expect(
          run.violations.join('\n'),
          isNot(contains('widgets/widgets.dart')),
        );
        expect(
          run.stdout,
          contains(RegExp(r'domain\s+\d+\s+\d+\s+\d+\s+[1-9]')),
        );
      });

      test('a generated file produces no finding', () async {
        final _Run run = await _check(<String>['--strict', root.path]);

        expect(
          run.violations.join('\n'),
          isNot(contains('capture_dao.g.dart')),
        );
      });

      test('an integration-covered screen produces no finding', () async {
        final _Run run = await _check(<String>['--strict', root.path]);

        expect(
          run.violations.join('\n'),
          isNot(contains('capture_screen.dart')),
        );
      });

      test('a covered file per layer produces no finding', () async {
        final _Run run = await _check(<String>['--strict', root.path]);

        expect(
          run.violations.join('\n'),
          isNot(contains('capture_session.dart')),
        );
        expect(
          run.violations.join('\n'),
          isNot(contains('capture_repository.dart')),
        );
        expect(run.violations.join('\n'), isNot(contains('pressable.dart')));
        expect(
          run.violations.join('\n'),
          isNot(contains('records_screen.dart')),
        );
      });

      test('the uncovered file in every layer is reported', () async {
        final _Run run = await _check(<String>['--strict', root.path]);

        expect(run.violations, contains(contains('session_clock.dart')));
        expect(run.violations, contains(contains('orphan_repository.dart')));
        expect(run.violations, contains(contains('bare_label.dart')));
        expect(run.violations, contains(contains('settings_screen.dart')));
        expect(run.violations, hasLength(4));
      });

      test('the table counts by layer', () async {
        final _Run run = await _check(<String>['--strict', root.path]);

        expect(run.stdout, contains('layer'));
        expect(run.stdout, contains('domain'));
        expect(run.stdout, contains('data'));
        expect(run.stdout, contains('widgets'));
        expect(run.stdout, contains('screens'));
        expect(run.summary, contains('4 missing'));
      });
    },
  );

  group('reporting', () {
    test('every missing file is named, not only the first', () async {
      final _Run run = await _check(<String>['--strict', _layersTree().path]);

      expect(run.violations, hasLength(greaterThan(1)));
    });

    test('every finding names the file and the line', () async {
      final _Run run = await _check(<String>['--strict', _layersTree().path]);

      expect(run.violations, isNotEmpty);
      for (final String violation in run.violations) {
        expect(violation, matches(RegExp(r'^lib/[\w./-]+\.dart:\d+: \S')));
      }
    });

    test('an argument it does not understand exits 1', () async {
      final _Run run = await _check(<String>['--bogus']);

      expect(run.exitCode, 1);
      expect(run.violations, contains(contains('unrecognised argument')));
      expect(run.violations, contains(contains('--strict')));
    });
  });
}

/// A project with one exempt, one covered and one uncovered file in each layer.
Directory _layersTree() {
  return _project(<String, String>{
    'lib/features/capture/domain/domain.dart': 'library;\n',
    'lib/features/capture/domain/capture_session.dart': _source,
    'lib/features/capture/domain/session_clock.dart': 'class SessionClock {}\n',
    'test/features/capture/domain/capture_session_test.dart': _test,
    'lib/features/capture/data/data.dart': 'library;\n',
    'lib/features/capture/data/capture_dao.g.dart':
        '// generated\nclass CaptureDao {}\n',
    'lib/features/capture/data/capture_repository.dart':
        'class CaptureRepository {}\n',
    'lib/features/capture/data/orphan_repository.dart':
        'class OrphanRepository {}\n',
    'test/features/capture/data/capture_repository_test.dart': _test,
    'lib/core/widgets/widgets.dart': 'library;\n',
    'lib/core/widgets/pressable.dart': 'class Pressable {}\n',
    'lib/core/widgets/bare_label.dart': 'class BareLabel {}\n',
    'test/core/widgets/pressable_test.dart': _test,
    'lib/features/capture/presentation/capture_screen.dart':
        'class CaptureScreen {}\n',
    'lib/features/records/presentation/records_screen.dart':
        'class RecordsScreen {}\n',
    'lib/features/settings/presentation/settings_screen.dart':
        'class SettingsScreen {}\n',
    'test/features/records/presentation/records_screen_test.dart': _test,
    'integration_test/capture_flow_test.dart':
        'void main() {\n  // pumps CaptureScreen\n}\n',
  });
}

/// Writes a throwaway project holding [files] at paths relative to its root.
Directory _project(Map<String, String> files) {
  final Directory root = Directory.systemTemp.createTempSync('tapture_tests_');
  addTearDown(() => root.deleteSync(recursive: true));
  for (final MapEntry<String, String> file in files.entries) {
    final File written = File('${root.path}/${file.key}');
    written.parent.createSync(recursive: true);
    written.writeAsStringSync(file.value);
  }
  return root;
}

Future<_Run> _check(List<String> args) async {
  final ProcessResult result = await Process.run(
    _dartExecutable(),
    <String>['run', _checker, ...args],
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
    output is String ? output : '',
  );
}

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

class _Run {
  const _Run(this.exitCode, this.violations, this.summary, this.stdout);

  final int exitCode;
  final List<String> violations;
  final String summary;
  final String stdout;
}
