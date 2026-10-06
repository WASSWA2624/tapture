import 'package:tapture/core/copy/localized_message.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/cost_guard.dart';
import 'job_writes.dart';
import 'processing_usage.dart';
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
    await _writes.setQueueMessage(
      jobId,
      guard.blockMessage,
      localizedMessage: guard.localizedBlockMessage,
    );
    throw CancelledFailure(
      message: guard.blockMessage,
      localizedMessage: guard.localizedBlockMessage,
      recoveryAction: 'Processing will be available after the daily reset.',
      localizedRecovery: const LocalizedMessage(
        key: 'processingDailyResetRecovery',
        fallback: 'Processing will be available after the daily reset.',
      ),
    );
  }

  Future<int> _requestsToday(String projectId) async => (await ProcessingUsage(
    db: _db,
    settings: _settings.store,
  ).on(_clock.nowUtc(), projectId: projectId)).getOrThrow().requests;
}
