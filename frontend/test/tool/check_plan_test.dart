@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The checker under test, driven as a process.
///
/// Its contract is one function — `Future<int> main(List<String> args)` — so
/// running it is also what the build does, which puts the exit code inside
/// what these tests cover rather than behind it.
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

  group('a plan that holds together', () {
    test('passes with step files and a step folder', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[
          _task(1),
          _task(2, dependsOn: '[001](01-setup.md)'),
        ]),
        '02-final/02-alpha.md': _fileTask(
          3,
          dependsOn: '[002](../01-setup.md)',
        ),
        '02-final/03-beta.md': _fileTask(4, dependsOn: '[003](02-alpha.md)'),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
      expect(run.summary, 'plan: 2 steps, 4 tasks, numbering and links intact');
    });

    test('a ticked Definition of done counts as a checkbox', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[
          _task(1, done: '- [x] Already done.'),
        ]),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });

    test('headings inside a fenced block are not tasks', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[
          _task(1, after: '```text\n## 777 — Not a task\n# Nor a step\n```'),
        ]),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(run.violations, isEmpty);
      expect(run.exitCode, 0);
    });
  });

  group('a plan that contradicts itself', () {
    test('a step file renamed without its heading is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(7, <String>[_task(1)]),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(
          contains(
            'plan/01-setup.md:1: the heading says step 07 and the filename '
            'says 01; renaming a file means renaming its heading',
          ),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('a step file with no step heading is reported', () async {
      final Directory plan = _plan(<String, String>{'01-setup.md': _task(1)});

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(contains('no heading of the form `# NN — Step title`')),
      );
      expect(run.exitCode, 1);
    });

    test('a hole in the step numbering is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[_task(1)]),
        '03-later.md': _step(3, <String>[_task(2)]),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(
          contains(
            'the plan runs to step 03 but has no step 02; steps are numbered '
            'consecutively from 01',
          ),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('a step number used by a file and a folder is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[_task(1)]),
        '01-final/01-alpha.md': _fileTask(2),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(run.violations, contains(contains('a number names one step')));
      expect(run.exitCode, 1);
    });

    test('a step folder prompt numbered out of sequence is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[_task(1)]),
        '02-final/02-alpha.md': _fileTask(2),
        '02-final/04-beta.md': _fileTask(3),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(
          contains(
            'plan/02-final/04-beta.md:0: the file is numbered 04 where 03 '
            'comes next; prompt files in a step folder are numbered on from '
            'the step number, 02',
          ),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('a step folder prompt with no task heading is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[_task(1)]),
        '02-final/02-alpha.md': '## Implement\n\nx\n',
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(contains('no heading of the form `# NNN — Title`')),
      );
      expect(run.exitCode, 1);
    });

    test('a stray file beside the steps is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[_task(1)]),
        'README.md': '# Plan\n',
        '02-final/02-alpha.md': _fileTask(2),
        '02-final/README.md': '# Final\n',
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        containsAll(<Matcher>[
          contains(
            'plan/README.md:0: only NN-slug.md step files and NN-slug/ step '
            'folders belong in the plan',
          ),
          contains(
            'plan/02-final/README.md:0: only NN-slug.md prompt files belong '
            'in a step folder',
          ),
        ]),
      );
      expect(run.exitCode, 1);
    });

    test('a level-two heading after the tasks begin is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[
          _task(1),
          '## Notes\n\nLoose prose.\n',
        ]),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(
          contains('after the first task every `## ` heading starts a task'),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('written position metadata is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[
          _task(1).replaceFirst(
            '### Implement',
            '**Implementation step:** 01.01\n\n### Implement',
          ),
        ]),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(contains('positions are no longer written into prompts')),
      );
      expect(run.exitCode, 1);
    });

    test(
      'a dependency on a later implementation position is reported',
      () async {
        final Directory plan = _plan(<String, String>{
          '01-setup.md': _step(1, <String>[
            _task(1),
            _task(2, dependsOn: '[003](01-setup.md)'),
            _task(3),
          ]),
        });

        final _Run run = await _check(<String>[plan.path]);

        expect(
          run.violations,
          contains(
            contains(
              'depends on task 003, which does not appear earlier than 002 in '
              'the plan; the plan is worked in order',
            ),
          ),
        );
        expect(run.exitCode, 1);
      },
    );

    test('a dependency on itself is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[
          _task(1),
          _task(2, dependsOn: '[002](01-setup.md)'),
        ]),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(
          contains(
            'depends on task 002, which does not appear earlier than 002',
          ),
        ),
      );
    });

    test('a dependency link naming no file is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[
          _task(1),
          _task(2, dependsOn: '[001](01-missing.md)'),
        ]),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(
          contains('the dependency link 01-missing.md names no file on disk'),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('a dependency link naming the wrong file is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[_task(1)]),
        '02-next.md': _step(2, <String>[
          _task(2, dependsOn: '[001](02-next.md)'),
        ]),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(
          contains(
            'the dependency link 02-next.md does not hold task 001, which is '
            'in plan/01-setup.md',
          ),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('a number used twice is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[
          _task(1),
          _task(2),
          _task(2, title: 'Gamma'),
        ]),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(run.violations, contains(contains('a number names one task')));
      expect(run.exitCode, 1);
    });

    test('a title used twice is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[
          _task(1, title: 'Same'),
          _task(2, title: 'same'),
        ]),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(
          contains('the title "same" is also task 001; a title names one task'),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('a slug used twice is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[_task(1)]),
        '02-final/02-alpha.md': _fileTask(2),
        '02-final/03-alpha.md': _fileTask(3),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(
          contains(
            'the slug alpha is also plan/02-final/02-alpha.md; a slug names one task',
          ),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('a hole in the task numbering is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[_task(1), _task(3)]),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(
          contains(
            'the plan runs to task 003 but has no task 002; the task numbering '
            'has a hole in it',
          ),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('each required section that is missing is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>['## 001 — Alpha\n\nNothing here.\n']),
        '02-final/02-beta.md': '# 002 — Beta\n\nNothing here.\n',
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        containsAll(<Matcher>[
          contains('plan/01-setup.md:5: no `### Implement` section'),
          contains('no `### Files` section'),
          contains('no `### Definition of done` section'),
          contains('plan/02-final/02-beta.md:1: no `## Implement` section'),
        ]),
      );
      expect(run.exitCode, 1);
    });

    test('a Definition of done with nothing to tick is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[
          _task(1, done: 'Just prose, nothing to tick.'),
        ]),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(contains('the Definition of done has no checkbox')),
      );
      expect(run.exitCode, 1);
    });

    test('a malformed checkbox is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[
          _task(1, done: '- [ ] Fine.\n- [y] Not fine.'),
        ]),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(
          contains('malformed Definition of done checkbox: - [y] Not fine.'),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('a started marker spelled any other way is reported', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(1, <String>[
          _task(1).replaceFirst(
            '### Implement',
            '**Implementation started:** yes\n\n### Implement',
          ),
        ]),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        contains(contains('write exactly **Implementation started:** Yes')),
      );
      expect(run.exitCode, 1);
    });

    test('every violation is reported, with its file and line', () async {
      final Directory plan = _plan(<String, String>{
        '01-setup.md': _step(9, <String>[
          _task(1),
          _task(3, dependsOn: '[004](01-setup.md)'),
          _task(4),
        ]),
      });

      final _Run run = await _check(<String>[plan.path]);

      expect(
        run.violations,
        containsAll(<Matcher>[
          contains('the heading says step 09 and the filename says 01'),
          contains('has no task 002'),
          contains(
            'depends on task 004, which does not appear earlier than 003',
          ),
        ]),
      );
      for (final String violation in run.violations) {
        expect(violation, matches(RegExp(r'^[\w\-./]+:\d+: \S')));
      }
      expect(run.exitCode, 1);
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

    test('a directory holding no step is reported', () async {
      final Directory root = Directory.systemTemp.createTempSync(
        'tapture_plan_',
      );
      addTearDown(() => root.deleteSync(recursive: true));

      final _Run run = await _check(<String>[root.path]);

      expect(
        run.violations,
        contains(
          contains('the plan holds no NN-slug.md step file or step folder'),
        ),
      );
      expect(run.exitCode, 1);
    });
  });
}

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

/// A step file: its heading, a line of prose, then [tasks].
String _step(int number, List<String> tasks) {
  final String padded = number.toString().padLeft(2, '0');
  return '# $padded — Fixture step\n\nStep prose.\n\n${tasks.join('\n')}';
}

/// A well-formed task inside a step file, with one thing optionally different.
///
/// Defaulting to a task that passes is what lets each case break exactly one
/// thing and see only that reported.
String _task(
  int number, {
  String? title,
  String dependsOn = '',
  String done = '- [ ] Done.',
  String after = 'Anything else.',
}) {
  final String padded = number.toString().padLeft(3, '0');
  return '## $padded — ${title ?? 'Task $padded'}\n\n'
      '${dependsOn.isEmpty ? '' : '**Depends on** $dependsOn\n\n'}'
      '### Implement\n\nDo the thing.\n\n'
      '### Files\n\n- `frontend/lib/app/app.dart` (edit)\n\n'
      '### Definition of done\n\n$done\n\n'
      '### Out of scope\n\n$after\n';
}

/// A well-formed prompt file of its own, for a step folder.
String _fileTask(int number, {String dependsOn = ''}) {
  final String padded = number.toString().padLeft(3, '0');
  return '# $padded — File task $padded\n\n'
      '${dependsOn.isEmpty ? '' : '**Depends on** $dependsOn\n\n'}'
      '## Implement\n\nDo the thing.\n\n'
      '## Files\n\n- `frontend/lib/app/app.dart` (edit)\n\n'
      '## Definition of done\n\n- [ ] Done.\n';
}

/// Writes a throwaway plan named `plan` holding [files], keyed by their path
/// inside it.
Directory _plan(Map<String, String> files) {
  final Directory root = Directory.systemTemp.createTempSync('tapture_plan_');
  addTearDown(() => root.deleteSync(recursive: true));
  for (final MapEntry<String, String> file in files.entries) {
    File('${root.path}/plan/${file.key}')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(file.value);
  }
  return Directory('${root.path}/plan');
}

/// Runs the checker with [args] and reads back what it found.
///
/// The output is decoded as UTF-8 rather than as whatever the host's console
/// codepage is: the messages carry em dashes, and on Windows the default
/// decoding turns one into three characters that match nothing.
Future<_Run> _check(List<String> args) async {
  final ProcessResult result = await Process.run(
    _dartExecutable(),
    <String>['run', '--verbosity=error', _checker, ...args],
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
