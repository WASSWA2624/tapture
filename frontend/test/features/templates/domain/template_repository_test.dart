import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_template_repository.dart';

void main() {
  late FakeTemplateRepository repo;

  setUp(() {
    repo = FakeTemplateRepository();
  });

  tearDown(() {
    repo.dispose();
  });

  test('save then byId round-trips a template', () async {
    final TemplateDef stored = _ok(await repo.save(aTemplate(name: 'Meters')));
    expect(_ok(await repo.byId(stored.id))?.name, 'Meters');
  });

  test('watchByProject lists only that project', () async {
    _ok(await repo.save(aTemplate(projectId: 'p1')));
    _ok(
      await repo.save((
        id: 'template-2',
        projectId: 'p2',
        name: 'Other',
        version: 1,
      )),
    );
    expect(await repo.watchByProject('p1').first, hasLength(1));
    expect(await repo.watchByProject('p2').first, hasLength(1));
  });

  test('delete with an empty reason is a StorageFailure', () async {
    final TemplateDef stored = _ok(await repo.save(aTemplate()));
    final Result<void> deleted = await repo.delete(stored.id, reason: '');
    expect(_failure(deleted), isA<StorageFailure>());
    expect(_failure(deleted).message, contains('reason'));
    expect(_ok(await repo.byId(stored.id)), isNotNull);
  });

  test('delete of a missing id is a StorageFailure, byId is null', () async {
    expect(_ok(await repo.byId('missing')), isNull);
    expect(
      _failure(await repo.delete('missing', reason: 'gone')),
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
