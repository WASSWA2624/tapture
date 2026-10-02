import '../export_record.dart';
import '../export_request.dart';
import '../value_formatter.dart';
import 'pdf_engine.dart';

/// One section per record, through [PdfEngine] (task 018 step 10): its
/// fields, its context path, operator and capture time, and its photos with
/// captions beneath it, in thumbnail or full-size layout.
final class RecordReport {
  /// The report of every record in [request], headed with [project].
  /// [cover] carries the export's own facts (date, operator, filters).
  static PdfDocument build(
    ExportRequest request, {
    required PdfEngine engine,
    required String project,
    List<String> cover = const <String>[],
  }) {
    final PdfLabels text = engine.labels;
    final int columns = PdfPhotoLayout.columns(request.extras.pdfPhotos);
    return engine.document(
      title: text.recordReport,
      project: project,
      coverLines: <String>[
        ...cover,
        text.recordsCount(request.records.length),
        if (request.markedIncomplete) text.incomplete,
      ],
      sections: <PdfSection>[
        for (final ExportRecord record in request.records)
          engine.section(
            heading: '${record.templateName} ${record.number}',
            lines: <String>[
              ...recordFacts(record, text),
              for (final ExportValue value in record.values)
                ...valueLines(value, request.columns, text),
            ],
            photos: engine.photoBlock(<PdfPhoto>[
              for (final ExportPhoto photo in record.photos)
                (caption: photo.caption, path: photo.storedPath),
            ], columns: columns),
          ),
      ],
    );
  }

  /// A record's context path, operator and capture time, each labelled;
  /// an absent fact is left out.
  static List<String> recordFacts(ExportRecord record, PdfLabels text) {
    final DateTime? captured = DateTime.tryParse(record.capturedAt);
    return <String>[
      if (record.contextPath.isNotEmpty)
        '${text.context}: ${record.contextPath}',
      if (record.operatorName.isNotEmpty)
        '${text.operator}: ${record.operatorName}',
      if (captured != null)
        '${text.captured}: ${_formatter.format(captured, 'dateTime', ExportFormat.pdf)}',
    ];
  }

  /// [value]'s line, through the one export formatter, then its raw and
  /// refined companions where [columns] asks for them and they differ.
  static List<String> valueLines(
    ExportValue value,
    ExportColumns columns,
    PdfLabels text,
  ) {
    final String shown = _formatter.format(
      value.finalText ?? value.refined ?? value.raw,
      value.type,
      ExportFormat.pdf,
    );
    final String raw = _formatter.format(
      value.raw,
      value.type,
      ExportFormat.pdf,
    );
    final String refined = _formatter.format(
      value.refined,
      value.type,
      ExportFormat.pdf,
    );
    return <String>[
      '${value.label}: $shown',
      if (columns.raw && raw.isNotEmpty && raw != shown)
        '${text.raw(value.label)}: $raw',
      if (columns.refined && refined.isNotEmpty && refined != shown)
        '${text.refined(value.label)}: $refined',
    ];
  }
}

/// The single formatter every export writer calls (FE-CONS-09).
const ExportValueFormatter _formatter = ExportValueFormatter(<String>{});
