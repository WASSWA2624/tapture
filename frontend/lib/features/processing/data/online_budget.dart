import 'package:drift/drift.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/cost_guard.dart';
import 'job_writes.dart';
import 'record_bundle.dart';
import 'stage_settings.dart';

/// Today's online usage and the daily cap check made before each call.
final class OnlineBudget {
  /// Creates the budget over [db].
  const OnlineBudget({
    required this._db,
    required this._clock,
    required this._settings,
    required this._writes,
  });

  final AppDatabase _db;
  final Clock _clock;
  final StageSettings _settings;
  final JobWrites _writes;

  /// Returns when another online request is allowed today for [bundle]'s
  /// project, against the project's own cap or the app's.
  ///
  /// At the cap the job goes back on the queue with [CostGuard]'s message
  /// naming the cap and the reset, and a [CancelledFailure] stops the stage.
  Future<void> require(String jobId, RecordBundle bundle) async {
    final CostGuard guard = CostGuard(
      requestsToday: await _requestsToday(bundle.record.projectId),
      imagesToday: 0,
      requestCap: _settings.project(bundle).dailyRequestCap,
      now: _clock.nowUtc(),
    );
    if (!guard.isBlocked) {
      return;
    }
    await _writes.setQueueMessage(jobId, guard.blockMessage);
    throw CancelledFailure(
      message: guard.blockMessage,
      recoveryAction: 'Processing will be available after the daily reset.',
    );
  }

  Future<int> _requestsToday(String projectId) async {
    final DateTime now = _clock.nowUtc();
    final DateTime start = DateTime.utc(now.year, now.month, now.day);
    final DateTime end = start.add(AppConstants.processing.dayWindow);
    final QueryRow row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM processing_results pr '
          'JOIN processing_jobs pj ON pj.id = pr.job_id '
          'JOIN records r ON r.id = pj.record_id '
          'WHERE r.project_id = ? AND pr.created_at >= ? '
          'AND pr.created_at < ? AND pr.request_summary LIKE ?',
          variables: <Variable<Object>>[
            Variable<String>(projectId),
            Variable<DateTime>(start),
            Variable<DateTime>(end),
            const Variable<String>('%"kind":"online"%'),
          ],
          readsFrom: <ResultSetImplementation<Object?, Object?>>{
            _db.processingResults,
            _db.processing,
            _db.records,
          },
        )
        .getSingle();
    return row.read<int>('c');
  }
}
