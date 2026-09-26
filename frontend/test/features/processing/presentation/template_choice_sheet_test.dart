import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/processing/presentation/template_choice_sheet.dart';

void main() {
  Future<List<({String? template, bool pin})>> pump(
    WidgetTester tester,
    List<String> options, {
    Failure? failure,
  }) async {
    final List<({String? template, bool pin})> chosen =
        <({String? template, bool pin})>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: Scaffold(
            body: TemplateChoiceSheet(
              options: options,
              failure: failure,
              onChosen: (String? template, bool pin) =>
                  chosen.add((template: template, pin: pin)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return chosen;
  }

  testWidgets('no shortlist shows the empty state', (
    WidgetTester tester,
  ) async {
    await pump(tester, const <String>[]);

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text(Copy.templateChoiceEmptyHeadline), findsOneWidget);
  });

  testWidgets('a shortlist that cannot load shows the failure', (
    WidgetTester tester,
  ) async {
    await pump(tester, const <String>[
      'Pump',
    ], failure: const StorageFailure(message: 'Could not load templates.'));

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('Pump'), findsNothing);
  });

  testWidgets('two choices leave room for something else', (
    WidgetTester tester,
  ) async {
    await pump(tester, const <String>['Pump', 'Motor']);

    expect(find.byType(AppButton), findsNWidgets(3));
    expect(find.text(Copy.templateChoiceOther), findsOneWidget);
    expect(find.text(Copy.templateChoicePin), findsOneWidget);
  });

  testWidgets('at most three large buttons are offered', (
    WidgetTester tester,
  ) async {
    await pump(tester, const <String>['Pump', 'Motor', 'Boiler', 'Fan']);

    expect(find.byType(AppButton), findsNWidgets(3));
    expect(find.text('Fan'), findsNothing);
    expect(find.text(Copy.templateChoiceOther), findsNothing);
  });

  testWidgets('a choice is pinned to the place unless the box is cleared', (
    WidgetTester tester,
  ) async {
    final List<({String? template, bool pin})> chosen = await pump(
      tester,
      const <String>['Pump', 'Motor'],
    );

    await tester.tap(find.text('Pump'));
    await tester.tap(find.text(Copy.templateChoicePin));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Motor'));
    await tester.tap(find.text(Copy.templateChoiceOther));

    expect(chosen, <({String? template, bool pin})>[
      (template: 'Pump', pin: true),
      (template: 'Motor', pin: false),
      (template: null, pin: false),
    ]);
  });
}
