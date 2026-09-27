import 'dart:typed_data';

/// Copies an imported workbook into the export folder (task 018).
///
/// The stored template is never opened for writing. [copyOf] returns a new
/// buffer; [source] is left byte-identical.
final class XlsxTemplateCopy {
  /// A new buffer with the same bytes as [source].
  static Uint8List copyOf(Uint8List source) {
    return Uint8List.fromList(source);
  }

  /// Features the encoder does not preserve, named for the summary.
  static const List<String> unpreserved = <String>[
    'pivot tables',
    'charts',
    'macros',
  ];
}
