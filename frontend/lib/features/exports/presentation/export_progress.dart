import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_progress_steps.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// Per-stage export progress and cancel (task 018).
final class ExportProgress extends StatelessWidget {
  /// Creates the progress list.
  const ExportProgress({
    this.stages = const <ExportStage>[],
    this.loading = false,
    this.empty = false,
    this.failure,
    this.onCancel,
    super.key,
  });

  /// Stages in order: records, photos, reports, archive.
  final List<ExportStage> stages;

  /// Whether progress has not started.
  final bool loading;

  /// Whether there is no job.
  final bool empty;

  /// Why the job failed.
  final Failure? failure;

  /// Stops the job and deletes partial files.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    if (loading) {
      return const SizedBox.shrink();
    }
    if (empty || stages.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.waiting,
        headline: localCopy.exportEmptyHeadline,
        message: localCopy.exportEmptyMessage,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppProgressSteps(
          steps: <ProgressStep>[
            for (final ExportStage stage in stages)
              ProgressStep(label: stage.label, state: stage.state),
          ],
        ),
        AppButton(
          key: const ValueKey<String>('export-cancel'),
          label: localCopy.exportCancel,
          variant: AppButtonVariant.secondary,
          onPressed: onCancel,
        ),
      ],
    );
  }
}

/// One named stage and where it is.
typedef ExportStage = ({String label, StepState state});
