@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The generator under test, driven as a process: its contract is one
/// function, `Future<int> main(List<String> args)`.
const String _generator = 'tool/new_task.dart';

/// The plan integrity checker, run over what the generator wrote.
///
/// A generated task that the plan's own guardrail rejects is not a task,
/// whatever it looks like, so proving that is part of proving this works.
const String _planChecker = 'tool/check_plan.dart';

/// The step file most fixture runs add to.
const String _step = '01-orchestration.md';

/// The step folder fixture runs add to, numbered on from step 03.
const String _folder = '03-hardening';

void main() {
  group('generating a task', () {
    test(
      'automatically refreshes the repository development tracker',
      () async {
        final Directory plan = _plan();
        final _Run run = await _generate(plan, 'New step');
        expect(run.exitCode, 0, reason: run.problems.join('\n'));
        final String tracker = File(
          '${plan.parent.path}/dev-tracker.md',
        ).readAsStringSync();
        expect(tracker, contains('**Tasks:** 4 total'));
        expect(
          tracker,
          contains('[004](dev-plan/01-orchestration.md#004--new-step)'),
        );
        expect(tracker, contains('4 Pending'));
        expect(tracker, contains('**Completed tasks: 0%**'));
      },
    );

    test('appends the next number to the end of the step file', () async {
      final Directory plan = _plan();
      final String before = _read(plan, _step);

      final _Run run = await _generate(plan, 'Shared YAML reader');
      final String written = _read(plan, _step);

      expect(run.exitCode, 0);
      expect(run.problems, isEmpty);
      expect(written, startsWith(before.trimRight()));
      final String block = written.substring(before.trimRight().length);
      expect(block, startsWith('\n\n## 004 — Shared YAML reader\n'));
      for (final String section in <String>[
        '### Implement',
        '### Files',
        '### Definition of done',
      ]) {
        expect(block, contains('\n$section\n'));
      }
      expect(block, contains('- [ ] Tests:'));
      expect(written, isNot(contains('{{')));
    });

    test(
      'writes into a step folder as its next numbered prompt file',
      () async {
        final Directory plan = _plan();

        final _Run run = await _generate(plan, 'Final sweep', step: _folder);
        final File written = File('${plan.path}/$_folder/04-final-sweep.md');

        expect(run.exitCode, 0, reason: run.problems.join('\n'));
        expect(written.existsSync(), isTrue);
        final String text = written.readAsStringSync().replaceAll('\r\n', '\n');
        expect(text, startsWith('# 004 — Final sweep\n'));
        for (final String section in <String>[
          '## Implement',
          '## Files',
          '## Definition of done',
        ]) {
          expect(text, contains('\n$section\n'));
        }
      },
    );

    test('the generated tasks pass the plan integrity checker', () async {
      final Directory plan = _plan();

      await _generate(plan, 'Shared YAML reader');
      await _generate(plan, 'Final sweep', step: _folder);
      final _Run checked = await _run(_planChecker, <String>[plan.path]);

      expect(checked.problems, isEmpty);
      expect(checked.exitCode, 0);
      expect(checked.summary, contains('5 tasks, numbering and links intact'));
    });

    test('takes the next number from the whole plan, not the step', () async {
      final Directory plan = _plan();

      await _generate(plan, 'First one', step: '02-foundation.md');
      await _generate(plan, 'Second one');

      expect(_read(plan, '02-foundation.md'), contains('## 004 — First one'));
      expect(_read(plan, _step), contains('## 005 — Second one'));
    });
  });

  group('refusing to generate', () {
    test('an invalid existing plan is left exactly as it was', () async {
      final Directory plan = _plan();
      final File source = File('${plan.path}/$_step');
      source.writeAsStringSync(
        source.readAsStringSync().replaceFirst('- [ ] Done.', '- [z] Invalid.'),
      );
      final String before = source.readAsStringSync();

      final _Run run = await _generate(plan, 'New step');

      expect(run.exitCode, 1);
      expect(
        run.problems,
        contains(contains('malformed Definition of done checkbox')),
      );
      expect(source.readAsStringSync(), before);
      expect(File('${plan.parent.path}/dev-tracker.md').existsSync(), isFalse);
    });

    test(
      'the same title twice fails rather than adding a second task',
      () async {
        final Directory plan = _plan();

        final _Run first = await _generate(plan, 'Same title');
        final String written = _read(plan, _step);
        final _Run second = await _generate(plan, 'same TITLE', step: _folder);

        expect(first.exitCode, 0);
        expect(second.exitCode, 1);
        expect(
          second.problems,
          contains(contains('already names task 004; a title names one task')),
        );
        expect(_read(plan, _step), written);
        expect(Directory('${plan.path}/$_folder').listSync(), hasLength(1));
      },
    );

    test('a refused run writes nothing at all', () async {
      final Directory plan = _plan();
      final String before = _read(plan, _step);

      final _Run run = await _generate(plan, '   ');

      expect(run.exitCode, 1);
      expect(run.problems, contains(contains('the title is empty')));
      expect(_read(plan, _step), before);
      expect(File('${plan.parent.path}/dev-tracker.md').existsSync(), isFalse);
    });

    test('a title with nothing to name a file after is refused', () async {
      final Directory plan = _plan();

      final _Run run = await _generate(plan, '— · —', step: _folder);

      expect(run.problems, contains(contains('no letter or digit')));
      expect(run.exitCode, 1);
    });

    test('a step that is not there is refused', () async {
      final Directory plan = _plan();

      final _Run run = await _run(_generator, <String>[
        '${plan.path}/99-absent.md',
        'A title',
      ]);

      expect(
        run.problems,
        contains(
          contains('no such NN-slug.md step file or NN-slug step folder'),
        ),
      );
      expect(run.exitCode, 1);
    });

    test('a path that is not a step is refused', () async {
      final Directory plan = _plan();

      final _Run run = await _run(_generator, <String>[plan.path, 'A title']);

      expect(run.problems, contains(contains('no such NN-slug.md step file')));
      expect(run.exitCode, 1);
    });

    test('the wrong number of arguments is refused', () async {
      final _Run run = await _run(_generator, <String>['only-one']);

      expect(run.problems, contains(contains('got 1 argument(s)')));
      expect(run.problems, contains(contains('usage: dart run')));
      expect(run.exitCode, 1);
    });

    test('every problem is reported, with its file and line', () async {
      final Directory plan = _plan();
      final File source = File('${plan.path}/$_step');
      source.writeAsStringSync(
        source.readAsStringSync().replaceFirst('# 01 —', '# 07 —'),
      );

      final _Run run = await _generate(plan, '  ');

      expect(
        run.problems,
        containsAll(<Matcher>[
          contains('the title is empty'),
          contains('the heading says step 07 and the filename says 01'),
        ]),
      );
      expect(run.summary, contains('2 problem(s)'));
      for (final String problem in run.problems) {
        expect(problem, matches(RegExp(r'^[\w\-./]+:\d+: \S')));
      }
    });
  });
}

/// What one run of a tool reported.
class _Run {
  const _Run(this.exitCode, this.problems, this.summary);

  /// The exit code: 0 when the task was written, 1 when something stopped it.
  final int exitCode;

  /// One line per problem, as the tool wrote them.
  final List<String> problems;

  /// The closing line saying what the run concluded.
  final String summary;
}

/// Builds a throwaway plan the integrity checker accepts as it stands: a step
/// file with two tasks, a step file with none yet, and a step folder with one
/// prompt file, so a case can add one task and see only that.
Directory _plan() {
  final Directory root = Directory.systemTemp.createTempSync('tapture_task_');
  addTearDown(() => root.deleteSync(recursive: true));
  final Directory plan = Directory('${root.path}/dev-plan')..createSync();
  File('${plan.path}/$_step').writeAsStringSync(
    '# 01 — Project setup and guardrails\n\nThe guardrails.\n\n'
    '${_task('001', 'First task', '##')}\n${_task('002', 'Second task', '##')}',
  );
  File(
    '${plan.path}/02-foundation.md',
  ).writeAsStringSync('# 02 — Foundation services\n\nThe services.\n');
  File('${plan.path}/$_folder/03-final-check.md')
    ..parent.createSync()
    ..writeAsStringSync(_task('003', 'Final check', '#'));
  return plan;
}

/// One well-formed task with its heading at [mark].
String _task(String id, String title, String mark) {
  return '$mark $id — $title\n\n'
      '$mark# Implement\n\nDo the thing.\n\n'
      '$mark# Files\n\n- `frontend/lib/app/app.dart` (edit)\n\n'
      '$mark# Definition of done\n\n- [ ] Done.\n';
}

String _read(Directory plan, String path) =>
    File('${plan.path}/$path').readAsStringSync().replaceAll('\r\n', '\n');

/// Runs the generator against a fixture plan.
Future<_Run> _generate(Directory plan, String title, {String step = _step}) {
  return _run(_generator, <String>['${plan.path}/$step', title]);
}

/// Runs [tool] with [args] and reads back what it reported.
///
/// The output is decoded as UTF-8 rather than as whatever the host's console
/// codepage is: the messages carry em dashes, and on Windows the default
/// decoding turns one into three characters that match nothing.
Future<_Run> _run(String tool, List<String> args) async {
  final ProcessResult result = await Process.run(
    _dartExecutable(),
    <String>['run', '--verbosity=error', tool, ...args],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
  final Object? errors = result.stderr;
  final Object? output = result.stdout;
  final List<String> problems = <String>[
    for (final String line in (errors is String ? errors : '').split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];
  return _Run(
    result.exitCode,
    problems,
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
