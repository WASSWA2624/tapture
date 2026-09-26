import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';

import '../domain/job_retry.dart';
import '../domain/job_runner.dart';
import '../domain/processing_repository.dart';
import '../domain/template_choice_needed.dart';
import 'egress_consent.dart';
import 'processing_batch_state.dart';
import 'queue_providers.dart';

/// Executes foreground queue batches and exposes cancellable progress.
final class ProcessingController extends Notifier<ProcessingBatchState> {
  CancellationToken _token = CancellationToken();

  @override
  ProcessingBatchState build() => const ProcessingBatchState();

  /// Processes every ready job, or only the jobs in [groupLabels] when
  /// any are given (process selected).
  ///
  /// When a stage cannot decide the template, [chooseTemplate] asks the
  /// operator. A null answer, or no [chooseTemplate], leaves the job queued
  /// and stops the batch; a choice is applied and the stage runs once more.
  ///
  /// Before the first online call of the app session, [confirmOnline] shows
  /// what would leave the device; an acceptance holds for the rest of the
  /// session ([egressConsentProvider]). With [stopAfter], each job stops once
  /// that stage is done and waits in the queue for the rest, as opportunistic
  /// on-device reading does. [notify] sends the end-of-batch notification.
  Future<void> process({
    String? projectId,
    List<String> groupLabels = const <String>[],
    Future<bool> Function(ProcessingJob job)? confirmOnline,
    Future<TemplateChoice?> Function(TemplateChoiceNeeded needed)?
    chooseTemplate,
    JobStage? stopAfter,
    bool notify = true,
  }) async {
    if (state.isRunning) {
      return;
    }
    _token = CancellationToken();
    state = const ProcessingBatchState(isRunning: true);
    final ProcessingRepository repository = ref.read(
      processingRepositoryProvider,
    );
    final Result<int> pending = await repository.enqueuePending(
      projectId: projectId,
      groupLabels: groupLabels,
    );
    if (pending case FailureResult<int>(:final Failure failure)) {
      state = ProcessingBatchState(
        failed: 1,
        steps: <ProgressStep>[
          ProgressStep(
            label: Copy.queueTitle,
            state: StepState.failed,
            detail: failure.message,
          ),
        ],
      );
      _notify(0, 1);
      return;
    }
    var succeeded = 0;
    var failed = 0;
    // Jobs waiting for an operator's template choice, passed over for the
    // rest of this batch.
    final Set<String> waiting = <String>{};
    while (!_token.isCancelled) {
      final Result<ProcessingJob?> claimed = await repository.claim(
        AppConstants.processing.jobLease,
        projectId: projectId,
        groupLabels: groupLabels,
        unfinished: stopAfter,
        skip: waiting,
      );
      if (claimed case FailureResult<ProcessingJob?>(:final Failure failure)) {
        failed++;
        _append(Copy.queueTitle, StepState.failed, failure.message);
        break;
      }
      final ProcessingJob? job = (claimed as Success<ProcessingJob?>).value;
      if (job == null) {
        break;
      }
      _append(job.recordId, StepState.running, Copy.processPreparing);
      final JobRunner runner = JobRunner(
        perform:
            (
              JobStage stage,
              ProcessingJob current,
              CancellationToken token,
            ) async {
              _replace(current.recordId, StepState.running, _stageLabel(stage));
              if (stage == JobStage.online &&
                  !ref.read(egressConsentProvider)) {
                final Future<bool> Function(ProcessingJob job)? confirm =
                    confirmOnline;
                if (confirm == null || !await confirm(current)) {
                  await repository.release(current.id);
                  _token.cancel();
                  throw const _ProcessingCancelled(Copy.egressDecline);
                }
                ref.read(egressConsentProvider.notifier).grant();
              }
              await _runStage(
                stage,
                current,
                repository,
                chooseTemplate,
                confirmOnline,
              );
            },
        persist: (ProcessingJob current, JobStage stage) async {
          return (await repository.markStage(
            current.id,
            stage,
          )).fold((failure) => throw failure, (ProcessingJob stored) => stored);
        },
        release: (ProcessingJob current) async {
          final result = await repository.release(current.id);
          return result.fold(
            (failure) => throw failure,
            (_) => current.copyWith(status: JobStatus.queued, clearLease: true),
          );
        },
      );
      try {
        final JobRun run = await runner.run(
          job,
          token: _token,
          stopAfter: stopAfter,
        );
        if (run.cancelled) {
          _replace(job.recordId, StepState.waiting, Copy.queueCancel);
          break;
        }
        if (run.paused) {
          succeeded++;
          _replace(job.recordId, StepState.done, Copy.processReadOnDevice);
          continue;
        }
        (await repository.complete(
          job.id,
        )).fold((Failure failure) => throw failure, (_) {});
        succeeded++;
        _replace(job.recordId, StepState.done, Copy.stepDone);
      } on _ProcessingCancelled catch (cancelled) {
        _replace(job.recordId, StepState.waiting, cancelled.detail);
        break;
      } on _AwaitingTemplateChoice {
        await repository.release(job.id);
        waiting.add(job.id);
        _replace(job.recordId, StepState.waiting, Copy.templateChoiceWaiting);
        continue;
      } on _TemplateChoiceFailed catch (error) {
        await repository.release(job.id);
        failed++;
        _replace(job.recordId, StepState.failed, error.failure.message);
        break;
      } on CancelledFailure catch (failure) {
        await repository.release(job.id);
        _replace(job.recordId, StepState.waiting, failure.message);
        break;
      } on Object catch (error) {
        final JobRetry retry = JobRetry.classify(
          error,
          attempt: job.attemptCount + 1,
        );
        final Result<void> recorded = await repository.fail(
          job.id,
          retry.reason,
          permanent: retry.permanent,
        );
        failed++;
        final String reason = recorded.fold(
          (Failure failure) => failure.message,
          (_) => retry.reason,
        );
        _replace(job.recordId, StepState.failed, reason);
      }
    }
    state = state.copyWith(
      isRunning: false,
      succeeded: succeeded,
      failed: failed,
    );
    if (notify && (!_token.isCancelled || succeeded > 0 || failed > 0)) {
      _notify(succeeded, failed);
    }
  }

  /// Reports a finished batch without waiting on it, so a permission prompt
  /// left unanswered never holds the batch open.
  void _notify(int succeeded, int failed) {
    unawaited(
      ref
          .read(processingNotificationsProvider)(succeeded, failed)
          .catchError((Object _) {}),
    );
  }

  /// Releases the current job between stages and keeps completed work.
  void cancel() {
    _token.cancel();
  }

  /// Returns one stopped job to the queue from either failures list.
  Future<void> retry(String jobId) async {
    final Result<void> retried = await ref
        .read(processingRepositoryProvider)
        .retry(jobId);
    if (retried case FailureResult<void>(:final Failure failure)) {
      state = ProcessingBatchState(
        failed: 1,
        steps: <ProgressStep>[
          ProgressStep(
            label: jobId,
            state: StepState.failed,
            detail: failure.message,
          ),
        ],
      );
    }
  }

  /// Runs [stage] for [job], and answers the template question when the
  /// stage returns one. With no one to ask, as in an unattended run, the job
  /// waits for an operator and the batch goes on without it.
  ///
  /// When local scoring narrowed the templates without deciding, the model
  /// is asked about the shortlist first, behind the session's egress
  /// preview; the operator is asked only when it cannot say. A choice
  /// settles the stage, so it is not run again.
  Future<void> _runStage(
    JobStage stage,
    ProcessingJob job,
    ProcessingRepository repository,
    Future<TemplateChoice?> Function(TemplateChoiceNeeded needed)?
    chooseTemplate,
    Future<bool> Function(ProcessingJob job)? confirmOnline,
  ) async {
    final ProcessingStageWork work = ref.read(processingStageWorkProvider);
    final TemplateChoiceNeeded? needed = await work(stage, job, _token);
    if (needed == null) {
      return;
    }
    TemplateChoice? choice;
    if (needed.modelMayDecide && await _mayGoOnline(job, confirmOnline)) {
      final String? assisted = await ref.read(processingTemplateAssistProvider)(
        job,
        needed,
      );
      if (assisted != null) {
        choice = (templateId: assisted, pin: false);
      }
    }
    if (choice == null && chooseTemplate == null) {
      throw const _AwaitingTemplateChoice();
    }
    choice ??= await chooseTemplate!(needed);
    if (choice == null) {
      await repository.release(job.id);
      _token.cancel();
      throw const _ProcessingCancelled(Copy.templateChoiceSkipped);
    }
    final Result<void> applied = await ref.read(
      processingTemplateChoiceProvider,
    )(needed, choice);
    if (applied case FailureResult<void>(:final Failure failure)) {
      throw _TemplateChoiceFailed(failure);
    }
  }

  /// Whether this session may send [job]'s data: the preview was already
  /// accepted, or [confirmOnline] accepts it now. A decline here only means
  /// the model is not asked; the operator still is.
  Future<bool> _mayGoOnline(
    ProcessingJob job,
    Future<bool> Function(ProcessingJob job)? confirmOnline,
  ) async {
    if (ref.read(egressConsentProvider)) {
      return true;
    }
    if (confirmOnline == null || !await confirmOnline(job)) {
      return false;
    }
    ref.read(egressConsentProvider.notifier).grant();
    return true;
  }

  void _append(String label, StepState stepState, String detail) {
    state = state.copyWith(
      steps: <ProgressStep>[
        ...state.steps,
        ProgressStep(label: label, state: stepState, detail: detail),
      ],
    );
  }

  void _replace(String label, StepState stepState, String detail) {
    state = state.copyWith(
      steps: <ProgressStep>[
        for (final ProgressStep step in state.steps)
          if (step.label == label)
            ProgressStep(label: label, state: stepState, detail: detail)
          else
            step,
      ],
    );
  }
}

/// Foreground batch state and intents.
final NotifierProvider<ProcessingController, ProcessingBatchState>
processingControllerProvider =
    NotifierProvider.autoDispose<ProcessingController, ProcessingBatchState>(
      ProcessingController.new,
    );

/// One stage implementation. Production overrides this with the local-first
/// worker; tests pass deterministic stage work.
final Provider<ProcessingStageWork> processingStageWorkProvider =
    Provider<ProcessingStageWork>((_) {
      return (JobStage _, ProcessingJob _, CancellationToken _) async => null;
    });

/// Applies the operator's template choice to the record, and stores the
/// pin when asked. The stand-in fails until a data-layer writer overrides
/// it, so an unwired choice is reported rather than silently dropped.
final Provider<ProcessingTemplateChoice> processingTemplateChoiceProvider =
    Provider<ProcessingTemplateChoice>((_) {
      return (TemplateChoiceNeeded _, TemplateChoice _) async {
        return const FailureResult<void>(
          ValidationFailure(
            message: Copy.templateChoiceApplyFailed,
            recoveryAction: Copy.templateChoiceApplyRecovery,
          ),
        );
      };
    });

/// The model's pick from a template shortlist, or null so the operator is
/// asked. The stand-in never asks a model; production uses the stage
/// worker's assist.
final Provider<ProcessingTemplateAssist> processingTemplateAssistProvider =
    Provider<ProcessingTemplateAssist>((_) {
      return (ProcessingJob _, TemplateChoiceNeeded _) async => null;
    });

/// Batch notification boundary. Production uses the local plugin.
final Provider<ProcessingBatchNotification> processingNotificationsProvider =
    Provider<ProcessingBatchNotification>((_) {
      return (int _, int _) async {};
    });

/// Exact egress size for one job, supplied by the production stage worker.
final Provider<ProcessingEgressSummary> processingEgressSummaryProvider =
    Provider<ProcessingEgressSummary>((_) {
      return (ProcessingJob _) async => (imageCount: 0, payloadBytes: 0);
    });

/// Runs one stage of a job. The token is cancelled when the batch is.
/// Detection returns its question when it cannot settle the template.
typedef ProcessingStageWork =
    Future<TemplateChoiceNeeded?> Function(
      JobStage,
      ProcessingJob,
      CancellationToken,
    );

/// Asks a model to pick from a template shortlist.
typedef ProcessingTemplateAssist =
    Future<String?> Function(ProcessingJob, TemplateChoiceNeeded);

/// Applies a template choice and reports whether it was stored.
typedef ProcessingTemplateChoice =
    Future<Result<void>> Function(TemplateChoiceNeeded, TemplateChoice);

typedef ProcessingEgressSummary =
    Future<({int imageCount, int payloadBytes})> Function(ProcessingJob);

typedef ProcessingBatchNotification =
    Future<void> Function(int succeeded, int failed);

String _stageLabel(JobStage stage) {
  return switch (stage) {
    JobStage.prepare => Copy.processPreparing,
    JobStage.onDevice => Copy.processReading,
    JobStage.detect => Copy.processDetecting,
    JobStage.online => Copy.processExtracting,
    JobStage.normalise || JobStage.validate => Copy.processChecking,
  };
}

/// A job whose template only an operator can choose, set aside by a batch
/// with no one to ask.
final class _AwaitingTemplateChoice implements Exception {
  const _AwaitingTemplateChoice();
}

final class _ProcessingCancelled implements Exception {
  const _ProcessingCancelled(this.detail);

  /// Shown on the job's step.
  final String detail;
}

final class _TemplateChoiceFailed implements Exception {
  const _TemplateChoiceFailed(this.failure);

  final Failure failure;
}
