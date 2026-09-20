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
import 'package:tapture/features/templates/presentation/output_mapping_screen.dart';
import 'package:tapture/features/templates/presentation/template_list_screen.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../projects/fakes/fake_project_repository.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  test('duplicateOutputColumn rejects a second claim on the same letter', () {
    expect(duplicateOutputColumn(const <String?>['A', 'B']), isNull);
    expect(duplicateOutputColumn(const <String?>['A', ' a ']), 'a');
    expect(duplicateOutputColumn(const <String?>['', '  ', null, 'C']), isNull);
    expect(duplicateOutputColumn(const <String?>['Col', 'col']), 'col');
  });

  testWidgets('built templates auto-assign headers from labels', (
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
            FieldDef(fieldKey: 'name', label: 'Name', type: FieldType.text),
          ],
        ),
      ),
    );
    await _pump(tester, templates: templates, templateId: stored.id);
    await tester.pumpAndSettle();

    expect(find.text(Copy.outputMappingBuiltHint), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
      'Serial',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
      'Name',
    );
  });

  testWidgets('imported templates keep letters and do not invent them', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final TemplateDef stored = _ok(
      await templates.save(
        aTemplate(
          name: 'Assets',
          fields: const <FieldDef>[
            FieldDef(
              fieldKey: 'serial',
              label: 'Serial',
              type: FieldType.text,
              outputColumn: 'B',
            ),
            FieldDef(fieldKey: 'name', label: 'Name', type: FieldType.text),
          ],
        ).copyWith(source: 'imported'),
      ),
    );
    await _pump(tester, templates: templates, templateId: stored.id);
    await tester.pumpAndSettle();

    expect(find.text(Copy.outputMappingImportedHint), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
      'B',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('save refuses two fields that claim the same column', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final TemplateDef stored = _ok(
      await templates.save(
        aTemplate(
          name: 'Assets',
          fields: const <FieldDef>[
            FieldDef(
              fieldKey: 'serial',
              label: 'Serial',
              type: FieldType.text,
              outputColumn: 'A',
            ),
            FieldDef(
              fieldKey: 'name',
              label: 'Name',
              type: FieldType.text,
              outputColumn: 'B',
            ),
          ],
        ).copyWith(source: 'imported'),
      ),
    );
    await _pump(tester, templates: templates, templateId: stored.id);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'A');
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();

    expect(find.text(Copy.outputMappingDuplicate), findsOneWidget);
    final TemplateDef unchanged = _ok(await templates.byId(stored.id))!;
    expect(unchanged.fields[0].outputColumn, 'A');
    expect(unchanged.fields[1].outputColumn, 'B');
    expect(unchanged.version, stored.version);
  });

  testWidgets('an empty template renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      overrides: <Override>[
        templateListProvider.overrideWith(
          (Ref _) => Stream<List<TemplateDef>>.value(const <TemplateDef>[]),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.outputMappingEmptyHeadline), findsOneWidget);
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
              message: 'The output columns could not be read.',
              recoveryAction: 'Try again.',
            ),
          ),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('The output columns could not be read.'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  List<Override> overrides = const <Override>[],
  FakeTemplateRepository? templates,
  String templateId = 'template-1',
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
        ...overrides,
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: OutputMappingScreen(templateId: templateId),
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
