import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/reference/data/lookup_search.dart';
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

  Future<ReferenceDataset> importSuppliers(List<ReferenceRow> rows) async {
    return _ok(
      await repo.importDataset(
        dataset: aDataset(id: '', projectId: 'p', rowCount: rows.length),
        rows: rows,
      ),
    );
  }

  Future<LookupSearchResult> search(
    ReferenceDataset dataset,
    String query, {
    List<String> matchColumns = const <String>[],
    bool fuzzy = false,
    double threshold = 0.8,
  }) async {
    return _ok(
      await LookupSearch.find(
        repository: repo,
        binding: LookupBinding(
          datasetId: dataset.id,
          matchColumns: matchColumns,
          fillMapping: const <String, String>{},
          fuzzyEnabled: fuzzy,
          fuzzyThreshold: threshold,
        ),
        dataset: dataset,
        query: query,
      ),
    );
  }

  test('a blank query finds nothing and suggests nothing', () async {
    final ReferenceDataset dataset = await importSuppliers(supplierRows(3));

    final LookupSearchResult result = await search(dataset, '   ');

    expect(result.matches, isEmpty);
    expect(result.suggested, isFalse);
  });

  test('an exact key is found through the key index', () async {
    final ReferenceDataset dataset = await importSuppliers(supplierRows(3));

    final LookupSearchResult result = await search(
      dataset,
      ' ${supplierKey(1)} ',
    );

    expect(result.matches.single.key, supplierKey(1));
    expect(result.suggested, isFalse);
  });

  test('a key in another case or accent is found by its folded key', () async {
    final ReferenceDataset dataset = await importSuppliers(<ReferenceRow>[
      aReferenceRow(
        key: 'Café-1',
        values: <String, String>{
          'code': 'Café-1',
          'name': 'Corner cafe',
          'phone': '1',
        },
      ),
      aReferenceRow(key: 'B-2'),
    ]);

    final LookupSearchResult result = await search(dataset, 'CAFE-1');

    expect(result.matches.single.key, 'Café-1');
    expect(result.suggested, isFalse);
  });

  test('a match column is searched past the first page', () async {
    final ReferenceDataset dataset = await importSuppliers(supplierRows(120));

    final LookupSearchResult result = await search(
      dataset,
      'Supplier 110',
      matchColumns: const <String>['name'],
    );

    expect(result.matches.single.key, supplierKey(110));
    expect(result.suggested, isFalse);
  });

  test('match columns are tried in their configured order', () async {
    final ReferenceDataset dataset = await importSuppliers(<ReferenceRow>[
      aReferenceRow(
        key: 'A',
        values: <String, String>{'code': 'A', 'name': '555', 'phone': '1'},
      ),
      aReferenceRow(
        key: 'B',
        values: <String, String>{'code': 'B', 'name': 'Bee', 'phone': '555'},
      ),
    ]);

    final LookupSearchResult byPhone = await search(
      dataset,
      '555',
      matchColumns: const <String>['phone', 'name'],
    );
    final LookupSearchResult byName = await search(
      dataset,
      '555',
      matchColumns: const <String>['name', 'phone'],
    );

    expect(byPhone.matches.single.key, 'B');
    expect(byName.matches.single.key, 'A');
  });

  test('a near miss is only a suggestion, and only with fuzzy on', () async {
    final ReferenceDataset dataset = await importSuppliers(<ReferenceRow>[
      aReferenceRow(
        key: 'A',
        values: <String, String>{
          'code': 'A',
          'name': 'Acme Supplies',
          'phone': '1',
        },
      ),
      aReferenceRow(
        key: 'B',
        values: <String, String>{
          'code': 'B',
          'name': 'Beta Traders',
          'phone': '2',
        },
      ),
    ]);

    final LookupSearchResult strict = await search(
      dataset,
      'Acme Suplies',
      matchColumns: const <String>['name'],
    );
    final LookupSearchResult fuzzy = await search(
      dataset,
      'Acme Suplies',
      matchColumns: const <String>['name'],
      fuzzy: true,
      threshold: 0.6,
    );

    expect(strict.matches, isEmpty);
    expect(strict.suggested, isFalse);
    expect(fuzzy.matches.single.key, 'A');
    expect(fuzzy.suggested, isTrue);
  });

  test('a page that fails to load returns its failure', () async {
    final Result<LookupSearchResult> result = await LookupSearch.find(
      repository: BrokenPagesRepository(),
      binding: const LookupBinding(
        datasetId: 'ds',
        matchColumns: <String>['name'],
        fillMapping: <String, String>{},
      ),
      dataset: aDataset(),
      query: 'Acme',
    );

    expect(
      result,
      isA<FailureResult<LookupSearchResult>>().having(
        (FailureResult<LookupSearchResult> failed) => failed.failure,
        'failure',
        same(brokenPageFailure),
      ),
    );
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
