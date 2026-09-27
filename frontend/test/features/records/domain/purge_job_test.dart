import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/records/domain/purge_candidate.dart';
import 'package:tapture/features/records/domain/purge_job.dart';
import 'package:tapture/features/records/domain/purge_report.dart';

import '../fakes/fake_purge_store.dart';
import '../fakes/record_results.dart';

final DateTime _now = DateTime.utc(2026, 9, 27, 9);

PurgeCandidate _deleted(
  String id, {
  required int daysAgo,
  bool mergeNeeded = false,
}) {
  return PurgeCandidate(
    recordId: id,
    projectId: 'project-1',
    deletedAt: DateTime.utc(2026, 9, 27 - daysAgo, 9),
    mergeNeeded: mergeNeeded,
  );
}

PurgeJob _job(FakePurgeStore store, {int retentionDays = 30}) {
  return PurgeJob(
    store: store,
    clock: FixedClock(_now),
    retentionDays: retentionDays,
  );
}

const StorageFailure _locked = StorageFailure(
  message: 'The record could not be removed.',
  recoveryAction: 'Try again later.',
);

void main() {
  test('the cutoff is now less the retention window in whole days', () {
    final FakePurgeStore store = FakePurgeStore();
    expect(_job(store).cutoff, DateTime.utc(2026, 8, 28, 9));
    expect(_job(store, retentionDays: 7).cutoff, DateTime.utc(2026, 9, 20, 9));
    expect(_job(store, retentionDays: 0).cutoff, _now);
    expect(_job(store, retentionDays: -3).cutoff, _now);
  });

  test('a deletion exactly one window old is due, a second younger is not', () {
    final PurgeJob job = _job(FakePurgeStore());
    expect(job.isDue(_deleted('old', daysAgo: 30)), isTrue);
    expect(
      job.isDue(
        PurgeCandidate(
          recordId: 'young',
          projectId: 'project-1',
          deletedAt: DateTime.utc(2026, 8, 28, 9, 0, 1),
        ),
      ),
      isFalse,
    );
  });

  test('a recent deletion survives a run', () async {
    final FakePurgeStore store = FakePurgeStore(<PurgeCandidate>[
      _deleted('recent', daysAgo: 3),
    ]);
    final PurgeReport report = okOf(await _job(store).run());
    expect(report, const PurgeReport(skippedRecent: 1));
    expect(store.attempted, isEmpty);
    expect(store.remaining.single.recordId, 'recent');
  });

  test('a record past the window is purged with its files', () async {
    final FakePurgeStore store = FakePurgeStore(<PurgeCandidate>[
      _deleted('old', daysAgo: 31),
      _deleted('recent', daysAgo: 29),
    ])..filesById['old'] = 3;
    final PurgeReport report = okOf(await _job(store).run());
    expect(report.purged, 1);
    expect(report.filesRemoved, 3);
    expect(report.skippedRecent, 1);
    expect(store.purged, <String>['old']);
    expect(store.remaining.single.recordId, 'recent');
  });

  test('an unmerged tombstone is skipped, however old', () async {
    final FakePurgeStore store = FakePurgeStore(<PurgeCandidate>[
      _deleted('needed', daysAgo: 90, mergeNeeded: true),
      _deleted('free', daysAgo: 90),
    ]);
    final PurgeReport report = okOf(await _job(store).run());
    expect(report.skippedMergeNeeded, 1);
    expect(report.purged, 1);
    expect(store.attempted, <String>['free']);
    expect(store.remaining.single.recordId, 'needed');
  });

  test(
    'one failing record is counted failed and does not stop the rest',
    () async {
      final FakePurgeStore store =
          FakePurgeStore(<PurgeCandidate>[
              _deleted('first', daysAgo: 40),
              _deleted('broken', daysAgo: 40),
              _deleted('thrower', daysAgo: 40),
              _deleted('last', daysAgo: 40),
            ])
            ..failuresById['broken'] = _locked
            ..throwsFor.add('thrower');
      final PurgeReport report = okOf(await _job(store).run());
      expect(report.purged, 2);
      expect(report.failed, 2);
      expect(store.attempted, <String>['first', 'broken', 'thrower', 'last']);
      expect(store.purged, <String>['first', 'last']);
      expect(
        store.remaining.map((PurgeCandidate held) => held.recordId),
        <String>['broken', 'thrower'],
      );
    },
  );

  test(
    'ignoreWindow purges recent ones but still skips merge-needed',
    () async {
      final FakePurgeStore store = FakePurgeStore(<PurgeCandidate>[
        _deleted('today', daysAgo: 0),
        _deleted('recent', daysAgo: 2),
        _deleted('needed', daysAgo: 1, mergeNeeded: true),
      ]);
      final PurgeReport report = okOf(
        await _job(store).run(ignoreWindow: true),
      );
      expect(report.purged, 2);
      expect(report.skippedRecent, 0);
      expect(report.skippedMergeNeeded, 1);
      expect(store.remaining.single.recordId, 'needed');
    },
  );

  test('an empty bin reports nothing', () async {
    final PurgeReport report = okOf(await _job(FakePurgeStore()).run());
    expect(report, PurgeReport.none);
  });

  test('a store that cannot list candidates fails the run', () async {
    final FakePurgeStore store = FakePurgeStore(<PurgeCandidate>[
      _deleted('old', daysAgo: 40),
    ])..listFailure = _locked;
    final Failure failure = failureOf(await _job(store).run());
    expect(failure, same(_locked));
    expect(store.attempted, isEmpty);
  });

  test('a second run finds nothing left to purge', () async {
    final FakePurgeStore store = FakePurgeStore(<PurgeCandidate>[
      _deleted('old', daysAgo: 40),
    ]);
    final PurgeJob job = _job(store);
    expect(okOf(await job.run()).purged, 1);
    expect(okOf(await job.run()), PurgeReport.none);
  });
}
