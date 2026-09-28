import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/sync_dev_tracker.dart';
import 'support/plan_fixture.dart';

void main() {
  test('completed task status preserves visible unfinished prerequisites', () {
    final PlanFixture fixture = PlanFixture()..phase('01-setup');
    fixture.task('01-setup', '001');
    fixture.task(
      '01-setup',
      '002',
      checks: '- [x] Verified.',
      depends: '[001](001-task.md)',
    );
    final TrackerSnapshot snapshot = readTracker(fixture.root);
    expect(snapshot.tasks.last.status, PlanStatus.complete);
    expect(
      snapshot.outputs['dev-plan/INDEX.md'],
      contains('Prerequisite review: 001'),
    );
  });
  test(
    'inline prose examples of started metadata do not mark a task started',
    () {
      final PlanFixture fixture = PlanFixture()..phase('01-setup');
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
      final PlanFixture fixture = PlanFixture()..phase('01-setup');
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
      expect(snapshot.phases.single.status, PlanStatus.partial);
      expect(snapshot.tasks.last.checked, 0);
      expect(
        snapshot.outputs['dev-plan/INDEX.md'],
        contains('4 total · 1 Complete · 2 Partially complete · 1 Pending'),
      );
    },
  );

  test('folder status reflects all complete, all pending and mixed tasks', () {
    final PlanFixture fixture = PlanFixture()
      ..phase('01-complete')
      ..phase('02-pending')
      ..phase('03-mixed');
    fixture.task('01-complete', '001', checks: '- [x] Verified.');
    fixture.task('02-pending', '002');
    fixture.task('03-mixed', '003', checks: '- [x] Verified.');
    fixture.task('03-mixed', '004');
    expect(
      readTracker(fixture.root).phases.map((PlanPhase phase) => phase.status),
      <PlanStatus>[PlanStatus.complete, PlanStatus.pending, PlanStatus.partial],
    );
  });

  test(
    'implementation order follows folders while stable IDs stay unchanged',
    () {
      final PlanFixture fixture = PlanFixture()
        ..phase('01-first')
        ..phase('02-second');
      fixture.task('01-first', '090');
      fixture.task(
        '02-second',
        '001',
        depends: '[090](../01-first/090-task.md)',
      );
      final TrackerSnapshot snapshot = readTracker(fixture.root);
      expect(snapshot.tasks.map((PlanTask task) => task.id), <String>[
        '090',
        '001',
      ]);
      expect(snapshot.tasks.last.step, '02.01');
      expect(
        snapshot.outputs['dev-plan/INDEX.md'],
        contains('Waiting for: 090'),
      );
      expect(
        snapshot.outputs['dev-tracker.md'],
        contains('Next actionable sub-step:** [01.01 · 090'),
      );
    },
  );

  test('refresh is idempotent and preserves prose, checklists and markers', () {
    final PlanFixture fixture = PlanFixture()..phase('01-setup');
    final File task = fixture.task(
      '01-setup',
      '001',
      started: '**Implementation started:** Yes',
    );
    final File readme = fixture.file('dev-plan/01-setup/README.md');
    readme.writeAsStringSync(
      '${readme.readAsStringSync()}\n$generatedStart\nstale\n$generatedEnd\n\nAfterward.\n',
    );
    readTracker(fixture.root).write();
    final DateTime modified = task.lastModifiedSync();
    expect(readTracker(fixture.root).write(), isEmpty);
    expect(task.lastModifiedSync(), modified);
    expect(task.readAsStringSync(), contains('**Implementation step:** 01.01'));
    expect(
      task.readAsStringSync(),
      contains('**Implementation started:** Yes'),
    );
    expect(
      task.readAsStringSync(),
      contains('- [ ] Implemented.\n- [ ] Verified.'),
    );
    expect(
      readme.readAsStringSync(),
      startsWith('# 01 — Phase\n\nHuman prose.'),
    );
    expect(readme.readAsStringSync(), endsWith('\n\nAfterward.\n'));
    expect(readme.readAsStringSync(), isNot(contains('stale')));
  });

  test('--check reports drift without modifying any file', () async {
    final PlanFixture fixture = PlanFixture()..phase('01-setup');
    final File task = fixture.task('01-setup', '001');
    final String before = task.readAsStringSync();
    final ProcessResult checked = await runTracker(fixture, <String>[
      '--check',
    ]);
    expect(checked.exitCode, 1);
    expect(checked.stderr, contains('dev-plan/01-setup/001-task.md'));
    expect(task.readAsStringSync(), before);
    expect(fixture.file('dev-tracker.md').existsSync(), isFalse);
    expect((await runTracker(fixture, <String>[])).exitCode, 0);
    expect((await runTracker(fixture, <String>['--check'])).exitCode, 0);
  });

  test('check mode detects stale step metadata as well as status drift', () {
    final PlanFixture fixture = PlanFixture()..phase('01-setup');
    final File task = fixture.task('01-setup', '001');
    readTracker(fixture.root).write();
    task.writeAsStringSync(
      task.readAsStringSync().replaceFirst('01.01', '99.01'),
    );
    expect(readTracker(fixture.root).stalePaths, <String>[
      'dev-plan/01-setup/001-task.md',
    ]);
    task.writeAsStringSync(
      task.readAsStringSync().replaceFirst('- [ ]', '- [x]'),
    );
    expect(
      readTracker(fixture.root).stalePaths,
      containsAll(<String>[
        'dev-tracker.md',
        'dev-plan/INDEX.md',
        'dev-plan/01-setup/README.md',
      ]),
    );
  });

  for (final String marker in <String>[
    '**Implementation started:** No',
    '**Implementation started** Yes',
    '**Implementation started:** yes',
  ]) {
    test('rejects invalid source marker $marker', () {
      final PlanFixture fixture = PlanFixture()..phase('01-setup');
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
      final PlanFixture fixture = PlanFixture()..phase('01-setup');
      fixture.task('01-setup', '001', checks: checks);
      expect(() => readTracker(fixture.root), throwsFormatException);
      expect(fixture.file('dev-tracker.md').existsSync(), isFalse);
    });
  }

  test('duplicate task IDs fail before writes', () {
    final PlanFixture fixture = PlanFixture()
      ..phase('01-first')
      ..phase('02-second');
    fixture.task('01-first', '001');
    fixture.task('02-second', '001');
    expect(() => readTracker(fixture.root), throwsFormatException);
    expect(fixture.file('dev-tracker.md').existsSync(), isFalse);
  });

  test('dangling, mismatched and forward dependencies fail before writes', () {
    for (final String dependency in <String>[
      '[002](002-task.md)',
      '[999](002-task.md)',
      '[002](absent.md)',
    ]) {
      final PlanFixture fixture = PlanFixture()..phase('01-setup');
      fixture.task('01-setup', '001', depends: dependency);
      fixture.task('01-setup', '002');
      expect(() => readTracker(fixture.root), throwsFormatException);
      expect(fixture.file('dev-tracker.md').existsSync(), isFalse);
    }
  });

  test('malformed README markers fail before any output writes', () {
    final PlanFixture fixture = PlanFixture()..phase('01-setup');
    fixture.task('01-setup', '001');
    fixture
        .file('dev-plan/01-setup/README.md')
        .writeAsStringSync('# 01 — Phase\n\n$generatedStart\n');
    expect(() => readTracker(fixture.root), throwsFormatException);
    expect(fixture.file('dev-tracker.md').existsSync(), isFalse);
  });

  test('orphan tasks cannot silently disappear from the tracker', () {
    final PlanFixture fixture = PlanFixture()..phase('01-setup');
    fixture.task('01-setup', '001');
    fixture
        .file('dev-plan/002-orphan.md')
        .writeAsStringSync('# 002 — Orphan\n');
    expect(() => readTracker(fixture.root), throwsFormatException);
  });

  test('the index and phase summaries retain exactly one row per task', () {
    final PlanFixture fixture = PlanFixture()..phase('01-setup');
    fixture.task('01-setup', '001', checks: '- [x] Verified.');
    fixture.task('01-setup', '002');
    final TrackerSnapshot snapshot = readTracker(fixture.root);
    for (final String path in <String>[
      'dev-plan/INDEX.md',
      'dev-plan/01-setup/README.md',
    ]) {
      final List<String> rows = snapshot.outputs[path]!
          .split('\n')
          .where((String line) => line.startsWith('| 01.'))
          .toList();
      expect(rows, hasLength(2));
      expect(
        rows.where((String line) => line.contains('001-task.md')),
        hasLength(1),
      );
      expect(
        rows.where((String line) => line.contains('002-task.md')),
        hasLength(1),
      );
    }
  });

  test(
    'compact progress counts completed tasks without weighting partial work',
    () {
      final TrackerSnapshot snapshot = readTracker(_mixedProgressPlan().root);
      final String tracker = snapshot.outputs['dev-tracker.md']!;
      final String summary = _plain(
        tracker
            .split('\n')
            .singleWhere((String line) => line.startsWith('**Files:**')),
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
      expect(_phaseRows(tracker), hasLength(4));

      final List<String> rows = _phaseRows(tracker);
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
      final PlanFixture fixture = PlanFixture()..phase('01-setup');
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
        _bars(_phaseRows(tracker).single).single,
        List<String>.filled(10, completed ? '█' : '░').join(),
      );
      expect(tracker, isNot(contains('NaN')));
      if (completed) {
        expect(tracker, contains('None — all tasks are complete'));
        expect(_taskLinks(_phaseRows(tracker).single), isEmpty);
      }
    });
  }

  test('fractional completion percentages round down', () {
    final PlanFixture fixture = PlanFixture()..phase('01-setup');
    fixture.task('01-setup', '001', checks: '- [x] Verified.');
    fixture.task('01-setup', '002', checks: '- [x] Verified.');
    fixture.task('01-setup', '003');
    final String tracker = readTracker(fixture.root).outputs['dev-tracker.md']!;

    expect(_percentage(tracker), 66);
    expect(_bars(tracker).first, '█████████████░░░░░░░');
  });

  test(
    'phase table links each unfinished task once and omits completed task detail',
    () {
      final TrackerSnapshot snapshot = readTracker(_mixedProgressPlan().root);
      final String tracker = snapshot.outputs['dev-tracker.md']!;
      final List<String> rows = _phaseRows(tracker);
      final List<String> links = _taskLinks(rows.join('\n'));

      expect(links, hasLength(4));
      for (final String id in <String>['002', '003', '004', '006']) {
        expect(
          links.where((String link) => link.endsWith('/$id-task.md')),
          hasLength(1),
        );
      }
      for (final String id in <String>['001', '005']) {
        expect(
          links.where((String link) => link.endsWith('/$id-task.md')),
          isEmpty,
        );
        expect(tracker, isNot(contains('/$id-task.md')));
      }
      final List<String> mixedCells = rows[1]
          .split('|')
          .map((String cell) => cell.trim())
          .toList();
      expect(_taskLinks(mixedCells[4]), hasLength(2));
      expect(
        _taskLinks(mixedCells[4]),
        everyElement(anyOf(endsWith('/002-task.md'), endsWith('/003-task.md'))),
      );
      expect(_taskLinks(mixedCells[5]), <String>[
        'dev-plan/02-progress/004-task.md',
      ]);
      expect(tracker, isNot(contains('| Sub-step |')));
      expect(
        tracker,
        isNot(matches(RegExp(r'^## \d{2} [—–-]', multiLine: true))),
      );
    },
  );

  test(
    'completed tasks with open prerequisites remain visible as a concise warning',
    () {
      final PlanFixture fixture = PlanFixture()..phase('01-setup');
      fixture.task('01-setup', '001');
      fixture.task(
        '01-setup',
        '002',
        checks: '- [x] Verified.',
        depends: '[001](001-task.md)',
      );
      final TrackerSnapshot snapshot = readTracker(fixture.root);
      final String tracker = snapshot.outputs['dev-tracker.md']!;
      final List<String> warningLines = tracker
          .split('\n')
          .where((String line) => line.toLowerCase().contains('prerequisite'))
          .toList();

      expect(_percentage(tracker), 50);
      expect(warningLines, hasLength(1));
      expect(_plain(warningLines.single), matches(RegExp(r'\b1\b')));
      expect(warningLines.single, contains('(dev-plan/INDEX.md'));
      expect(tracker, isNot(contains('/002-task.md')));
      expect(
        snapshot.outputs['dev-plan/INDEX.md'],
        contains('Prerequisite review: 001'),
      );
    },
  );

  test(
    'an empty phase has zero progress without altering overall task completion',
    () {
      final PlanFixture fixture = PlanFixture()
        ..phase('01-ready')
        ..phase('02-empty');
      fixture.task('01-ready', '001', checks: '- [x] Verified.');
      final String tracker = readTracker(
        fixture.root,
      ).outputs['dev-tracker.md']!;

      expect(_percentage(tracker), 100);
      expect(_plain(_phaseRows(tracker).last), contains('0/0'));
      expect(_plain(_phaseRows(tracker).last), contains('Pending'));
      expect(_bars(_phaseRows(tracker).last).single, '░░░░░░░░░░');
      expect(tracker, isNot(contains('NaN')));
      expect(tracker, isNot(contains('Infinity')));
    },
  );

  test(
    'the compact tracker retains next work, history and automatic refresh guidance',
    () {
      final TrackerSnapshot snapshot = readTracker(_mixedProgressPlan().root);
      final String tracker = snapshot.outputs['dev-tracker.md']!;

      expect(tracker, contains('Next actionable sub-step:** [02.01 · 002'));
      expect(tracker, contains('dev-plan/01-orchestration/history/README.md'));
      expect(tracker, contains('dev-plan/INDEX.md'));
      expect(tracker, matches(RegExp(r'dev-plan/(?:STANDARD|README)\.md')));
      expect(tracker.toLowerCase(), contains('automatically'));
    },
  );
}

PlanFixture _mixedProgressPlan() {
  final PlanFixture fixture = PlanFixture()
    ..phase('01-ready')
    ..phase('02-progress')
    ..phase('03-done')
    ..phase('04-later');
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
    depends: '[001](../01-ready/001-task.md)',
  );
  fixture.task(
    '02-progress',
    '003',
    started: '**Implementation started:** Yes',
  );
  fixture.task('02-progress', '004', depends: '[002](002-task.md)');
  fixture.task('03-done', '005', checks: '- [x] Verified.');
  fixture.task('04-later', '006', depends: '[004](../02-progress/004-task.md)');
  return fixture;
}

String _plain(String text) => text.replaceAll('*', '').replaceAll('`', '');

int _percentage(String text) =>
    int.parse(RegExp(r'\b(\d+)%').firstMatch(text)!.group(1)!);

List<String> _bars(String text) => RegExp(
  r'[█░]+',
).allMatches(text).map((RegExpMatch match) => match.group(0)!).toList();

List<String> _phaseRows(String text) => text
    .split('\n')
    .where(
      (String line) =>
          line.startsWith('|') &&
          RegExp(r'\]\(dev-plan/\d{2}-[^/]+/README\.md\)').hasMatch(line),
    )
    .toList();

List<String> _taskLinks(String text) => RegExp(
  r'\]\((dev-plan/[^)]+/\d{3}-[^)]+\.md)\)',
).allMatches(text).map((RegExpMatch match) => match.group(1)!).toList();
