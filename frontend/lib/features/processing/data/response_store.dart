import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/processing.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

/// Stores a provider response as it arrived, before it is parsed.
///
/// The request summary is shape and size only. A key or bearer token is
/// refused.
final class ResponseStore {
  /// Opens against [db].
  ResponseStore({
    required this._db,
    required this._clock,
    required this._deviceId,
    required this._ids,
  });

  final AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;

  /// Appends [rawResponse]. [requestSummary] must not carry a secret.
  Future<Result<ProcessingResult>> save({
    required String jobId,
    required String requestSummary,
    required String rawResponse,
    required bool parsedOk,
  }) {
    if (_hasSecret(requestSummary)) {
      return Future<Result<ProcessingResult>>.value(
        const FailureResult<ProcessingResult>(
          StorageFailure(
            message: 'A request summary cannot include a secret.',
            recoveryAction: 'Store shape and size only, then save again.',
          ),
        ),
      );
    }
    return insertProcessingResult(
      _db,
      row: ProcessingResultsCompanion(
        jobId: Value(jobId),
        requestSummary: Value(requestSummary),
        rawResponse: Value(rawResponse),
        parsedOk: Value(parsedOk),
      ),
      clock: _clock,
      deviceId: _deviceId,
      ids: _ids,
    );
  }

  /// Stored responses for [jobId], oldest first.
  Future<Result<List<ProcessingResult>>> forJob(String jobId) {
    return listProcessingResults(_db, jobId: jobId);
  }
}

bool _hasSecret(String summary) {
  final String folded = summary.toLowerCase();
  return folded.contains('bearer ') ||
      folded.contains('"apikey"') ||
      folded.contains('"api_key"') ||
      folded.contains('"secret"') ||
      folded.contains('"token"');
}
