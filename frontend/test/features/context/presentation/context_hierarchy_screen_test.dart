import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/theme_controller.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
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

  for (final Size size in const <Size>[
    Size(360, 780),
    Size(780, 360),
    Size(800, 1000),
    Size(1280, 800),
  ]) {
    for (final double scale in <double>[1, 2]) {
      testWidgets(
        'saved levels at ${size.width.toInt()}x${size.height.toInt()} and '
        '${scale}x text are inset, with one handle and one menu a row',
        (WidgetTester tester) async {
          final FakeContextRepository contexts = FakeContextRepository();
          final FakeTemplateRepository templates = FakeTemplateRepository();
          addTearDown(contexts.dispose);
          addTearDown(templates.dispose);
          await templates.save(_template);
          await contexts.saveHierarchy('project-1', _levels);

          await _pump(
            tester,
            contexts: contexts,
            templates: templates,
            mode: AppThemeMode.light,
            textScale: scale,
            size: size,
          );

          expect(tester.takeException(), isNull);
          final Finder rows = find.byType(AppListTile);
          expect(rows, findsNWidgets(_levels.length));
          final double gutter = AppPage.gutter(tester.element(rows.first));
          expect(tester.getTopLeft(rows.first).dx, gutter);
          expect(tester.getTopRight(rows.first).dx, size.width - gutter);
          expect(
            find.descendant(of: rows, matching: find.byIcon(AppIcons.reorder)),
            findsNWidgets(_levels.length),
          );
          expect(find.byIcon(AppIcons.reorder), findsNWidgets(_levels.length));
          expect(
            find.descendant(of: rows, matching: find.byType(AppOverflowMenu)),
            findsNWidgets(_levels.length),
          );
          // The level names appear once: no second, plain list above.
          expect(find.text('District'), findsOneWidget);
        },
        // Desktop is where the list used to add a second handle.
        variant: TargetPlatformVariant.only(TargetPlatform.windows),
      );
    }
  }

  testWidgets('a level is removed from its menu', (WidgetTester tester) async {
    final FakeContextRepository contexts = FakeContextRepository();
    final FakeTemplateRepository templates = FakeTemplateRepository();
    addTearDown(contexts.dispose);
    addTearDown(templates.dispose);
    await templates.save(_template);
    await contexts.saveHierarchy('project-1', _levels);
    await _pump(
      tester,
      contexts: contexts,
      templates: templates,
      mode: AppThemeMode.light,
      textScale: 1,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('context-level-menu-facility')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(Copy.contextRemoveLevel));
    await tester.pumpAndSettle();

    expect(find.text('Facility'), findsNothing);
    final ContextState stored =
        ((await contexts.load('project-1')) as Success<ContextState>).value;
    expect(stored.levels.map((ContextLevel level) => level.fieldKey), <String>[
      'district',
    ]);
  });
}

const List<ContextLevel> _levels = <ContextLevel>[
  ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
  ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
];

Future<void> _pump(
  WidgetTester tester, {
  required FakeContextRepository contexts,
  required FakeTemplateRepository templates,
  required AppThemeMode mode,
  required double textScale,
  Size size = const Size(400, 800),
}) async {
  debugDisableShadows = true;
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
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
