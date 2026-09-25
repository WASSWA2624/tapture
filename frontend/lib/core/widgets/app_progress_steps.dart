import 'package:flutter/material.dart' hide StepState;
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';

part 'progress_step.dart';

/// Done / running / waiting / failed list for long jobs (processing, export).
///
/// A state change keeps the same row height so later steps do not jump
/// (FE-A11Y-05, FE-A11Y-07).
class AppProgressSteps extends StatelessWidget {
  /// Creates the list. [steps] are shown in order.
  const AppProgressSteps({super.key, required this.steps});

  /// Steps to render. Order is the job order.
  final List<ProgressStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < steps.length; i++)
          _ProgressStepRow(key: ValueKey<int>(i), step: steps[i]),
      ],
    );
  }
}

/// Lifecycle of one [ProgressStep]. Colour is never the only signal.
enum StepState {
  /// The step finished successfully.
  done,

  /// The step is in progress.
  running,

  /// The step has not started.
  waiting,

  /// The step failed.
  failed,
}

class _ProgressStepRow extends StatelessWidget {
  const _ProgressStepRow({super.key, required this.step});

  final ProgressStep step;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final (Color color, IconData icon, String stateLabel) = _style(
      step.state,
      colors,
    );
    final String caption = step.detail ?? stateLabel;
    final String announcement = Copy.progressAnnouncement(
      label: step.label,
      state: stateLabel,
      detail: step.detail,
    );
    return Semantics(
      liveRegion: true,
      container: true,
      label: announcement,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.minTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.x4,
            vertical: Space.x2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: Space.x6,
                height: Space.x6,
                child: step.state == StepState.running
                    ? _RunningMark(color: color)
                    : Icon(icon, color: color, size: Space.x6),
              ),
              const SizedBox(width: Space.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      step.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyStrong.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: Space.x1),
                    Text(
                      caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(color: colors.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunningMark extends StatelessWidget {
  const _RunningMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      strokeWidth: Space.x0,
      color: color,
      value: MediaQuery.disableAnimationsOf(context)
          ? Space.x3 / Space.x4
          : null,
    );
  }
}

(Color, IconData, String) _style(StepState state, AppColors colors) {
  return switch (state) {
    StepState.done => (colors.success, AppIcons.done, Copy.stepDone),
    StepState.running => (colors.info, AppIcons.processing, Copy.stepRunning),
    StepState.waiting => (colors.outline, AppIcons.queued, Copy.stepWaiting),
    StepState.failed => (colors.danger, AppIcons.error, Copy.failed),
  };
}
