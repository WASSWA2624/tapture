import 'dart:convert';
import 'dart:typed_data';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';

/// The one PDF foundation every report uses (task 018).
///
/// Reports supply text. Sizes stay here, taken from [AppConstants], so a
/// report never chooses a font size or a colour.
final class PdfEngine {
  /// Creates an engine.
  const PdfEngine();

  /// Cover, header and the body lines a report supplied.
  PdfDocument document({
    required String title,
    required String project,
    required List<String> coverLines,
    required List<String> bodyLines,
    List<String> photos = const <String>[],
  }) {
    return (
      title: title,
      project: project,
      coverLines: coverLines,
      bodyLines: bodyLines,
      photos: photos,
    );
  }

  /// Photo lines every report shares. [columns] is 1, 2, 3 or 4.
  List<String> photoBlock(
    List<({String caption, String path})> photos, {
    required int columns,
    bool captions = true,
  }) {
    return <String>[
      for (final ({String caption, String path}) photo in photos)
        captions
            ? 'Photo ${photo.path} ${photo.caption}'
            : 'Photo ${photo.path}',
      'columns $columns',
    ];
  }

  /// Renders [document] to PDF bytes. A cancelled token yields nothing and
  /// the caller deletes the target.
  Stream<double> render({
    required PdfDocument document,
    required CancellationToken token,
    required void Function(Uint8List bytes) emit,
    required void Function() discard,
  }) async* {
    if (token.isCancelled) {
      discard();
      return;
    }
    yield 0;
    emit(_bytes(document));
    if (token.isCancelled) {
      discard();
      return;
    }
    yield 1;
  }

  Uint8List _bytes(PdfDocument document) {
    final String text = <String>[
      document.project,
      document.title,
      ...document.coverLines,
      ...document.bodyLines,
      ...document.photos,
      '1 of 1',
    ].join(' ');
    final String escaped = text
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
    final double size = AppConstants.exportValues.pdfBody;
    final String stream = 'BT /F1 $size Tf 72 800 Td ($escaped) Tj ET';
    final String body =
        '%PDF-1.4\n'
        '1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n'
        '2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n'
        '3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
        '/Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >> endobj\n'
        '4 0 obj << /Length ${stream.length} >> stream\n$stream\nendstream\n'
        'endobj\n'
        '5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n'
        'trailer << /Root 1 0 R >>\n'
        '%%EOF';
    return Uint8List.fromList(utf8.encode(body));
  }
}

/// One report laid out by [PdfEngine].
typedef PdfDocument = ({
  String title,
  String project,
  List<String> coverLines,
  List<String> bodyLines,
  List<String> photos,
});
