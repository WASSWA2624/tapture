import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/features/processing/presentation/record_processing_scope.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/screen_fonts.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);

  const fields = <FieldDef>[
    FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
    FieldDef(fieldKey: 'voltage', label: 'Voltage', type: FieldType.number),
    FieldDef(
      fieldKey: 'manual',
      label: 'Operator only',
      type: FieldType.text,
      inputMode: InputMode.manualOnly,
    ),
  ];

  testWidgets('all, selected and single field scopes keep stable keys', (
    tester,
  ) async {
    List<String>? scope;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: Scaffold(
            body: RecordProcessingScope(
              recordId: 'record-1',
              fields: fields,
              onSelected: (List<String> selected) => scope = selected,
            ),
          ),
        ),
      ),
    );
    final Finder selected = find.byKey(
      const ValueKey<String>('processing-selected-fields'),
    );
    expect(tester.widget<AppButton>(selected).onPressed, isNull);
    expect(find.text('Operator only'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey<String>('processing-scope-voltage')),
    );
    await tester.pumpAndSettle();
    await tester.tap(selected);
    expect(scope, <String>['voltage']);
    await tester.tap(
      find.byKey(const ValueKey<String>('processing-scope-serial')),
    );
    await tester.pumpAndSettle();
    await tester.tap(selected);
    expect(scope, <String>['serial', 'voltage']);
    await tester.tap(
      find.byKey(const ValueKey<String>('processing-all-fields')),
    );
    expect(scope, isEmpty);
  });

  testWidgets(
    'field scope controls remain usable with large text and short windows',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final Size size in <Size>[
        const Size(400, 800),
        const Size(800, 400),
        const Size(1200, 700),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: buildTheme(brightness: Brightness.light),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: RecordProcessingScope(
                    recordId: 'record-1',
                    fields: fields,
                    onSelected: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.byKey(const ValueKey<String>('processing-selected-fields')),
        );
        expect(
          find.byKey(const ValueKey<String>('processing-selected-fields')),
          findsOneWidget,
        );
      }
    },
  );
}
