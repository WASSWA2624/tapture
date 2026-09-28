import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

/// The shared PDF renderer: local layout, pagination, headers and photo blocks.
final class PdfEngine {
  /// Creates the renderer; reports supply content rather than layout.
  const PdfEngine();

  /// Builds the content shared by each report family.
  PdfDocument document({
    required String title,
    required String project,
    required List<String> coverLines,
    required List<String> bodyLines,
    PdfPhotoBlock photos = (
      entries: const <({String caption, String path})>[],
      columns: 2,
      captions: true,
    ),
  }) => (
    title: title,
    project: project,
    coverLines: coverLines,
    bodyLines: bodyLines,
    photos: photos,
  );

  /// Photo metadata with a common one-to-four-column layout.
  PdfPhotoBlock photoBlock(
    List<({String caption, String path})> photos, {
    required int columns,
    bool captions = true,
  }) => (entries: photos, columns: columns.clamp(1, 4), captions: captions);

  /// Renders away from the UI isolate. [images] holds already reduced photo bytes
  /// keyed by the report's photo paths. No original file is opened or changed.
  Stream<double> render({
    required PdfDocument document,
    required CancellationToken token,
    required void Function(Uint8List bytes) emit,
    required void Function() discard,
    Map<String, Uint8List> images = const <String, Uint8List>{},
    Uint8List? font,
  }) async* {
    if (token.isCancelled) {
      discard();
      return;
    }
    yield 0;
    final Result<Uint8List> result = await runIsolate(_render, (
      document: document,
      images: images,
      font: font,
    ), cancel: token);
    switch (result) {
      case FailureResult<Uint8List>(:final Failure failure):
        discard();
        if (failure is! CancelledFailure) throw failure;
      case Success<Uint8List>(:final Uint8List value):
        if (token.isCancelled) {
          discard();
          return;
        }
        emit(value);
        yield 1;
    }
  }
}

/// Report content, independent of the rendering library and file system.
typedef PdfDocument = ({
  String title,
  String project,
  List<String> coverLines,
  List<String> bodyLines,
  PdfPhotoBlock photos,
});

/// Ordered photos with their shared layout choices.
typedef PdfPhotoBlock = ({
  List<({String caption, String path})> entries,
  int columns,
  bool captions,
});

Future<Uint8List> _render(
  ({PdfDocument document, Map<String, Uint8List> images, Uint8List? font}) job,
) async {
  final PdfDocument source = job.document;
  final pw.Document pdf = pw.Document(
    title: source.title,
    author: source.project,
  );
  final pw.Font? font = job.font == null
      ? null
      : pw.Font.ttf(ByteData.sublistView(job.font!));
  // Every style derives from the theme's own text style, so the embedded font
  // reaches the headings as well as the body text.
  final pw.ThemeData fonts = pw.ThemeData.withFont(base: font, bold: font);
  final pw.ThemeData theme = fonts.copyWith(
    defaultTextStyle: fonts.defaultTextStyle.copyWith(
      fontSize: AppConstants.exportValues.pdfBody,
    ),
  );
  final pw.EdgeInsets margin = pw.EdgeInsets.all(AppConstants.pdfLayout.margin);
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: margin,
      theme: theme,
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            source.project,
            style: theme.defaultTextStyle.copyWith(
              fontSize: AppConstants.pdfLayout.heading,
            ),
          ),
          pw.SizedBox(height: AppConstants.pdfLayout.gap),
          pw.Text(
            source.title,
            style: theme.defaultTextStyle.copyWith(
              fontSize: AppConstants.pdfLayout.title,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: AppConstants.pdfLayout.gap),
          for (final String line in source.coverLines) pw.Paragraph(text: line),
        ],
      ),
    ),
  );
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: margin,
      theme: theme,
      maxPages: AppConstants.pdfLayout.maxPages,
      header: (pw.Context context) => pw.Header(
        level: 0,
        child: pw.Text('${source.project} — ${source.title}'),
      ),
      footer: (pw.Context context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('${context.pageNumber} of ${context.pagesCount}'),
      ),
      build: (pw.Context context) => <pw.Widget>[
        for (final String line in source.bodyLines) pw.Paragraph(text: line),
        if (source.photos.entries.isNotEmpty)
          pw.Header(level: 1, text: 'Photos'),
        ..._photoRows(source.photos, job.images),
      ],
    ),
  );
  return pdf.save();
}

List<pw.Widget> _photoRows(PdfPhotoBlock block, Map<String, Uint8List> images) {
  final List<pw.Widget> rows = <pw.Widget>[];
  for (int offset = 0; offset < block.entries.length; offset += block.columns) {
    rows.add(
      pw.Padding(
        padding: pw.EdgeInsets.only(bottom: AppConstants.pdfLayout.gap),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            for (int column = 0; column < block.columns; column++)
              pw.Expanded(
                child: offset + column >= block.entries.length
                    ? pw.SizedBox()
                    : _photo(block.entries[offset + column], block, images),
              ),
          ],
        ),
      ),
    );
  }
  return rows;
}

pw.Widget _photo(
  ({String caption, String path}) photo,
  PdfPhotoBlock block,
  Map<String, Uint8List> images,
) {
  final Uint8List? bytes = images[photo.path];
  return pw.Padding(
    padding: pw.EdgeInsets.all(AppConstants.pdfLayout.photoGap),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        if (bytes == null)
          pw.Text('Missing photo: ${photo.path}')
        else
          pw.Image(
            pw.MemoryImage(bytes),
            height: AppConstants.pdfLayout.photoHeight / block.columns,
            fit: pw.BoxFit.contain,
          ),
        if (block.captions && photo.caption.isNotEmpty) pw.Text(photo.caption),
        pw.Text(photo.path),
      ],
    ),
  );
}
