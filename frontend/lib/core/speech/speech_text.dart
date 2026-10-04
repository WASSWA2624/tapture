/// How transcript text is put together from its segments, so the session,
/// dictation and the stored transcript read the same words the same way.
abstract final class SpeechText {
  /// Joins [texts] in order with one space between them. Each text is
  /// trimmed first, and one left empty adds nothing.
  static String join(Iterable<String> texts) {
    final StringBuffer joined = StringBuffer();
    for (final String text in texts) {
      final String trimmed = text.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (joined.isNotEmpty) {
        joined.write(' ');
      }
      joined.write(trimmed);
    }
    return joined.toString();
  }
}
