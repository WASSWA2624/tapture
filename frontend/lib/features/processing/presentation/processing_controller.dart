import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';

import '../domain/job_retry.dart';
import '../domain/job_runner.dart';
import '../domain/processing_repository.dart';
import 'processing_batch_state.dart';
import 'queue_providers.dart';

/// Executes foreground queue batches and exposes cancellable progress.
final class ProcessingController extends Notifier<ProcessingBatchState> {
  var _isCancelled = false;

  @override
  ProcessingBatchState build() => const ProcessingBatchState();

  /// Processes every ready job, or only [groupLabel] when supplied.
  Future<void> process({
    String? projectId,
    String? groupLabel,
    Future<bool> Function(ProcessingJob job)? confirmOnline,
  }) async {
    if (state.isRunning) {
      return;
    }
    _isCancelled = false;
    state = const ProcessingBatchState(isRunning: true);
    final ProcessingRepository repository = ref.read(
      processingRepositoryProvider,
    );
    final Result<int> pending = await repository.enqueuePending(
      projectId: projectId,
      groupLabel: groupLabel,
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
      await ref.read(processingNotificationsProvider)(0, 1);
      return;
    }
    var succeeded = 0;
    var failed = 0;
    var onlineConfirmed = false;
    while (!_isCancelled) {
      final ProcessingJob? job =
          (await repository.claim(
            AppConstants.processing.jobLease,
            projectId: projectId,
            groupLabel: groupLabel,
          )).fold((Failure failure) => throw failure, (ProcessingJob? value) {
            return value;
          });
      if (job == null) {
        break;
      }
      _append(job.recordId, StepState.running, Copy.processPreparing);
      final JobRunner runner = JobRunner(
        perform: (JobStage stage, ProcessingJob current) async {
          _replace(current.recordId, StepState.running, _stageLabel(stage));
          if (stage == JobStage.online && !onlineConfirmed) {
            final Future<bool> Function(ProcessingJob job)? confirm =
                confirmOnline;
            if (confirm == null || !await confirm(current)) {
              await repository.release(current.id);
              _isCancelled = true;
              throw const _ProcessingCancelled();
            }
            onlineConfirmed = true;
          }
          await ref.read(processingStageWorkProvider)(stage, current);
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
          isCancelled: () => _isCancelled,
        );
        if (run.cancelled) {
          _replace(job.recordId, StepState.waiting, Copy.queueCancel);
          break;
        }
        (await repository.complete(
          job.id,
        )).fold((Failure failure) => throw failure, (_) {});
        succeeded++;
        _replace(job.recordId, StepState.done, Copy.stepDone);
      } on _ProcessingCancelled {
        _replace(job.recordId, StepState.waiting, Copy.egressDecline);
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
        (await repository.fail(
          job.id,
          retry.reason,
          permanent: retry.permanent,
        )).fold((Failure failure) => throw failure, (_) {});
        failed++;
        _replace(job.recordId, StepState.failed, retry.reason);
      }
    }
    state = state.copyWith(
      isRunning: false,
      succeeded: succeeded,
      failed: failed,
    );
    if (!_isCancelled || succeeded > 0 || failed > 0) {
      await ref.read(processingNotificationsProvider)(succeeded, failed);
    }
  }

  /// Releases the current job between stages and keeps completed work.
  void cancel() {
    _isCancelled = true;
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
final Provider<Future<void> Function(JobStage, ProcessingJob)>
processingStageWorkProvider =
    Provider<Future<void> Function(JobStage, ProcessingJob)>((_) {
      return (JobStage _, ProcessingJob _) async {};
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

final class _ProcessingCancelled implements Exception {
  const _ProcessingCancelled();
}
