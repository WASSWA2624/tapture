import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  testWidgets('error copy is rendered and a clear control empties the field', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      AppTextField(
        label: 'Name',
        controller: controller,
        errorText: 'Required',
        clearable: true,
      ),
    );

    expect(find.text('Required'), findsOneWidget);
    expect(find.byType(AppTextField), meetsTapTarget());
    expect(find.byType(AppTextField), hasSemanticLabel('Name'));

    await tester.enterText(find.byType(TextField), 'Ada');
    await tester.pump();
    expect(controller.text, 'Ada');
    await tester.tap(find.byTooltip('Clear Name'));
    await tester.pump();
    expect(controller.text, isEmpty);
  });

  testWidgets('obscureText hides typed characters', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      AppTextField(label: 'PIN', controller: controller, obscureText: true),
    );

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );
  });

  testWidgets('a hidden field ends in a control that shows and hides it', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: '1234',
    );
    addTearDown(controller.dispose);
    await _pump(
      tester,
      AppTextField(
        label: 'PIN',
        controller: controller,
        obscureText: true,
        clearable: true,
      ),
    );
    bool hidden() =>
        tester.widget<TextField>(find.byType(TextField)).obscureText;

    expect(hidden(), isTrue);
    expect(
      tester.getRect(find.byTooltip('Show PIN')).right,
      greaterThan(tester.getRect(find.byTooltip('Clear PIN')).right),
    );

    await tester.tap(find.byTooltip('Show PIN'));
    await tester.pump();
    expect(hidden(), isFalse);
    expect(controller.text, '1234');
    expect(
      tester.widget<TextField>(find.byType(TextField)).enableSuggestions,
      isFalse,
    );

    await tester.tap(find.byTooltip('Hide PIN'));
    await tester.pump();
    expect(hidden(), isTrue);
  });

  testWidgets('a plain field has no show / hide control', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();
    addTearDown(controller.dispose);
    await _pump(tester, AppTextField(label: 'Name', controller: controller));

    expect(find.byTooltip('Show Name'), findsNothing);
  });

  testWidgets('minLines is forwarded on a multiline field', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      AppTextField(
        label: 'Notes',
        controller: controller,
        minLines: 3,
        maxLines: 8,
      ),
    );
    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 3);
    expect(field.maxLines, 8);
  });

  testWidgets('a multi-line field stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final TextEditingController controller = TextEditingController(
      text: 'A long caption that wraps.',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: AppPage(
          title: 'Field',
          body: AppTextField(
            label: 'Caption',
            controller: controller,
            maxLines: 4,
            maxLength: 80,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(AppTextField), meetsTapTarget());
    await expectNoA11yIssues(tester);
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
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
