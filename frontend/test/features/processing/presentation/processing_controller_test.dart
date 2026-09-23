import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
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
          return (JobStage stage, ProcessingJob _) async => stages.add(stage);
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
          return (JobStage stage, ProcessingJob _) async => stages.add(stage);
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
}
