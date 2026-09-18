import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  _horizontalCases();

  final List<Choice<String>> options = <Choice<String>>[
    const Choice<String>('a', 'Alpha'),
    const Choice<String>('b', 'Bravo'),
    const Choice<String>('c', 'Charlie'),
  ];

  testWidgets('tapping an option reports it and marks it selected', (
    WidgetTester tester,
  ) async {
    String? latest;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AppRadioGroup<String>(
            label: 'Grade',
            options: options,
            value: latest,
            onChanged: (String value) => setState(() => latest = value),
          );
        },
      ),
    );

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Bravo'), findsOneWidget);
    expect(find.text('Charlie'), findsOneWidget);
    expect(find.byType(AppRadioGroup<String>), meetsTapTarget());
    expect(find.byType(AppRadioGroup<String>), hasSemanticLabel('Grade'));

    await tester.tap(find.text('Bravo'));
    await tester.pump();
    expect(latest, 'b');
    expect(
      tester
          .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
          .groupValue,
      'b',
    );
  });

  testWidgets('a disabled group ignores taps', (WidgetTester tester) async {
    String? latest = 'a';
    await _pump(
      tester,
      AppRadioGroup<String>(
        label: 'Grade',
        options: options,
        value: latest,
        enabled: false,
        onChanged: (String value) => latest = value,
      ),
    );

    await tester.tap(find.text('Charlie'));
    await tester.pump();
    expect(latest, 'a');
  });

  testWidgets('the group stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: AppPage(
          title: 'Grade',
          body: AppRadioGroup<String>(
            label: 'Grade',
            options: options,
            value: 'a',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await expectNoA11yIssues(tester);
  });
}

void _horizontalCases() {
  final List<Choice<String>> short = <Choice<String>>[
    const Choice<String>('g', 'General'),
    const Choice<String>('e', 'Error'),
    const Choice<String>('s', 'Suggestion'),
    const Choice<String>('o', 'Other'),
  ];

  testWidgets('horizontal options share one line when there is room', (
    WidgetTester tester,
  ) async {
    String? latest;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AppRadioGroup<String>(
            label: 'Type',
            options: short,
            value: latest,
            direction: Axis.horizontal,
            showLabel: false,
            onChanged: (String value) => setState(() => latest = value),
          );
        },
      ),
      width: 1200,
    );
    final double top = tester.getTopLeft(find.text('General')).dy;
    for (final Choice<String> option in short) {
      expect(tester.getTopLeft(find.text(option.label)).dy, top);
    }
    expect(find.text('Type'), findsNothing);
    expect(find.byType(AppRadioGroup<String>), hasSemanticLabel('Type'));
    expect(find.byType(AppRadioGroup<String>), meetsTapTarget());
    await tester.tap(find.text('Suggestion'));
    await tester.pump();
    expect(latest, 's');
    await expectNoA11yIssues(tester);
  });

  testWidgets('horizontal options that do not fit form even columns', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppRadioGroup<String>(
        label: 'Type',
        options: short,
        value: 'g',
        direction: Axis.horizontal,
        onChanged: (String _) {},
      ),
      width: 440,
    );
    double top(String label) => tester.getTopLeft(find.text(label)).dy;
    double left(String label) => tester.getTopLeft(find.text(label)).dx;
    expect(find.text('Type'), findsOneWidget);
    expect(top('General'), top('Error'));
    expect(top('Suggestion'), top('Other'));
    expect(top('Suggestion'), greaterThan(top('General')));
    expect(left('General'), left('Suggestion'));
    expect(left('Error'), left('Other'));
  });

  testWidgets('horizontal options survive 200 percent text', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(
      tester,
      AppRadioGroup<String>(
        label: 'Type',
        options: short,
        value: 'g',
        direction: Axis.horizontal,
        onChanged: (String _) {},
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(AppRadioGroup<String>), meetsTapTarget());
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 400,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(Space.x4), child: child),
      ),
    ),
  );
}
