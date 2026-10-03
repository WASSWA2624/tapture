import 'package:flutter/material.dart' hide StepState;
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

import 'processing_batch_state.dart';

/// One line for the foreground batch: its progress while it runs, then the
/// summary and, when it stopped early, why. Nothing before the first run.
class ProcessBatchLine extends StatelessWidget {
  /// Creates the line for [batch].
  const ProcessBatchLine({super.key, required this.batch});

  /// The batch to describe.
  final ProcessingBatchState batch;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final List<ProgressStep> steps = batch.steps;
    if (!batch.isRunning &&
        steps.isEmpty &&
        batch.succeeded == null &&
        batch.failed == null) {
      return const SizedBox.shrink();
    }
    var done = 0;
    var failed = 0;
    ProgressStep? current;
    ProgressStep? stopped;
    for (final ProgressStep step in steps) {
      switch (step.state) {
        case StepState.done:
          done++;
          break;
        case StepState.failed:
          failed++;
          stopped = step;
          break;
        case StepState.waiting:
          stopped = step;
          break;
        case StepState.running:
          current = step;
          break;
      }
    }
    final String message;
    final SnackTone tone;
    if (batch.isRunning) {
      message = localCopy.queueProgress(
        done,
        failed,
        stage: localCopy.stateText(current?.localizedDetail, current?.detail),
      );
      tone = SnackTone.info;
    } else {
      final int failures = batch.failed ?? failed;
      message = localCopy.queueSummary(
        batch.succeeded ?? done,
        failures,
        detail: localCopy.stateText(stopped?.localizedDetail, stopped?.detail),
      );
      tone = failures > 0 || stopped != null
          ? SnackTone.warning
          : SnackTone.success;
    }
    return Padding(
      padding: const EdgeInsets.only(top: Space.x2),
      child: AppBanner(
        key: const ValueKey<String>('queue-batch-line'),
        message: message,
        icon: tone.icon,
        tone: tone,
      ),
    );
  }
}
