import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/errors/failure.dart';

import 'reference_dataset.dart';
import 'reference_row.dart';

/// A parsed table waiting on the key-column screen: the dataset header, its
/// rows in file order, and for every column how many of its values repeat,
/// its first few values, and the first few values that repeat.
typedef DatasetImportDraft = ({
  ReferenceDataset dataset,
  List<ReferenceRow> rows,
  Map<String, int> duplicateCounts,
  Map<String, List<String>> samples,
  Map<String, List<String>> collisions,
});

/// Builds the one [DatasetImportDraft] shape the CSV, JSON and spreadsheet
/// readers all land, so a table reads the same whichever route it arrived by.
abstract final class DatasetDraft {
  /// The column an export writes to mark rows added on the device. It is a
  /// flag on the row, never a data column.
  static const String addedOnDeviceColumn = 'addedOnDevice';

  /// [labels] as unique column names in the same order: a blank label
  /// becomes `column_N` and a repeat gains `_2`, `_3` and so on, so no
  /// column is lost.
  static List<String> uniqueColumns(List<String> labels) {
    final List<String> columns = <String>[];
    final Set<String> taken = <String>{};
    for (int index = 0; index < labels.length; index++) {
      final String trimmed = labels[index].trim();
      final String base = trimmed.isEmpty ? 'column_${index + 1}' : trimmed;
      String candidate = base;
      int suffix = 2;
      while (taken.contains(candidate)) {
        candidate = '${base}_$suffix';
        suffix++;
      }
      taken.add(candidate);
      columns.add(candidate);
    }
    return columns;
  }

  /// The draft for [rows] under [columns], keyed on the first data column
  /// until the operator picks another.
  ///
  /// A column named [addedOnDeviceColumn] marks rows added on the device and
  /// is dropped from the data. Throws a [ValidationFailure] when the table
  /// has no data column.
  static DatasetImportDraft build({
    required List<String> columns,
    required List<Map<String, String>> rows,
    required DatasetSource source,
    required String sourceFile,
    required DateTime importedAt,
    String? projectId,
    String? name,
  }) {
    final List<String> dataColumns = <String>[
      for (final String column in columns)
        if (column != addedOnDeviceColumn) column,
    ];
    if (dataColumns.isEmpty) {
      throw ValidationFailure(
        localizedMessage: DomainCopy.messages.failureThatTableHasNoDataColumns,
        localizedRecovery: DomainCopy.messages.failureAddAHeaderRowAndTryAgain,
      );
    }
    final String key = dataColumns.first;
    final List<ReferenceRow> mapped = <ReferenceRow>[
      for (final Map<String, String> row in rows)
        ReferenceRow(
          id: '',
          datasetId: '',
          key: row[key] ?? '',
          values: <String, String>{
            for (final String column in dataColumns) column: row[column] ?? '',
          },
          addedOnDevice: row[addedOnDeviceColumn]?.trim() == 'true',
        ),
    ];
    final Map<String, int> duplicateCounts = <String, int>{};
    final Map<String, List<String>> collisions = <String, List<String>>{};
    for (final String column in dataColumns) {
      final ({int duplicates, List<String> colliding}) repeats = _repeats(
        rows,
        column,
      );
      duplicateCounts[column] = repeats.duplicates;
      collisions[column] = repeats.colliding;
    }
    final String fileName = sourceFile.replaceAll(r'\', '/').split('/').last;
    return (
      dataset: ReferenceDataset(
        id: '',
        name: (name == null || name.trim().isEmpty)
            ? fileName.replaceAll(_extension, '')
            : name.trim(),
        keyColumn: key,
        columns: dataColumns,
        source: source,
        importedAt: importedAt,
        rowCount: mapped.length,
        projectId: projectId,
        sourceFile: sourceFile,
      ),
      rows: mapped,
      duplicateCounts: duplicateCounts,
      samples: <String, List<String>>{
        for (final String column in dataColumns)
          column: <String>[
            for (final Map<String, String> row in rows.take(_shown))
              row[column] ?? '',
          ],
      },
      collisions: collisions,
    );
  }
}

/// How many sample and colliding values a column offers.
const int _shown = 3;

/// A file name's final extension, dot included.
final RegExp _extension = RegExp(r'\.[^.]+$');

/// How many of [column]'s values repeat an earlier one, and the first few
/// non-blank values that repeat, in the order they first appear.
({int duplicates, List<String> colliding}) _repeats(
  List<Map<String, String>> rows,
  String column,
) {
  final Map<String, int> counts = <String, int>{};
  for (final Map<String, String> row in rows) {
    final String value = row[column] ?? '';
    counts[value] = (counts[value] ?? 0) + 1;
  }
  int duplicates = 0;
  final List<String> colliding = <String>[];
  for (final MapEntry<String, int> entry in counts.entries) {
    if (entry.value < 2) {
      continue;
    }
    duplicates += entry.value - 1;
    if (colliding.length < _shown && entry.key.trim().isNotEmpty) {
      colliding.add(entry.key);
    }
  }
  return (duplicates: duplicates, colliding: colliding);
}
