/// Where a transcript's page stands: the operator's unsaved edit and the
/// work in flight. The transcript itself is read from the store.
final class TranscriptDetailStatus {
  /// A page with [draft] unsaved, [saving] an edit, a revert or a rename,
  /// and [finishing] the rest of the recording.
  const TranscriptDetailStatus({
    this.draft,
    this.saving = false,
    this.finishing = false,
  });

  /// The text being edited, not yet saved; null when nothing was typed.
  /// Never logged.
  final String? draft;

  /// Whether an edit, a revert or a rename is being written.
  final bool saving;

  /// Whether the rest of the recording is being transcribed.
  final bool finishing;

  /// This status with the given parts replaced; [clearDraft] drops the
  /// draft.
  TranscriptDetailStatus copyWith({
    String? draft,
    bool? saving,
    bool? finishing,
    bool clearDraft = false,
  }) {
    return TranscriptDetailStatus(
      draft: clearDraft ? null : draft ?? this.draft,
      saving: saving ?? this.saving,
      finishing: finishing ?? this.finishing,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TranscriptDetailStatus &&
      other.draft == draft &&
      other.saving == saving &&
      other.finishing == finishing;

  @override
  int get hashCode => Object.hash(draft, saving, finishing);
}
