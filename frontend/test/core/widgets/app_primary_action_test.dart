import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';

import '../../support/a11y_matchers.dart';

void main() {
  testWidgets('a busy primary action swallows taps', (
    WidgetTester tester,
  ) async {
    final List<String> taps = <String>[];
    await _pump(
      tester,
      AppPrimaryAction(
        label: 'Capture',
        busy: true,
        onPressed: () => taps.add('hit'),
      ),
    );
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();
    expect(taps, isEmpty);

    await _pump(
      tester,
      AppPrimaryAction(label: 'Capture', onPressed: () => taps.add('hit')),
    );
    await tester.tap(find.byType(AppPrimaryAction));
    await tester.pump();
    expect(taps, <String>['hit']);
  });

  testWidgets(
    'the primary action is full width, taller than a row button, and 48dp',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: const Scaffold(
            body: AppPrimaryAction(
              label: 'Capture',
              caption: 'Writes to this device',
              onPressed: _ignorePress,
            ),
          ),
        ),
      );

      final Size size = tester.getSize(find.byType(AppPrimaryAction));
      expect(size.width, 400);
      expect(size.height, greaterThanOrEqualTo(Sizes.controlHeight));
      expect(find.byType(AppPrimaryAction), meetsTapTarget());
      expect(find.byType(AppPrimaryAction), hasSemanticLabel('Capture'));
      await expectNoA11yIssues(tester);
    },
  );

  testWidgets(
    'caption and 200 percent text scale do not clip in either orientation',
    (WidgetTester tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      for (final Size size in <Size>[
        const Size(400, 800),
        const Size(800, 400),
      ]) {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTheme(brightness: Brightness.light),
            home: const AppPage(
              title: 'Capture',
              body: Text('Session'),
              footer: AppPrimaryAction(
                label: 'Capture and analyse',
                caption: 'Saves to this device, then queues a job',
                onPressed: _ignorePress,
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
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

void _ignorePress() {}
