import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/import/header_detection.dart';
import 'package:tapture/core/import/workbook_reader.dart';

import '../domain/reference_dataset.dart';
import '../domain/reference_row.dart';
import 'dataset_csv_import.dart';

/// Parses a spreadsheet via [WorkbookReader] into a draft [ReferenceDataset].
abstract final class DatasetXlsxImport {
  /// Opens [path] with the shared workbook reader (FE-CONS-01, FE-STR-09).
  static Future<Result<DatasetImportDraft>> parse(
    String path, {
    String? projectId,
    String? name,
    int sheetIndex = 0,
    void Function(double)? onProgress,
    CancellationToken? cancel,
  }) async {
    final Result<WorkbookSnapshot> opened = await WorkbookReader.open(
      path,
      onProgress: onProgress,
      cancel: cancel,
    );
    return switch (opened) {
      FailureResult<WorkbookSnapshot>(:final Failure failure) =>
        FailureResult<DatasetImportDraft>(failure),
      Success<WorkbookSnapshot>(:final WorkbookSnapshot value) => _fromSnapshot(
        value,
        path: path,
        projectId: projectId,
        name: name,
        sheetIndex: sheetIndex,
      ),
    };
  }
}

Result<DatasetImportDraft> _fromSnapshot(
  WorkbookSnapshot snapshot, {
  required String path,
  String? projectId,
  String? name,
  required int sheetIndex,
}) {
  if (snapshot.sheets.isEmpty) {
    return const FailureResult<DatasetImportDraft>(
      ValidationFailure(
        message: 'That workbook has no sheets.',
        recoveryAction: 'Choose a workbook with a sheet of data.',
      ),
    );
  }
  final int index = sheetIndex < 0 || sheetIndex >= snapshot.sheets.length
      ? 0
      : sheetIndex;
  final WorkbookSheet sheet = snapshot.sheets[index];
  final HeaderGuess header = sheet.header.labels.isNotEmpty
      ? sheet.header
      : HeaderDetection.choose(sheet.rows);
  if (header.labels.isEmpty) {
    return const FailureResult<DatasetImportDraft>(
      ValidationFailure(
        message: 'That sheet has no header row.',
        recoveryAction: 'Add a header row and try again.',
      ),
    );
  }
  final List<String> columns = <String>[
    for (int i = 0; i < header.labels.length; i++)
      _unique(header.labels[i].trim(), i, header.labels),
  ];
  final int dataStart = header.rowNumber; // 1-based
  final List<Map<String, String>> rows = <Map<String, String>>[];
  for (int r = dataStart; r < sheet.rows.length; r++) {
    final List<String> line = sheet.rows[r];
    if (line.every((String cell) => cell.trim().isEmpty)) {
      continue;
    }
    rows.add(<String, String>{
      for (int c = 0; c < columns.length; c++)
        columns[c]: c < line.length ? line[c] : '',
    });
  }
  final String keyGuess = columns.first;
  final List<ReferenceRow> mapped = <ReferenceRow>[
    for (final Map<String, String> row in rows)
      ReferenceRow(
        id: '',
        datasetId: '',
        key: row[keyGuess] ?? '',
        values: row,
      ),
  ];
  final Map<String, int> duplicateCounts = <String, int>{
    for (final String column in columns) column: _dups(rows, column),
  };
  final Map<String, List<String>> samples = <String, List<String>>{
    for (final String column in columns)
      column: <String>[
        for (final Map<String, String> row in rows.take(3)) row[column] ?? '',
      ],
  };
  final String fileName = path.replaceAll('\\', '/').split('/').last;
  return Success<DatasetImportDraft>((
    dataset: ReferenceDataset(
      id: '',
      name: (name == null || name.isEmpty)
          ? fileName.replaceAll(RegExp(r'\.[^.]+$'), '')
          : name,
      keyColumn: keyGuess,
      columns: columns,
      source: DatasetSource.xlsx,
      importedAt: DateTime.now().toUtc(),
      rowCount: mapped.length,
      projectId: projectId,
      sourceFile: path,
    ),
    rows: mapped,
    duplicateCounts: duplicateCounts,
    samples: samples,
  ));
}

String _unique(String label, int index, List<String> headers) {
  final String base = label.isEmpty ? 'column_${index + 1}' : label;
  int suffix = 2;
  String candidate = base;
  final Set<String> earlier = <String>{
    for (int i = 0; i < index; i++)
      headers[i].trim().isEmpty ? 'column_${i + 1}' : headers[i].trim(),
  };
  while (earlier.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

int _dups(List<Map<String, String>> rows, String column) {
  final Map<String, int> counts = <String, int>{};
  for (final Map<String, String> row in rows) {
    final String value = row[column] ?? '';
    counts[value] = (counts[value] ?? 0) + 1;
  }
  int dups = 0;
  for (final int count in counts.values) {
    if (count > 1) {
      dups += count - 1;
    }
  }
  return dups;
}
