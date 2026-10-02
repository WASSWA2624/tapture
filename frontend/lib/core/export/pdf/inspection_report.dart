import '../export_record.dart';
import '../export_request.dart';
import 'pdf_engine.dart';
import 'record_report.dart';

/// A checklist report in the order of the template's predefined rows, not
/// capture order (task 018 step 10, A15). Each row prints its captured
/// result, observation, risk and recommendation with its evidence photos
/// beneath; a row never found prints **Not found**, a finding rather than a
/// gap. The cover carries the compliance total and the not-found count.
final class InspectionReport {
  /// The report of checklist [checklist]. [rows] are its predefined rows in
  /// order; [records] are the exported records of that checklist; [notFound]
  /// is the set of row ids the missing-item computation of task 015 found
  /// uncaptured. Records that answer no predefined row follow the rows.
  static PdfDocument build({
    required PdfEngine engine,
    required String project,
    required String checklist,
    required List<InspectionRowSpec> rows,
    required List<ExportRecord> records,
    required Set<String> notFound,
    required ExportColumns columns,
    int photoColumns = 3,
    List<String> cover = const <String>[],
  }) {
    final PdfLabels text = engine.labels;
    final Map<String, ExportRecord> answers = <String, ExportRecord>{
      for (final ExportRecord record in records.reversed)
        if (record.templateRowId case final String row) row: record,
    };
    final Set<String> known = <String>{
      for (final InspectionRowSpec row in rows) row.id,
    };
    var compliant = 0;
    var missing = 0;
    final List<PdfSection> sections = <PdfSection>[];
    for (final InspectionRowSpec row in rows) {
      final ExportRecord? answer = answers[row.id];
      if (answer == null || notFound.contains(row.id)) {
        missing += 1;
        sections.add(
          engine.section(heading: row.label, lines: <String>[text.notFound]),
        );
        continue;
      }
      if (complies(answer)) {
        compliant += 1;
      }
      sections.add(_answer(engine, row.label, answer, columns, photoColumns));
    }
    for (final ExportRecord record in records) {
      if (record.templateRowId == null ||
          !known.contains(record.templateRowId)) {
        sections.add(
          _answer(
            engine,
            '${record.templateName} ${record.number}',
            record,
            columns,
            photoColumns,
          ),
        );
      }
    }
    return engine.document(
      title: text.inspectionReport,
      project: '$project · $checklist',
      coverLines: <String>[
        ...cover,
        text.checklistRows(rows.length),
        text.compliance(compliant, rows.length),
        text.notFoundCount(missing),
      ],
      sections: sections,
    );
  }

  /// Whether [record]'s result reads as compliant: its first value whose key
  /// names a result, compliance or pass reads yes, pass, compliant or ok.
  static bool complies(ExportRecord record) {
    for (final ExportValue value in record.values) {
      if (_resultKey.hasMatch(value.key)) {
        final String answer =
            (value.finalText ?? value.refined ?? value.raw ?? '')
                .trim()
                .toLowerCase();
        return _compliant.contains(answer);
      }
    }
    return false;
  }

  static PdfSection _answer(
    PdfEngine engine,
    String heading,
    ExportRecord record,
    ExportColumns columns,
    int photoColumns,
  ) {
    return engine.section(
      heading: heading,
      lines: <String>[
        for (final ExportValue value in record.values)
          ...RecordReport.valueLines(value, columns, engine.labels),
      ],
      photos: engine.photoBlock(<PdfPhoto>[
        for (final ExportPhoto photo in record.photos)
          (caption: photo.caption, path: photo.storedPath),
      ], columns: photoColumns),
    );
  }
}

/// One predefined checklist row: its stored id and operator-facing label.
typedef InspectionRowSpec = ({String id, String label});

final RegExp _resultKey = RegExp('result|complian|pass');

const Set<String> _compliant = <String>{
  'yes',
  'y',
  'pass',
  'passed',
  'compliant',
  'complies',
  'ok',
  'true',
  'satisfactory',
};
