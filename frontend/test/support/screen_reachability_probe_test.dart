import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screen_probe.dart';

void main() {
  const ValueKey<String> target = ValueKey<String>('natural-control');

  Future<void> pumpControl(
    WidgetTester tester,
    double height, {
    bool outside = false,
    VoidCallback? onTap,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: height,
            width: 180,
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  if (outside) const SizedBox(height: 800),
                  Semantics(
                    key: target,
                    container: true,
                    button: true,
                    label: 'Choose target',
                    onTap: onTap,
                    child: GestureDetector(
                      excludeFromSemantics: true,
                      onTap: onTap,
                      child: const ColoredBox(
                        color: Colors.white,
                        child: SizedBox(height: 200, width: 180),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('tall control retains a usable painted region and callback', (
    WidgetTester tester,
  ) async {
    bool pressed = false;
    await pumpControl(tester, 80, onTap: () => pressed = true);
    final Finder control = find.byKey(target);
    expect(ScreenProbe.reachabilityIssues(tester, control), isEmpty);
    expect(
      await ScreenProbe.accessibilityIssues(
        tester,
        reachableTargets: <Finder>[control],
        within: find.byType(Scaffold),
      ),
      isEmpty,
    );
    final Rect region = tester
        .getRect(control)
        .intersect(ScreenProbe.targetViewport(tester, control));
    await tester.tapAt(region.center);
    expect(pressed, isTrue);
    expect(tester.getRect(control).height, 200);
  });

  testWidgets('sub48 painted region fails despite a large wrapper', (
    WidgetTester tester,
  ) async {
    await pumpControl(tester, 36);
    expect(
      ScreenProbe.reachabilityIssues(tester, find.byKey(target)),
      contains(contains('Interactive painted region')),
    );
    expect(
      await ScreenProbe.accessibilityIssues(
        tester,
        reachableTargets: <Finder>[find.byKey(target)],
        within: find.byType(Scaffold),
      ),
      contains(contains('Interactive painted region')),
    );
  });

  testWidgets('unreachable control outside every viewport fails', (
    WidgetTester tester,
  ) async {
    await pumpControl(tester, 80, outside: true);
    expect(
      ScreenProbe.reachabilityIssues(tester, find.byKey(target)),
      contains(contains('Interactive painted region')),
    );
    expect(
      await ScreenProbe.accessibilityIssues(
        tester,
        reachableTargets: <Finder>[find.byKey(target)],
        within: find.byType(Scaffold),
      ),
      contains(contains('Interactive painted region')),
    );
  });
}
