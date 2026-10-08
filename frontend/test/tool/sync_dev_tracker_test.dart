import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/plan_source.dart';
import '../../tool/sync_dev_tracker.dart';
import 'support/plan_fixture.dart';

void main() {
  test('completed task status preserves visible unfinished prerequisites', () {
    final PlanFixture fixture = PlanFixture()..step('01-setup');
    fixture.task('01-setup', '001');
    fixture.task(
      '01-setup',
      '002',
      checks: '- [x] Verified.',
      depends: '[001](01-setup.md)',
    );
    final TrackerSnapshot snapshot = readTracker(fixture.root);
    expect(snapshot.tasks.last.status, PlanStatus.complete);
    expect(
      snapshot.outputs['dev-tracker.md'],
      contains('Prerequisite review: 001'),
    );
  });

  test(
    'inline prose examples of started metadata do not mark a task started',
    () {
      final PlanFixture fixture = PlanFixture()..step('01-setup');
      fixture.task(
        '01-setup',
        '001',
        after: 'The marker `**Implementation started:** Yes` records progress.',
      );
      expect(readTracker(fixture.root).tasks.single.status, PlanStatus.pending);
    },
  );

  test(
    'status comes from acceptance checks and explicit started marker only',
    () {
      final PlanFixture fixture = PlanFixture()..step('01-setup');
      fixture.task('01-setup', '001', checks: '- [x] Done.\n- [X] Verified.');
      fixture.task('01-setup', '002', checks: '- [x] Done.\n- [ ] Verified.');
      fixture.task(
        '01-setup',
        '003',
        started: '**Implementation started:** Yes',
      );
      fixture.task('01-setup', '004', after: '- [x] An unrelated note.');

      final TrackerSnapshot snapshot = readTracker(fixture.root);

      expect(snapshot.tasks.map((PlanTask task) => task.status), <PlanStatus>[
        PlanStatus.complete,
        PlanStatus.partial,
        PlanStatus.partial,
        PlanStatus.pending,
      ]);
      expect(snapshot.steps.single.status, PlanStatus.partial);
      expect(snapshot.tasks.last.checked, 0);
      expect(
        snapshot.outputs['dev-tracker.md'],
        contains('4 total · 1 Complete · 2 Partially complete · 1 Pending'),
      );
    },
  );

  test('step status reflects all complete, all pending and mixed tasks', () {
    final PlanFixture fixture = PlanFixture()
      ..step('01-complete')
      ..step('02-pending')
      ..step('03-mixed');
    fixture.task('01-complete', '001', checks: '- [x] Verified.');
    fixture.task('02-pending', '002');
    fixture.task('03-mixed', '003', checks: '- [x] Verified.');
    fixture.task('03-mixed', '004');
    expect(
      readTracker(fixture.root).steps.map((PlanStep step) => step.status),
      <PlanStatus>[PlanStatus.complete, PlanStatus.pending, PlanStatus.partial],
    );
  });

  test(
    'implementation order follows steps and file order while IDs stay unchanged',
    () {
      final PlanFixture fixture = PlanFixture()
        ..step('01-first')
        ..step('02-second');
      fixture.task('01-first', '002');
      fixture.task('02-second', '001', depends: '[002](01-first.md)');
      final TrackerSnapshot snapshot = readTracker(fixture.root);
      expect(snapshot.tasks.map((PlanTask task) => task.id), <String>[
        '002',
        '001',
      ]);
      expect(snapshot.tasks.last.position, '02.01');
      expect(snapshot.outputs['dev-tracker.md'], contains('Waiting for: 002'));
      expect(
        snapshot.outputs['dev-tracker.md'],
        contains('Next actionable sub-step:** [01.01 · 002'),
      );
    },
  );

  test(
    'a step folder holds one prompt file per task, numbered on from the step',
    () {
      final PlanFixture fixture = PlanFixture()..step('01-setup');
      fixture.task('01-setup', '001', checks: '- [x] Verified.');
      fixture.folderTask('02-final', '003');
      fixture.folderTask('02-final', '002', depends: '[001](../01-setup.md)');
      final TrackerSnapshot snapshot = readTracker(fixture.root);
      final PlanStep folder = snapshot.steps.last;
      expect(folder.title, 'Final');
      expect(folder.tasks.map((PlanTask task) => task.id), <String>[
        '003',
        '002',
      ]);
      expect(folder.tasks.map((PlanTask task) => task.position), <String>[
        '02.01',
        '02.02',
      ]);
      expect(folder.tasks.last.dependencies.single.id, '001');
      expect(
        snapshot.outputs['dev-tracker.md'],
        contains('[003](dev-plan/02-final/02-task-003.md)'),
      );
      expect(
        snapshot.outputs['dev-tracker.md'],
        contains('[002](dev-plan/02-final/03-task-002.md)'),
      );
    },
  );

  test('a step folder prompt numbered out of sequence fails before writes', () {
    final PlanFixture fixture = PlanFixture()..step('01-setup');
    fixture.task('01-setup', '001');
    fixture
        .folderTask('02-final', '002')
        .renameSync('${fixture.root.path}/dev-plan/02-final/03-task-002.md');
    expect(() => readTracker(fixture.root), throwsFormatException);
    expect(fixture.file('dev-tracker.md').existsSync(), isFalse);
  });

  test('refresh is idempotent and never writes a prompt', () {
    final PlanFixture fixture = PlanFixture()..step('01-setup');
    final File step = fixture.task(
      '01-setup',
      '001',
      started: '**Implementation started:** Yes',
    );
    final String before = step.readAsStringSync();
    final TrackerSnapshot snapshot = readTracker(fixture.root);
    expect(snapshot.outputs.keys, <String>['dev-tracker.md']);
    expect(snapshot.write(), <String>['dev-tracker.md']);
    final DateTime modified = fixture.file('dev-tracker.md').lastModifiedSync();
    expect(readTracker(fixture.root).write(), isEmpty);
    expect(fixture.file('dev-tracker.md').lastModifiedSync(), modified);
    expect(step.readAsStringSync(), before);
  });

  test('--check reports drift without modifying any file', () async {
    final PlanFixture fixture = PlanFixture()..step('01-setup');
    final File step = fixture.task('01-setup', '001');
    final String before = step.readAsStringSync();
    final ProcessResult checked = await runTracker(fixture, <String>[
      '--check',
    ]);
    expect(checked.exitCode, 1);
    expect(checked.stderr, contains('dev-tracker.md'));
    expect(step.readAsStringSync(), before);
    expect(fixture.file('dev-tracker.md').existsSync(), isFalse);
    expect((await runTracker(fixture, <String>[])).exitCode, 0);
    expect((await runTracker(fixture, <String>['--check'])).exitCode, 0);
  });

  test('check mode detects a ticked box as tracker drift', () {
    final PlanFixture fixture = PlanFixture()..step('01-setup');
    final File step = fixture.task('01-setup', '001');
    readTracker(fixture.root).write();
    expect(readTracker(fixture.root).stalePaths, isEmpty);
    step.writeAsStringSync(
      step.readAsStringSync().replaceFirst('- [ ]', '- [x]'),
    );
    expect(readTracker(fixture.root).stalePaths, <String>['dev-tracker.md']);
  });

  for (final String marker in <String>[
    '**Implementation started:** No',
    '**Implementation started** Yes',
    '**Implementation started:** yes',
  ]) {
    test('rejects invalid source marker $marker', () {
      final PlanFixture fixture = PlanFixture()..step('01-setup');
      fixture.task('01-setup', '001', started: marker);
      expect(() => readTracker(fixture.root), throwsFormatException);
    });
  }

  for (final String checks in <String>[
    '',
    '- [y] Invalid.',
    '- [] Invalid.',
    '- [x]',
  ]) {
    test('rejects missing or malformed acceptance checks: $checks', () {
      final PlanFixture fixture = PlanFixture()..step('01-setup');
      fixture.task('01-setup', '001', checks: checks);
      expect(() => readTracker(fixture.root), throwsFormatException);
      expect(fixture.file('dev-tracker.md').existsSync(), isFalse);
    });
  }

  test('duplicate task IDs fail before writes', () {
    final PlanFixture fixture = PlanFixture()
      ..step('01-first')
      ..step('02-second');
    fixture.task('01-first', '001', title: 'First');
    fixture.task('02-second', '001', title: 'Second');
    expect(() => readTracker(fixture.root), throwsFormatException);
    expect(fixture.file('dev-tracker.md').existsSync(), isFalse);
  });

  test('dangling, mismatched and forward dependencies fail before writes', () {
    for (final String dependency in <String>[
      '[002](01-setup.md)',
      '[999](01-setup.md)',
      '[002](absent.md)',
      '[003](01-setup.md)',
    ]) {
      final PlanFixture fixture = PlanFixture()
        ..step('01-setup')
        ..step('02-other');
      fixture.task('01-setup', '001');
      fixture.task('01-setup', '002', depends: dependency);
      fixture.task('02-other', '003');
      expect(
        () => readTracker(fixture.root),
        throwsFormatException,
        reason: dependency,
      );
      expect(fixture.file('dev-tracker.md').existsSync(), isFalse);
    }
  });

  test('stray files cannot sit in the plan beside the steps', () {
    for (final String stray in <String>[
      'dev-plan/README.md',
      'dev-plan/INDEX.md',
      'dev-plan/002-orphan.md',
    ]) {
      final PlanFixture fixture = PlanFixture()..step('01-setup');
      fixture.task('01-setup', '001');
      fixture.file(stray).writeAsStringSync('# 002 — Orphan\n');
      expect(() => readTracker(fixture.root), throwsFormatException);
    }
  });

  test('the task index retains exactly one row per task', () {
    final PlanFixture fixture = PlanFixture()..step('01-setup');
    fixture.task('01-setup', '001', checks: '- [x] Verified.');
    fixture.task('01-setup', '002');
    final String tracker = readTracker(fixture.root).outputs['dev-tracker.md']!;
    final List<String> rows = tracker
        .split('\n')
        .where((String line) => line.startsWith('| 01.'))
        .toList();
    expect(rows, hasLength(2));
    expect(rows.first, contains('](dev-plan/01-setup.md#001--task-001)'));
    expect(rows.first, contains('| 1/1 |'));
    expect(rows.last, contains('](dev-plan/01-setup.md#002--task-002)'));
    expect(rows.last, contains('| 0/2 |'));
    expect(tracker, contains('## Task index'));
    expect(tracker, contains('<details>'));
    expect(tracker, contains('</details>'));
  });

  test(
    'compact progress counts completed tasks without weighting partial work',
    () {
      final TrackerSnapshot snapshot = readTracker(_mixedProgressPlan().root);
      final String tracker = snapshot.outputs['dev-tracker.md']!;
      final String summary = _plain(
        tracker
            .split('\n')
            .singleWhere((String line) => line.startsWith('**Tasks:**')),
      );

      expect(_percentage(tracker), 33);
      expect(_bars(tracker).first, '██████░░░░░░░░░░░░░░');
      expect(summary, matches(RegExp(r'\b2 Complete\b', caseSensitive: false)));
      expect(
        summary,
        matches(
          RegExp(r'\b2 (?:Partial|Partially complete)\b', caseSensitive: false),
        ),
      );
      expect(summary, matches(RegExp(r'\b2 Pending\b', caseSensitive: false)));
      expect(summary, contains('6 total'));
      expect(tracker, contains('Partially complete'));
      expect(_stepRows(tracker), hasLength(4));

      final List<String> rows = _stepRows(tracker);
      expect(_plain(rows[0]), contains('1/1'));
      expect(_plain(rows[1]), contains('0/3'));
      expect(_plain(rows[2]), contains('1/1'));
      expect(_plain(rows[3]), contains('0/1'));
      expect(_bars(rows[0]).single, '██████████');
      expect(_bars(rows[1]).single, '░░░░░░░░░░');
      expect(_plain(rows[1]), contains('Partial'));
    },
  );

  for (final bool completed in <bool>[false, true]) {
    test('visual progress has an exact ${completed ? 100 : 0}% boundary', () {
      final PlanFixture fixture = PlanFixture()..step('01-setup');
      fixture.task(
        '01-setup',
        '001',
        checks: completed ? '- [x] Verified.' : '- [ ] Verified.',
      );
      final String tracker = readTracker(
        fixture.root,
      ).outputs['dev-tracker.md']!;

      expect(_percentage(tracker), completed ? 100 : 0);
      expect(
        _bars(tracker).first,
        List<String>.filled(20, completed ? '█' : '░').join(),
      );
      expect(
        _bars(_stepRows(tracker).single).single,
        List<String>.filled(10, completed ? '█' : '░').join(),
      );
      expect(tracker, isNot(contains('NaN')));
      if (completed) {
        expect(tracker, contains('None — all tasks are complete'));
        expect(_taskLinks(_stepRows(tracker).single), isEmpty);
      }
    });
  }

  test('fractional completion percentages round down', () {
    final PlanFixture fixture = PlanFixture()..step('01-setup');
    fixture.task('01-setup', '001', checks: '- [x] Verified.');
    fixture.task('01-setup', '002', checks: '- [x] Verified.');
    fixture.task('01-setup', '003');
    final String tracker = readTracker(fixture.root).outputs['dev-tracker.md']!;

    expect(_percentage(tracker), 66);
    expect(_bars(tracker).first, '█████████████░░░░░░░');
  });

  test(
    'step table links each unfinished task once and leaves completed ones to the index',
    () {
      final TrackerSnapshot snapshot = readTracker(_mixedProgressPlan().root);
      final String tracker = snapshot.outputs['dev-tracker.md']!;
      final List<String> rows = _stepRows(tracker);
      final List<String> links = _taskLinks(rows.join('\n'));

      expect(links, hasLength(4));
      for (final String id in <String>['002', '003', '004', '006']) {
        expect(
          links.where((String link) => link.endsWith('#$id--task-$id')),
          hasLength(1),
        );
      }
      for (final String id in <String>['001', '005']) {
        expect(
          links.where((String link) => link.endsWith('#$id--task-$id')),
          isEmpty,
        );
      }
      final List<String> mixedCells = rows[1]
          .split('|')
          .map((String cell) => cell.trim())
          .toList();
      expect(_taskLinks(mixedCells[4]), hasLength(2));
      expect(
        _taskLinks(mixedCells[4]),
        everyElement(
          anyOf(endsWith('#002--task-002'), endsWith('#003--task-003')),
        ),
      );
      expect(_taskLinks(mixedCells[5]), <String>[
        'dev-plan/02-progress.md#004--task-004',
      ]);
      expect(
        tracker,
        isNot(matches(RegExp(r'^## \d{2} [—–-]', multiLine: true))),
      );
    },
  );

  test(
    'completed tasks with open prerequisites remain visible as a concise warning',
    () {
      final PlanFixture fixture = PlanFixture()..step('01-setup');
      fixture.task('01-setup', '001');
      fixture.task(
        '01-setup',
        '002',
        checks: '- [x] Verified.',
        depends: '[001](01-setup.md)',
      );
      final String tracker = readTracker(
        fixture.root,
      ).outputs['dev-tracker.md']!;
      final List<String> warningLines = tracker
          .split('\n')
          .where((String line) => line.startsWith('**Prerequisite review:**'))
          .toList();

      expect(_percentage(tracker), 50);
      expect(warningLines, hasLength(1));
      expect(_plain(warningLines.single), matches(RegExp(r'\b1\b')));
      expect(warningLines.single, contains('(#task-index)'));
      expect(tracker, contains('Prerequisite review: 001'));
    },
  );

  test(
    'an empty step has zero progress without altering overall task completion',
    () {
      final PlanFixture fixture = PlanFixture()
        ..step('01-ready')
        ..step('02-empty');
      fixture.task('01-ready', '001', checks: '- [x] Verified.');
      final String tracker = readTracker(
        fixture.root,
      ).outputs['dev-tracker.md']!;

      expect(_percentage(tracker), 100);
      expect(_plain(_stepRows(tracker).last), contains('0/0'));
      expect(_plain(_stepRows(tracker).last), contains('Pending'));
      expect(_bars(_stepRows(tracker).last).single, '░░░░░░░░░░');
      expect(tracker, isNot(contains('NaN')));
      expect(tracker, isNot(contains('Infinity')));
    },
  );

  test(
    'the compact tracker retains next work and automatic refresh guidance',
    () {
      final TrackerSnapshot snapshot = readTracker(_mixedProgressPlan().root);
      final String tracker = snapshot.outputs['dev-tracker.md']!;

      expect(tracker, contains('Next actionable sub-step:** [02.01 · 002'));
      expect(tracker, contains('(AGENTS.md#progress-updates)'));
      expect(tracker, contains('(#task-index)'));
      expect(tracker.toLowerCase(), contains('automatically'));
    },
  );

  test('heading anchors are the ones a Markdown renderer generates', () {
    expect(
      headingAnchor('087 — Arrange implementation flow'),
      '087--arrange-implementation-flow',
    );
    expect(
      headingAnchor('003 — Design system: tokens, themes and widgets'),
      '003--design-system-tokens-themes-and-widgets',
    );
    expect(headingAnchor('Keep `Radii` (never zero)'), 'keep-radii-never-zero');
  });
}

PlanFixture _mixedProgressPlan() {
  final PlanFixture fixture = PlanFixture()
    ..step('01-ready')
    ..step('02-progress')
    ..step('03-done')
    ..step('04-later');
  fixture.task(
    '01-ready',
    '001',
    checks: '- [x] Implemented.\n- [x] Verified.',
  );
  fixture.task(
    '02-progress',
    '002',
    checks:
        '${List<String>.filled(9, '- [x] Met.').join('\n')}\n- [ ] Remaining.',
    depends: '[001](01-ready.md)',
  );
  fixture.task(
    '02-progress',
    '003',
    started: '**Implementation started:** Yes',
  );
  fixture.task('02-progress', '004', depends: '[002](02-progress.md)');
  fixture.task('03-done', '005', checks: '- [x] Verified.');
  fixture.task('04-later', '006', depends: '[004](02-progress.md)');
  return fixture;
}

String _plain(String text) => text.replaceAll('*', '').replaceAll('`', '');

int _percentage(String text) =>
    int.parse(RegExp(r'\b(\d+)%').firstMatch(text)!.group(1)!);

List<String> _bars(String text) => RegExp(
  r'[█░]+',
).allMatches(text).map((RegExpMatch match) => match.group(0)!).toList();

List<String> _stepRows(String text) => text
    .split('\n')
    .where(
      (String line) =>
          line.startsWith('|') &&
          RegExp(r'^\| \d{2} · \[.*\]\(dev-plan/\d{2}-[^)]+\)').hasMatch(line),
    )
    .toList();

List<String> _taskLinks(String text) => RegExp(
  r'\]\((dev-plan/[^)#]+#\d{3}[^)]*)\)',
).allMatches(text).map((RegExpMatch match) => match.group(1)!).toList();
