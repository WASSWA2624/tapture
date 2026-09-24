import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/save_and_analyse.dart';
import 'package:tapture/features/processing/processing.dart';

void main() {
  test(
    'retry of a committed record skips persistence and re-enqueues',
    () async {
      var persistCalls = 0;
      var enqueueCalls = 0;
      const CaptureSession session = CaptureSession(
        id: 'session-1',
        projectId: 'project-1',
        templateId: 'template-1',
        contextSnapshot: <String, String>{},
        recordId: 'record-1',
        captions: <String, String>{'': 'Record note'},
      );

      final Result<SaveAndAnalyseResult> result = await SaveAndAnalyse.run(
        session: session,
        persist: (CaptureSession _) async {
          persistCalls += 1;
          return const Success<String>('unexpected');
        },
        enqueue: (String recordId) async {
          enqueueCalls += 1;
          return Success<ProcessingJob>(
            SaveAndAnalyse.jobFor(jobId: 'job-1', recordId: recordId),
          );
        },
      );

      final SaveAndAnalyseResult saved = switch (result) {
        Success<SaveAndAnalyseResult>(:final value) => value,
        FailureResult<SaveAndAnalyseResult>(:final Failure failure) =>
          throw TestFailure(failure.message),
      };
      expect(saved.recordId, 'record-1');
      expect(saved.enqueueFailed, isFalse);
      expect(persistCalls, 0);
      expect(enqueueCalls, 1);
    },
  );
}
