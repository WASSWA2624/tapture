import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';

export 'package:tapture/core/widgets/app_progress_steps.dart' show ProgressStep;

/// Process all, process selected, cancel, and the end-of-run summary.
class ProcessActions extends StatelessWidget {
  /// Creates the actions. [steps] is empty before a run starts.
  const ProcessActions({
    super.key,
    required this.steps,
    this.running = false,
    this.succeeded,
    this.failed,
    this.onProcessAll,
    this.onProcessSelected,
    this.selectedCount = 0,
    this.onCancel,
  });

  /// Per-record progress.
  final List<ProgressStep> steps;

  /// Whether a batch is in progress.
  final bool running;

  /// Succeeded count once the batch has finished.
  final int? succeeded;

  /// Failed count once the batch has finished.
  final int? failed;

  /// Starts every waiting record.
  final VoidCallback? onProcessAll;

  /// Starts the current selection.
  final VoidCallback? onProcessSelected;

  /// How many records are selected. The selected action stays hidden at zero.
  final int selectedCount;

  /// Stops the batch. Work already finished is kept.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final int? succeeded = this.succeeded;
    final int? failed = this.failed;
    final bool finished = !running && succeeded != null && failed != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (steps.isNotEmpty) AppProgressSteps(steps: steps),
        if (finished) Text(Copy.queueSummary(succeeded, failed)),
        if (running)
          AppButton(label: Copy.queueCancel, onPressed: onCancel)
        else ...<Widget>[
          AppButton(label: Copy.queueProcessAll, onPressed: onProcessAll),
          if (onProcessSelected != null && selectedCount > 0)
            AppButton(
              label: Copy.queueProcessSelected,
              variant: AppButtonVariant.secondary,
              onPressed: onProcessSelected,
            ),
        ],
      ],
    );
  }
}
