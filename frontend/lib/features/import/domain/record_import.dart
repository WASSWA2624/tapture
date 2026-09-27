import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/validation/validation.dart';

import 'import_duplicates.dart';

/// Turns mapped spreadsheet rows into records (task 020).
///
/// Invalid rows are collected. Valid rows still import. Created records
/// carry source [importedSource]. A cancelled run keeps nothing from the
/// unfinished batch.
final class RecordImport {
  /// Source written on every record this import creates.
  static const String importedSource = 'IMPORTED_TABLE';

  /// Suggests a column for each field whose key or label matches a header.
  static Map<String, String> suggest({
    required List<String> headers,
    required List<FieldRule> fields,
  }) {
    final Map<String, String> mapping = <String, String>{};
    for (final FieldRule field in fields) {
      for (final String header in headers) {
        final String folded = header.trim().toLowerCase();
        if (folded == field.fieldKey.toLowerCase() ||
            folded == field.label.trim().toLowerCase()) {
          mapping[header] = field.fieldKey;
        }
      }
    }
    return mapping;
  }

  /// Identity fields that [columnToField] does not cover.
  static List<String> missingIdentity({
    required List<FieldRule> fields,
    required Map<String, String> columnToField,
  }) {
    final Set<String> mapped = columnToField.values.toSet();
    return <String>[
      for (final FieldRule field in fields)
        if (field.identity && !mapped.contains(field.fieldKey)) field.label,
    ];
  }

  /// Imports [mapping]. [onlyRows] retries just those spreadsheet row numbers.
  Stream<ImportProgress> run(
    RecordMapping mapping, {
    required CancellationToken token,
    ValidationEngine engine = validationEngine,
  }) async* {
    final List<ImportedRow> created = <ImportedRow>[];
    final List<ImportedRow> updated = <ImportedRow>[];
    final List<RowFailure> skipped = <RowFailure>[];
    final List<RowFailure> failures = <RowFailure>[];
    final int total = mapping.rows.length;
    for (var index = 0; index < mapping.rows.length; index++) {
      if (token.isCancelled) {
        yield _progress(
          done: index,
          total: total,
          created: const <ImportedRow>[],
          updated: const <ImportedRow>[],
          skipped: skipped,
          failures: failures,
        );
        return;
      }
      final int rowNumber = mapping.firstDataRow + index;
      if (mapping.onlyRows != null && !mapping.onlyRows!.contains(rowNumber)) {
        continue;
      }
      final Map<String, String> values = _values(
        mapping.rows[index],
        mapping.columnToField,
      );
      final List<ValidationIssue> issues = engine.validateRecord(
        fields: mapping.fields,
        values: values,
        hasEvidence: false,
        conflicts: const <String>[],
      );
      final ValidationIssue? block = issues
          .where((ValidationIssue issue) => issue.blocks)
          .firstOrNull;
      if (block != null) {
        failures.add((row: rowNumber, reason: block.message, values: values));
        continue;
      }
      final String identity = _identity(mapping.fields, values);
      final String? existing = mapping.existingByIdentity[identity];
      final ImportMatch match = ImportDuplicates.apply(
        matched: existing != null && identity.isNotEmpty,
        choice: mapping.choices[rowNumber],
        applyToAll: mapping.applyToAll,
      );
      switch (match) {
        case ImportMatch.ask || ImportMatch.keep:
          skipped.add((
            row: rowNumber,
            reason: match == ImportMatch.ask
                ? 'Choose what to do with the existing record.'
                : 'Kept the existing record.',
            values: values,
          ));
        case ImportMatch.create:
          created.add((
            row: rowNumber,
            source: importedSource,
            values: values,
            existingId: null,
          ));
        case ImportMatch.replace || ImportMatch.merge:
          updated.add((
            row: rowNumber,
            source: importedSource,
            values: values,
            existingId: existing,
          ));
      }
      if ((index + 1) % mapping.batchSize == 0) {
        yield _progress(
          done: index + 1,
          total: total,
          created: created,
          updated: updated,
          skipped: skipped,
          failures: failures,
        );
      }
    }
    yield _progress(
      done: total,
      total: total,
      created: created,
      updated: updated,
      skipped: skipped,
      failures: failures,
    );
  }

  /// CSV of skipped and failed rows, for correction and re-import.
  static String correctiveList(RecordImportResult result) {
    final StringBuffer buffer = StringBuffer('row,outcome,reason\n');
    for (final RowFailure row in result.skipped) {
      buffer.writeln('${row.row},skipped,${_cell(row.reason)}');
    }
    for (final RowFailure row in result.failures) {
      buffer.writeln('${row.row},failed,${_cell(row.reason)}');
    }
    return buffer.toString();
  }
}

/// One mapped import.
typedef RecordMapping = ({
  List<FieldRule> fields,
  Map<String, String> columnToField,
  List<Map<String, String>> rows,
  Map<String, String> existingByIdentity,
  ImportDuplicateChoice? applyToAll,
  Map<int, ImportDuplicateChoice> choices,
  Set<int>? onlyRows,
  int firstDataRow,
  int batchSize,
});

/// A row that was written.
typedef ImportedRow = ({
  int row,
  String source,
  Map<String, String> values,
  String? existingId,
});

/// A row that was not written, with the reason.
typedef RowFailure = ({int row, String reason, Map<String, String> values});

/// Counts and the rows behind them.
typedef RecordImportResult = ({
  List<ImportedRow> created,
  List<ImportedRow> updated,
  List<RowFailure> skipped,
  List<RowFailure> failures,
});

/// Progress through one import.
typedef ImportProgress = ({int done, int total, RecordImportResult result});

ImportProgress _progress({
  required int done,
  required int total,
  required List<ImportedRow> created,
  required List<ImportedRow> updated,
  required List<RowFailure> skipped,
  required List<RowFailure> failures,
}) {
  return (
    done: done,
    total: total,
    result: (
      created: List<ImportedRow>.of(created),
      updated: List<ImportedRow>.of(updated),
      skipped: List<RowFailure>.of(skipped),
      failures: List<RowFailure>.of(failures),
    ),
  );
}

Map<String, String> _values(
  Map<String, String> row,
  Map<String, String> columnToField,
) {
  final Map<String, String> values = <String, String>{};
  for (final MapEntry<String, String> entry in columnToField.entries) {
    values[entry.value] = row[entry.key] ?? '';
  }
  return values;
}

String _identity(List<FieldRule> fields, Map<String, String> values) {
  final StringBuffer buffer = StringBuffer();
  for (final FieldRule field in fields) {
    if (!field.identity) {
      continue;
    }
    if (buffer.isNotEmpty) {
      buffer.write('|');
    }
    buffer.write(values[field.fieldKey] ?? '');
  }
  return buffer.toString();
}

String _cell(String reason) {
  if (reason.contains(',') || reason.contains('"')) {
    return '"${reason.replaceAll('"', '""')}"';
  }
  return reason;
}
