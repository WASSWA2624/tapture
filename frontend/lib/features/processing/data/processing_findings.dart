import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/processing_findings_repository.dart';

import 'stage_support.dart';

/// Bounded per-record findings and unresolved charge identities from local jobs.
final class ProcessingFindings implements ProcessingFindingsRepository {
  /// Production reader over the app's one database.
  const ProcessingFindings({required this._db});

  /// Empty fake used before bootstrap and by isolated feature tests.
  const ProcessingFindings.empty() : _db = null;

  final AppDatabase? _db;

  /// The latest job only; adding a review never materialises the whole queue.
  @override
  Stream<List<String>> watchRecord(String recordId) async* {
    final AppDatabase? db = _db;
    if (db == null) {
      yield const <String>[];
      return;
    }
    try {
      final query = db.select(db.processing)
        ..where(($ProcessingTable row) => row.recordId.equals(recordId))
        ..orderBy(<OrderClauseGenerator<$ProcessingTable>>[
          ($ProcessingTable row) => OrderingTerm.desc(row.queuedAt),
          ($ProcessingTable row) => OrderingTerm.desc(row.id),
        ])
        ..limit(1);
      await for (final List<ProcessingJobRow> rows in query.watch()) {
        yield rows.isEmpty
            ? const <String>[]
            : StageSupport.strings(rows.single.rejections ?? '[]');
      }
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw Failure.from(storageFailureFrom(error));
    }
  }

  /// An attempted request with no local reply may already have been charged.
  @override
  Future<Result<bool>> requiresRetryApproval(String jobId) async {
    final AppDatabase? db = _db;
    if (db == null) return const Success<bool>(false);
    try {
      final List<ProcessingResult> rows = await (db.select(
        db.processingResults,
      )..where(($ProcessingResultsTable row) => row.jobId.equals(jobId))).get();
      final Set<String> attempts = <String>{};
      final Set<String> replies = <String>{};
      for (final ProcessingResult row in rows) {
        final String? id = StageSupport.summaryValue(
          row.requestSummary,
          'idempotencyKey',
        );
        if (id == null) continue;
        if (StageSupport.summaryValue(row.requestSummary, 'kind') ==
            'attempt') {
          attempts.add(id);
        }
        if (StageSupport.summaryValue(row.requestSummary, 'kind') == 'online' ||
            StageSupport.summaryValue(row.requestSummary, 'kind') ==
                'transcript') {
          replies.add(id);
        }
      }
      return Success<bool>(attempts.difference(replies).isNotEmpty);
    } on Failure catch (failure) {
      return FailureResult<bool>(failure);
    } on Object catch (error) {
      return FailureResult<bool>(storageFailureFrom(error));
    }
  }
}
