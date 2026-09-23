import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/processing.dart';

import 'capture_session.dart';

part 'save_and_analyse_result.dart';

/// Save path that persists then enqueues analysis. A failed enqueue leaves
/// a complete CAPTURED record with a retryable job (task 012).
abstract final class SaveAndAnalyse {
  /// Status written before enqueue.
  static const String capturedStatus = 'CAPTURED';

  /// Builds a processing job for [session] after the record is durable.
  static ProcessingJob jobFor({
    required String jobId,
    required String recordId,
  }) {
    return ProcessingJob(
      id: jobId,
      recordId: recordId,
      stage: '',
      attemptCount: 0,
    );
  }

  /// Persists via [persist] then enqueues via [enqueue]. A session carrying a
  /// [CaptureSession.recordId] has already committed its raw record, so retry
  /// goes straight to enqueue instead of duplicating immutable evidence.
  /// On enqueue failure returns the committed id with [enqueueFailed].
  static Future<Result<SaveAndAnalyseResult>> run({
    required CaptureSession session,
    required Future<Result<String>> Function(CaptureSession session) persist,
    required Future<Result<ProcessingJob>> Function(String recordId) enqueue,
  }) async {
    if (!session.hasEvidence && session.recordCaption.trim().isEmpty) {
      return const FailureResult<SaveAndAnalyseResult>(
        ValidationFailure(
          message: 'Add at least one photo or a caption before saving.',
          recoveryAction: 'Add evidence, then try again.',
        ),
      );
    }
    final String? committedId = session.recordId;
    final Result<String> saved = committedId == null
        ? await persist(session)
        : Success<String>(committedId);
    return saved.fold(FailureResult<SaveAndAnalyseResult>.new, (
      String recordId,
    ) async {
      final Result<ProcessingJob> job = await enqueue(recordId);
      return job.fold(
        (Failure _) => Success<SaveAndAnalyseResult>(
          SaveAndAnalyseResult(recordId: recordId, enqueueFailed: true),
        ),
        (ProcessingJob _) => Success<SaveAndAnalyseResult>(
          SaveAndAnalyseResult(recordId: recordId),
        ),
      );
    });
  }
}
