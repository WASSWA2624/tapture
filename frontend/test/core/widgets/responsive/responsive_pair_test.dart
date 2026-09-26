import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';

const ValueKey<String> _start = ValueKey<String>('start');
const ValueKey<String> _end = ValueKey<String>('end');

void main() {
  testWidgets('at compact width start stacks above end, both full width', (
    WidgetTester tester,
  ) async {
    await _pumpPair(tester, width: 400);

    final Rect start = tester.getRect(find.byKey(_start));
    final Rect end = tester.getRect(find.byKey(_end));
    expect(start.bottom + Space.x3, end.top);
    expect(start.left, end.left);
    expect(start.width, 400);
    expect(end.width, 400);
  });

  for (final double width in <double>[800, 1200]) {
    testWidgets('at $width dp the two share a row in their flex ratio', (
      WidgetTester tester,
    ) async {
      await _pumpPair(tester, width: width, endFlex: 2);

      final Rect start = tester.getRect(find.byKey(_start));
      final Rect end = tester.getRect(find.byKey(_end));
      expect(start.top, end.top);
      expect(start.right + Space.x3, end.left);
      expect(end.width, closeTo(start.width * 2, 0.01));
      expect(start.width + end.width + Space.x3, width);
    });
  }

  testWidgets('the row is top-aligned when one side is taller', (
    WidgetTester tester,
  ) async {
    await _pumpPair(tester, width: 800, taller: true);

    expect(
      tester.getRect(find.byKey(_start)).top,
      tester.getRect(find.byKey(_end)).top,
    );
  });

  testWidgets('under right-to-left start sits on the right', (
    WidgetTester tester,
  ) async {
    await _pumpPair(tester, width: 800, direction: TextDirection.rtl);

    final Rect start = tester.getRect(find.byKey(_start));
    final Rect end = tester.getRect(find.byKey(_end));
    expect(start.left, greaterThan(end.left));
    expect(start.right, 800);
  });
}

Future<void> _pumpPair(
  WidgetTester tester, {
  required double width,
  int endFlex = 1,
  bool taller = false,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 600);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Align(
          alignment: Alignment.topCenter,
          child: ResponsivePair(
            endFlex: endFlex,
            start: const SizedBox(key: _start, height: 48),
            end: SizedBox(key: _end, height: taller ? 96 : 48),
          ),
        ),
      ),
    ),
  );
}
