import 'package:flutter/material.dart' hide StepState;
import 'package:tapture/core/widgets/app_progress_steps.dart';

/// Live state for one foreground processing batch.
@immutable
final class ProcessingBatchState {
  /// Creates an idle or running batch state.
  const ProcessingBatchState({
    this.isRunning = false,
    this.steps = const <ProgressStep>[],
    this.succeeded,
    this.failed,
  });

  /// Whether a runner currently owns a batch.
  final bool isRunning;

  /// Per-record progress in claim order.
  final List<ProgressStep> steps;

  /// Successful records after the batch stops.
  final int? succeeded;

  /// Failed records after the batch stops.
  final int? failed;

  /// Returns a copy with explicitly supplied counters.
  ProcessingBatchState copyWith({
    bool? isRunning,
    List<ProgressStep>? steps,
    int? succeeded,
    int? failed,
    bool clearSummary = false,
  }) {
    return ProcessingBatchState(
      isRunning: isRunning ?? this.isRunning,
      steps: steps ?? this.steps,
      succeeded: clearSummary ? null : (succeeded ?? this.succeeded),
      failed: clearSummary ? null : (failed ?? this.failed),
    );
  }
}
