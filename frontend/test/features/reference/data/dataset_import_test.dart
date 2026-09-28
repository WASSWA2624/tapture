import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/reference/data/dataset_csv_import.dart';
import 'package:tapture/features/reference/data/dataset_import.dart';
import 'package:tapture/features/reference/data/reference_repository_impl.dart';
import 'package:tapture/features/reference/domain/domain.dart';

import '../reference_fixtures.dart';

void main() {
  late AppDatabase db;
  late ReferenceRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.memory();
    repo = ReferenceRepositoryImpl(
      db: db,
      clock: FixedClock(fixtureImportedAt),
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(FixedClock(fixtureImportedAt)),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('refuses a document that is not a CSV, JSON or XLSX table', () async {
    final Result<DatasetImportDraft> result = await DatasetImport.read(
      _bytesOf('code,name\nA,One\n', 'table.txt'),
    );

    expect(_failure(result), isA<ValidationFailure>());
  });

  test('refuses an empty document', () async {
    final Result<DatasetImportDraft> result = await DatasetImport.read(
      PickedBytes(Uint8List(0), 'empty.csv'),
    );

    expect(_failure(result), isA<ValidationFailure>());
  });

  test('refuses a file over the size limit without reading it', () async {
    final Result<DatasetImportDraft> result = await DatasetImport.read(
      PickedFile(
        File('never-read.csv'),
        'huge.csv',
        AppConstants.imports.spreadsheetMaxBytes + 1,
      ),
    );

    expect(_failure(result), isA<ValidationFailure>());
  });

  test('reads browser CSV bytes into a draft named after the file', () async {
    final DatasetImportDraft draft = _ok(
      await DatasetImport.read(
        _bytesOf('﻿code,name\nA,One\nB,Two\n', 'Suppliers.CSV'),
        projectId: 'p',
      ),
    );

    expect(draft.dataset.name, 'Suppliers');
    expect(draft.dataset.source, DatasetSource.csv);
    expect(draft.dataset.projectId, 'p');
    expect(draft.dataset.columns, <String>['code', 'name']);
    expect(draft.rows.map((ReferenceRow row) => row.key), <String>['A', 'B']);
  });

  test('reads browser JSON bytes into a draft', () async {
    final PickedBytes document = _bytesOf(
      '[{"code":"A","name":"One"},{"code":"B","name":"Two"}]',
      'parts.json',
    );

    final DatasetImportDraft draft = _ok(await DatasetImport.read(document));

    expect(draft.dataset.name, 'parts');
    expect(draft.dataset.source, DatasetSource.json);
    expect(draft.dataset.columns, <String>['code', 'name']);
    expect(draft.rows.last.values['name'], 'Two');
  });

  test('refuses bytes that are not UTF-8 text or that carry NUL', () async {
    final List<PickedBytes> unreadable = <PickedBytes>[
      PickedBytes(Uint8List.fromList(<int>[0xFF, 0xFE, 0x41]), 'latin.csv'),
      _bytesOf('code,name\nA\u0000,One\n', 'nul.csv'),
    ];

    for (final PickedBytes document in unreadable) {
      expect(
        _failure(await DatasetImport.read(document)),
        isA<ValidationFailure>().having(
          (ValidationFailure failure) => failure.message,
          'message',
          'That table could not be read as text.',
        ),
        reason: document.name,
      );
    }
  });

  test('a CSV file on this device imports into the database', () async {
    final Directory temp = Directory.systemTemp.createTempSync(
      'tapture-dataset-import-',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    final File file = File('${temp.path}/suppliers.csv')
      ..writeAsStringSync('code,name,phone\nK1,Acme,1\nK2,Beta,2\n');

    final DatasetImportDraft draft = _ok(
      await DatasetImport.read(
        PickedFile(file, 'suppliers.csv', file.lengthSync()),
        projectId: 'p',
      ),
    );
    final ReferenceDataset saved = _ok(
      await repo.importDataset(dataset: draft.dataset, rows: draft.rows),
    );
    final List<ReferenceRow> rows = _ok(
      await repo.pageRows(datasetId: saved.id, offset: 0, limit: 10),
    );
    final ReferenceRow? second = _ok(
      await repo.lookupByKey(datasetId: saved.id, keyValue: 'K2'),
    );

    final List<String?> names = <String?>[
      for (final ReferenceRow row in rows) row.values['name'],
    ];
    expect(draft.dataset.name, 'suppliers');
    expect(names, <String>['Acme', 'Beta']);
    expect(second?.values['phone'], '2');
  });
}

PickedBytes _bytesOf(String text, String name) {
  return PickedBytes(Uint8List.fromList(utf8.encode(text)), name);
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
    Success<T>() => throw TestFailure('expected a failure'),
  };
}
