part of 'processing.dart';

/// One stored provider response for a [Processing] job.
///
/// [rawResponse] and [requestSummary] are written once when the job
/// finishes and never rewritten.
class ProcessingResults extends Table with MergeColumns {
  /// Job this result belongs to. Several rows may share a job across retries.
  TextColumn get jobId => text()();

  /// Shape and size of the request. Never a key or bearer token.
  TextColumn get requestSummary => text()();

  /// Provider output as it arrived. Written once.
  TextColumn get rawResponse => text()();

  /// Whether the response parsed against the template schema.
  BoolColumn get parsedOk => boolean()();

  /// Token count or cost figure, when the provider reported one.
  TextColumn get tokensOrCost => text().nullable()();
}

final class _ProcessingResultsDao
    extends BaseDao<ProcessingResults, ProcessingResult> {
  _ProcessingResultsDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.processingResults);
}
