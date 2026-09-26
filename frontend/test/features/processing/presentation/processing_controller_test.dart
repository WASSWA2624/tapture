import 'dart:async';

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

import '../../../support/fakes/fake_notifications.dart';
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
          return (JobStage stage, ProcessingJob _, CancellationToken _) async {
            stages.add(stage);
            return null;
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
          return (JobStage stage, ProcessingJob _, CancellationToken _) async {
            stages.add(stage);
            return null;
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

    /// Records each stage, and returns [needed] from detect until [decided].
    ProcessingStageWork detectOnce(
      List<JobStage> stages,
      bool Function() decided,
    ) {
      return (JobStage stage, ProcessingJob _, CancellationToken _) async {
        stages.add(stage);
        if (stage == JobStage.detect && !decided()) {
          return needed;
        }
        return null;
      };
    }

    test(
      'asks once, applies the choice, and the choice settles detection',
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

  group('a shortlist a model may decide', () {
    const TemplateChoiceNeeded shortlist = TemplateChoiceNeeded(
      recordId: 'record-1',
      projectId: 'project-1',
      shortlist: <({String templateId, String label})>[
        (templateId: 'pump', label: 'Pump'),
        (templateId: 'motor', label: 'Motor'),
      ],
      modelMayDecide: true,
    );

    Future<
      ({
        List<TemplateChoice> applied,
        List<TemplateChoiceNeeded> asked,
        int previews,
        int assists,
      })
    >
    run({required String? model, required bool accept}) async {
      final FakeProcessingRepository repository = FakeProcessingRepository();
      addTearDown(repository.dispose);
      await repository.save(
        const ProcessingJob(id: 'job-1', recordId: 'record-1'),
      );
      final List<TemplateChoice> applied = <TemplateChoice>[];
      final List<TemplateChoiceNeeded> asked = <TemplateChoiceNeeded>[];
      var previews = 0;
      var assists = 0;
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          processingRepositoryProvider.overrideWith((_) => repository),
          processingStageWorkProvider.overrideWith((_) {
            return (
              JobStage stage,
              ProcessingJob _,
              CancellationToken _,
            ) async {
              if (stage == JobStage.detect && applied.isEmpty) {
                return shortlist;
              }
              return null;
            };
          }),
          processingTemplateAssistProvider.overrideWith((_) {
            return (ProcessingJob _, TemplateChoiceNeeded _) async {
              assists++;
              return model;
            };
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
      final ProviderSubscription<ProcessingBatchState> subscription = container
          .listen<ProcessingBatchState>(
            processingControllerProvider,
            (_, _) {},
          );
      addTearDown(subscription.close);
      await container
          .read(processingControllerProvider.notifier)
          .process(
            confirmOnline: (_) async {
              previews++;
              return accept;
            },
            chooseTemplate: (TemplateChoiceNeeded question) async {
              asked.add(question);
              return (templateId: 'pump', pin: true);
            },
          );
      return (
        applied: applied,
        asked: asked,
        previews: previews,
        assists: assists,
      );
    }

    test('the model decides after the preview and nobody is asked', () async {
      final result = await run(model: 'motor', accept: true);
      expect(result.previews, 1, reason: 'the preview comes first');
      expect(result.assists, 1);
      expect(result.asked, isEmpty);
      expect(result.applied, <TemplateChoice>[
        (templateId: 'motor', pin: false),
      ]);
    });

    test(
      'a model that cannot say leaves the question to the operator',
      () async {
        final result = await run(model: null, accept: true);
        expect(result.assists, 1);
        expect(result.asked, hasLength(1));
        expect(result.applied, <TemplateChoice>[
          (templateId: 'pump', pin: true),
        ]);
      },
    );

    test('a declined preview asks the operator without the model', () async {
      final result = await run(model: 'motor', accept: false);
      expect(result.assists, 0);
      expect(result.asked, hasLength(1));
      expect(result.applied.single.templateId, 'pump');
    });
  });

  test(
    'an unattended run sets aside a job only an operator can place',
    () async {
      final FakeProcessingRepository repository = FakeProcessingRepository();
      addTearDown(repository.dispose);
      final DateTime queued = DateTime.utc(2026, 9, 26, 8);
      await repository.save(
        ProcessingJob(id: 'job-1', recordId: 'record-1', queuedAt: queued),
      );
      await repository.save(
        ProcessingJob(
          id: 'job-2',
          recordId: 'record-2',
          queuedAt: queued.add(const Duration(minutes: 1)),
        ),
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          processingRepositoryProvider.overrideWith((_) => repository),
          processingStageWorkProvider.overrideWith((_) {
            return (
              JobStage stage,
              ProcessingJob job,
              CancellationToken _,
            ) async {
              if (stage == JobStage.detect && job.id == 'job-1') {
                return const TemplateChoiceNeeded(
                  recordId: 'record-1',
                  projectId: 'project-1',
                  shortlist: <({String templateId, String label})>[
                    (templateId: 'pump', label: 'Pump'),
                    (templateId: 'motor', label: 'Motor'),
                  ],
                );
              }
              return null;
            };
          }),
          processingNotificationsProvider.overrideWith((_) {
            return (int _, int _) async {};
          }),
        ],
      );
      addTearDown(container.dispose);
      final ProviderSubscription<ProcessingBatchState> subscription = container
          .listen<ProcessingBatchState>(
            processingControllerProvider,
            (_, _) {},
          );
      addTearDown(subscription.close);

      // As the unattended path runs: consent given, nobody to ask.
      await container
          .read(processingControllerProvider.notifier)
          .process(confirmOnline: (_) async => true);

      final ProcessingBatchState state = container.read(
        processingControllerProvider,
      );
      expect(state.succeeded, 1);
      expect(state.failed, 0);
      final Map<String, JobStatus> statuses = <String, JobStatus>{
        for (final ProcessingJob job in repository.stored) job.id: job.status,
      };
      expect(statuses, <String, JobStatus>{
        'job-1': JobStatus.queued,
        'job-2': JobStatus.completed,
      });
      expect(
        state.steps
            .firstWhere((ProgressStep s) => s.label == 'record-1')
            .detail,
        Copy.templateChoiceWaiting,
      );
    },
  );

  test('an unanswered permission prompt never holds a batch open', () async {
    final FakeProcessingRepository repository = FakeProcessingRepository();
    addTearDown(repository.dispose);
    await repository.save(
      const ProcessingJob(id: 'job-1', recordId: 'record-1'),
    );
    final FakeNotifications platform = FakeNotifications(
      prompt: Completer<bool>(),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        processingRepositoryProvider.overrideWith((_) => repository),
        processingStageWorkProvider.overrideWith((_) {
          return (JobStage _, ProcessingJob _, CancellationToken _) async =>
              null;
        }),
        processingNotificationsProvider.overrideWith((_) {
          return (int succeeded, int failed) => platform.notifications
              .reportBatch(succeeded: succeeded, failed: failed);
        }),
      ],
    );
    addTearDown(container.dispose);
    final ProviderSubscription<ProcessingBatchState> subscription = container
        .listen<ProcessingBatchState>(processingControllerProvider, (_, _) {});
    addTearDown(subscription.close);

    await container
        .read(processingControllerProvider.notifier)
        .process(confirmOnline: (_) async => true)
        .timeout(const Duration(seconds: 5));

    expect(platform.permissionRequests, 1, reason: 'the prompt is showing');
    expect(container.read(processingControllerProvider).isRunning, isFalse);
    expect(container.read(processingControllerProvider).succeeded, 1);
    expect(platform.shown, isEmpty);
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
            return null;
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
