@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The checker under test, driven as a process.
///
/// Its contract is one function — `Future<int> main(List<String> args)` — so a
/// test that imported something to call would be testing an API the task says
/// must not exist. Running it is also what the build does, which puts the exit
/// code inside what these tests cover rather than behind it.
const String _checker = 'tool/check_plan.dart';

/// The plan this repository actually ships, which the checker reads by
/// default and which has to hold together.
const String _realPlan = '../dev-plan';

void main() {
  group('the shipped plan', () {
    test('holds together', () async {
      final _Run run = await _check(<String>[]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
      expect(run.summary, contains('tasks, numbering and links intact'));
    });

    test('is what the checker reads when it is given no argument', () async {
      final _Run implicit = await _check(<String>[]);
      final _Run explicit = await _check(<String>[_realPlan]);

      expect(implicit.summary, explicit.summary);
    });
  });

  group('a plan that contradicts itself', () {
    test('a file renumbered without its heading is reported', () async {
      final Directory plan = _plan(<_Fixture>[
        _task(1, 'alpha'),
        _task(2, 'beta', heading: 7),
      ]);

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(
          contains(
            'the heading says task 007 and the filename says 002; renaming a '
            'file means renaming its heading',
          ),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('a file with no numbered heading at all is reported', () async {
      final Directory plan = _plan(<_Fixture>[
        _task(1, 'alpha'),
        (name: '002-beta.md', body: '## Implement\n\nx\n'),
      ]);

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(contains('no heading of the form `# 002 — Title`')),
      );
      expect(run.exitCode, 1);
    });

    test('a dependency on a higher-numbered task is reported', () async {
      final Directory plan = _plan(<_Fixture>[
        _task(1, 'alpha'),
        _task(2, 'beta', dependsOn: <int>[3]),
        _task(3, 'gamma'),
      ]);

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(
          contains(
            'depends on task 003, which is not lower than 002; the plan is '
            'worked in order',
          ),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('a dependency on itself is reported', () async {
      final Directory plan = _plan(<_Fixture>[
        _task(1, 'alpha'),
        _task(2, 'beta', dependsOn: <int>[2]),
      ]);

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(contains('depends on task 002, which is not lower than 002')),
      );
    });

    test('a dependency link naming no file is reported', () async {
      final Directory plan = _plan(<_Fixture>[
        _task(1, 'alpha'),
        (
          name: '002-beta.md',
          body:
              '# 002 — Beta\n\n**Depends on** [001](001-missing.md)\n\n'
              '## Implement\n\nx\n\n## Files\n\n- y\n\n'
              '## Definition of done\n\n- [ ] Done.\n',
        ),
      ]);

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(
          contains('the dependency link 001-missing.md names no file on disk'),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('a number used twice is reported', () async {
      final Directory plan = _plan(<_Fixture>[
        _task(1, 'alpha'),
        _task(2, 'beta'),
        _task(2, 'gamma'),
      ]);

      final _Run run = await _check(<String>[plan.path]);

      expect(run.violations, contains(contains('a number names one task')));
      expect(run.exitCode, 1);
    });

    test('a slug used twice is reported', () async {
      final Directory plan = _plan(<_Fixture>[
        _task(1, 'alpha'),
        _task(2, 'alpha'),
      ]);

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(contains('the slug alpha is also plan/01-phase/001-alpha.md')),
      );
      expect(run.exitCode, 1);
    });

    test('a hole in the numbering is reported', () async {
      final Directory plan = _plan(<_Fixture>[
        _task(1, 'alpha'),
        _task(3, 'gamma'),
      ]);

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(
          contains(
            'the plan runs to 003 but has no task 002; the numbering has a '
            'hole in it',
          ),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('a hole the ledger retires is not reported', () async {
      final Directory plan = _plan(<_Fixture>[
        _task(1, 'alpha'),
        _task(3, 'gamma'),
      ], ledger: _ledger(<String>['| 002 | Merged into 001. |']));

      final _Run run = await _check(<String>[plan.path]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });

    test('a range in the ledger retires every number in it', () async {
      final Directory plan = _plan(<_Fixture>[
        _task(1, 'alpha'),
        _task(5, 'epsilon'),
      ], ledger: _ledger(<String>['| 002–004 | Merged into 001. |']));

      final _Run run = await _check(<String>[plan.path]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });

    test('a hole the ledger does not retire is still reported', () async {
      final Directory plan = _plan(<_Fixture>[
        _task(1, 'alpha'),
        _task(4, 'delta'),
      ], ledger: _ledger(<String>['| 002 | Merged into 001. |']));

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(
          contains(
            'has no task 003; the numbering has a hole in it, and '
            'RETIRED.md does not retire it',
          ),
        ),
      );
      expect(run.violations, isNot(contains(contains('has no task 002'))));
      expect(run.exitCode, 1);
    });

    test('a retired number a file still carries is reported', () async {
      final Directory plan = _plan(<_Fixture>[
        _task(1, 'alpha'),
        _task(2, 'beta'),
      ], ledger: _ledger(<String>['| 002 | Merged into 001. |']));

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(
          contains(
            'task 002 is retired in RETIRED.md, so no file may carry that '
            'number again',
          ),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('a row outside the ledger section retires nothing', () async {
      final Directory plan = _plan(
        <_Fixture>[_task(1, 'alpha'), _task(3, 'gamma')],
        ledger:
            '# Retired task numbers\n\n## What absorbed what\n\n'
            '| Was | Is now |\n| :--- | :--- |\n'
            '| 002 | Merged into 001. |\n',
      );

      final _Run run = await _check(<String>[plan.path]);

      expect(run.violations, contains(contains('has no task 002')));
      expect(run.exitCode, 1);
    });

    test('each required section that is missing is reported', () async {
      final Directory plan = _plan(<_Fixture>[
        (name: '001-alpha.md', body: '# 001 — Alpha\n\nNothing here.\n'),
      ]);

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        containsAll(<Matcher>[
          contains('no `## Implement` section'),
          contains('no `## Files` section'),
          contains('no `## Definition of done` section'),
        ]),
      );
      expect(run.exitCode, 1);
    });

    test('a Definition of done with nothing to tick is reported', () async {
      final Directory plan = _plan(<_Fixture>[
        (
          name: '001-alpha.md',
          body:
              '# 001 — Alpha\n\n## Implement\n\nx\n\n## Files\n\n- y\n\n'
              '## Definition of done\n\nJust prose, nothing to tick.\n\n'
              '## Out of scope\n\nNothing.\n',
        ),
      ]);

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(contains('the Definition of done has no checkbox')),
      );
      expect(run.exitCode, 1);
    });

    test('a ticked Definition of done counts as a checkbox', () async {
      final Directory plan = _plan(<_Fixture>[
        _task(1, 'alpha', done: '- [x] Already done.'),
      ]);

      final _Run run = await _check(<String>[plan.path]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });

    test('every violation is reported, not only the first', () async {
      final Directory plan = _plan(<_Fixture>[
        _task(1, 'alpha'),
        _task(2, 'beta', heading: 9),
        _task(4, 'delta', dependsOn: <int>[5]),
        _task(5, 'epsilon'),
      ]);

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        containsAll(<Matcher>[
          contains('the heading says task 009 and the filename says 002'),
          contains('has no task 003'),
          contains('depends on task 005, which is not lower than 004'),
        ]),
      );
      expect(run.exitCode, 1);
    });

    test('every violation names the file and the line', () async {
      final Directory plan = _plan(<_Fixture>[
        _task(1, 'alpha'),
        _task(2, 'beta', heading: 9),
        _task(4, 'delta', dependsOn: <int>[5]),
        _task(5, 'epsilon'),
      ]);

      final _Run run = await _check(<String>[plan.path]);

      for (final String violation in run.violations) {
        expect(violation, matches(RegExp(r'^[\w\-./]+:\d+: \S')));
      }
    });
  });

  group('a plan that is not there', () {
    test('a directory that does not exist is reported', () async {
      final Directory root = Directory.systemTemp.createTempSync(
        'tapture_plan_',
      );
      addTearDown(() => root.deleteSync(recursive: true));

      final _Run run = await _check(<String>['${root.path}/absent']);

      expect(
        run.violations,
        contains(contains('there is no plan directory here to check')),
      );
      expect(run.exitCode, 1);
    });

    test('a directory holding no task file is reported', () async {
      final Directory root = Directory.systemTemp.createTempSync(
        'tapture_plan_',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      File('${root.path}/README.md').writeAsStringSync('# Not a task\n');

      final _Run run = await _check(<String>[root.path]);

      expect(
        run.violations,
        contains(contains('holds no NNN-slug.md task file')),
      );
      expect(run.exitCode, 1);
    });

    test('a README beside the tasks is not mistaken for one', () async {
      final Directory plan = _plan(<_Fixture>[_task(1, 'alpha')]);
      File('${plan.path}/01-phase/README.md').writeAsStringSync('# Phase\n');

      final _Run run = await _check(<String>[plan.path]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });
  });
}

/// One file to write into a throwaway plan.
typedef _Fixture = ({String name, String body});

/// What one run of the checker reported.
class _Run {
  const _Run(this.exitCode, this.violations, this.summary);

  /// The exit code: 0 when the plan holds together, 1 on any structural error.
  final int exitCode;

  /// One line per violation, as the checker wrote them.
  final List<String> violations;

  /// The closing line saying what the run concluded.
  final String summary;
}

/// A well-formed task file, with one thing optionally wrong with it.
///
/// Defaulting to a file that passes is what lets each case break exactly one
/// thing and see only that reported.
_Fixture _task(
  int number,
  String slug, {
  int? heading,
  List<int> dependsOn = const <int>[],
  String done = '- [ ] Done.',
}) {
  final String padded = number.toString().padLeft(3, '0');
  final String claimed = (heading ?? number).toString().padLeft(3, '0');
  final String links = dependsOn
      .map((int target) {
        final String targetPadded = target.toString().padLeft(3, '0');
        return '[$targetPadded]($targetPadded-${_slugFor(target)}.md)';
      })
      .join(', ');
  final String depends = links.isEmpty ? '' : '  |  **Depends on** $links';
  return (
    name: '$padded-$slug.md',
    body:
        '# $claimed — ${slug[0].toUpperCase()}${slug.substring(1)}\n\n'
        '**Phase** 01 · Fixtures$depends\n\n'
        '## Implement\n\nDo the thing.\n\n'
        '## Files\n\n- `frontend/lib/app/app.dart` (edit)\n\n'
        '## Definition of done\n\n$done\n\n'
        '## Out of scope\n\nAnything else.\n',
  );
}

/// The slug a fixture task of a given number carries, so a dependency link
/// points at the file the fixture actually writes.
String _slugFor(int number) {
  const List<String> slugs = <String>[
    'alpha',
    'beta',
    'gamma',
    'delta',
    'epsilon',
  ];
  return slugs[(number - 1) % slugs.length];
}

/// Writes a throwaway plan holding [fixtures] in one phase folder, and the
/// [ledger] of retired numbers beside them when there is one.
Directory _plan(List<_Fixture> fixtures, {String? ledger}) {
  final Directory root = Directory.systemTemp.createTempSync('tapture_plan_');
  addTearDown(() => root.deleteSync(recursive: true));
  final Directory plan = Directory('${root.path}/plan/01-phase')
    ..createSync(recursive: true);
  for (final _Fixture fixture in fixtures) {
    File('${plan.path}/${fixture.name}').writeAsStringSync(fixture.body);
  }
  if (ledger != null) {
    File('${root.path}/plan/RETIRED.md').writeAsStringSync(ledger);
  }
  return Directory('${root.path}/plan');
}

/// A `RETIRED.md` whose table holds [rows].
///
/// The prose around the table is what the real ledger carries, so a fixture
/// that parses only because it is bare would prove nothing.
String _ledger(List<String> rows) {
  return '# Retired task numbers\n\n'
      'A merged task takes the lowest number of the range it absorbs. The rest '
      'are retired rather than reused.\n\n'
      '## Retired numbers\n\n'
      '| Numbers | Retired because |\n| :--- | :--- |\n'
      '${rows.join('\n')}\n';
}

/// Runs the checker with [args] and reads back what it found.
///
/// The output is decoded as UTF-8 rather than as whatever the host's console
/// codepage is: the messages carry em dashes, and on Windows the default
/// decoding turns one into three characters that match nothing.
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
  );
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
