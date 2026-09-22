import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/reference/data/dataset_csv_import.dart';
import 'package:tapture/features/reference/data/dataset_export.dart';
import 'package:tapture/features/reference/data/dataset_json_import.dart';
import 'package:tapture/features/reference/domain/reference_dataset.dart';
import 'package:tapture/features/reference/domain/reference_row.dart';

void main() {
  test('CSV parser handles semicolon, quotes, BOM and blank rows', () {
    const String text =
        '\uFEFFcode;name\n'
        'A;"Acme, Inc"\n'
        '\n'
        'B;Beta\n';
    final DatasetImportDraft draft = _ok(
      DatasetCsvImport.parseText(text, sourceFile: 'parts.csv'),
    );
    expect(draft.dataset.columns, <String>['code', 'name']);
    expect(draft.rows, hasLength(2));
    expect(draft.rows.first.values['name'], 'Acme, Inc');
  });

  test('JSON importer unions keys in first-seen order', () {
    const String text =
        '['
        '{"code":"A","name":"One"},'
        '{"code":"B","phone":"123","name":"Two"}'
        ']';
    final DatasetImportDraft draft = _ok(
      DatasetJsonImport.parseText(text, sourceFile: 'parts.json'),
    );
    expect(draft.dataset.columns, <String>['code', 'name', 'phone']);
    expect(draft.rows.first.values['phone'], '');
    expect(draft.rows.last.values['phone'], '123');
  });

  test('CSV and JSON export re-import keep column order and device rows', () {
    final ReferenceDataset dataset = ReferenceDataset(
      id: 'ds',
      name: 'Parts',
      keyColumn: 'code',
      columns: const <String>['code', 'name', 'phone'],
      source: DatasetSource.csv,
      importedAt: DateTime.utc(2026, 9, 22),
      rowCount: 2,
      sourceFile: 'parts.csv',
    );
    final List<ReferenceRow> rows = <ReferenceRow>[
      const ReferenceRow(
        id: '1',
        datasetId: 'ds',
        key: 'A',
        values: <String, String>{'code': 'A', 'name': 'One', 'phone': '1'},
      ),
      const ReferenceRow(
        id: '2',
        datasetId: 'ds',
        key: 'B',
        values: <String, String>{'code': 'B', 'name': 'Two', 'phone': '2'},
        addedOnDevice: true,
      ),
    ];
    final String csv = DatasetExport.csvText(dataset: dataset, rows: rows);
    final DatasetImportDraft fromCsv = _ok(
      DatasetCsvImport.parseText(csv, sourceFile: 'round.csv'),
    );
    expect(fromCsv.dataset.columns.first, 'code');
    expect(fromCsv.dataset.columns, containsAll(<String>['name', 'phone']));
    expect(fromCsv.rows, hasLength(2));

    final String json = DatasetExport.jsonText(dataset: dataset, rows: rows);
    final DatasetImportDraft fromJson = _ok(
      DatasetJsonImport.parseText(json, sourceFile: 'round.json'),
    );
    expect(fromJson.dataset.columns.first, 'code');
    expect(fromJson.rows.map((ReferenceRow r) => r.key), <String>['A', 'B']);
  });
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
