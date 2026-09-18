import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/responsive/form_factor.dart';

void main() {
  testWidgets('a pointing desktop is desktop at any width', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      platform: TargetPlatform.windows,
      size: const Size(400, 800),
    );
    expect(find.textContaining('desktop'), findsOneWidget);
    expect(find.textContaining('dialogs:false'), findsOneWidget);
  });

  testWidgets('a compact android phone is mobile', (WidgetTester tester) async {
    await _pump(
      tester,
      platform: TargetPlatform.android,
      size: const Size(400, 800),
    );
    expect(find.textContaining('mobile'), findsOneWidget);
    expect(find.textContaining('dialogs:false'), findsOneWidget);
  });

  testWidgets('a wide android device is a tablet', (WidgetTester tester) async {
    await _pump(
      tester,
      platform: TargetPlatform.android,
      size: const Size(800, 1000),
    );
    expect(find.textContaining('tablet'), findsOneWidget);
  });

  testWidgets('a desktop with room prefers a dialog', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      platform: TargetPlatform.windows,
      size: const Size(1200, 800),
    );
    expect(find.textContaining('desktop'), findsOneWidget);
    expect(find.textContaining('dialogs:true'), findsOneWidget);
    expect(SizeClass.fromWidth(1200), SizeClass.expanded);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required TargetPlatform platform,
  required Size size,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(
        brightness: Brightness.light,
      ).copyWith(platform: platform),
      home: Builder(
        builder: (BuildContext context) {
          return Text(
            '${context.formFactor.name} dialogs:${context.prefersDialogs}',
          );
        },
      ),
    ),
  );
}
