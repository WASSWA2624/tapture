import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';
import 'package:tapture/features/projects/presentation/record_edit_sheet.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';
import '../../templates/fakes/fake_template_repository.dart';
import '../fakes/fake_project_repository.dart';

const List<FieldDef> _fields = <FieldDef>[
  FieldDef(
    fieldKey: 'asset_tag',
    label: 'Asset tag',
    type: FieldType.text,
    sortOrder: 1,
  ),
  FieldDef(
    fieldKey: 'record_uid',
    label: 'Record id',
    type: FieldType.text,
    inputMode: InputMode.auto,
    sortOrder: 0,
  ),
  FieldDef(
    fieldKey: 'secret',
    label: 'Hidden field',
    type: FieldType.text,
    hidden: true,
    sortOrder: 2,
  ),
  FieldDef(
    fieldKey: 'condition_note',
    label: 'Condition note',
    type: FieldType.longText,
    sortOrder: 3,
  ),
  FieldDef(
    fieldKey: 'quantity',
    label: 'Quantity',
    type: FieldType.number,
    sortOrder: 4,
  ),
];

ProjectRecordRow _row({List<ProjectRecordFieldValue>? fields}) {
  return (
    id: 'r1',
    templateId: 'template-1',
    status: 'captured',
    photoCount: 1,
    thumb: null,
    fields: fields ?? const <ProjectRecordFieldValue>[],
  );
}

void main() {
  testWidgets('a raw save with no values lists its editable fields by label', (
    WidgetTester tester,
  ) async {
    await _pump(tester, row: _row());

    expect(find.text('Asset tag'), findsOneWidget);
    expect(find.text('Condition note'), findsOneWidget);
    expect(find.text('Quantity'), findsOneWidget);
    expect(find.text('Record id'), findsNothing);
    expect(find.text('Hidden field'), findsNothing);
    expect(find.text(Copy.save), findsOneWidget);
    final double tag = tester.getTopLeft(find.text('Asset tag')).dy;
    final double note = tester.getTopLeft(find.text('Condition note')).dy;
    expect(tag, lessThan(note));
  });

  testWidgets('save adds a new value and refines a stored one', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(
      tester,
      row: _row(
        fields: const <ProjectRecordFieldValue>[
          (fieldKey: 'quantity', raw: '2', refined: '', approved: ''),
        ],
      ),
    );

    await tester.enterText(_field('Asset tag'), 'A-9');
    await tester.enterText(_field('Quantity'), '3');
    await tester.tap(find.text(Copy.save));
    await tester.pumpAndSettle();

    expect(harness.projects.addedFields, <String, String>{
      'r1/asset_tag': 'A-9',
    });
    final List<ProjectRecordRow>? rows = await tester.runAsync(
      () => harness.projects
          .watchRecords('project-1', statuses: const <String>['captured'])
          .first,
    );
    final ProjectRecordRow saved = rows!.single;
    final ProjectRecordFieldValue quantity = saved.fields.firstWhere(
      (ProjectRecordFieldValue field) => field.fieldKey == 'quantity',
    );
    expect(quantity.raw, '2');
    expect(quantity.refined, '3');
    expect(find.byType(RecordEditSheet), findsNothing);
  });

  testWidgets('a failed save keeps the sheet open with what was typed', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _pump(tester, row: _row());
    harness.projects.fieldWriteFailure = const StorageFailure(
      message: 'The device storage is full.',
      recoveryAction: 'Free some space and try again.',
    );

    await tester.enterText(_field('Asset tag'), 'A-9');
    await tester.tap(find.text(Copy.save));
    await tester.pumpAndSettle();

    expect(find.byType(RecordEditSheet), findsOneWidget);
    expect(find.text('A-9'), findsOneWidget);
    expect(
      find.widgetWithText(AppBanner, 'The device storage is full.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a record with nothing to edit says so instead of a blank sheet',
    (WidgetTester tester) async {
      await _pump(
        tester,
        row: (
          id: 'r1',
          templateId: 'removed-template',
          status: 'captured',
          photoCount: 0,
          thumb: null,
          fields: const <ProjectRecordFieldValue>[],
        ),
      );

      expect(find.text(Copy.recordEditNoFieldsHeadline), findsOneWidget);
      expect(find.text(Copy.save), findsNothing);
    },
  );

  testWidgets('at 200 percent text Save stays on screen', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester, row: _row());

    expect(tester.takeException(), isNull);
    final Rect save = tester.getRect(find.byType(AppPrimaryAction));
    expect(save.bottom, lessThanOrEqualTo(886));
  });
}

Finder _field(String label) {
  return find.ancestor(of: find.text(label), matching: find.byType(TextField));
}

typedef _Harness = ({FakeProjectRepository projects});

Future<_Harness> _pump(
  WidgetTester tester, {
  required ProjectRecordRow row,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(393, 886);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final FakeProjectRepository projects = FakeProjectRepository()
    ..seedRecords('project-1', <ProjectRecordRow>[row]);
  final FakeTemplateRepository templates = FakeTemplateRepository();
  await templates.save(aTemplate(fields: _fields));
  addTearDown(projects.dispose);
  addTearDown(templates.dispose);
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        projectRepositoryProvider.overrideWith((Ref _) => projects),
        templateRepositoryProvider.overrideWith((Ref _) => templates),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (BuildContext context) {
                return AppButton(
                  label: 'Open',
                  onPressed: () => showRecordEditSheet(context, row),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return (projects: projects);
}
