import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

import '../../../support/a11y_matchers.dart';

void main() {
  testWidgets('shows the message and dismiss fires without taking focus', (
    WidgetTester tester,
  ) async {
    var dismissed = false;
    await _pump(
      tester,
      Column(
        children: <Widget>[
          AppBanner(
            message: 'You are offline. Captures stay on this device.',
            icon: Icons.cloud_off,
            tone: SnackTone.warning,
            onDismiss: () => dismissed = true,
          ),
          const TextField(),
        ],
      ),
    );

    expect(
      find.text('You are offline. Captures stay on this device.'),
      findsOneWidget,
    );
    expect(
      find.byType(AppBanner),
      hasSemanticLabel('You are offline. Captures stay on this device.'),
    );
    expect(find.byType(AppIconButton), meetsTapTarget());

    await tester.tap(find.byType(TextField));
    await tester.pump();
    final FocusNode? fieldFocus = tester.binding.focusManager.primaryFocus;

    await tester.tap(find.byType(AppIconButton));
    await tester.pump();
    expect(dismissed, isTrue);
    expect(tester.binding.focusManager.primaryFocus, same(fieldFocus));
  });

  testWidgets('stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: AppPage(
          title: 'Banner',
          body: AppBanner(
            message: 'You are offline. Captures stay on this device.',
            icon: Icons.cloud_off,
            tone: SnackTone.warning,
            onDismiss: () {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
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
      home: Scaffold(body: child),
    ),
  );
}
