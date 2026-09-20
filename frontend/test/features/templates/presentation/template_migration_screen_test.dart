import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/templates/presentation/template_list_screen.dart';
import 'package:tapture/features/templates/presentation/template_migration_screen.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../projects/fakes/fake_project_repository.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  testWidgets('added, removed and retyped fields list the affected counts', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final TemplateDef first = _ok(
      await templates.save(
        aTemplate(
          name: 'Assets',
          fields: const <FieldDef>[
            FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
            FieldDef(fieldKey: 'extra', label: 'Extra', type: FieldType.number),
          ],
        ),
      ),
    );
    final TemplateDef stored = _ok(
      await templates.save(
        first.copyWith(
          fields: const <FieldDef>[
            FieldDef(
              fieldKey: 'serial',
              label: 'Serial',
              type: FieldType.number,
            ),
            FieldDef(fieldKey: 'name', label: 'Name', type: FieldType.text),
          ],
        ),
      ),
    );
    await _pump(
      tester,
      templates: templates,
      templateId: stored.id,
      records: const <CapturedTemplateRecord>[
        (
          id: 'record-1',
          templateVersion: 1,
          fields: <String, String>{'serial': 'A-1', 'extra': '3'},
          retired: <String>{},
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text(Copy.templateMigrationExplain), findsOneWidget);
    expect(find.text(Copy.templateMigrationAdded), findsOneWidget);
    expect(find.text(Copy.templateMigrationRemoved), findsOneWidget);
    expect(find.text(Copy.templateMigrationRetyped), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Extra'), findsOneWidget);
    expect(find.text('Serial'), findsOneWidget);
    expect(find.text(Copy.recordsCount(1)), findsNWidgets(3));
  });

  testWidgets('an empty queue renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final TemplateDef stored = _ok(
      await templates.save(
        aTemplate(
          name: 'Assets',
          fields: const <FieldDef>[
            FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
          ],
        ),
      ),
    );
    await _pump(tester, templates: templates, templateId: stored.id);
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.templateMigrationEmptyHeadline), findsOneWidget);
  });

  testWidgets('a failed load renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        templateListProvider.overrideWith(
          (Ref _) => Stream<List<TemplateDef>>.error(
            const StorageFailure(
              message: 'The migration list could not be read.',
              recoveryAction: 'Try again.',
            ),
          ),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('The migration list could not be read.'), findsOneWidget);
  });

  testWidgets('a failed move leaves records on the captured version', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final TemplateDef first = _ok(
      await templates.save(
        aTemplate(
          name: 'Assets',
          fields: const <FieldDef>[
            FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
          ],
        ),
      ),
    );
    final TemplateDef stored = _ok(
      await templates.save(
        first.copyWith(
          fields: const <FieldDef>[
            FieldDef(
              fieldKey: 'serial',
              label: 'Serial',
              type: FieldType.number,
            ),
          ],
        ),
      ),
    );
    List<CapturedTemplateRecord>? written;
    await _pump(
      tester,
      templates: templates,
      templateId: stored.id,
      records: const <CapturedTemplateRecord>[
        (
          id: 'record-1',
          templateVersion: 1,
          fields: <String, String>{'serial': 'A-1'},
          retired: <String>{},
        ),
      ],
      persist: (List<CapturedTemplateRecord> next) async {
        written = next;
        return const FailureResult<void>(
          StorageFailure(
            message: 'The records could not be moved.',
            recoveryAction: 'Free space, then try again.',
          ),
        );
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pumpAndSettle();
    expect(find.text(Copy.templateMigrationConfirmTitle), findsOneWidget);
    await tester.tap(find.text(Copy.templateMigrationAction).last);
    await tester.pumpAndSettle();

    expect(find.text('The records could not be moved.'), findsOneWidget);
    expect(written, isNotNull);
    expect(written!.single.templateVersion, stored.version);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  List<Override> overrides = const <Override>[],
  FakeTemplateRepository? templates,
  String templateId = 'template-1',
  List<CapturedTemplateRecord> records = const <CapturedTemplateRecord>[],
  Future<Result<void>> Function(List<CapturedTemplateRecord> next)? persist,
}) async {
  final FakeProjectRepository projects = FakeProjectRepository();
  addTearDown(projects.dispose);
  _ok(await projects.create(aProject()));
  final SettingsStore store = SettingsStore.fake(
    stored: <String, Object?>{SettingKeys.openProjectId.name: 'project-1'},
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        projectRepositoryProvider.overrideWith((Ref _) => projects),
        projectSettingsStoreProvider.overrideWith((Ref _) => store),
        if (templates != null)
          templateRepositoryProvider.overrideWith((Ref _) => templates),
        templateCapturedRecordsProvider.overrideWithValue(records),
        if (persist != null)
          templateMigrationPersistProvider.overrideWithValue(persist),
        ...overrides,
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: TemplateMigrationScreen(templateId: templateId),
      ),
    ),
  );
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
