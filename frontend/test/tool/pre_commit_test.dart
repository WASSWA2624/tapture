@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/sync_dev_tracker.dart';
import 'support/plan_fixture.dart';

void main() {
  final String? shell = gitShell();
  group(
    'pre-commit tracker integration',
    skip: shell == null ? 'Git shell unavailable' : false,
    () {
      test(
        'refreshes a documentation-only commit and never auto-stages',
        () async {
          final PlanFixture fixture = await _repository();
          final File task = fixture.file('dev-plan/01-setup/001-task.md');
          task.writeAsStringSync(
            task.readAsStringSync().replaceFirst(
              '- [ ] Implemented.',
              '- [x] Implemented.',
            ),
          );
          await fixture.git(<String>['add', 'dev-plan/01-setup/001-task.md']);
          final String stagedTracker =
              (await fixture.git(<String>['show', ':dev-tracker.md'])).stdout
                  as String;

          final ProcessResult run = await _hook(fixture, shell!);

          expect(run.exitCode, 1);
          expect(run.stderr, contains('Nothing was auto-staged'));
          expect(
            fixture.file('dev-tracker.md').readAsStringSync(),
            contains('1 Partially complete'),
          );
          expect(
            (await fixture.git(<String>['show', ':dev-tracker.md'])).stdout,
            stagedTracker,
          );
          expect(fixture.file('frontend/verified').existsSync(), isFalse);
          await fixture.git(<String>['add', 'dev-tracker.md', 'dev-plan']);
          expect((await _hook(fixture, shell)).exitCode, 0);
        },
      );

      test('backend-only commit checks and refreshes tracker drift', () async {
        final PlanFixture fixture = await _repository();
        fixture
            .file('backend.txt')
            .writeAsStringSync('Backend implementation.\n');
        await fixture.git(<String>['add', 'backend.txt']);
        fixture.file('dev-tracker.md').writeAsStringSync('Stale tracker.\n');
        final ProcessResult run = await _hook(fixture, shell!);
        expect(run.exitCode, 1);
        expect(
          fixture.file('dev-tracker.md').readAsStringSync(),
          startsWith('# Tapture'),
        );
        expect(fixture.file('frontend/verified').existsSync(), isFalse);
      });

      test(
        'partially staged source tasks are preserved and clearly rejected',
        () async {
          final PlanFixture fixture = await _repository();
          final File task = fixture.file('dev-plan/01-setup/001-task.md');
          task.writeAsStringSync(
            task.readAsStringSync().replaceFirst(
              '- [ ] Implemented.',
              '- [x] Implemented.',
            ),
          );
          await fixture.git(<String>['add', 'dev-plan/01-setup/001-task.md']);
          task.writeAsStringSync(
            '${task.readAsStringSync()}\nUnstaged prose.\n',
          );
          final String before = task.readAsStringSync();
          final ProcessResult run = await _hook(fixture, shell!);
          expect(run.exitCode, 1);
          expect(run.stderr, contains('is partially staged'));
          expect(task.readAsStringSync(), before);
          expect(
            (await fixture.git(<String>[
              'show',
              ':dev-plan/01-setup/001-task.md',
            ])).stdout,
            isNot(contains('Unstaged prose')),
          );
        },
      );

      test(
        'unrelated unstaged task and phase prose does not block a clean documentation commit',
        () async {
          final PlanFixture fixture = await _repository();
          fixture.file('notes.txt').writeAsStringSync('Documentation.\n');
          await fixture.git(<String>['add', 'notes.txt']);
          final File task = fixture.file('dev-plan/01-setup/001-task.md');
          task.writeAsStringSync(
            '${task.readAsStringSync()}\nUnrelated prose.\n',
          );
          final File readme = fixture.file('dev-plan/01-setup/README.md');
          readme.writeAsStringSync(
            '${readme.readAsStringSync()}\nUnrelated phase prose.\n',
          );
          final ProcessResult run = await _hook(fixture, shell!);
          expect(run.exitCode, 0, reason: '${run.stdout}\n${run.stderr}');
          expect(task.readAsStringSync(), endsWith('Unrelated prose.\n'));
        },
      );

      test(
        'staged generated summaries cannot describe an unstaged checklist change',
        () async {
          final PlanFixture fixture = await _repository();
          final File task = fixture.file('dev-plan/01-setup/001-task.md');
          task.writeAsStringSync(
            task.readAsStringSync().replaceFirst(
              '- [ ] Implemented.',
              '- [x] Implemented.',
            ),
          );
          readTracker(fixture.root).write();
          await fixture.git(<String>[
            'add',
            'dev-tracker.md',
            'dev-plan/INDEX.md',
            'dev-plan/01-setup/README.md',
          ]);
          final ProcessResult run = await _hook(fixture, shell!);
          expect(run.exitCode, 1, reason: '${run.stdout}\n${run.stderr}');
          expect(run.stderr, contains('staged summaries do not match'));
          expect(
            (await fixture.git(<String>[
              'show',
              ':dev-plan/01-setup/001-task.md',
            ])).stdout,
            contains('- [ ] Implemented.'),
          );
        },
      );

      test(
        'a staged task deleted from the workspace is rejected without restoration',
        () async {
          final PlanFixture fixture = await _repository();
          final File task = fixture.file('dev-plan/01-setup/001-task.md');
          task.writeAsStringSync('${task.readAsStringSync()}\nStaged prose.\n');
          await fixture.git(<String>['add', 'dev-plan/01-setup/001-task.md']);
          task.deleteSync();
          final ProcessResult run = await _hook(fixture, shell!);
          expect(run.exitCode, 1);
          expect(run.stderr, contains('is partially staged'));
          expect(task.existsSync(), isFalse);
        },
      );

      test(
        'Dart commits refresh the tracker before running the fast verifier',
        () async {
          final PlanFixture fixture = await _repository();
          fixture
              .file('frontend/change.dart')
              .writeAsStringSync('void changed() {}\n');
          await fixture.git(<String>['add', 'frontend/change.dart']);
          final ProcessResult run = await _hook(fixture, shell!);
          expect(run.exitCode, 0, reason: '${run.stdout}\n${run.stderr}');
          expect(
            fixture.file('frontend/verified').readAsStringSync(),
            '--fast',
          );
        },
      );
    },
  );
}

Future<PlanFixture> _repository() async {
  final PlanFixture fixture = PlanFixture()..phase('01-setup');
  fixture.task('01-setup', '001');
  Directory('${fixture.root.path}/frontend/tool').createSync(recursive: true);
  File(
    'tool/sync_dev_tracker.dart',
  ).copySync('${fixture.root.path}/frontend/tool/sync_dev_tracker.dart');
  File('tool/check_staged_dev_tracker.dart').copySync(
    '${fixture.root.path}/frontend/tool/check_staged_dev_tracker.dart',
  );
  fixture
      .file('frontend/tool/verify.dart')
      .writeAsStringSync(
        "import 'dart:io';\nvoid main(List<String> args) { File('verified').writeAsStringSync(args.join(' ')); }\n",
      );
  readTracker(fixture.root).write();
  expect((await fixture.git(<String>['init', '-q'])).exitCode, 0);
  await fixture.git(<String>['config', 'core.autocrlf', 'false']);
  await fixture.git(<String>['add', '.']);
  expect(
    (await fixture.git(<String>[
      '-c',
      'user.name=Test',
      '-c',
      'user.email=test@example.com',
      '-c',
      'core.hooksPath=.no-hooks',
      'commit',
      '-qm',
      'Fixture',
    ])).exitCode,
    0,
  );
  return fixture;
}

Future<ProcessResult> _hook(PlanFixture fixture, String shell) {
  return Process.run(
    shell,
    <String>[File('tool/hooks/pre-commit').absolute.path.replaceAll('\\', '/')],
    workingDirectory: fixture.root.path,
    environment: Platform.isWindows
        ? <String, String>{
            'PATH':
                '${File(shell).parent.path};${Platform.environment['PATH'] ?? Platform.environment['Path'] ?? ''}',
          }
        : null,
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
  );
}
