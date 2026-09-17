@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The generator under test, driven as a process.
///
/// Its contract is one function — `Future<int> main(List<String> args)` — so a
/// test that imported something to call would be testing an API the task says
/// must not exist.
const String _generator = 'tool/new_task.dart';

/// The plan integrity checker from task 006, run over what this one wrote.
///
/// A generated file that the plan's own guardrail rejects is not a task file,
/// whatever it looks like, so proving that is part of proving this works.
const String _planChecker = 'tool/check_plan.dart';

/// The phase folder every fixture plan is built around.
const String _phase = '01-orchestration';

void main() {
  group('generating a task', () {
    test('writes the next free number into the phase folder', () async {
      final Directory plan = _plan();

      final _Run run = await _generate(
        plan,
        'shared-yaml-reader',
        'Shared '
            'YAML reader',
      );

      expect(run.exitCode, 0);
      expect(run.problems, isEmpty);
      expect(
        File('${plan.path}/$_phase/003-shared-yaml-reader.md').existsSync(),
        isTrue,
      );
    });

    test('populates the heading, the phase line and the sections', () async {
      final Directory plan = _plan();

      await _generate(plan, 'shared-yaml-reader', 'Shared YAML reader');
      final String written = File(
        '${plan.path}/$_phase/003-shared-yaml-reader.md',
      ).readAsStringSync();

      expect(written, startsWith('# 003 — Shared YAML reader\n'));
      expect(written, contains('**Phase** 01 · Project setup and guardrails'));
      expect(written, contains('**Standard** [STANDARD.md](../STANDARD.md)'));
      for (final String section in <String>[
        '## Implement',
        '## Files',
        '## Definition of done',
      ]) {
        expect(written, contains('\n$section\n'));
      }
      expect(written, isNot(contains('{{')));
    });

    test('the generated file passes the plan integrity checker', () async {
      final Directory plan = _plan();

      await _generate(plan, 'shared-yaml-reader', 'Shared YAML reader');
      final _Run checked = await _run(_planChecker, <String>[plan.path]);

      expect(checked.problems, isEmpty);
      expect(checked.exitCode, 0);
      expect(checked.summary, contains('3 tasks, numbering and links intact'));
    });

    test('lists the task in the phase README', () async {
      final Directory plan = _plan();

      await _generate(plan, 'shared-yaml-reader', 'Shared YAML reader');
      final List<String> lines = File(
        '${plan.path}/$_phase/README.md',
      ).readAsLinesSync();

      expect(
        lines,
        contains('- [ ] [003 — Shared YAML reader](003-shared-yaml-reader.md)'),
      );
    });

    test('lists the task in the index, under its own phase', () async {
      final Directory plan = _plan();

      await _generate(plan, 'shared-yaml-reader', 'Shared YAML reader');
      final List<String> lines = File(
        '${plan.path}/INDEX.md',
      ).readAsLinesSync();
      final int entry = lines.indexOf(
        '- [ ] [003 — Shared YAML reader]'
        '($_phase/003-shared-yaml-reader.md)',
      );

      expect(
        entry,
        greaterThan(
          lines.indexOf(
            '## 01 — Project setup and '
            'guardrails',
          ),
        ),
      );
      expect(entry, lessThan(lines.indexOf('## 02 — Foundation services')));
    });

    test('brings the phase README summary back into agreement', () async {
      final Directory plan = _plan();

      await _generate(plan, 'shared-yaml-reader', 'Shared YAML reader');
      final List<String> lines = File(
        '${plan.path}/$_phase/README.md',
      ).readAsLinesSync();

      expect(
        lines,
        contains('Tasks 001–003 (3). Each file is a standalone prompt.'),
      );
    });

    test('brings the index total back into agreement', () async {
      final Directory plan = _plan();

      await _generate(plan, 'shared-yaml-reader', 'Shared YAML reader');
      final List<String> lines = File(
        '${plan.path}/INDEX.md',
      ).readAsLinesSync();

      expect(
        lines,
        contains(
          '3 implementation prompts across 2 phases. Work top to '
          'bottom.',
        ),
      );
    });

    test('takes the next number from the whole plan, not the phase', () async {
      final Directory plan = _plan();

      await _generate(plan, 'first-one', 'First one', phase: '02-foundation');
      await _generate(plan, 'second-one', 'Second one');

      expect(
        File('${plan.path}/02-foundation/003-first-one.md').existsSync(),
        isTrue,
      );
      expect(
        File('${plan.path}/$_phase/004-second-one.md').existsSync(),
        isTrue,
      );
    });
  });

  group('refusing to generate', () {
    test('the same slug twice fails rather than overwriting', () async {
      final Directory plan = _plan();

      final _Run first = await _generate(plan, 'same-slug', 'First title');
      final String written = File(
        '${plan.path}/$_phase/003-same-slug.md',
      ).readAsStringSync();
      final _Run second = await _generate(plan, 'same-slug', 'Second title');

      expect(first.exitCode, 0);
      expect(second.exitCode, 1);
      expect(
        second.problems,
        contains(contains('already names a task here; a slug names one task')),
      );
      expect(
        File('${plan.path}/$_phase/003-same-slug.md').readAsStringSync(),
        written,
      );
    });

    test('a refused run writes nothing at all', () async {
      final Directory plan = _plan();
      final String indexBefore = File(
        '${plan.path}/INDEX.md',
      ).readAsStringSync();
      final String readmeBefore = File(
        '${plan.path}/$_phase/README.md',
      ).readAsStringSync();

      final _Run run = await _generate(plan, 'Not A Slug', 'A title');

      expect(run.exitCode, 1);
      expect(File('${plan.path}/INDEX.md').readAsStringSync(), indexBefore);
      expect(
        File('${plan.path}/$_phase/README.md').readAsStringSync(),
        readmeBefore,
      );
      expect(
        Directory('${plan.path}/$_phase').listSync().whereType<File>().length,
        3,
      );
    });

    test('a slug that is not lower-case and hyphenated is refused', () async {
      final Directory plan = _plan();

      final _Run run = await _generate(plan, 'Shared_Yaml', 'A title');

      expect(
        run.problems,
        contains(contains('is not lower-case words joined by single hyphens')),
      );
      expect(run.exitCode, 1);
    });

    test('an empty title is refused', () async {
      final Directory plan = _plan();

      final _Run run = await _generate(plan, 'valid-slug', '   ');

      expect(run.problems, contains(contains('the title is empty')));
      expect(run.exitCode, 1);
    });

    test('a phase folder that is not there is refused', () async {
      final Directory plan = _plan();

      final _Run run = await _run(_generator, <String>[
        '${plan.path}/99-absent',
        'valid-slug',
        'A title',
      ]);

      expect(run.problems, contains(contains('no such phase folder')));
      expect(run.exitCode, 1);
    });

    test('a phase whose README has no heading is refused', () async {
      final Directory plan = _plan();
      File(
        '${plan.path}/$_phase/README.md',
      ).writeAsStringSync('No heading here.\n');

      final _Run run = await _generate(plan, 'valid-slug', 'A title');

      expect(
        run.problems,
        contains(contains('no heading of the form `# NN — Phase title`')),
      );
      expect(run.exitCode, 1);
    });

    test('the wrong number of arguments is refused', () async {
      final _Run run = await _run(_generator, <String>['only-one']);

      expect(run.problems, contains(contains('got 1 argument(s)')));
      expect(run.problems, contains(contains('usage: dart run')));
      expect(run.exitCode, 1);
    });

    test('every problem is reported, not only the first', () async {
      final Directory plan = _plan();
      File(
        '${plan.path}/$_phase/README.md',
      ).writeAsStringSync('No heading here.\n');

      final _Run run = await _generate(plan, 'Not A Slug', '  ');

      expect(
        run.problems,
        containsAll(<Matcher>[
          contains('is not lower-case words joined by single hyphens'),
          contains('the title is empty'),
          contains('no heading of the form'),
        ]),
      );
      expect(run.summary, contains('3 problem(s)'));
    });

    test('every problem names the file and the line', () async {
      final Directory plan = _plan();

      final _Run run = await _generate(plan, 'Not A Slug', '  ');

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

/// Builds a throwaway plan of two phases and two tasks, which the integrity
/// checker accepts as it stands, so a case can add one task and see only that.
Directory _plan() {
  final Directory root = Directory.systemTemp.createTempSync('tapture_task_');
  addTearDown(() => root.deleteSync(recursive: true));
  final Directory plan = Directory('${root.path}/dev-plan')..createSync();
  Directory('${plan.path}/$_phase').createSync();
  Directory('${plan.path}/02-foundation').createSync();

  _task(
    plan,
    _phase,
    1,
    'first-task',
    'First task',
    '01 · Project setup and '
        'guardrails',
  );
  _task(
    plan,
    _phase,
    2,
    'second-task',
    'Second task',
    '01 · Project setup and '
        'guardrails',
  );

  File('${plan.path}/$_phase/README.md').writeAsStringSync(
    '# 01 — Project setup and guardrails\n\n'
    'The guardrails.\n\n'
    'Tasks 001–002 (2). Each file is a standalone prompt.\n\n'
    '- [ ] [001 — First task](001-first-task.md)\n'
    '- [ ] [002 — Second task](002-second-task.md)\n',
  );
  File('${plan.path}/02-foundation/README.md').writeAsStringSync(
    '# 02 — Foundation services\n\n'
    'The services.\n\n'
    'Tasks 003–003 (0). Each file is a standalone prompt.\n',
  );
  File('${plan.path}/INDEX.md').writeAsStringSync(
    '# Tapture — task index\n\n'
    '2 implementation prompts across 2 phases. Work top to bottom.\n\n'
    '## 01 — Project setup and guardrails\n\n'
    '- [ ] [001 — First task]($_phase/001-first-task.md)\n'
    '- [ ] [002 — Second task]($_phase/002-second-task.md)\n\n'
    '## 02 — Foundation services\n\n',
  );
  return plan;
}

/// Writes one well-formed task into a fixture plan.
void _task(
  Directory plan,
  String phase,
  int number,
  String slug,
  String title,
  String phaseLine,
) {
  final String padded = number.toString().padLeft(3, '0');
  File('${plan.path}/$phase/$padded-$slug.md').writeAsStringSync(
    '# $padded — $title\n\n'
    '**Phase** $phaseLine\n\n'
    '## Implement\n\nDo the thing.\n\n'
    '## Files\n\n- `frontend/lib/app/app.dart` (edit)\n\n'
    '## Definition of done\n\n- [ ] Done.\n\n'
    '## Out of scope\n\nAnything else.\n',
  );
}

/// Runs the generator against a fixture plan.
Future<_Run> _generate(
  Directory plan,
  String slug,
  String title, {
  String phase = _phase,
}) {
  return _run(_generator, <String>['${plan.path}/$phase', slug, title]);
}

/// Runs [tool] with [args] and reads back what it reported.
///
/// The output is decoded as UTF-8 rather than as whatever the host's console
/// codepage is: the messages carry em dashes, and on Windows the default
/// decoding turns one into three characters that match nothing.
Future<_Run> _run(String tool, List<String> args) async {
  final ProcessResult result = await Process.run(
    _dartExecutable(),
    <String>['run', tool, ...args],
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
