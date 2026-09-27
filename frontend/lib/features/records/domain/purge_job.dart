import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';

import 'purge_candidate.dart';
import 'purge_report.dart';
import 'purge_store.dart';

/// The retention purge's policy (task 014 step 7, D13).
///
/// Takes only deleted records whose window has passed, never one a merge
/// still needs, and purges each on its own so one failure does not stop the
/// rest. Pure Dart: the rows and files go through [store].
final class PurgeJob {
  /// Creates a job over [store], timed by [clock], keeping deleted records
  /// for [retentionDays] whole days.
  const PurgeJob({
    required this.store,
    required this.clock,
    required this.retentionDays,
  });

  /// Where candidates come from and where they are removed.
  final PurgeStore store;

  /// The clock the window is measured on.
  final Clock clock;

  /// Whole days a deleted record stays recoverable. Below 0 reads as 0.
  final int retentionDays;

  /// The latest deletion instant a run takes: now less [retentionDays] whole
  /// days. A record deleted at or before it is due.
  DateTime get cutoff {
    final int days = retentionDays < 0 ? 0 : retentionDays;
    return DateTime.fromMillisecondsSinceEpoch(
      clock.nowUtc().millisecondsSinceEpoch -
          days * Duration.millisecondsPerDay,
      isUtc: true,
    );
  }

  /// Whether [candidate]'s window has passed.
  bool isDue(PurgeCandidate candidate) => !candidate.deletedAt.isAfter(cutoff);

  /// Purges every due candidate and reports the counts.
  ///
  /// With [ignoreWindow] (the recycle bin's "empty now") every deleted
  /// record is due, but a record a merge still needs is still skipped. A
  /// record that fails to purge is counted in [PurgeReport.failed] and the
  /// run moves on; only a failure to list the candidates fails the run.
  Future<Result<PurgeReport>> run({bool ignoreWindow = false}) async {
    final Result<List<PurgeCandidate>> listed = await _guard(store.candidates);
    final List<PurgeCandidate> candidates;
    switch (listed) {
      case FailureResult<List<PurgeCandidate>>(:final Failure failure):
        return FailureResult<PurgeReport>(failure);
      case Success<List<PurgeCandidate>>(:final List<PurgeCandidate> value):
        candidates = value;
    }
    final DateTime limit = cutoff;
    int purged = 0;
    int skippedRecent = 0;
    int skippedMergeNeeded = 0;
    int filesRemoved = 0;
    int failed = 0;
    for (final PurgeCandidate candidate in candidates) {
      if (!ignoreWindow && candidate.deletedAt.isAfter(limit)) {
        skippedRecent++;
        continue;
      }
      if (candidate.mergeNeeded) {
        skippedMergeNeeded++;
        continue;
      }
      final Result<int> removed = await _guard(() => store.purge(candidate));
      switch (removed) {
        case Success<int>(:final int value):
          purged++;
          filesRemoved += value;
        case FailureResult<int>():
          failed++;
      }
    }
    return Success<PurgeReport>(
      PurgeReport(
        purged: purged,
        skippedRecent: skippedRecent,
        skippedMergeNeeded: skippedMergeNeeded,
        filesRemoved: filesRemoved,
        failed: failed,
      ),
    );
  }
}

/// Runs [call], turning a store that throws into a [FailureResult] so one
/// bad record cannot end the run.
Future<Result<T>> _guard<T>(Future<Result<T>> Function() call) async {
  try {
    return await call();
  } on Object catch (error) {
    return FailureResult<T>(Failure.from(error));
  }
}
