import 'package:drift/drift.dart';
import 'package:tapture/core/ai/ai_usage.dart';
import 'package:tapture/core/ai/auxiliary_ai_usage.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/settings/settings.dart';

import '../domain/processing_usage_repository.dart';
import 'stage_support.dart';

/// One accounting query shared by request limits, queue counts and cost views.
final class ProcessingUsage implements ProcessingUsageRepository {
  /// Reads durable attempt identities and optional provider usage metadata.
  const ProcessingUsage({
    required this._db,
    required this._settings,
    this._clock = const SystemClock(),
  });

  final AppDatabase _db;
  final SettingsStore _settings;
  final Clock _clock;

  /// A bounded aggregate subscription invalidates spending when replies arrive.
  @override
  Stream<({Map<String, double> reservedCosts, int? totalTokens})> watchSpend({
    String? projectId,
  }) =>
      (_db.selectOnly(
            _db.processingResults,
          )..addColumns(<Expression<Object>>[_db.processingResults.id.count()]))
          .watch()
          .asyncMap((_) async {
            final usage = (await on(
              _clock.nowUtc(),
              projectId: projectId,
            )).getOrThrow();
            return (
              reservedCosts: usage.reservedCosts,
              totalTokens: usage.totalTokens,
            );
          });

  /// Attempts count once, including failures; replies never double-count them.
  Future<
    Result<
      ({
        int requests,
        int images,
        Map<String, double> reservedCosts,
        int? totalTokens,
      })
    >
  >
  on(DateTime day, {String? projectId}) async {
    try {
      return Success(await _on(day, projectId: projectId));
    } on Failure catch (failure) {
      return FailureResult(failure);
    } on Object catch (error) {
      return FailureResult(storageFailureFrom(error));
    }
  }

  Future<
    ({
      int requests,
      int images,
      Map<String, double> reservedCosts,
      int? totalTokens,
    })
  >
  _on(DateTime day, {String? projectId}) async {
    final DateTime start = DateTime.utc(day.year, day.month, day.day);
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT pr.id AS id, pr.request_summary AS summary FROM processing_results pr '
          'JOIN processing_jobs pj ON pj.id = pr.job_id '
          'JOIN records r ON r.id = pj.record_id '
          'WHERE pr.created_at >= ? AND pr.created_at < ? '
          '${projectId == null ? '' : 'AND r.project_id = ?'}',
          variables: <Variable<Object>>[
            Variable<DateTime>(start),
            Variable<DateTime>(start.add(AppConstants.processing.dayWindow)),
            if (projectId != null) Variable<String>(projectId),
          ],
          readsFrom: <ResultSetImplementation<Object?, Object?>>{
            _db.processingResults,
            _db.processing,
            _db.records,
          },
        )
        .get();
    final Map<String, int> images = <String, int>{};
    final Map<String, AiUsage> usage = <String, AiUsage>{};
    for (final QueryRow row in rows) {
      final Object? summary = StageSupport.json(row.read<String>('summary'));
      if (summary is! Map<String, Object?> ||
          (summary['kind'] != 'online' &&
              summary['kind'] != 'attempt' &&
              !(summary['kind'] == 'transcript' &&
                  summary['source'] != 'device'))) {
        continue;
      }
      final String identity = summary['idempotencyKey'] is String
          ? summary['idempotencyKey']! as String
          : row.read<String>('id');
      final Object? count = summary['images'] is List
          ? (summary['images']! as List<Object?>).length
          : summary['imageCount'];
      images[identity] = count is int && count >= 0 ? count : 0;
      try {
        final AiUsage? reported = AiUsage.fromJson(summary['usage']);
        if (reported != null) usage[identity] = reported;
      } on FormatException {
        // Optional legacy usage never changes capture or request accounting.
      }
    }
    final Map<String, double> costs = <String, double>{};
    int? tokens;
    for (final AiUsage reported in usage.values) {
      costs.update(
        reported.currency,
        (double amount) => amount + reported.reservedCost,
        ifAbsent: () => reported.reservedCost,
      );
      if (reported.totalTokens case final int count) {
        tokens = (tokens ?? 0) + count;
      }
    }
    return (
      requests:
          images.length +
          AuxiliaryAiUsage(
            _settings.read(SettingKeys.aiAuxiliaryUsage),
          ).count(day, projectId: projectId),
      images: images.values.fold(0, (int total, int count) => total + count),
      reservedCosts: Map<String, double>.unmodifiable(costs),
      totalTokens: tokens,
    );
  }
}
