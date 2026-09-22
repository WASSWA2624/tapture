import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/reference/domain/reference_dataset.dart';
import 'package:tapture/features/reference/domain/reference_repository.dart';

import '../../../support/fakes/fake_reference_repository.dart';

void main() {
  late FakeReferenceRepository repo;
  final DateTime importedAt = DateTime.utc(2026, 9, 22);

  setUp(() {
    repo = FakeReferenceRepository();
  });

  tearDown(() {
    repo.dispose();
  });

  test('save then byId round-trips a dataset', () async {
    final ReferenceDataset dataset = ReferenceDataset(
      id: 'ds-1',
      name: 'Assets',
      keyColumn: 'serial',
      columns: const <String>['serial', 'name'],
      source: DatasetSource.csv,
      importedAt: importedAt,
      rowCount: 3,
    );
    _ok(await repo.save(dataset));
    expect(_ok(await repo.byId('ds-1'))?.name, 'Assets');
    expect(await repo.watchAll().first, hasLength(1));
  });

  test('save without a name is a ValidationFailure', () async {
    final ReferenceDataset dataset = ReferenceDataset(
      id: 'ds-1',
      name: '',
      keyColumn: 'serial',
      columns: const <String>['serial'],
      source: DatasetSource.csv,
      importedAt: importedAt,
      rowCount: 0,
    );
    expect(_failure(await repo.save(dataset)), isA<ValidationFailure>());
  });

  test('delete with an empty reason is a StorageFailure', () async {
    _ok(
      await repo.save(
        ReferenceDataset(
          id: 'ds-1',
          name: 'Assets',
          keyColumn: 'serial',
          columns: const <String>['serial'],
          source: DatasetSource.csv,
          importedAt: importedAt,
          rowCount: 0,
        ),
      ),
    );
    expect(
      _failure(await repo.delete('ds-1', reason: '')),
      isA<StorageFailure>(),
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

Failure _failure<T>(Result<T> result) {
  return switch (result) {
    FailureResult<T>(:final Failure failure) => failure,
    Success<T>() => throw TestFailure('expected a failure'),
  };
}
