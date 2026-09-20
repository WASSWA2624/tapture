import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';

import '../../support/factories.dart';

/// Save, watch and delete contract shared by the Drift implementation
/// and the in-memory fake (FE-STATE-10).
void runTemplateRepositoryContract(TemplateRepository Function() repository) {
  test('save then byId round-trips a template', () async {
    final TemplateRepository repo = repository();
    final TemplateDef stored = _ok(await repo.save(aTemplate(name: 'Meters')));
    expect(_ok(await repo.byId(stored.id))?.name, 'Meters');
  });

  test('watchByProject lists only that project', () async {
    final TemplateRepository repo = repository();
    _ok(await repo.save(aTemplate(projectId: 'p1')));
    _ok(
      await repo.save(
        aTemplate(id: 'template-2', projectId: 'p2', name: 'Other'),
      ),
    );
    expect(await repo.watchByProject('p1').first, hasLength(1));
    expect(await repo.watchByProject('p2').first, hasLength(1));
  });

  test('delete with an empty reason is a StorageFailure', () async {
    final TemplateRepository repo = repository();
    final TemplateDef stored = _ok(await repo.save(aTemplate()));
    final Result<void> deleted = await repo.delete(stored.id, reason: '');
    expect(_failure(deleted), isA<StorageFailure>());
    expect(_failure(deleted).message, contains('reason'));
    expect(_ok(await repo.byId(stored.id)), isNotNull);
  });

  test('delete of a missing id is a StorageFailure, byId is null', () async {
    final TemplateRepository repo = repository();
    expect(_ok(await repo.byId('missing')), isNull);
    expect(
      _failure(await repo.delete('missing', reason: 'gone')),
      isA<StorageFailure>(),
    );
  });

  test(
    'an empty name is a ValidationFailure, not a thrown Exception',
    () async {
      final TemplateRepository repo = repository();
      final Result<TemplateDef> saved = await repo.save(aTemplate(name: ''));
      expect(_failure(saved), isA<ValidationFailure>());
      expect(_failure(saved).message, isNotEmpty);
      expect(_failure(saved).recoveryAction, isNotEmpty);
    },
  );

  test('watchByProject emits after save', () async {
    final TemplateRepository repo = repository();
    final Future<List<TemplateDef>> next = repo
        .watchByProject('project-1')
        .skip(1)
        .first;
    _ok(await repo.save(aTemplate(name: 'Beta')));
    expect((await next).single.name, 'Beta');
  });

  test('delete hides the template from byId and watch', () async {
    final TemplateRepository repo = repository();
    final TemplateDef stored = _ok(await repo.save(aTemplate(name: 'Meters')));
    _ok(await repo.delete(stored.id, reason: 'retired'));
    expect(_ok(await repo.byId(stored.id)), isNull);
    expect(await repo.watchByProject('project-1').first, isEmpty);
  });

  test('a second save bumps version and keeps fields and rows', () async {
    final TemplateRepository repo = repository();
    const FieldDef field = FieldDef(
      fieldKey: 'serial',
      label: 'Serial',
      type: FieldType.text,
      requiredness: Requiredness.recommended,
    );
    const TemplateRow row = TemplateRow(
      identifier: 'm-1',
      label: 'Meter 1',
      outputRowNumber: 4,
      aliases: <String>['M1'],
    );
    final TemplateDef first = _ok(
      await repo.save(
        aTemplate(
          fields: <FieldDef>[field],
          identityFieldKeys: <String>['serial'],
          rows: <TemplateRow>[row],
        ),
      ),
    );
    expect(first.version, 1);
    final TemplateDef second = _ok(
      await repo.save(first.copyWith(name: 'Meters v2')),
    );
    expect(second.version, 2);
    expect(second.name, 'Meters v2');
    expect(second.fields.single.fieldKey, 'serial');
    expect(second.fields.single.requiredness, Requiredness.recommended);
    expect(second.identityFieldKeys, <String>['serial']);
    expect(second.rows.single.aliases, <String>['M1']);
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
