import 'dart:convert';
import 'dart:typed_data';

import 'export_record.dart';
import 'export_request.dart';
import 'record_document_text.dart';
import 'xlsx_writer.dart';

/// UTF-8 text reports and unchanged-layout text template substitution.
abstract final class PlainTextWriter {
  /// Streams the same selected values used by the editable Word report.
  static Iterable<String> chunks(ExportRequest request) sync* {
    for (final String line in RecordDocumentText.lines(request)) {
      yield '$line\n';
    }
  }

  /// Preserves all original punctuation and whitespace around field placeholders.
  static Uint8List fill(
    Uint8List source,
    ExportRecord record, {
    bool markedIncomplete = false,
  }) {
    final String text = decode(source);
    final String filled = RecordDocumentText.fill(text, record);
    final String newline = text.contains('\r\n') ? '\r\n' : '\n';
    return Uint8List.fromList(
      utf8.encode(
        markedIncomplete
            ? '$filled$newline${XlsxWriter.incompleteStamp}$newline'
            : filled,
      ),
    );
  }

  /// Accepts UTF-8 text only, rejecting binary control bytes.
  static String decode(Uint8List source) {
    final String text = utf8.decode(source);
    if (text.runes.any(
      (rune) => rune < 32 && rune != 9 && rune != 10 && rune != 13,
    )) {
      throw const FormatException('A text template contains binary data.');
    }
    return text;
  }
}
