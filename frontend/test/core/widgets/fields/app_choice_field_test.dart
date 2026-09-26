import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  final List<Choice<String>> three = <Choice<String>>[
    const Choice<String>('a', 'Alpha'),
    const Choice<String>('b', 'Bravo'),
    const Choice<String>('c', 'Charlie'),
  ];
  final List<Choice<String>> four = <Choice<String>>[
    ...three,
    const Choice<String>('d', 'Delta'),
  ];

  testWidgets('three options render as a segmented control', (
    WidgetTester tester,
  ) async {
    String? latest;
    await _pump(
      tester,
      AppChoiceField<String>(
        label: 'Grade',
        options: three,
        onChanged: (String? value) => latest = value,
      ),
    );

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Bravo'), findsOneWidget);
    expect(find.text('Charlie'), findsOneWidget);
    expect(find.byType(AppChoiceField<String>), meetsTapTarget());
    expect(find.byType(AppChoiceField<String>), hasSemanticLabel('Grade'));

    await tester.tap(find.text('Bravo'));
    await tester.pump();
    expect(latest, 'b');
  });

  testWidgets('a selected segment carries a tick, not only a tint', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppChoiceField<String>(
        label: 'Grade',
        options: three,
        value: 'b',
        onChanged: (_) {},
      ),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  for (final int count in <int>[1, 2, 3]) {
    testWidgets('alwaysSheet shows the value and opens a sheet with $count '
        'option(s)', (WidgetTester tester) async {
      String? latest;
      await _pump(
        tester,
        AppChoiceField<String>(
          label: 'Project',
          options: three.take(count).toList(),
          value: 'a',
          alwaysSheet: true,
          onChanged: (String? value) => latest = value,
        ),
      );

      expect(find.text('Project'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byType(AppChoiceField<String>), meetsTapTarget());

      await tester.tap(find.byType(AppChoiceField<String>));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await tester.tap(find.text(three[count - 1].label).last);
      await tester.pumpAndSettle();
      expect(latest, three[count - 1].value);
    });
  }

  testWidgets('four options open a searchable sheet', (
    WidgetTester tester,
  ) async {
    String? latest;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AppChoiceField<String>(
            label: 'Grade',
            options: four,
            value: latest,
            onChanged: (String? value) => setState(() => latest = value),
          );
        },
      ),
      size: const Size(400, 800),
    );

    expect(find.text('Delta'), findsNothing);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.byType(AppChoiceField<String>));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Delta'), findsOneWidget);

    await tester.tap(find.text('Delta'));
    await tester.pumpAndSettle();
    expect(latest, 'd');
    expect(find.text('Delta'), findsOneWidget);
  });

  testWidgets('a 200-option sheet stays usable on a compact screen', (
    WidgetTester tester,
  ) async {
    final List<Choice<int>> options = <Choice<int>>[
      for (int i = 0; i < 200; i++) Choice<int>(i, 'Option $i'),
    ];
    await _pump(
      tester,
      AppChoiceField<int>(label: 'Item', options: options, onChanged: (_) {}),
      size: const Size(400, 800),
    );

    await tester.tap(find.byType(AppChoiceField<int>));
    await tester.pumpAndSettle();

    expect(find.text('Option 0'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '199');
    await tester.pump();
    expect(find.text('Option 199'), findsOneWidget);
    expect(find.text('Option 0'), findsNothing);
  });

  testWidgets('a search miss names the query, and clearing it restores rows', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppChoiceField<String>(label: 'Grade', options: four, onChanged: (_) {}),
      size: const Size(400, 800),
    );
    await tester.tap(find.byType(AppChoiceField<String>));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zulu');
    await tester.pump();
    expect(find.text(Copy.choiceNoMatch('zulu')), findsOneWidget);
    expect(find.text(Copy.searchNoMatchMessage), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text(Copy.choiceNoMatch('zulu')), findsNothing);
  });

  testWidgets('a segmented field stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: AppPage(
          title: 'Choice',
          body: AppChoiceField<String>(
            label: 'Grade',
            options: three,
            value: 'a',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await expectNoA11yIssues(tester);
  });
  for (final double scale in <double>[1, 2]) {
    testWidgets('a sheet field is as tall as a labelled text field at '
        '${(scale * 100).round()} percent text', (WidgetTester tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final TextEditingController text = TextEditingController(text: 'Alpha');
      addTearDown(text.dispose);
      await _pump(
        tester,
        Column(
          children: <Widget>[
            AppChoiceField<String>(
              key: const ValueKey<String>('sheet'),
              label: 'Project',
              options: four,
              value: 'a',
              onChanged: (_) {},
            ),
            AppTextField(
              key: const ValueKey<String>('text'),
              label: 'Caption',
              controller: text,
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      final double sheet = tester
          .getSize(find.byKey(const ValueKey<String>('sheet')))
          .height;
      final double field = tester
          .getSize(find.byKey(const ValueKey<String>('text')))
          .height;
      expect(sheet, field);
      expect(sheet, greaterThanOrEqualTo(Sizes.minTapTarget));
      expect(find.byKey(const ValueKey<String>('sheet')), meetsTapTarget());
      // The value line sits inside the trigger, not clipped by it.
      final Rect trigger = tester.getRect(
        find.byKey(const ValueKey<String>('sheet')),
      );
      final Rect value = tester.getRect(find.text('Alpha').first);
      expect(trigger.top, lessThanOrEqualTo(value.top));
      expect(trigger.bottom, greaterThanOrEqualTo(value.bottom));
      await expectNoA11yIssues(tester);
    });
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(400, 800),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
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
