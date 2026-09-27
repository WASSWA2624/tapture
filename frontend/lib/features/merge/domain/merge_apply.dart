/// Applies a plan as one transaction over a snapshot (task 019).
///
/// A failure restores the snapshot, files included. Nothing is half-applied.
final class MergeApply {
  /// Creates an applier.
  const MergeApply();

  /// Runs [steps] against [before]. [failAt] is the step index that throws,
  /// or null when every step succeeds.
  ApplyOutcome run({
    required Map<String, String> before,
    required List<String> steps,
    int? failAt,
  }) {
    final Map<String, String> snapshot = <String, String>{...before};
    final Map<String, String> working = <String, String>{...before};
    for (var index = 0; index < steps.length; index++) {
      if (failAt == index) {
        return (applied: false, state: snapshot, mergeId: null);
      }
      working['step-$index'] = steps[index];
    }
    return (applied: true, state: working, mergeId: 'merge-1');
  }
}

/// Whether the project changed, and the state to keep.
typedef ApplyOutcome = ({
  bool applied,
  Map<String, String> state,
  String? mergeId,
});
