import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/features/context/context.dart';
import 'package:tapture/features/context/presentation/context_hierarchy_screen.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/fakes/fake_context_repository.dart';
import '../../../support/fakes/fake_template_repository.dart';

void main() {
  testWidgets(
    'template context proposals in every theme and at 200 percent text',
    (WidgetTester tester) async {
      final FakeContextRepository contexts = FakeContextRepository();
      final FakeTemplateRepository templates = FakeTemplateRepository();
      addTearDown(contexts.dispose);
      addTearDown(templates.dispose);
      await templates.save(_template);

      final List<String> failures = <String>[];
      for (final AppThemeMode mode in AppThemeMode.values) {
        for (final double scale in <double>[1, 2]) {
          await _pump(
            tester,
            contexts: contexts,
            templates: templates,
            mode: mode,
            textScale: scale,
          );
          final String suffix = scale == 2 ? '_text2' : '';
          try {
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                'goldens/context_hierarchy${suffix}_${mode.name}.png',
              ),
            );
          } catch (error) {
            failures.add('${mode.name} scale $scale: $error');
          }
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
      if (failures.isNotEmpty) {
        fail('golden moved:\n${failures.join('\n')} (FE-TEST-02)');
      }
    },
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeContextRepository contexts,
  required FakeTemplateRepository templates,
  required AppThemeMode mode,
  required double textScale,
}) async {
  debugDisableShadows = true;
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(() {
    debugDisableShadows = false;
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.platformDispatcher.clearLocaleTestValue();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      retry: (int _, Object _) => null,
      overrides: <Override>[
        contextRepositoryProvider.overrideWith((Ref _) => contexts),
        templateRepositoryProvider.overrideWith((Ref _) => templates),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(
          brightness: mode == AppThemeMode.dark
              ? Brightness.dark
              : Brightness.light,
          outdoor: mode == AppThemeMode.outdoor,
        ),
        home: const ContextHierarchyScreen(projectId: 'project-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const TemplateDef _template = TemplateDef(
  id: 'template-1',
  templateKey: 'inspection',
  name: 'Inspection',
  version: 1,
  projectId: 'project-1',
  fields: <FieldDef>[
    FieldDef(
      fieldKey: 'district',
      label: 'District',
      type: FieldType.text,
      contextLevel: 1,
      sortOrder: 0,
    ),
    FieldDef(
      fieldKey: 'facility',
      label: 'Facility',
      type: FieldType.text,
      contextLevel: 2,
      sortOrder: 1,
    ),
    FieldDef(
      fieldKey: 'surveyor',
      label: 'Surveyor',
      type: FieldType.text,
      stickable: true,
      sortOrder: 2,
    ),
  ],
  identityFieldKeys: <String>[],
  rows: <TemplateRow>[],
);
