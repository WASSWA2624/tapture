import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/features/templates/presentation/field_add_sheet.dart';
import 'package:tapture/features/templates/presentation/required_columns_screen.dart';
import 'package:tapture/features/templates/presentation/template_create_screen.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../../support/pump_app.dart';
import '../../../support/screen_fonts.dart';
import '../fakes/fake_template_repository.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);

  for (final Size size in <Size>[
    const Size(390, 844),
    const Size(390, 300),
    const Size(800, 1280),
    const Size(800, 500),
    const Size(1200, 1600),
    const Size(1200, 800),
  ]) {
    for (final double scale in <double>[1, 2]) {
      testWidgets(
        'requirement saves preserve long field labels at $size x$scale',
        (WidgetTester tester) async {
          final FakeTemplateRepository store = await _seededStore();
          addTearDown(store.dispose);
          final SemanticsHandle semantics = tester.ensureSemantics();
          try {
            await _pump(
              tester,
              const RequiredColumnsScreen(templateId: 'template'),
              store,
              size: size,
              scale: scale,
            );
            final String label = store.stored.single.fields.single.label;
            expect(find.text(label), findsOneWidget);
            expect(
              find.bySemanticsLabel(Copy.requiredColumnRadios(label)),
              findsOneWidget,
            );
            final Finder required = find.text(Copy.fieldRequired);
            await tester.ensureVisible(required);
            await tester.pump();
            await tester.tap(required);
            await tester.pump();
            expect(
              store.stored.single.fields.single.requiredness,
              Requiredness.optional,
            );
            await tester.tap(_primary(Copy.save));
            await tester.pumpAndSettle();
            expect(
              store.stored.single.fields.single.requiredness,
              Requiredness.required,
            );
            expect(store.stored.single.fields.single.label, label);
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  testWidgets('advanced field inputs survive a failed grouped save', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository store = (await _seededStore())
      ..saveFailure = const StorageFailure(message: 'The device is full.');
    addTearDown(store.dispose);
    await _pump(tester, const FieldAddSheet(templateId: 'template'), store);
    expect(_field(Copy.fieldDefaultValue), findsNothing);
    await tester.enterText(_field(Copy.fieldLabel), 'Asset');
    final Finder advanced = find.byWidgetPredicate(
      (Widget widget) =>
          widget is AppSwitchTile && widget.title == Copy.fieldAdvanced,
    );
    await tester.ensureVisible(advanced);
    await tester.tap(advanced);
    await tester.pumpAndSettle();
    await tester.ensureVisible(_field(Copy.fieldDefaultValue));
    await tester.enterText(_field(Copy.fieldDefaultValue), 'Kept value');
    await tester.tap(_primary(Copy.save));
    await tester.pumpAndSettle();
    expect(store.count, 1);
    expect(
      tester.widget<AppTextField>(_field(Copy.fieldLabel)).controller.text,
      'Asset',
    );
    expect(
      tester
          .widget<AppTextField>(_field(Copy.fieldDefaultValue))
          .controller
          .text,
      'Kept value',
    );
    expect(find.text('The device is full.'), findsWidgets);
    expect(store.stored.single.fields, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('grouped blank template keeps drafts after a failed save', (
    WidgetTester tester,
  ) async {
    final FakeTemplateRepository store = (await _seededStore())
      ..saveFailure = const StorageFailure(message: 'The device is full.');
    addTearDown(store.dispose);
    await _pump(
      tester,
      const TemplateCreateScreen(projectId: 'project'),
      store,
    );
    await tester.enterText(_field(Copy.projectName), 'Equipment form');
    await tester.enterText(_field(Copy.fieldLabel), 'Serial');
    await tester.tap(_primary(Copy.templatesCreate));
    await tester.pumpAndSettle();
    expect(store.count, 1);
    expect(
      tester.widget<AppTextField>(_field(Copy.projectName)).controller.text,
      'Equipment form',
    );
    expect(
      tester.widget<AppTextField>(_field(Copy.fieldLabel)).controller.text,
      'Serial',
    );
    expect(find.text('The device is full.'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Finder _field(String label) => find.byWidgetPredicate(
  (Widget widget) => widget is AppTextField && widget.label == label,
);

Finder _primary(String label) => find.byWidgetPredicate(
  (Widget widget) => widget is AppPrimaryAction && widget.label == label,
);

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  FakeTemplateRepository store, {
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await pumpApp(
    tester,
    screen,
    useScreenFonts: true,
    overrides: <Override>[templateRepositoryProvider.overrideWithValue(store)],
  );
  await tester.pumpAndSettle();
}

Future<FakeTemplateRepository> _seededStore() async {
  final FakeTemplateRepository store = FakeTemplateRepository();
  await store.save(
    aTemplate(
      id: 'template',
      projectId: 'project',
      name: 'Equipment',
      fields: const <FieldDef>[
        FieldDef(
          fieldKey: 'serial',
          label: 'Serial number on the equipment manufacturer label',
          type: FieldType.text,
        ),
      ],
    ),
  );
  return store;
}
