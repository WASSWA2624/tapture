import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'pdf_labels.dart';

export 'pdf_labels.dart';

/// The one PDF foundation every report stands on (task 018 step 9, task
/// 090): a cover page, a running header naming the project and report, a
/// numbered `n of m` footer, wrapped and paginated body sections, labelled
/// charts and the photo block. Reports supply content only; every size,
/// weight and colour comes from [style], which the caller derives from the
/// app's type scale and palette, and every word from [labels].
///
/// This is the only file that may import the rendering library.
final class PdfEngine {
  /// Creates the renderer.
  const PdfEngine({required this.style, required this.labels});

  /// Type sizes and colours, taken from the app's tokens.
  final PdfStyle style;

  /// Every word the reports print.
  final PdfLabels labels;

  /// A report: its cover totals and its body sections, in reading order.
  PdfDocument document({
    required String title,
    required String project,
    required List<String> coverLines,
    required List<PdfSection> sections,
  }) => (
    title: title,
    project: project,
    coverLines: coverLines,
    sections: sections,
  );

  /// One block of the body: a heading, its lines, a labelled chart and the
  /// photos evidencing it, beneath it.
  PdfSection section({
    String heading = '',
    List<String> lines = const <String>[],
    List<PdfBar> chart = const <PdfBar>[],
    PdfPhotoBlock? photos,
  }) => (
    heading: heading,
    lines: lines,
    chart: chart,
    photos: photos ?? photoBlock(const <PdfPhoto>[], columns: 1),
  );

  /// The photo grid every report uses: [columns] is 1 for full size and
  /// 2 to 4 for thumbnails.
  PdfPhotoBlock photoBlock(
    List<PdfPhoto> photos, {
    required int columns,
    bool captions = true,
  }) => (entries: photos, columns: columns.clamp(1, 4), captions: captions);

  /// Renders [document] on the isolate runner and hands the finished bytes
  /// to [emit]. [images] holds already reduced photo bytes keyed by the
  /// report's photo paths; no original file is opened or changed. A cancel
  /// before, during or after the render calls [discard] and emits nothing.
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
      style: style,
      labels: labels,
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
  List<PdfSection> sections,
});

/// One body block. An empty [heading], [chart] or photo block is left out.
typedef PdfSection = ({
  String heading,
  List<String> lines,
  List<PdfBar> chart,
  PdfPhotoBlock photos,
});

/// One labelled bar of a chart; its value is also printed beside it, so the
/// chart never carries what its lines do not (FE-THEME-05).
typedef PdfBar = ({String label, int value});

/// One photo: its caption and the path its reduced bytes are keyed by.
typedef PdfPhoto = ({String caption, String path});

/// Ordered photos with their shared layout choices.
typedef PdfPhotoBlock = ({List<PdfPhoto> entries, int columns, bool captions});

/// Sizes and spacing in points and colours as ARGB values, derived from the
/// app's type scale, spacing scale and palette by the caller.
typedef PdfStyle = ({
  double title,
  double heading,
  double body,
  double caption,
  double margin,
  double gap,
  double tight,
  int ink,
  int muted,
  int accent,
  int rule,
});

/// The body of [PdfDocument] as plain lines in reading order: each section's
/// heading, then its lines and chart rows.
extension PdfDocumentText on PdfDocument {
  /// Every heading and line of the body, in order.
  List<String> get bodyLines => <String>[
    for (final PdfSection section in sections) ...<String>[
      if (section.heading.isNotEmpty) section.heading,
      ...section.lines,
    ],
  ];
}

typedef _Job = ({
  PdfDocument document,
  PdfStyle style,
  PdfLabels labels,
  Map<String, Uint8List> images,
  Uint8List? font,
});

Future<Uint8List> _render(_Job job) async {
  final PdfDocument source = job.document;
  final PdfStyle style = job.style;
  final pw.Document pdf = pw.Document(
    title: source.title,
    author: source.project,
  );
  final Uint8List? fontBytes = job.font;
  final pw.ThemeData theme = pw.ThemeData.withFont(
    base: fontBytes == null
        ? null
        : pw.Font.ttf(ByteData.sublistView(fontBytes)),
  );
  final pw.TextStyle body = theme.defaultTextStyle.copyWith(
    fontSize: style.body,
    color: PdfColor.fromInt(style.ink),
  );
  final pw.TextStyle caption = body.copyWith(
    fontSize: style.caption,
    color: PdfColor.fromInt(style.muted),
  );
  final pw.TextStyle heading = body.copyWith(fontSize: style.heading);
  final pw.ThemeData themed = theme.copyWith(
    defaultTextStyle: body,
    paragraphStyle: body,
  );
  final double gap = style.gap;
  final pw.EdgeInsets margin = pw.EdgeInsets.all(style.margin);
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: margin,
      theme: themed,
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(source.project, style: heading),
          pw.SizedBox(height: gap),
          pw.Text(source.title, style: body.copyWith(fontSize: style.title)),
          pw.SizedBox(height: gap),
          for (final String line in source.coverLines) pw.Paragraph(text: line),
        ],
      ),
    ),
  );
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: margin,
      theme: themed,
      maxPages: AppConstants.pdfLayout.maxPages,
      header: (pw.Context context) => pw.Container(
        margin: pw.EdgeInsets.only(bottom: gap),
        padding: pw.EdgeInsets.only(bottom: style.tight),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColor.fromInt(style.rule)),
          ),
        ),
        child: pw.Text('${source.project} · ${source.title}', style: caption),
      ),
      footer: (pw.Context context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          job.labels.pageOf(context.pageNumber, context.pagesCount),
          style: caption,
        ),
      ),
      build: (pw.Context context) => <pw.Widget>[
        for (final PdfSection section in source.sections) ...<pw.Widget>[
          if (section.heading.isNotEmpty)
            pw.Padding(
              padding: pw.EdgeInsets.only(top: gap, bottom: gap / 2),
              child: pw.Text(section.heading, style: heading),
            ),
          for (final String line in section.lines) pw.Paragraph(text: line),
          if (section.chart.isNotEmpty) _chart(section.chart, style, caption),
          ..._photoRows(section.photos, job.images, job.labels, style, caption),
        ],
      ],
    ),
  );
  return pdf.save();
}

/// Horizontal bars in the accent colour, each labelled and valued.
pw.Widget _chart(List<PdfBar> bars, PdfStyle style, pw.TextStyle caption) {
  final int top = bars.fold<int>(
    0,
    (int highest, PdfBar bar) => math.max(highest, bar.value),
  );
  final double gap = style.tight;
  return pw.Padding(
    padding: pw.EdgeInsets.only(bottom: style.gap),
    child: pw.Column(
      children: <pw.Widget>[
        for (final PdfBar bar in bars)
          pw.Padding(
            padding: pw.EdgeInsets.only(bottom: gap),
            child: pw.Row(
              children: <pw.Widget>[
                pw.Expanded(flex: 2, child: pw.Text(bar.label, style: caption)),
                pw.SizedBox(width: gap),
                pw.Expanded(
                  flex: 3,
                  child: pw.Row(
                    children: <pw.Widget>[
                      if (bar.value > 0)
                        pw.Expanded(
                          flex: bar.value,
                          child: pw.Container(
                            height: style.caption,
                            color: PdfColor.fromInt(style.accent),
                          ),
                        ),
                      if (top - bar.value > 0)
                        pw.Expanded(
                          flex: top - bar.value,
                          child: pw.SizedBox(),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(width: gap),
                pw.Text('${bar.value}', style: caption),
              ],
            ),
          ),
      ],
    ),
  );
}

List<pw.Widget> _photoRows(
  PdfPhotoBlock block,
  Map<String, Uint8List> images,
  PdfLabels labels,
  PdfStyle style,
  pw.TextStyle caption,
) {
  final List<pw.Widget> rows = <pw.Widget>[];
  for (int offset = 0; offset < block.entries.length; offset += block.columns) {
    rows.add(
      pw.Padding(
        padding: pw.EdgeInsets.only(bottom: style.gap),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            for (int column = 0; column < block.columns; column++)
              pw.Expanded(
                child: offset + column >= block.entries.length
                    ? pw.SizedBox()
                    : _photo(
                        block.entries[offset + column],
                        block,
                        images,
                        labels,
                        style,
                        caption,
                      ),
              ),
          ],
        ),
      ),
    );
  }
  return rows;
}

pw.Widget _photo(
  PdfPhoto photo,
  PdfPhotoBlock block,
  Map<String, Uint8List> images,
  PdfLabels labels,
  PdfStyle style,
  pw.TextStyle caption,
) {
  final Uint8List? bytes = images[photo.path];
  return pw.Padding(
    padding: pw.EdgeInsets.all(style.tight),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        if (bytes == null)
          pw.Text('${labels.missingPhoto}: ${photo.path}', style: caption)
        else
          pw.Image(
            pw.MemoryImage(bytes),
            height: AppConstants.pdfLayout.photoHeight / block.columns,
            fit: pw.BoxFit.contain,
          ),
        if (block.captions && photo.caption.isNotEmpty)
          pw.Text(photo.caption, style: caption),
        pw.Text(photo.path, style: caption),
      ],
    ),
  );
}
