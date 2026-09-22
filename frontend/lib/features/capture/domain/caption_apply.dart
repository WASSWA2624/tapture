/// How a caption write combines with existing text.
enum CaptionApplyMode {
  /// Adds [text] on a new line after the previous value.
  append,

  /// Replaces the previous value; caller keeps history separately.
  replace,
}

/// Which photos a caption write targets.
enum CaptionScope {
  /// The photo the sheet was opened from.
  thisPhoto,

  /// The current multi-selection.
  selected,

  /// Every photo in the session.
  all,
}

/// One independent caption row to persist.
final class CaptionWrite {
  /// Creates a write.
  const CaptionWrite({
    required this.photoId,
    required this.text,
    this.previousText,
  });

  /// Photo that owns this row.
  final String photoId;

  /// New raw caption text.
  final String text;

  /// Previous text kept recoverable on replace.
  final String? previousText;
}

/// Builds per-photo caption rows for a scope (task 012 captions).
abstract final class CaptionApply {
  /// Resolves [scope] to photo ids from [allIds] / [selectedIds] / [thisId].
  static List<String> resolveIds({
    required CaptionScope scope,
    required String? thisId,
    required List<String> selectedIds,
    required List<String> allIds,
  }) {
    return switch (scope) {
      CaptionScope.thisPhoto =>
        thisId == null || thisId.isEmpty ? const <String>[] : <String>[thisId],
      CaptionScope.selected => List<String>.of(selectedIds),
      CaptionScope.all => List<String>.of(allIds),
    };
  }

  /// Builds one [CaptionWrite] per photo. Append joins with a newline;
  /// replace keeps [previous] recoverable.
  static List<CaptionWrite> apply({
    required List<String> photoIds,
    required String text,
    required CaptionApplyMode mode,
    required Map<String, String> existing,
  }) {
    return <CaptionWrite>[
      for (final String id in photoIds)
        CaptionWrite(
          photoId: id,
          text: mode == CaptionApplyMode.append
              ? _append(existing[id] ?? '', text)
              : text,
          previousText: mode == CaptionApplyMode.replace ? existing[id] : null,
        ),
    ];
  }

  static String _append(String previous, String next) {
    if (previous.trim().isEmpty) {
      return next;
    }
    if (next.trim().isEmpty) {
      return previous;
    }
    return '$previous\n$next';
  }
}
