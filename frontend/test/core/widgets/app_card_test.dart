import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_card.dart';
import 'package:tapture/core/widgets/app_page.dart';

import '../../support/a11y_matchers.dart';

void main() {
  testWidgets('a tap opens a tappable card and a static card ignores taps', (
    WidgetTester tester,
  ) async {
    bool opened = false;
    await _pump(
      tester,
      Column(
        children: <Widget>[
          AppCard(onTap: () => opened = true, child: const Text('Review')),
          const AppCard(child: Text('Static')),
        ],
      ),
    );

    expect(find.byType(AppCard).first, meetsTapTarget());
    await tester.tap(find.text('Review'));
    await tester.pump();
    expect(opened, isTrue);

    opened = false;
    await tester.tap(find.text('Static'));
    await tester.pump();
    expect(opened, isFalse);
  });

  testWidgets('a card stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: AppPage(
          title: 'Card',
          body: AppCard(
            onTap: () {},
            child: const Text(
              'A long detail paragraph that must wrap rather than clip '
              'the page at two hundred percent text scale.',
            ),
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
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(Space.x4), child: child),
      ),
    ),
  );
}
