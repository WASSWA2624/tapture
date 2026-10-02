import 'package:tapture/core/files/path_sanitizer.dart';

/// Text from outside the app: OCR, transcripts, cells, bundles and file names.
///
/// [raw] stays the stored evidence. Requests, the screen and file names use a
/// derived form, so the text cannot close a block, reorder what is shown or
/// leave its folder (FE-SEC-05, FE-SEC-08).
final class UntrustedText {
  /// Wraps [raw] without changing it.
  const UntrustedText(this.raw);

  /// The captured text, unchanged.
  final String raw;

  /// [raw] inside a `<label>` block for a provider request.
  ///
  /// `&`, `<` and `>` are written as entities, so nothing inside the block can
  /// open or close a marker: the only closing marker is the last line.
  /// [label] is a fixed name chosen by the caller, never untrusted text.
  String asDataBlock(String label) {
    if (!_label.hasMatch(label)) {
      throw ArgumentError.value(label, 'label', 'Use letters and underscores');
    }
    final String escaped = raw
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    return '<$label>\n$escaped\n</$label>';
  }

  /// [raw] for a text widget: every visible character as captured.
  ///
  /// A text widget reads no markup, so nothing is entity-escaped. Control
  /// characters other than line breaks and tabs, and the invisible direction
  /// overrides that can make text read in a different order than it was
  /// written, are removed.
  String forDisplay() => raw.replaceAll(_hidden, '');

  /// [raw] as one ASCII file name: separators and dots, so every traversal
  /// sequence, become hyphens and the shared path rule does the rest. A name
  /// with nothing a file can keep becomes `file`.
  String forFileName() {
    final String flattened = forDisplay().replaceAll(_separators, '-');
    try {
      return sanitiseSegment(flattened);
    } on Object {
      return _fallbackName;
    }
  }
}

/// A data-block label: a fixed identifier.
final RegExp _label = RegExp(r'^[a-z][a-z_]*$');

/// C0 and C1 controls other than tab and line breaks, plus the bidirectional
/// embeddings, overrides and isolates (U+202A to U+202E, U+2066 to U+2069).
final RegExp _hidden = RegExp(
  r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F'
  r'\u202A-\u202E\u2066-\u2069]',
  unicode: true,
);

/// Path separators in either direction, and dots.
final RegExp _separators = RegExp(r'[\\/.]+');

/// The name used when the text keeps nothing a file name can hold.
const String _fallbackName = 'file';
