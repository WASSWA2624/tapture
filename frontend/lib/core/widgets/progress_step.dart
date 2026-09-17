part of 'app_progress_steps.dart';

/// One row in [AppProgressSteps]: a label, a [StepState], and optional detail.
@immutable
class ProgressStep {
  /// Creates a step. [detail] is a second line; omitted, the state name is
  /// shown so colour is never the only signal (FE-A11Y-05).
  const ProgressStep({required this.label, required this.state, this.detail});

  /// What this step does, shown as the primary line.
  final String label;

  /// Done, running, waiting or failed.
  final StepState state;

  /// Optional supporting line (elapsed time, error reason).
  final String? detail;

  @override
  bool operator ==(Object other) {
    return other is ProgressStep &&
        other.label == label &&
        other.state == state &&
        other.detail == detail;
  }

  @override
  int get hashCode => Object.hash(label, state, detail);
}
