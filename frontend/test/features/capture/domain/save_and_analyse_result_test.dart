import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/save_and_analyse.dart';
import 'package:tapture/features/processing/domain/processing_repository.dart';

import '../../../support/matchers.dart';

const CaptureSession _session = CaptureSession(
  id: 'session-1',
  templateId: 't',
  contextSnapshot: <String, String>{},
  photos: <PhotoDraft>[
    PhotoDraft(id: 'p', projectId: 'proj', relativePath: 'a.jpg', sha256: 'h'),
  ],
);

const StorageFailure _offline = StorageFailure(
  message: 'offline',
  recoveryAction: 'retry',
);

Future<Result<String>> _persistAs(CaptureSession _) async {
  return const Success<String>('rec-9');
}

Future<Result<ProcessingJob>> _enqueueFails(String _) async {
  return const FailureResult<ProcessingJob>(_offline);
}

Future<Result<ProcessingJob>> _enqueueWorks(String recordId) async {
  return Success<ProcessingJob>(
    SaveAndAnalyse.jobFor(jobId: 'job-1', recordId: recordId),
  );
}

void main() {
  test('a failed enqueue leaves a complete captured record with a retryable '
      'job', () async {
    final SaveAndAnalyseResult result = valueOf(
      await SaveAndAnalyse.run(
        session: _session,
        persist: _persistAs,
        enqueue: _enqueueFails,
      ),
    );

    expect(result.recordId, 'rec-9');
    expect(result.enqueueFailed, isTrue);
  });

  test('a successful enqueue reports the record with nothing to retry', () async {
    final SaveAndAnalyseResult result = valueOf(
      await SaveAndAnalyse.run(
        session: _session,
        persist: _persistAs,
        enqueue: _enqueueWorks,
      ),
    );

    expect(result.recordId, 'rec-9');
    expect(result.enqueueFailed, isFalse);
  });

  test('the record id is the one persistence returned, not the session '
      'id', () async {
    final SaveAndAnalyseResult result = valueOf(
      await SaveAndAnalyse.run(
        session: _session,
        persist: _persistAs,
        enqueue: _enqueueWorks,
      ),
    );

    expect(result.recordId, isNot(_session.id));
  });

  test(
    'a result that needs a retry names the durable record so the retry '
    'skips persistence and only enqueues',
    () async {
      final SaveAndAnalyseResult first = valueOf(
        await SaveAndAnalyse.run(
          session: _session,
          persist: _persistAs,
          enqueue: _enqueueFails,
        ),
      );
      var persistCalls = 0;
      final List<String> enqueued = <String>[];

      final SaveAndAnalyseResult retried = valueOf(
        await SaveAndAnalyse.run(
          session: _session.copyWith(recordId: first.recordId),
          persist: (CaptureSession _) async {
            persistCalls += 1;
            return const Success<String>('rec-duplicate');
          },
          enqueue: (String recordId) async {
            enqueued.add(recordId);
            return _enqueueWorks(recordId);
          },
        ),
      );

      expect(persistCalls, 0);
      expect(enqueued, <String>['rec-9']);
      expect(retried.recordId, 'rec-9');
      expect(retried.enqueueFailed, isFalse);
    },
  );

  test('a failed persist yields no result at all', () async {
    final Result<SaveAndAnalyseResult> result = await SaveAndAnalyse.run(
      session: _session,
      persist: (CaptureSession _) async =>
          const FailureResult<String>(_offline),
      enqueue: _enqueueWorks,
    );

    expect(result, isFailure<SaveAndAnalyseResult, StorageFailure>());
  });
}
