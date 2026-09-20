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
import 'package:tapture/features/templates/presentation/required_columns_screen.dart';
import 'package:tapture/features/templates/presentation/requiredness_controller.dart';
import 'package:tapture/features/templates/presentation/template_list_screen.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../projects/fakes/fake_project_repository.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  testWidgets('the three-radio grid and hide toggle rewrite the draft', (
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
              group: 'identity',
            ),
            FieldDef(
              fieldKey: 'record_uid',
              label: 'Record uid',
              type: FieldType.text,
              group: 'record_admin',
              requiredness: Requiredness.required,
            ),
          ],
        ),
      ),
    );
    await _pump(tester, templates: templates, templateId: stored.id);
    await tester.pumpAndSettle();

    expect(find.text(Copy.requiredColumnGroup('identity')), findsOneWidget);
    expect(find.text(Copy.requiredColumnShowGroup), findsOneWidget);
    expect(find.text('Record uid, Required'), findsNothing);

    await tester.tap(
      find.text(Copy.requiredColumnCell('Serial', Copy.fieldRequired)),
    );
    await tester.pump();
    await tester.tap(find.text(Copy.requiredColumnHide));
    await tester.pump();

    expect(
      find.text(Copy.requiredColumnShipped(Copy.fieldOptional)),
      findsOneWidget,
    );

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(RequiredColumnsScreen)),
    );
    final RequirednessView view = container.read(
      requirednessControllerProvider(stored.id),
    );
    expect(view.fields.first.requiredness, Requiredness.required);
    expect(view.fields.first.hidden, isTrue);
  });

  testWidgets('the radio grid stays usable at 200 percent text', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
              group: 'identity',
            ),
          ],
        ),
      ),
    );
    await _pump(tester, templates: templates, templateId: stored.id);
    await tester.pumpAndSettle();

    expect(
      find.text(Copy.requiredColumnCell('Serial', Copy.fieldRequired)),
      findsOneWidget,
    );
    expect(find.text(Copy.requiredColumnHide), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(find.text(Copy.requiredColumnsEmptyHeadline), findsOneWidget);
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
              message: 'The columns could not be read.',
              recoveryAction: 'Try again.',
            ),
          ),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('The columns could not be read.'), findsOneWidget);
  });

  testWidgets('a failed save renders on the list', (WidgetTester tester) async {
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
              group: 'identity',
            ),
          ],
        ),
      ),
    );
    templates.saveFailure = const StorageFailure(
      message: 'The columns could not be saved on this device.',
      recoveryAction: 'Free space, then try again.',
    );
    await _pump(tester, templates: templates, templateId: stored.id);
    await tester.pumpAndSettle();

    await tester.tap(
      find.text(Copy.requiredColumnCell('Serial', Copy.fieldRequired)),
    );
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();

    expect(
      find.text('The columns could not be saved on this device.'),
      findsOneWidget,
    );
    expect(
      _ok(await templates.byId(stored.id))!.fields.single.requiredness,
      Requiredness.optional,
    );
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
        home: RequiredColumnsScreen(templateId: templateId),
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
