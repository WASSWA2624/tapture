import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';

import '../../support/a11y_matchers.dart';

void main() {
  testWidgets('a busy button swallows taps', (WidgetTester tester) async {
    final List<String> taps = <String>[];
    await _pump(
      tester,
      AppButton(label: 'Save', busy: true, onPressed: () => taps.add('hit')),
    );
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(taps, isEmpty);

    await _pump(
      tester,
      AppButton(label: 'Save', onPressed: () => taps.add('hit')),
    );
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(taps, <String>['hit']);
  });

  testWidgets('all three controls meet the 48dp target and stay labelled', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const AppPage(
        title: 'Actions',
        body: Column(
          children: <Widget>[
            AppButton(label: 'Save', onPressed: _ignorePress),
            AppIconButton(
              icon: Icons.search,
              semanticLabel: 'Search',
              tooltip: 'Search',
              onPressed: _ignorePress,
            ),
            AppPrimaryAction(label: 'Capture', onPressed: _ignorePress),
          ],
        ),
      ),
    );

    expect(find.byType(AppButton), meetsTapTarget());
    expect(find.byType(AppIconButton), meetsTapTarget());
    expect(find.byType(AppPrimaryAction), meetsTapTarget());
    expect(find.byType(AppButton), hasSemanticLabel('Save'));
    expect(find.byType(AppIconButton), hasSemanticLabel('Search'));
    expect(find.byType(AppPrimaryAction), hasSemanticLabel('Capture'));
    await expectNoA11yIssues(tester);
  });

  testWidgets('every variant stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pump(
      tester,
      AppPage(
        title: 'Buttons',
        body: Column(
          children: <Widget>[
            for (final AppButtonVariant variant in AppButtonVariant.values)
              AppButton(
                label: 'Save ${variant.name}',
                variant: variant,
                icon: Icons.check,
                onPressed: _ignorePress,
              ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -80));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: home is AppPage ? home : Scaffold(body: Center(child: home)),
    ),
  );
}

void _ignorePress() {}
