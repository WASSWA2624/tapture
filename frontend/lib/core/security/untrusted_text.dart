/// Text from outside the app: OCR, transcripts, cells, bundles and file names.
///
/// [raw] stays the stored evidence. Display, requests and file names use a
/// derived form so the text cannot close a block, a tag or a path.
final class UntrustedText {
  /// Wraps [raw] without changing it.
  const UntrustedText(this.raw);

  /// The captured text, unchanged.
  final String raw;

  /// A labelled block. A closing marker inside [raw] is escaped.
  String asDataBlock(String label) {
    final String closer = '</$label>';
    final String escaped = raw.replaceAll(closer, '$closer>');
    return '<$label>\n$escaped\n$closer';
  }

  /// Escaped for rendering. Tags cannot be read as markup.
  String forDisplay() {
    return raw
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  /// An ASCII file name with separators and traversal sequences removed.
  String forFileName() {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in raw.runes) {
      final String char = String.fromCharCode(rune);
      if (_safe.hasMatch(char)) {
        buffer.write(char);
      } else if (char == ' ') {
        buffer.write('_');
      }
    }
    var name = buffer.toString();
    while (name.contains('..')) {
      name = name.replaceAll('..', '.');
    }
    name = name.replaceAll(RegExp(r'^\.+|\.+$'), '');
    if (name.isEmpty) {
      return 'file';
    }
    return name;
  }
}

final RegExp _safe = RegExp(r'[A-Za-z0-9._-]');
