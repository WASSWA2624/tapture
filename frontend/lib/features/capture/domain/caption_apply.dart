/// How a caption write combines with existing text.
enum CaptionApplyMode {
  /// Adds [text] on a new line after the previous value.
  append,

  /// Replaces the previous value; caller keeps history separately.
  replace,
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

  /// Photos a caption goes to: the selected ones among [visibleIds], in
  /// tray order, and every visible photo when none is selected. One photo
  /// is therefore always its own target.
  static List<String> targets({
    required List<String> visibleIds,
    required Set<String> selectedIds,
  }) {
    final List<String> selected = <String>[
      for (final String id in visibleIds)
        if (selectedIds.contains(id)) id,
    ];
    return selected.isEmpty ? List<String>.of(visibleIds) : selected;
  }

  /// The caption every one of [ids] shares, or `''` when they differ or
  /// there are none. The caption field shows this for its targets.
  static String sharedText({
    required List<String> ids,
    required Map<String, String> captions,
  }) {
    if (ids.isEmpty) {
      return '';
    }
    final String first = captions[ids.first] ?? '';
    for (final String id in ids.skip(1)) {
      if ((captions[id] ?? '') != first) {
        return '';
      }
    }
    return first;
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
