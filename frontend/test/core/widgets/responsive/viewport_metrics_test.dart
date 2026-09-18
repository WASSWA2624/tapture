import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/responsive/viewport_metrics.dart';

void main() {
  testWidgets('metrics read the window, not a feature-owned size', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    late ViewportMetrics metrics;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Builder(
          builder: (BuildContext context) {
            metrics = context.viewportMetrics;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(metrics.viewport, const Size(400, 800));
    expect(metrics.devicePixelRatio, 2);
    expect(metrics.orientation, Orientation.portrait);
    expect(metrics.sizeClass, SizeClass.compact);
    expect(metrics.textScale, 1);
  });
}
