import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_action_dock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';

import '../../support/pump_app.dart';
import '../../support/screen_fonts.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);

  testWidgets('a bounded short dock keeps every command reachable', (
    WidgetTester tester,
  ) async {
    final List<String> commands = <String>[];
    await pumpApp(
      tester,
      Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: AppActionDock(
            maxHeight: 88,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final String label in <String>['First', 'Middle', 'Last'])
                  AppButton(
                    label: label,
                    expand: true,
                    onPressed: () => commands.add(label),
                  ),
              ],
            ),
          ),
        ),
      ),
      useScreenFonts: true,
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(AppActionDock)).height,
      lessThanOrEqualTo(88),
    );
    for (final String label in <String>['First', 'Middle', 'Last']) {
      final Finder command = find.widgetWithText(AppButton, label);
      await tester.ensureVisible(command);
      await tester.pump();
      expect(command.hitTestable(), findsOneWidget);
      expect(
        tester.getSize(command).height,
        greaterThanOrEqualTo(Sizes.minTapTarget),
      );
      await tester.tap(command);
      await tester.pump();
    }
    expect(commands, <String>['First', 'Middle', 'Last']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard insets leave the draft and dock commands reachable', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 420);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final TextEditingController controller = TextEditingController();
    addTearDown(controller.dispose);
    final List<String> commands = <String>[];
    await pumpApp(
      tester,
      AppPage(
        title: 'Project',
        showAppBar: false,
        body: AppTextField(
          label: 'Name',
          controller: controller,
          dictation: false,
        ),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final String label in <String>['Save', 'Cancel', 'More'])
              AppButton(
                label: label,
                expand: true,
                onPressed: () => commands.add(label),
              ),
          ],
        ),
      ),
      useScreenFonts: true,
    );
    await tester.enterText(find.byType(TextField), 'Retained draft');
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    await tester.pumpAndSettle();
    const double keyboardTop = 220;
    final Rect dock = tester.getRect(find.byType(AppActionDock));
    expect(dock.height, lessThanOrEqualTo(keyboardTop / 2));
    expect(dock.bottom, lessThanOrEqualTo(keyboardTop));
    expect(find.byType(TextField).hitTestable(), findsOneWidget);
    for (final String label in <String>['Save', 'Cancel', 'More']) {
      final Finder command = find.widgetWithText(AppButton, label);
      await tester.ensureVisible(command);
      await tester.pump();
      expect(command.hitTestable(), findsOneWidget);
      expect(tester.getRect(command).center.dy, lessThan(keyboardTop));
      await tester.tap(command);
      await tester.pump();
    }
    expect(commands, <String>['Save', 'Cancel', 'More']);
    expect(controller.text, 'Retained draft');
    expect(tester.takeException(), isNull);
  });
}
