import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
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

  group('compact sheet trigger', () {
    testWidgets('is opt-in and keeps the labelled selected value', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        Column(
          children: <Widget>[
            AppChoiceField<String>(
              key: const ValueKey<String>('default-choice'),
              label: 'Project',
              options: four,
              value: 'a',
              onChanged: (_) {},
            ),
            AppChoiceField<String>(
              key: const ValueKey<String>('compact-choice'),
              label: 'Project',
              options: four,
              value: 'a',
              compact: true,
              onChanged: (_) {},
            ),
          ],
        ),
      );
      final Finder standard = find.byKey(
        const ValueKey<String>('default-choice'),
      );
      final Finder compact = find.byKey(
        const ValueKey<String>('compact-choice'),
      );
      expect(
        find.descendant(of: standard, matching: find.byType(InputDecorator)),
        findsOneWidget,
      );
      final AppListTile row = tester.widget<AppListTile>(
        find.descendant(of: compact, matching: find.byType(AppListTile)),
      );
      expect(row.title, 'Alpha');
      expect(row.subtitle, 'Project');
      expect(row.wrapText, isTrue);
      expect(row.dense, isTrue);
      expect(compact, meetsTapTarget());
      expect(compact, hasSemanticLabel('Project'));
      expect(
        find.descendant(of: compact, matching: find.text('Alpha')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    for (final int count in <int>[1, 3, 4]) {
      testWidgets('retains searchable selection with $count options', (
        WidgetTester tester,
      ) async {
        String? picked;
        await _pump(
          tester,
          AppChoiceField<String>(
            label: 'Project',
            options: four.take(count).toList(),
            value: 'a',
            compact: true,
            alwaysSheet: true,
            onChanged: (String? value) => picked = value,
          ),
        );
        final Finder trigger = find.byType(AppChoiceField<String>);
        expect(trigger, meetsTapTarget());
        await tester.tap(trigger);
        await tester.pumpAndSettle();
        final String label = four[count - 1].label;
        await tester.enterText(find.byType(TextField), label.toUpperCase());
        await tester.pump();
        final Finder choice = find.descendant(
          of: find.byType(AppBottomSheet),
          matching: find.widgetWithText(AppListTile, label),
        );
        expect(choice, findsOneWidget);
        expect(choice, meetsTapTarget());
        await tester.tap(choice);
        await tester.pumpAndSettle();
        expect(picked, four[count - 1].value);
        expect(find.byType(AppBottomSheet), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('disabled selection remains readable and cannot open', (
      WidgetTester tester,
    ) async {
      int changes = 0;
      await _pump(
        tester,
        AppChoiceField<String>(
          label: 'Project',
          options: four,
          value: 'b',
          compact: true,
          enabled: false,
          onChanged: (_) => changes++,
        ),
      );
      expect(find.text('Project'), findsOneWidget);
      expect(find.text('Bravo'), findsOneWidget);
      final AppListTile row = tester.widget<AppListTile>(
        find.byType(AppListTile),
      );
      expect(row.onTap, isNull);
      expect(
        tester
            .getSemantics(find.byType(AppListTile))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      await tester.tap(find.byType(AppChoiceField<String>));
      await tester.pumpAndSettle();
      expect(find.byType(AppBottomSheet), findsNothing);
      expect(changes, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('complete labels grow naturally at 200 percent text', (
      WidgetTester tester,
    ) async {
      const String label = 'Project with a complete field label';
      const String selected =
          'Selected project with its complete descriptive name';
      final List<double> heights = <double>[];
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final double scale in <double>[1, 2]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await _pump(
          tester,
          AppChoiceField<String>(
            label: label,
            options: const <Choice<String>>[Choice<String>('a', selected)],
            value: 'a',
            compact: true,
            alwaysSheet: true,
            onChanged: (_) {},
          ),
          size: const Size(320, 740),
        );
        final Finder trigger = find.byType(AppChoiceField<String>);
        final Rect bounds = tester.getRect(trigger);
        heights.add(bounds.height);
        expect(trigger, meetsTapTarget());
        for (final String text in <String>[label, selected]) {
          final RenderParagraph paragraph = tester
              .renderObject<RenderParagraph>(
                find.descendant(
                  of: find.text(text),
                  matching: find.byType(RichText),
                ),
              );
          expect(paragraph.didExceedMaxLines, isFalse, reason: text);
          final Rect painted = MatrixUtils.transformRect(
            paragraph.getTransformTo(null),
            paragraph.paintBounds,
          );
          expect(painted.left, greaterThanOrEqualTo(bounds.left));
          expect(painted.right, lessThanOrEqualTo(bounds.right));
          expect(painted.top, greaterThanOrEqualTo(bounds.top));
          expect(painted.bottom, lessThanOrEqualTo(bounds.bottom));
        }
        expect(trigger, hasSemanticLabel(label));
        expect(tester.takeException(), isNull);
      }
      expect(heights.last, greaterThan(heights.first));
    });

    testWidgets('compact uses the same sheet without alwaysSheet', (
      WidgetTester tester,
    ) async {
      String? picked;
      await _pump(
        tester,
        AppChoiceField<String>(
          label: 'Grade',
          options: three,
          compact: true,
          onChanged: (String? value) => picked = value,
        ),
      );
      expect(find.byType(AppListTile), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);
      await tester.tap(find.byType(AppChoiceField<String>));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await tester.tap(find.widgetWithText(AppListTile, 'Charlie'));
      await tester.pumpAndSettle();
      expect(picked, 'c');
      expect(find.byType(AppBottomSheet), findsNothing);
    });
  });

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

  testWidgets('sheet labels retain their default decoration', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppChoiceField<String>(
        label: 'Project',
        options: four,
        value: 'a',
        onChanged: (_) {},
      ),
    );
    final InputDecorator field = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    expect(field.decoration.labelText, 'Project');
    expect(field.decoration.label, isNull);
  });

  for (final String? value in <String?>[null, 'a']) {
    testWidgets('a wrapped sheet label stays readable at text 2 with '
        'selection $value', (WidgetTester tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      const String label = 'Supported providers with a longer field label';
      String? picked;
      await _pump(
        tester,
        AppChoiceField<String>(
          label: label,
          wrapLabel: true,
          options: four,
          value: value,
          onChanged: (String? next) => picked = next,
        ),
        size: const Size(393, 852),
      );
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text(label), matching: find.byType(RichText)),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      final Rect painted = MatrixUtils.transformRect(
        paragraph.getTransformTo(null),
        paragraph.paintBounds,
      );
      expect(painted.left, greaterThanOrEqualTo(0));
      expect(painted.right, lessThanOrEqualTo(393));
      expect(painted.top, greaterThanOrEqualTo(0));
      expect(painted.bottom, lessThanOrEqualTo(852));
      final Rect trigger = tester.getRect(find.byType(AppChoiceField<String>));
      expect(painted.top, greaterThanOrEqualTo(trigger.top));
      expect(painted.bottom, lessThanOrEqualTo(trigger.bottom));
      expect(find.byType(AppChoiceField<String>), meetsTapTarget());
      expect(find.byType(AppChoiceField<String>), hasSemanticLabel(label));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(AppChoiceField<String>));
      await tester.pumpAndSettle();
      final Finder choice = find.widgetWithText(AppListTile, 'Delta');
      await tester.scrollUntilVisible(
        choice,
        48,
        scrollable: find.descendant(
          of: find.byType(AppBottomSheet),
          matching: find.byWidgetPredicate(
            (Widget widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          ),
        ),
      );
      await Scrollable.ensureVisible(tester.element(choice), alignment: .5);
      await tester.pumpAndSettle();
      expect(choice.hitTestable(), findsOneWidget);
      await tester.tap(choice);
      await tester.pumpAndSettle();
      expect(picked, 'd');
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

  testWidgets(
    'sheet search and choices scroll in short landscape with keyboard',
    (WidgetTester tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.view.viewInsets = const FakeViewPadding(bottom: 112);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetViewInsets);
      String? chosen;
      await _pump(
        tester,
        AppChoiceField<String>(
          label: 'Grade',
          options: four,
          alwaysSheet: true,
          onChanged: (String? value) => chosen = value,
        ),
        size: const Size(393, 320),
      );
      await tester.ensureVisible(find.byType(AppChoiceField<String>));
      await tester.tap(find.byType(AppChoiceField<String>));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Delta');
      await tester.pumpAndSettle();
      final Finder option = find.widgetWithText(AppListTile, 'Delta');
      await tester.scrollUntilVisible(
        option,
        Sizes.minTapTarget,
        scrollable: find
            .byWidgetPredicate(
              (Widget widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .last,
      );
      await Scrollable.ensureVisible(tester.element(option), alignment: 0.5);
      await tester.pumpAndSettle();
      final Rect viewport = tester.getRect(
        find.ancestor(of: option, matching: find.byType(Scrollable)).first,
      );
      expect(
        tester.getCenter(option).dy,
        inInclusiveRange(viewport.top, viewport.bottom),
      );
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(chosen, 'd');
      expect(tester.takeException(), isNull);
    },
  );

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
