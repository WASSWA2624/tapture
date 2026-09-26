import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/processing/domain/template_choice_needed.dart';
import 'package:tapture/features/processing/presentation/processing_batch_state.dart';
import 'package:tapture/features/processing/presentation/processing_controller.dart';
import 'package:tapture/features/processing/presentation/queue_providers.dart';

import '../../../support/fakes/fake_processing_repository.dart';

void main() {
  test('a foreground batch runs every stage and reports one summary', () async {
    final FakeProcessingRepository repository = FakeProcessingRepository();
    addTearDown(repository.dispose);
    await repository.save(
      const ProcessingJob(id: 'job-1', recordId: 'record-1'),
    );
    final List<JobStage> stages = <JobStage>[];
    final List<({int succeeded, int failed})> notices =
        <({int succeeded, int failed})>[];
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        processingRepositoryProvider.overrideWith((_) => repository),
        processingStageWorkProvider.overrideWith((_) {
          return (JobStage stage, ProcessingJob _, CancellationToken _) async =>
              stages.add(stage);
        }),
        processingNotificationsProvider.overrideWith((_) {
          return (int succeeded, int failed) async {
            notices.add((succeeded: succeeded, failed: failed));
          };
        }),
      ],
    );
    addTearDown(container.dispose);
    final ProviderSubscription<ProcessingBatchState> subscription = container
        .listen<ProcessingBatchState>(processingControllerProvider, (_, _) {});
    addTearDown(subscription.close);

    await container
        .read(processingControllerProvider.notifier)
        .process(confirmOnline: (_) async => true);

    expect(stages, JobStage.values);
    expect(container.read(processingControllerProvider).succeeded, 1);
    expect(container.read(processingControllerProvider).failed, 0);
    expect(notices, <({int succeeded, int failed})>[(succeeded: 1, failed: 0)]);
    expect(
      (await repository.byId(
        'job-1',
      )).fold((_) => null, (ProcessingJob? job) => job?.status),
      JobStatus.completed,
    );
  });

  test('declining first egress leaves the job claimable at detect', () async {
    final FakeProcessingRepository repository = FakeProcessingRepository();
    addTearDown(repository.dispose);
    await repository.save(
      const ProcessingJob(id: 'job-1', recordId: 'record-1'),
    );
    final List<JobStage> stages = <JobStage>[];
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        processingRepositoryProvider.overrideWith((_) => repository),
        processingStageWorkProvider.overrideWith((_) {
          return (JobStage stage, ProcessingJob _, CancellationToken _) async =>
              stages.add(stage);
        }),
      ],
    );
    addTearDown(container.dispose);
    final ProviderSubscription<ProcessingBatchState> subscription = container
        .listen<ProcessingBatchState>(processingControllerProvider, (_, _) {});
    addTearDown(subscription.close);

    await container
        .read(processingControllerProvider.notifier)
        .process(confirmOnline: (_) async => false);

    expect(stages, <JobStage>[
      JobStage.prepare,
      JobStage.onDevice,
      JobStage.detect,
    ]);
    final ProcessingJob? stored = (await repository.byId(
      'job-1',
    )).fold((_) => null, (ProcessingJob? job) => job);
    expect(stored?.status, JobStatus.queued);
    expect(stored?.stage, JobStage.detect.name);
  });

  test('retry returns a stopped job to the queue', () async {
    final FakeProcessingRepository repository = FakeProcessingRepository();
    addTearDown(repository.dispose);
    await repository.save(
      const ProcessingJob(
        id: 'job-1',
        recordId: 'record-1',
        status: JobStatus.failed,
        permanent: true,
        lastError: 'Authentication failed.',
      ),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        processingRepositoryProvider.overrideWith((_) => repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(processingControllerProvider.notifier).retry('job-1');

    final ProcessingJob? stored = (await repository.byId(
      'job-1',
    )).fold((_) => null, (ProcessingJob? job) => job);
    expect(stored?.status, JobStatus.queued);
    expect(stored?.permanent, isFalse);
    expect(stored?.lastError, isNull);
  });

  group('a stage that cannot decide the template', () {
    const TemplateChoiceNeeded needed = TemplateChoiceNeeded(
      recordId: 'record-1',
      projectId: 'project-1',
      shortlist: <({String templateId, String label})>[
        (templateId: 'pump', label: 'Pump'),
        (templateId: 'motor', label: 'Motor'),
      ],
      pinKey: 'room=Plant room',
    );

    /// Records each stage, and throws [needed] from detect until [decided].
    ProcessingStageWork detectOnce(
      List<JobStage> stages,
      bool Function() decided,
    ) {
      return (JobStage stage, ProcessingJob _, CancellationToken _) async {
        stages.add(stage);
        if (stage == JobStage.detect && !decided()) {
          throw needed;
        }
      };
    }

    test(
      'asks once, applies the choice, retries the stage and finishes',
      () async {
        final FakeProcessingRepository repository = FakeProcessingRepository();
        addTearDown(repository.dispose);
        await repository.save(
          const ProcessingJob(id: 'job-1', recordId: 'record-1'),
        );
        final List<JobStage> stages = <JobStage>[];
        final List<TemplateChoiceNeeded> asked = <TemplateChoiceNeeded>[];
        final List<TemplateChoice> applied = <TemplateChoice>[];
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            processingRepositoryProvider.overrideWith((_) => repository),
            processingStageWorkProvider.overrideWith((_) {
              return detectOnce(stages, () => applied.isNotEmpty);
            }),
            processingTemplateChoiceProvider.overrideWith((_) {
              return (TemplateChoiceNeeded _, TemplateChoice choice) async {
                applied.add(choice);
                return const Success<void>(null);
              };
            }),
          ],
        );
        addTearDown(container.dispose);
        final ProviderSubscription<ProcessingBatchState> subscription =
            container.listen<ProcessingBatchState>(
              processingControllerProvider,
              (_, _) {},
            );
        addTearDown(subscription.close);

        await container
            .read(processingControllerProvider.notifier)
            .process(
              confirmOnline: (_) async => true,
              chooseTemplate: (TemplateChoiceNeeded question) async {
                asked.add(question);
                return (
                  templateId: question.shortlist.last.templateId,
                  pin: true,
                );
              },
            );

        expect(asked, <TemplateChoiceNeeded>[needed]);
        expect(applied, <TemplateChoice>[(templateId: 'motor', pin: true)]);
        expect(stages, <JobStage>[
          JobStage.prepare,
          JobStage.onDevice,
          JobStage.detect,
          JobStage.detect,
          JobStage.online,
          JobStage.normalise,
          JobStage.validate,
        ]);
        expect(container.read(processingControllerProvider).succeeded, 1);
        expect(container.read(processingControllerProvider).failed, 0);
        expect(
          (await repository.byId(
            'job-1',
          )).fold((_) => null, (ProcessingJob? job) => job?.status),
          JobStatus.completed,
        );
      },
    );

    test(
      'no answer releases the job queued with the record untouched',
      () async {
        final FakeProcessingRepository repository = FakeProcessingRepository();
        addTearDown(repository.dispose);
        await repository.save(
          const ProcessingJob(id: 'job-1', recordId: 'record-1'),
        );
        final List<JobStage> stages = <JobStage>[];
        var applies = 0;
        final List<({int succeeded, int failed})> notices =
            <({int succeeded, int failed})>[];
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            processingRepositoryProvider.overrideWith((_) => repository),
            processingStageWorkProvider.overrideWith((_) {
              return detectOnce(stages, () => false);
            }),
            processingTemplateChoiceProvider.overrideWith((_) {
              return (TemplateChoiceNeeded _, TemplateChoice _) async {
                applies++;
                return const Success<void>(null);
              };
            }),
            processingNotificationsProvider.overrideWith((_) {
              return (int succeeded, int failed) async {
                notices.add((succeeded: succeeded, failed: failed));
              };
            }),
          ],
        );
        addTearDown(container.dispose);
        final ProviderSubscription<ProcessingBatchState> subscription =
            container.listen<ProcessingBatchState>(
              processingControllerProvider,
              (_, _) {},
            );
        addTearDown(subscription.close);

        await container
            .read(processingControllerProvider.notifier)
            .process(
              confirmOnline: (_) async => true,
              chooseTemplate: (_) async => null,
            );

        expect(applies, 0);
        expect(stages, <JobStage>[
          JobStage.prepare,
          JobStage.onDevice,
          JobStage.detect,
        ]);
        final ProcessingJob? stored = (await repository.byId(
          'job-1',
        )).fold((_) => null, (ProcessingJob? job) => job);
        expect(stored?.status, JobStatus.queued);
        expect(stored?.stage, JobStage.onDevice.name);
        expect(stored?.lastError, isNull);
        final ProcessingBatchState state = container.read(
          processingControllerProvider,
        );
        expect(state.failed, 0);
        expect(state.steps.single.state, StepState.waiting);
        expect(state.steps.single.detail, Copy.templateChoiceSkipped);
        expect(notices, isEmpty);
      },
    );

    test(
      'a choice that cannot be applied is reported and the job stays queued',
      () async {
        final FakeProcessingRepository repository = FakeProcessingRepository();
        addTearDown(repository.dispose);
        await repository.save(
          const ProcessingJob(id: 'job-1', recordId: 'record-1'),
        );
        final List<JobStage> stages = <JobStage>[];
        final ProviderContainer container = ProviderContainer(
          overrides: <Override>[
            processingRepositoryProvider.overrideWith((_) => repository),
            processingStageWorkProvider.overrideWith((_) {
              return detectOnce(stages, () => false);
            }),
          ],
        );
        addTearDown(container.dispose);
        final ProviderSubscription<ProcessingBatchState> subscription =
            container.listen<ProcessingBatchState>(
              processingControllerProvider,
              (_, _) {},
            );
        addTearDown(subscription.close);

        await container
            .read(processingControllerProvider.notifier)
            .process(
              confirmOnline: (_) async => true,
              chooseTemplate: (_) async => (templateId: 'pump', pin: false),
            );

        expect(stages, <JobStage>[
          JobStage.prepare,
          JobStage.onDevice,
          JobStage.detect,
        ]);
        final ProcessingBatchState state = container.read(
          processingControllerProvider,
        );
        expect(state.failed, 1);
        expect(state.steps.single.state, StepState.failed);
        expect(state.steps.single.detail, Copy.templateChoiceApplyFailed);
        final ProcessingJob? stored = (await repository.byId(
          'job-1',
        )).fold((_) => null, (ProcessingJob? job) => job);
        expect(stored?.status, JobStatus.queued);
        expect(stored?.stage, JobStage.onDevice.name);
      },
    );
  });

  test('cancelling a batch cancels the token its stages hold', () async {
    final FakeProcessingRepository repository = FakeProcessingRepository();
    addTearDown(repository.dispose);
    await repository.save(
      const ProcessingJob(id: 'job-1', recordId: 'record-1'),
    );
    final List<CancellationToken> tokens = <CancellationToken>[];
    late final ProviderContainer container;
    container = ProviderContainer(
      overrides: <Override>[
        processingRepositoryProvider.overrideWith((_) => repository),
        processingStageWorkProvider.overrideWith((_) {
          return (JobStage _, ProcessingJob _, CancellationToken token) async {
            tokens.add(token);
            container.read(processingControllerProvider.notifier).cancel();
          };
        }),
      ],
    );
    addTearDown(container.dispose);
    final ProviderSubscription<ProcessingBatchState> subscription = container
        .listen<ProcessingBatchState>(processingControllerProvider, (_, _) {});
    addTearDown(subscription.close);

    await container
        .read(processingControllerProvider.notifier)
        .process(confirmOnline: (_) async => true);

    expect(tokens, hasLength(1));
    expect(tokens.single.isCancelled, isTrue);
    expect(
      (await repository.byId(
        'job-1',
      )).fold((_) => null, (ProcessingJob? job) => job?.status),
      JobStatus.queued,
    );
  });
}
