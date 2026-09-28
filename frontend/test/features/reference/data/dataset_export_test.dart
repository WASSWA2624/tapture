import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/download_service.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/reference/data/dataset_csv_import.dart';
import 'package:tapture/features/reference/data/dataset_export.dart';
import 'package:tapture/features/reference/data/dataset_json_import.dart';
import 'package:tapture/features/reference/data/reference_repository_impl.dart';
import 'package:tapture/features/reference/domain/domain.dart';

import '../reference_fixtures.dart';

void main() {
  late AppDatabase db;
  late ReferenceRepositoryImpl repo;
  late Directory documents;
  late StorageRoot storageRoot;
  late List<String> handedOut;

  setUp(() {
    db = AppDatabase.memory();
    repo = ReferenceRepositoryImpl(
      db: db,
      clock: FixedClock(fixtureImportedAt),
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(FixedClock(fixtureImportedAt)),
    );
    documents = Directory.systemTemp.createTempSync('tapture-dataset-export-');
    storageRoot = StorageRoot.fake(documentsDirectory: documents);
    handedOut = <String>[];
  });

  tearDown(() async {
    await db.close();
    documents.deleteSync(recursive: true);
  });

  /// 120 supplier rows, spanning three pages, and one row added on device.
  Future<ReferenceDataset> importSuppliers() async {
    final List<ReferenceRow> rows = <ReferenceRow>[
      ...supplierRows(120),
      aReferenceRow(key: 'Z-DEVICE', addedOnDevice: true),
    ];
    return _ok(
      await repo.importDataset(
        dataset: aDataset(id: '', projectId: 'p', rowCount: rows.length),
        rows: rows,
      ),
    );
  }

  Future<Result<String?>> exportDataset(
    ReferenceDataset dataset, {
    required bool json,
    ReferenceRepository? repository,
    CancellationToken? cancel,
  }) {
    return DatasetExport.download(
      dataset: dataset,
      repository: repository ?? repo,
      downloads: DownloadService.fake(
        onSaveStored: (String relativePath, String fileName, String mime) {
          handedOut.add(relativePath);
        },
      ),
      storageRoot: storageRoot,
      projectFolder: 'site-a',
      exportId: 'e1',
      json: json,
      cancel: cancel,
    );
  }

  Future<File> stored(String relativePath) async {
    final Directory root = _ok(await storageRoot.resolve());
    return File('${root.path}/$relativePath');
  }

  test('streams every page into a CSV that imports back whole', () async {
    final ReferenceDataset dataset = await importSuppliers();

    final Result<String?> result = await exportDataset(dataset, json: false);
    final File file = await stored(handedOut.single);
    final DatasetImportDraft back = _ok(
      DatasetCsvImport.parseText(
        file.readAsStringSync(),
        sourceFile: 'back.csv',
      ),
    );

    expect(_ok(result), 'downloads/site-a/Suppliers.csv');
    expect(handedOut.single, 'projects/site-a/exports/e1-Suppliers.csv');
    expect(back.dataset.columns, supplierColumns);
    expect(back.rows, hasLength(121));
    expect(back.rows.first.key, supplierKey(0));
    expect(back.rows[119].key, supplierKey(119));
    expect(back.rows[119].addedOnDevice, isFalse);
    expect(back.rows.last.key, 'Z-DEVICE');
    expect(back.rows.last.addedOnDevice, isTrue);
  });

  test('streams every page into one JSON array', () async {
    final ReferenceDataset dataset = await importSuppliers();

    final Result<String?> result = await exportDataset(dataset, json: true);
    final File file = await stored(handedOut.single);
    final DatasetImportDraft back = _ok(
      DatasetJsonImport.parseText(
        file.readAsStringSync(),
        sourceFile: 'back.json',
      ),
    );

    expect(_ok(result), 'downloads/site-a/Suppliers.json');
    expect(back.dataset.columns, supplierColumns);
    expect(back.rows, hasLength(121));
    expect(back.rows[60].values['name'], 'Supplier 60');
    expect(back.rows.last.addedOnDevice, isTrue);
  });

  test('a failed page fails the export and hands nothing out', () async {
    final Result<String?> result = await exportDataset(
      aDataset(),
      json: false,
      repository: BrokenPagesRepository(),
    );
    final File file = await stored('projects/site-a/exports/e1-Suppliers.csv');

    expect(
      result,
      isA<FailureResult<String?>>().having(
        (FailureResult<String?> failed) => failed.failure,
        'failure',
        same(brokenPageFailure),
      ),
    );
    expect(handedOut, isEmpty);
    expect(file.existsSync(), isFalse);
  });

  test('a cancelled export stops before it hands anything out', () async {
    final ReferenceDataset dataset = await importSuppliers();

    final Result<String?> result = await exportDataset(
      dataset,
      json: false,
      cancel: CancellationToken()..cancel(),
    );

    expect(
      result,
      isA<FailureResult<String?>>().having(
        (FailureResult<String?> failed) => failed.failure,
        'failure',
        isA<CancelledFailure>(),
      ),
    );
    expect(handedOut, isEmpty);
  });

  test('a name with nothing left to save under fails as a result', () async {
    final Result<String?> result = await exportDataset(
      aDataset(name: '???'),
      json: false,
    );

    expect(
      result,
      isA<FailureResult<String?>>().having(
        (FailureResult<String?> failed) => failed.failure,
        'failure',
        isA<ValidationFailure>(),
      ),
    );
    expect(handedOut, isEmpty);
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
