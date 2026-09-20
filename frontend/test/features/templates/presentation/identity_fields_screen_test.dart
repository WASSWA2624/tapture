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
import 'package:tapture/features/templates/presentation/identity_fields_screen.dart';
import 'package:tapture/features/templates/presentation/template_list_screen.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../projects/fakes/fake_project_repository.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  testWidgets('a shipped identity set is shown, not invented', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(templates.dispose);
    final TemplateDef stored = _ok(
      await templates.save(
        aTemplate(
          name: 'Assets',
          identityFieldKeys: const <String>['serial'],
          fields: const <FieldDef>[
            FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
            FieldDef(fieldKey: 'name', label: 'Name', type: FieldType.text),
          ],
        ),
      ),
    );
    await _pump(tester, templates: templates, templateId: stored.id);
    await tester.pumpAndSettle();

    expect(find.text(Copy.identityFieldsExplain), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox).at(0)).value, isTrue);
    expect(tester.widget<Checkbox>(find.byType(Checkbox).at(1)).value, isFalse);

    await tester.tap(find.text('Name'));
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pumpAndSettle();

    final TemplateDef saved = _ok(await templates.byId(stored.id))!;
    expect(saved.identityFieldKeys, <String>['serial', 'name']);
    expect(saved.fields[0].identity, isTrue);
    expect(saved.fields[1].identity, isTrue);
    expect(saved.version, stored.version + 1);
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
    expect(find.text(Copy.identityFieldsEmptyHeadline), findsOneWidget);
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
              message: 'The identity fields could not be read.',
              recoveryAction: 'Try again.',
            ),
          ),
        ),
      ],
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('The identity fields could not be read.'), findsOneWidget);
  });

  testWidgets('a failed save renders on the list', (WidgetTester tester) async {
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
    templates.saveFailure = const StorageFailure(
      message: 'The identity fields could not be saved on this device.',
      recoveryAction: 'Free space, then try again.',
    );
    await _pump(tester, templates: templates, templateId: stored.id);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Serial'));
    await tester.pump();
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();

    expect(
      find.text('The identity fields could not be saved on this device.'),
      findsOneWidget,
    );
    expect(_ok(await templates.byId(stored.id))!.identityFieldKeys, isEmpty);
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
        home: IdentityFieldsScreen(templateId: templateId),
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
