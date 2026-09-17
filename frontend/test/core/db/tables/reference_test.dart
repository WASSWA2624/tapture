import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/reference.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late AppDatabase db;
  late UuidV7Service ids;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);

  setUp(() {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
  });

  tearDown(() async {
    await db.close();
  });

  test('a dataset inserts and round-trips its header', () async {
    final ReferenceDatasetRow written = _ok(
      await upsertReferenceDataset(
        db,
        row: _dataset(name: 'Parts', sourceFile: 'parts.csv'),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    expect(written.name, 'Parts');
    expect(written.scope, ReferenceScope.global);
    expect(written.projectId, isNull);
    expect(written.keyColumn, 'serial');
    expect(jsonDecode(written.columns), <String>['serial', 'model']);
    expect(written.sourceFile, 'parts.csv');
    expect(written.rowCount, 0);
  });

  test(
    'keyed lookup hits the unique index and normalised lookup folds the query',
    () async {
      final ReferenceDatasetRow dataset = _ok(
        await upsertReferenceDataset(
          db,
          row: _dataset(name: 'Parts', sourceFile: 'parts.csv'),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final ReferenceLookupRow cafe = _ok(
        await upsertReferenceRow(
          db,
          row: ReferenceRowsCompanion(
            datasetId: Value<String>(dataset.id),
            keyValue: const Value<String>('Café Latte'),
            values: Value<String>(
              jsonEncode(<String, String>{'name': 'Coffee'}),
            ),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await upsertReferenceRow(
          db,
          row: ReferenceRowsCompanion(
            datasetId: Value<String>(dataset.id),
            keyValue: const Value<String>('SN-001'),
            values: Value<String>(jsonEncode(<String, String>{'name': 'Pump'})),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      final ReferenceLookupRow? byKey = _ok(
        await lookupReferenceRowByKey(
          db,
          datasetId: dataset.id,
          keyValue: 'SN-001',
        ),
      );
      expect(byKey?.values, contains('Pump'));

      final List<ReferenceLookupRow> folded = _ok(
        await lookupReferenceRowsByNormalised(
          db,
          datasetId: dataset.id,
          query: '  CAFE   LATTE ',
        ),
      );
      expect(folded, hasLength(1));
      expect(folded.single.id, cafe.id);
      expect(cafe.keyNormalised, 'cafe latte');

      final List<QueryRow> keyPlan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM reference_rows '
            'WHERE dataset_id = ? AND key_value = ?',
            variables: <Variable<String>>[
              Variable<String>(dataset.id),
              const Variable<String>('SN-001'),
            ],
          )
          .get();
      expect(
        keyPlan.map((QueryRow row) => row.read<String>('detail')).join('; '),
        contains('reference_rows_by_key'),
      );

      final List<QueryRow> foldedPlan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM reference_rows '
            'WHERE dataset_id = ? AND key_normalised = ?',
            variables: <Variable<String>>[
              Variable<String>(dataset.id),
              const Variable<String>('cafe latte'),
            ],
          )
          .get();
      expect(
        foldedPlan.map((QueryRow row) => row.read<String>('detail')).join('; '),
        contains('reference_rows_by_normalised'),
      );
    },
  );

  test('re-importing the same source file updates rows in place', () async {
    final ReferenceDatasetRow first = _ok(
      await importReferenceDataset(
        db,
        dataset: _dataset(name: 'Parts', sourceFile: 'parts.csv', rowCount: 1),
        rows: <({String keyValue, Map<String, String> values})>[
          (keyValue: 'SN-001', values: <String, String>{'name': 'Old pump'}),
        ],
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    final ReferenceLookupRow original = _ok(
      await lookupReferenceRowByKey(
        db,
        datasetId: first.id,
        keyValue: 'SN-001',
      ),
    )!;

    final ReferenceDatasetRow second = _ok(
      await importReferenceDataset(
        db,
        dataset: _dataset(
          name: 'Parts v2',
          sourceFile: 'parts.csv',
          rowCount: 1,
        ),
        rows: <({String keyValue, Map<String, String> values})>[
          (keyValue: 'SN-001', values: <String, String>{'name': 'New pump'}),
        ],
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    expect(second.id, first.id);
    expect(second.name, 'Parts v2');

    final List<ReferenceDatasetRow> datasets = await db
        .select(db.reference)
        .get();
    expect(datasets, hasLength(1));

    final ReferenceLookupRow updated = _ok(
      await lookupReferenceRowByKey(
        db,
        datasetId: first.id,
        keyValue: 'SN-001',
      ),
    )!;
    expect(updated.id, original.id);
    expect(jsonDecode(updated.values), <String, String>{'name': 'New pump'});
  });

  test(
    'a dataset of 10,000 rows imports and a key lookup stays under 300ms',
    () async {
      const int n = 10000;
      final List<({String keyValue, Map<String, String> values})> rows =
          <({String keyValue, Map<String, String> values})>[
            for (int i = 0; i < n; i++)
              (
                keyValue: 'k-${i.toString().padLeft(5, '0')}',
                values: <String, String>{'n': '$i'},
              ),
          ];
      final ReferenceDatasetRow dataset = _ok(
        await importReferenceDataset(
          db,
          dataset: _dataset(name: 'Big', sourceFile: 'big.csv', rowCount: n),
          rows: rows,
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(dataset.rowCount, n);

      final Stopwatch watch = Stopwatch()..start();
      final ReferenceLookupRow? found = _ok(
        await lookupReferenceRowByKey(
          db,
          datasetId: dataset.id,
          keyValue: 'k-05000',
        ),
      );
      watch.stop();
      expect(found?.values, contains('5000'));
      expect(watch.elapsedMilliseconds, lessThan(300));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('version 7 creates the reference tables with merge columns', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_reference_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    final File seed = File('${directory.path}/tapture.sqlite');
    _seedVersion1(seed);

    final AppDatabase upgraded = AppDatabase.open(
      directoryPath: directory.path,
    );
    addTearDown(upgraded.close);
    await upgraded.customSelect('SELECT 1').get();

    expect(
      await _columns(upgraded, 'reference_datasets'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'name',
        'scope',
        'project_id',
        'key_column',
        'columns',
        'source_file',
        'imported_at',
        'row_count',
      ]),
    );
    expect(
      await _columns(upgraded, 'reference_rows'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'dataset_id',
        'key_value',
        'key_normalised',
        'values',
      ]),
    );
  });
}

ReferenceCompanion _dataset({
  required String name,
  required String sourceFile,
  int rowCount = 0,
}) {
  return ReferenceCompanion(
    name: Value<String>(name),
    scope: const Value<ReferenceScope>(ReferenceScope.global),
    keyColumn: const Value<String>('serial'),
    columns: Value<String>(jsonEncode(<String>['serial', 'model'])),
    sourceFile: Value<String>(sourceFile),
    importedAt: Value<DateTime>(DateTime.utc(2026, 9, 17, 8)),
    rowCount: Value<int>(rowCount),
  );
}

void _seedVersion1(File file) {
  file.parent.createSync(recursive: true);
  final Database database = sqlite3.open(file.path);
  database.execute('PRAGMA user_version = 1');
  database.dispose();
}

Future<Set<String>> _columns(AppDatabase db, String table) async {
  final List<QueryRow> info = await db
      .customSelect('PRAGMA table_info("$table")')
      .get();
  return <String>{for (final QueryRow row in info) row.read<String>('name')};
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
