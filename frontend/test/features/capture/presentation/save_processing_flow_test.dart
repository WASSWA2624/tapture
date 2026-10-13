import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/capture/presentation/record_caption_field.dart';
import 'package:tapture/features/processing/domain/processing_findings_repository.dart';
import 'package:tapture/features/processing/presentation/processing_controller.dart';
import 'package:tapture/features/processing/processing.dart';
import 'package:tapture/features/review/review.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_processing_repository.dart';
import '../../../support/fakes/fake_record_repository.dart';
import '../../../support/screen_fonts.dart';
import '../../../support/screen_matrix.dart';
import '../../review/fakes/fake_review_repository.dart';
import 'capture_workflow_fixture.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);

  testWidgets(
    'offline Save and analyse commits before processing and opens manual review',
    (tester) async {
      final FakeProcessingRepository queue = FakeProcessingRepository();
      final FakeRecordRepository records = FakeRecordRepository();
      addTearDown(queue.dispose);
      late CaptureWorkflowFixture fixture;
      final List<JobStage> started = <JobStage>[];
      fixture = await CaptureWorkflowFixture.open(
        tester,
        cell: const ScreenMatrix(Size(600, 1000), 1, Brightness.light, false),
        offline: true,
        recordStore: records,
        extraOverrides: <Override>[
          processingRepositoryProvider.overrideWith((Ref _) => queue),
          reviewRepositoryProvider.overrideWith(
            (Ref _) => FakeReviewRepository(records),
          ),
          reviewProposalsProvider.overrideWith(
            (Ref _, String _) async => const <ReanalyseProposal>[],
          ),
          processingFindingsStoreProvider.overrideWith(
            (Ref _) => const _ManualFindings(),
          ),
          processingStageWorkProvider.overrideWith(
            (Ref _) =>
                (JobStage stage, ProcessingJob job, CancellationToken _) async {
                  expect(
                    fixture.records.records[job.recordId]?.recordCaption,
                    'Original field evidence',
                  );
                  started.add(stage);
                  if (stage == JobStage.validate) {
                    records.seedEntry(
                      aRecordEntry(
                        id: job.recordId,
                        projectId: 'p1',
                        templateId: 't1',
                        status: RecordStatus.needsReview,
                        caption: 'Original field evidence',
                        fields: const <String, String>{},
                      ),
                    );
                  }
                  return null;
                },
          ),
        ],
      );
      final Finder caption = find.descendant(
        of: find.byType(RecordCaptionField),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(caption);
      await tester.enterText(caption, 'Original field evidence');
      await tester.pumpAndSettle();
      final String sessionId = fixture.session(tester).id;
      FocusManager.instance.primaryFocus?.unfocus();
      final Finder save = find.byKey(
        const ValueKey<String>('capture-save-process'),
      );
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(fixture.records.persisted, hasLength(1));
      expect(
        fixture.records.persisted.single.recordCaption,
        'Original field evidence',
      );
      expect(fixture.session(tester).id, isNot(sessionId));
      expect(
        find.byKey(const ValueKey<String>('route-review')),
        findsOneWidget,
      );
      expect(
        tester.widget<ReviewScreen>(find.byType(ReviewScreen)).analyseOnOpen,
        isTrue,
      );
      expect(started, JobStage.values);
      expect(queue.stored.single.status, JobStatus.completed);
      expect(find.text(Copy.processingManualFallback), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('review-type-it')),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

final class _ManualFindings implements ProcessingFindingsRepository {
  const _ManualFindings();
  @override
  Stream<List<String>> watchRecord(String recordId) =>
      Stream<List<String>>.value(<String>[Copy.processingManualFallback]);
  @override
  Future<Result<bool>> requiresRetryApproval(String jobId) async =>
      const Success<bool>(false);
  @override
  Future<Result<bool>> requiresRecordRetryApproval(String recordId) async =>
      const Success<bool>(false);
}
