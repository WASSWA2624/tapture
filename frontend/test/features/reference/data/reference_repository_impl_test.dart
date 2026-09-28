import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/reference.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/reference/data/reference_mapper.dart';
import 'package:tapture/features/reference/data/reference_repository_impl.dart';
import 'package:tapture/features/reference/domain/reference_dataset.dart';
import 'package:tapture/features/reference/domain/reference_row.dart';

void main() {
  late AppDatabase db;
  late ReferenceRepositoryImpl repo;
  final DateTime t0 = DateTime.utc(2026, 9, 22, 8);
  late UuidV7Service ids;

  setUp(() {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
    repo = ReferenceRepositoryImpl(
      db: db,
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: ids,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('mapper round-trips a dataset and its rows', () async {
    final ReferenceDataset dataset = ReferenceDataset(
      id: 'ds-1',
      name: 'Suppliers',
      keyColumn: 'code',
      columns: const <String>['code', 'name', 'phone'],
      source: DatasetSource.csv,
      importedAt: t0,
      rowCount: 1,
      duplicatesAllowed: true,
      projectId: 'proj-1',
      sourceFile: 'suppliers.csv',
    );
    final ReferenceCompanion companion = ReferenceMapper.datasetToRow(dataset);
    final ReferenceDatasetRow written = _ok(
      await upsertReferenceDataset(
        db,
        row: companion,
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    final ReferenceDataset mapped = ReferenceMapper.datasetFromRow(written);
    expect(mapped.name, 'Suppliers');
    expect(mapped.columns, <String>['code', 'name', 'phone']);
    expect(mapped.source, DatasetSource.csv);
    expect(mapped.duplicatesAllowed, isTrue);
    expect(mapped.sourceFile, 'suppliers.csv');

    final ReferenceRow row = ReferenceRow(
      id: 'row-1',
      datasetId: written.id,
      key: 'S1',
      values: const <String, String>{
        'code': 'S1',
        'name': 'Acme',
        'phone': '123',
      },
      addedOnDevice: true,
    );
    final ReferenceLookupRow stored = _ok(
      await upsertReferenceRow(
        db,
        row: ReferenceMapper.rowToRow(row),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    final ReferenceRow back = ReferenceMapper.rowFromRow(stored);
    expect(back.key, 'S1');
    expect(back.addedOnDevice, isTrue);
    expect(back.values['phone'], '123');
    expect(back.values.containsKey('__tapture_addedOnDevice'), isFalse);
  });

  test('importDataset refuses silent duplicates', () async {
    final Result<ReferenceDataset> result = await repo.importDataset(
      dataset: ReferenceDataset(
        id: '',
        name: 'Parts',
        keyColumn: 'serial',
        columns: const <String>['serial', 'name'],
        source: DatasetSource.csv,
        importedAt: t0,
        rowCount: 2,
        projectId: 'proj-1',
        sourceFile: 'parts.csv',
      ),
      rows: const <ReferenceRow>[
        ReferenceRow(
          id: '',
          datasetId: '',
          key: 'A',
          values: <String, String>{'serial': 'A', 'name': 'One'},
        ),
        ReferenceRow(
          id: '',
          datasetId: '',
          key: 'A',
          values: <String, String>{'serial': 'A', 'name': 'Two'},
        ),
      ],
    );
    expect(_failure(result), isA<ValidationFailure>());
  });

  test('importDataset then pageRows and lookupByKey', () async {
    final ReferenceDataset saved = _ok(
      await repo.importDataset(
        dataset: ReferenceDataset(
          id: '',
          name: 'Parts',
          keyColumn: 'serial',
          columns: const <String>['serial', 'name'],
          source: DatasetSource.json,
          importedAt: t0,
          rowCount: 1,
          projectId: 'proj-1',
          sourceFile: 'parts.json',
        ),
        rows: const <ReferenceRow>[
          ReferenceRow(
            id: '',
            datasetId: '',
            key: 'SN-1',
            values: <String, String>{'serial': 'SN-1', 'name': 'Bolt'},
          ),
        ],
      ),
    );
    final List<ReferenceRow> page = _ok(
      await repo.pageRows(datasetId: saved.id, offset: 0, limit: 10),
    );
    expect(page, hasLength(1));
    expect(
      _ok(
        await repo.lookupByKey(datasetId: saved.id, keyValue: 'SN-1'),
      )?.values['name'],
      'Bolt',
    );
  });

  test(
    'accepted duplicate keys keep separate rows and stable IDs on reimport',
    () async {
      final ReferenceDataset draft = ReferenceDataset(
        id: '',
        name: 'Suppliers',
        keyColumn: 'code',
        columns: const <String>['code', 'name'],
        source: DatasetSource.csv,
        importedAt: t0,
        rowCount: 2,
        projectId: 'p',
        sourceFile: 'suppliers.csv',
        duplicatesAllowed: true,
      );
      final List<ReferenceRow> rows = <ReferenceRow>[
        for (final String name in <String>['North', 'South'])
          ReferenceRow(
            id: '',
            datasetId: '',
            key: 'ACME',
            values: <String, String>{'code': 'ACME', 'name': name},
          ),
      ];
      final ReferenceDataset saved = _ok(
        await repo.importDataset(dataset: draft, rows: rows),
      );
      final List<ReferenceRow> before = _ok(await repo.allRows(saved.id));
      expect(before, hasLength(2));
      expect(
        _ok(await repo.lookupByKey(datasetId: saved.id, keyValue: 'ACME')),
        isNull,
      );
      await repo.importDataset(dataset: draft, rows: rows);
      final List<ReferenceRow> after = _ok(await repo.allRows(saved.id));
      expect(
        after.map((ReferenceRow row) => row.id),
        before.map((ReferenceRow row) => row.id),
      );
      expect(
        after.map((ReferenceRow row) => row.values['name']).toSet(),
        <String>{'North', 'South'},
      );
    },
  );

  test(
    'ten thousand rows search and page in SQLite within the lookup budget',
    () async {
      final ReferenceDataset saved = _ok(
        await repo.importDataset(
          dataset: ReferenceDataset(
            id: '',
            name: 'Assets',
            keyColumn: 'code',
            columns: const <String>['code', 'description'],
            source: DatasetSource.csv,
            importedAt: t0,
            rowCount: 10000,
            projectId: 'p',
            sourceFile: 'assets.csv',
          ),
          rows: <ReferenceRow>[
            for (int i = 0; i < 10000; i++)
              ReferenceRow(
                id: '',
                datasetId: '',
                key: i.toString().padLeft(5, '0'),
                values: <String, String>{'description': 'Asset number $i'},
              ),
          ],
        ),
      );
      final Stopwatch timer = Stopwatch()..start();
      final List<ReferenceRow> found = _ok(
        await repo.pageRows(
          datasetId: saved.id,
          offset: 0,
          limit: 50,
          query: 'Asset number 9999',
        ),
      );
      timer.stop();
      expect(found.single.key, '09999');
      expect(timer.elapsedMilliseconds, lessThan(300));
      expect(
        _ok(await repo.pageRows(datasetId: saved.id, offset: 9990, limit: 50)),
        hasLength(10),
      );
      expect(
        _ok(await repo.pageRows(datasetId: saved.id, offset: 0, limit: 0)),
        isEmpty,
      );
    },
  );

  test('search folds non-ASCII case and pages across scan chunks', () async {
    final ReferenceDataset saved = _ok(
      await repo.importDataset(
        dataset: ReferenceDataset(
          id: '',
          name: 'Sites',
          keyColumn: 'code',
          columns: const <String>['code', 'site'],
          source: DatasetSource.csv,
          importedAt: t0,
          rowCount: 120,
          projectId: 'p',
          sourceFile: 'sites.csv',
        ),
        rows: <ReferenceRow>[
          for (int i = 0; i < 120; i++)
            ReferenceRow(
              id: '',
              datasetId: '',
              key: 'S${i.toString().padLeft(3, '0')}',
              values: <String, String>{
                'code': 'S${i.toString().padLeft(3, '0')}',
                'site': i.isEven ? 'ÉCOLE $i' : 'Depot $i',
              },
            ),
        ],
      ),
    );

    final List<ReferenceRow> first = _ok(
      await repo.pageRows(
        datasetId: saved.id,
        offset: 0,
        limit: 50,
        query: 'école',
      ),
    );
    final List<ReferenceRow> second = _ok(
      await repo.pageRows(
        datasetId: saved.id,
        offset: 50,
        limit: 50,
        query: 'École',
      ),
    );

    final List<String> evenKeys = <String>[
      for (int i = 100; i < 120; i += 2) 'S$i',
    ];
    expect(first, hasLength(50));
    expect(first.first.key, 'S000');
    expect(first.last.key, 'S098');
    expect(second.map((ReferenceRow row) => row.key), evenKeys);
  });

  test('search never matches the added-on-device marker', () async {
    final ReferenceDataset saved = _ok(
      await repo.importDataset(
        dataset: ReferenceDataset(
          id: '',
          name: 'Parts',
          keyColumn: 'serial',
          columns: const <String>['serial', 'name'],
          source: DatasetSource.device,
          importedAt: t0,
          rowCount: 1,
          projectId: 'p',
          sourceFile: 'device:parts',
        ),
        rows: const <ReferenceRow>[
          ReferenceRow(
            id: '',
            datasetId: '',
            key: 'Z1',
            values: <String, String>{'serial': 'Z1', 'name': 'Zed'},
            addedOnDevice: true,
          ),
        ],
      ),
    );

    final List<ReferenceRow> byMarker = _ok(
      await repo.pageRows(
        datasetId: saved.id,
        offset: 0,
        limit: 10,
        query: 'true',
      ),
    );
    final List<ReferenceRow> byName = _ok(
      await repo.pageRows(
        datasetId: saved.id,
        offset: 0,
        limit: 10,
        query: 'ZED',
      ),
    );

    expect(byMarker, isEmpty);
    expect(byName.single.addedOnDevice, isTrue);
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

Failure _failure<T>(Result<T> result) {
  return switch (result) {
    FailureResult<T>(:final Failure failure) => failure,
    Success<T>() => throw TestFailure('expected failure'),
  };
}
