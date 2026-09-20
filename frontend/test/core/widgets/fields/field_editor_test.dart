import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_date_field.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/field_editor.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/features/templates/domain/field_def.dart';
import 'package:tapture/features/templates/presentation/field_editor_bindings.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  testWidgets('a text edit writes MANUAL, verified and the previous value', (
    WidgetTester tester,
  ) async {
    FieldValue latest = const FieldValue(
      fieldKey: 'serial',
      value: 'ABB',
      source: ValueSource.ocr,
    );
    await _pump(
      tester,
      field: const FieldDef(
        fieldKey: 'serial',
        label: 'Serial',
        type: FieldType.text,
      ),
      value: latest,
      onChanged: (FieldValue next) => latest = next,
    );

    expect(find.byType(AppTextField), meetsTapTarget());
    expect(find.byType(AppTextField), hasSemanticLabel('Serial'));

    await tester.enterText(find.byType(TextField), 'ABB-1');
    await tester.pump();

    expect(latest.source, ValueSource.manual);
    expect(latest.verified, isTrue);
    expect(latest.value, 'ABB-1');
    expect(latest.audit, hasLength(1));
    expect(latest.audit.single.previousValue, 'ABB');
    expect(latest.audit.single.newValue, 'ABB-1');
  });

  testWidgets('a choice edit writes MANUAL and the previous value', (
    WidgetTester tester,
  ) async {
    FieldValue latest = const FieldValue(
      fieldKey: 'grade',
      value: 'a',
      source: ValueSource.lookup,
    );
    await _pump(
      tester,
      field: const FieldDef(
        fieldKey: 'grade',
        label: 'Grade',
        type: FieldType.choice,
        options: <Object>['a', 'b', 'c'],
      ),
      value: latest,
      onChanged: (FieldValue next) => latest = next,
    );

    expect(find.byType(AppChoiceField<String>), meetsTapTarget());
    expect(find.byType(AppChoiceField<String>), hasSemanticLabel('Grade'));

    await tester.tap(find.text('b'));
    await tester.pump();

    expect(latest.source, ValueSource.manual);
    expect(latest.verified, isTrue);
    expect(latest.value, 'b');
    expect(latest.audit.single.previousValue, 'a');
    expect(latest.audit.single.newValue, 'b');
  });

  testWidgets('a date edit writes MANUAL and the previous value', (
    WidgetTester tester,
  ) async {
    final DateTime stamp = DateTime.utc(2026, 9, 17);
    FieldValue latest = FieldValue(
      fieldKey: 'when',
      value: stamp,
      source: ValueSource.auto,
    );
    await _pump(
      tester,
      field: const FieldDef(
        fieldKey: 'when',
        label: 'When',
        type: FieldType.date,
      ),
      value: latest,
      onChanged: (FieldValue next) => latest = next,
    );

    expect(find.byType(AppDateField), meetsTapTarget());
    expect(find.byType(AppDateField), hasSemanticLabel('When'));

    await tester.tap(find.byTooltip('Clear When'));
    await tester.pump();

    expect(latest.source, ValueSource.manual);
    expect(latest.verified, isTrue);
    expect(latest.value, isNull);
    expect(latest.audit.single.previousValue, stamp);
    expect(latest.audit.single.newValue, isNull);
  });

  testWidgets('a change back to the original value still writes an audit row', (
    WidgetTester tester,
  ) async {
    FieldValue latest = const FieldValue(
      fieldKey: 'serial',
      value: 'ABB',
      source: ValueSource.ocr,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          fieldEditorBindingsProvider.overrideWithValue(
            templateFieldEditorBindings,
          ),
        ],
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext _, StateSetter setState) {
                return FieldEditor(
                  field: fieldEditorField(
                    const FieldDef(
                      fieldKey: 'serial',
                      label: 'Serial',
                      type: FieldType.text,
                    ),
                  ),
                  value: latest,
                  onChanged: (FieldValue next) {
                    setState(() => latest = next);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'NEW');
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'ABB');
    await tester.pump();

    expect(latest.source, ValueSource.manual);
    expect(latest.value, 'ABB');
    expect(latest.audit, hasLength(2));
    expect(latest.audit.first.previousValue, 'ABB');
    expect(latest.audit.first.newValue, 'NEW');
    expect(latest.audit.last.previousValue, 'NEW');
    expect(latest.audit.last.newValue, 'ABB');
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required FieldDef field,
  required FieldValue value,
  required ValueChanged<FieldValue> onChanged,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        fieldEditorBindingsProvider.overrideWithValue(
          templateFieldEditorBindings,
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(
          body: FieldEditor(
            field: fieldEditorField(field),
            value: value,
            onChanged: onChanged,
          ),
        ),
      ),
    ),
  );
}
