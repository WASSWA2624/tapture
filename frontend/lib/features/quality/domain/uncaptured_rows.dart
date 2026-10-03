/// What a verification exercise did not find (task 015).
final class UncapturedRows {
  /// Creates the two missing sets.
  const UncapturedRows(this.registerNotFound, this.checklistNotCaptured);

  /// Register rows that produced no record.
  final List<String> registerNotFound;

  /// Checklist rows that were never captured.
  final List<String> checklistNotCaptured;

  /// [registerIds] that are not in [capturedRegisterIds], and [checklistIds]
  /// that are not in [capturedChecklistIds]. Order follows the inputs.
  static UncapturedRows compute({
    required List<String> registerIds,
    required Set<String> capturedRegisterIds,
    required List<String> checklistIds,
    required Set<String> capturedChecklistIds,
  }) {
    return UncapturedRows(
      <String>[
        for (final String id in registerIds)
          if (!capturedRegisterIds.contains(id)) id,
      ],
      <String>[
        for (final String id in checklistIds)
          if (!capturedChecklistIds.contains(id)) id,
      ],
    );
  }
}
