import 'export_record.dart';
import 'export_request.dart';
import 'tabular_columns.dart';
import 'value_formatter.dart';
import 'xlsx_writer.dart';

/// Shared selected record text used by Word, plain text and template placeholders.
abstract final class RecordDocumentText {
  /// Each record's selected fields and evidence, without another formatting policy.
  static Iterable<String> lines(ExportRequest request) sync* {
    const ExportValueFormatter formatter = ExportValueFormatter(<String>{});
    if (request.markedIncomplete) yield XlsxWriter.incompleteStamp;
    for (final ExportRecord record in request.records) {
      yield '${record.templateName} ${record.number}';
      for (final ExportColumn column in TabularColumns.plan(
        request,
        <ExportRecord>[record],
      )) {
        final String value = formatter.format(
          TabularColumns.value(record, column),
          TabularColumns.type(record, column),
          ExportFormat.txt,
        );
        yield '${column.header}: $value';
      }
      if (record.contextPath.isNotEmpty) yield record.contextPath;
      for (final ExportPhoto photo in record.photos) {
        yield '${photo.storedPath}: ${photo.caption}';
      }
      yield '';
    }
  }

  /// Placeholder values come only from the record, with empty missing fields.
  static Map<String, String> values(ExportRecord record) {
    const ExportValueFormatter formatter = ExportValueFormatter(<String>{});
    return <String, String>{
      'record_number': record.number,
      'template_name': record.templateName,
      'context_path': record.contextPath,
      'operator_name': record.operatorName,
      for (final ExportValue value in record.values)
        value.key: formatter.format(
          value.finalText ?? value.refined ?? value.raw,
          value.type,
          ExportFormat.txt,
        ),
    };
  }

  /// Native cells use the same formatter and captured types as other writers.
  static Map<String, Object?> typedValues(ExportRecord record) {
    const ExportValueFormatter formatter = ExportValueFormatter(<String>{});
    return <String, Object?>{
      ...values(record),
      for (final ExportValue value in record.values)
        value.key: formatter.typed(
          value.finalText ?? value.refined ?? value.raw,
          value.type,
        ),
    };
  }

  /// Recognises explicit field placeholders rather than interpreting user text.
  static final RegExp placeholder = RegExp(
    r'\{\{\s*([A-Za-z][A-Za-z0-9_]*)\s*\}\}',
  );

  /// Substitutes placeholders only; unknown fields are deliberately left empty.
  static String fill(String text, ExportRecord record) {
    final Map<String, String> fields = values(record);
    return text.replaceAllMapped(
      placeholder,
      (Match match) => fields[match.group(1)] ?? '',
    );
  }
}
