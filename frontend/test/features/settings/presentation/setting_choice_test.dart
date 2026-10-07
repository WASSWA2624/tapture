import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/features/settings/presentation/setting_choice.dart';

void main() {
  testWidgets('alwaysSheet searches without changing on cancel or current choice', (WidgetTester tester) async {
    final List<String> picked = <String>[];
    await _pump(tester, value: 'a', onChanged: picked.add, alwaysSheet: true);
    expect(find.text('Bravo'), findsNothing);
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alpha').last);
    await tester.pumpAndSettle();
    expect(picked, isEmpty);
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'brav');
    await tester.pumpAndSettle();
    expect(find.text('Bravo'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(picked, isEmpty);
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bravo'));
    await tester.pumpAndSettle();
    expect(picked, <String>['b']);
  });
  testWidgets('shows its name, every choice and what it changes', (
    WidgetTester tester,
  ) async {
    await _pump(tester, value: 'a', onChanged: (_) {});

    expect(find.byType(AppChoiceField<String>), findsOneWidget);
    expect(find.text('Mode'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Bravo'), findsOneWidget);
    expect(find.text('Used from the next session.'), findsOneWidget);
  });

  testWidgets('picking another choice reports it; the current one does not', (
    WidgetTester tester,
  ) async {
    final List<String> picked = <String>[];
    await _pump(tester, value: 'a', onChanged: picked.add);

    await tester.tap(find.text('Alpha'));
    await tester.pump();
    expect(picked, isEmpty);

    await tester.tap(find.text('Bravo'));
    await tester.pump();
    expect(picked, <String>['b']);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required String value,
  required ValueChanged<String> onChanged,
  bool alwaysSheet = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: Scaffold(
        body: SettingChoice<String>(
          alwaysSheet: alwaysSheet,
          label: 'Mode',
          effect: 'Used from the next session.',
          value: value,
          options: const <Choice<String>>[
            Choice<String>('a', 'Alpha'),
            Choice<String>('b', 'Bravo'),
          ],
          onChanged: onChanged,
        ),
      ),
    ),
  );
}
