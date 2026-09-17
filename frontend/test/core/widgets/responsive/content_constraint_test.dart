import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/responsive/content_constraint.dart';

void main() {
  testWidgets('the child is capped and centred on an expanded window', (
    WidgetTester tester,
  ) async {
    const Key childKey = Key('column');
    await _pumpConstraint(
      tester,
      window: const Size(1200, 800),
      child: const ColoredBox(key: childKey, color: Color(0xFF000000)),
    );

    final Rect child = tester.getRect(find.byKey(childKey));
    expect(child.width, 720);
    expect(child.center.dx, 600);
  });

  testWidgets('the child fills a compact window instead of overflowing', (
    WidgetTester tester,
  ) async {
    const Key childKey = Key('column');
    await _pumpConstraint(
      tester,
      window: const Size(400, 800),
      child: const ColoredBox(key: childKey, color: Color(0xFF000000)),
    );

    expect(tester.getSize(find.byKey(childKey)).width, 400);
  });
}

Future<void> _pumpConstraint(
  WidgetTester tester, {
  required Size window,
  required Widget child,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = window;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: ContentConstraint(child: child)),
    ),
  );
}
