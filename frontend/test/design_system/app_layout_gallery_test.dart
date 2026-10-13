import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/gallery/app_layout_gallery.dart';

import '../support/pump_app.dart';
import '../support/screen_fonts.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);

  for (final ({String name, Brightness brightness, bool outdoor}) mode
      in <({String name, Brightness brightness, bool outdoor})>[
        (name: 'light', brightness: Brightness.light, outdoor: false),
        (name: 'dark', brightness: Brightness.dark, outdoor: false),
        (name: 'outdoor', brightness: Brightness.light, outdoor: true),
      ]) {
    testWidgets('selected layout catalogue in ${mode.name}', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 3000);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      });
      await pumpApp(
        tester,
        const AppPage(title: 'Layouts', body: AppLayoutGallery()),
        brightness: mode.brightness,
        outdoor: mode.outdoor,
        useScreenFonts: true,
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(AppPage),
        matchesGoldenFile('goldens/project_layouts_${mode.name}.png'),
      );
    });
  }
}
