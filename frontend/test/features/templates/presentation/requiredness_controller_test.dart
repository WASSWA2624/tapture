import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/data/template_repository_impl.dart';
import 'package:tapture/features/templates/domain/template_repository.dart';
import 'package:tapture/features/templates/presentation/field_add_sheet.dart';
import 'package:tapture/features/templates/presentation/requiredness_controller.dart';
import 'package:tapture/features/templates/presentation/template_list_screen.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../projects/fakes/fake_project_repository.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  test('REQUIRED blocks approval, never capture', () {
    expect(RequirednessController.blocksCapture, isFalse);
    expect(
      RequirednessController.incompleteSaveStatus,
      RecordStatus.needsReview,
    );
    expect(
      RequirednessController.marksOlderRecordIncomplete(
        capturedVersion: 1,
        currentVersion: 2,
      ),
      isFalse,
    );
  });

  test('a multi-field pass commits exactly one version', () async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final List<FieldDef> forty = <FieldDef>[
      for (int index = 0; index < 40; index++)
        FieldDef(
          fieldKey: 'field_$index',
          label: 'Field $index',
          type: FieldType.text,
          requiredness: Requiredness.recommended,
        ),
    ];
    final TemplateDef stored = _ok(
      await templates.save(aTemplate(name: 'Assets', fields: forty)),
    );
    expect(stored.version, 1);

    final ProviderContainer container = await _container(templates: templates);
    addTearDown(container.dispose);
    final RequirednessController controller = container.read(
      requirednessControllerProvider(stored.id).notifier,
    );
    for (int index = 0; index < 40; index++) {
      controller.set(
        'field_$index',
        index < 8 ? Requiredness.required : Requiredness.optional,
      );
    }
    controller.setHidden('field_9', true);

    final TemplateVersion version = await controller.commit();
    expect(version.number, 2);
    final TemplateDef after = _ok(await templates.byId(stored.id))!;
    expect(after.version, 2);
    expect(
      after.fields.where(
        (FieldDef field) => field.requiredness == Requiredness.required,
      ),
      hasLength(8),
    );
    expect(after.fields[9].hidden, isTrue);
    expect(FieldAddSheet.visibleKeys(after.fields), isNot(contains('field_9')));
  });

  test('an earlier record is not marked incomplete after a bump', () async {
    final AppDatabase db = AppDatabase.memory();
    addTearDown(db.close);
    final DateTime t0 = DateTime.utc(2026, 9, 20, 8);
    final FixedClock clock = FixedClock(t0);
    final TemplateRepositoryImpl templates = TemplateRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-test',
      ids: UuidV7Service.sequence(clock),
    );
    final TemplateDef stored = _ok(
      await templates.save(
        aTemplate(
          fields: const <FieldDef>[
            FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
            FieldDef(fieldKey: 'name', label: 'Name', type: FieldType.text),
          ],
        ),
      ),
    );
    await upsertRecord(
      db,
      row: RecordsCompanion(
        projectId: const Value<String>('project-1'),
        templateId: Value<String>(stored.id),
        status: const Value<String>('captured'),
        processingMode: const Value<String>('manual'),
        contextJson: const Value<String>('{}'),
        identityHash: const Value<String>('h1'),
        source: const Value<String>('capture'),
        capturedAt: Value<DateTime>(t0),
        capturedBy: const Value<String>('Ada'),
      ),
      clock: clock,
      deviceId: 'device-test',
      ids: UuidV7Service.sequence(clock),
    );

    final ProviderContainer container = await _container(templates: templates);
    addTearDown(container.dispose);
    final RequirednessController controller = container.read(
      requirednessControllerProvider(stored.id).notifier,
    );
    controller.set('serial', Requiredness.required);
    controller.set('name', Requiredness.required);
    final TemplateVersion version = await controller.commit();
    expect(version.number, stored.version + 1);
    expect((await db.select(db.records).get()).single.status, 'captured');
  });
}

Future<ProviderContainer> _container({
  required TemplateRepository templates,
}) async {
  final FakeProjectRepository projects = FakeProjectRepository();
  addTearDown(projects.dispose);
  _ok(await projects.create(aProject()));
  final SettingsStore store = SettingsStore.fake(
    stored: <String, Object?>{SettingKeys.openProjectId.name: 'project-1'},
  );
  final ProviderContainer container = ProviderContainer(
    retry: (int _, Object _) => null,
    overrides: <Override>[
      templateRepositoryProvider.overrideWith((Ref _) => templates),
      projectRepositoryProvider.overrideWith((Ref _) => projects),
      projectSettingsStoreProvider.overrideWith((Ref _) => store),
    ],
  );
  container.listen<AsyncValue<List<TemplateDef>>>(
    templateListProvider,
    (AsyncValue<List<TemplateDef>>? _, AsyncValue<List<TemplateDef>> _) {},
    fireImmediately: true,
  );
  await container.read(templateListProvider.future);
  return container;
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
