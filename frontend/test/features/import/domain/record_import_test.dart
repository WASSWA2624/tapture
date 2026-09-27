import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/validation/field_rule.dart';
import 'package:tapture/features/import/domain/import_duplicates.dart';
import 'package:tapture/features/import/domain/record_import.dart';

void main() {
  const FieldRule serial = FieldRule(
    fieldKey: 'serial',
    label: 'Serial',
    identity: true,
    required: true,
  );
  const FieldRule name = FieldRule(fieldKey: 'name', label: 'Name');

  RecordMapping mapping({
    ImportDuplicateChoice? applyToAll,
    Map<int, ImportDuplicateChoice> choices =
        const <int, ImportDuplicateChoice>{},
    Set<int>? onlyRows,
  }) {
    return (
      fields: const <FieldRule>[serial, name],
      columnToField: const <String, String>{'Serial': 'serial', 'Name': 'name'},
      rows: const <Map<String, String>>[
        <String, String>{'Serial': 'A-1', 'Name': 'Pump'},
        <String, String>{'Serial': '', 'Name': 'Blank'},
        <String, String>{'Serial': 'A-1', 'Name': 'Again'},
      ],
      existingByIdentity: const <String, String>{'A-1': 'existing'},
      applyToAll: applyToAll,
      choices: choices,
      onlyRows: onlyRows,
      firstDataRow: 2,
      batchSize: 2,
    );
  }

  test('invalid rows are kept aside and valid rows still import', () async {
    final List<ImportProgress> steps = await RecordImport()
        .run(
          mapping(
            choices: const <int, ImportDuplicateChoice>{
              2: ImportDuplicateChoice.replace,
            },
          ),
          token: CancellationToken(),
        )
        .toList();
    final RecordImportResult result = steps.last.result;
    expect(result.failures.single.row, 3);
    expect(result.failures.single.reason, isNotEmpty);
    expect(result.updated.single.source, RecordImport.importedSource);
    expect(result.updated.single.existingId, 'existing');
    expect(RecordImport.correctiveList(result), contains('3,failed'));
  });

  test('ten thousand rows report progress per batch', () async {
    final List<Map<String, String>> rows = <Map<String, String>>[
      for (var index = 0; index < 10000; index++)
        <String, String>{'Name': 'Row $index'},
    ];
    final List<ImportProgress> steps = await RecordImport().run((
      fields: const <FieldRule>[name],
      columnToField: const <String, String>{'Name': 'name'},
      rows: rows,
      existingByIdentity: const <String, String>{},
      applyToAll: null,
      choices: const <int, ImportDuplicateChoice>{},
      onlyRows: null,
      firstDataRow: 2,
      batchSize: 1000,
    ), token: CancellationToken()).toList();
    expect(steps.length, greaterThan(1));
    expect(steps.last.done, 10000);
    expect(steps.last.result.created, hasLength(10000));
    expect(steps.last.result.created.first.source, RecordImport.importedSource);
  });

  test('retry runs only the failed rows', () async {
    final RecordImportResult first =
        (await RecordImport()
                .run(mapping(), token: CancellationToken())
                .toList())
            .last
            .result;
    final RecordImportResult retry =
        (await RecordImport()
                .run(
                  mapping(
                    onlyRows: <int>{
                      for (final RowFailure row in first.failures) row.row,
                    },
                  ),
                  token: CancellationToken(),
                )
                .toList())
            .last
            .result;
    expect(retry.failures.single.row, first.failures.single.row);
    expect(retry.created, isEmpty);
    expect(retry.updated, isEmpty);
  });

  test(
    'a header that matches a field is suggested, and a missing identity is named',
    () {
      expect(
        RecordImport.suggest(
          headers: const <String>['Serial', 'Notes'],
          fields: const <FieldRule>[serial, name],
        ),
        <String, String>{'Serial': 'serial'},
      );
      expect(
        RecordImport.missingIdentity(
          fields: const <FieldRule>[serial],
          columnToField: const <String, String>{},
        ),
        <String>['Serial'],
      );
    },
  );
}
