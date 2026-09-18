import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_floating_button.dart';

import '../../support/a11y_matchers.dart';

void main() {
  testWidgets('the control is labelled, 48dp, and icon-only until hover', (
    WidgetTester tester,
  ) async {
    final List<Rect> taps = <Rect>[];
    await _pump(
      tester,
      AppFloatingButton(
        icon: Icons.feedback_outlined,
        label: Copy.feedback,
        hint: Copy.feedbackButtonHint,
        expandOnHover: true,
        startX: 0.5,
        startY: 0.5,
        onPressed: taps.add,
      ),
    );

    expect(find.byIcon(Icons.feedback_outlined), findsOneWidget);
    expect(find.text(Copy.feedback), findsNothing);
    expect(find.byType(AppFloatingButton), meetsTapTarget());
    expect(find.byType(AppFloatingButton), hasSemanticLabel(Copy.feedback));

    final TestGesture mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byIcon(Icons.feedback_outlined)));
    await tester.pumpAndSettle();
    expect(_labelOnButton(), findsOneWidget);

    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(_labelOnButton(), findsNothing);

    await tester.tap(find.byIcon(Icons.feedback_outlined));
    await tester.pump();
    expect(taps, hasLength(1));
  });

  testWidgets('a drag moves the control and does not fire onPressed', (
    WidgetTester tester,
  ) async {
    final List<Rect> taps = <Rect>[];
    await _pump(
      tester,
      AppFloatingButton(
        icon: Icons.feedback_outlined,
        label: Copy.feedback,
        hint: Copy.feedbackButtonHint,
        startX: 1,
        startY: 1,
        onPressed: taps.add,
      ),
    );

    final Offset before = tester.getCenter(
      find.byIcon(Icons.feedback_outlined),
    );
    await tester.drag(
      find.byIcon(Icons.feedback_outlined),
      const Offset(-80, -120),
    );
    await tester.pumpAndSettle();
    final Offset after = tester.getCenter(find.byIcon(Icons.feedback_outlined));
    expect(after.dx, lessThan(before.dx));
    expect(after.dy, lessThan(before.dy));
    expect(taps, isEmpty);
  });

  testWidgets('touch does not show the label even when expandOnHover is set', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      AppFloatingButton(
        icon: Icons.feedback_outlined,
        label: Copy.feedback,
        hint: Copy.feedbackButtonHint,
        expandOnHover: true,
        startX: 0.5,
        startY: 0.5,
        onPressed: (_) {},
      ),
    );
    expect(find.text(Copy.feedback), findsNothing);
  });
}

Finder _labelOnButton() {
  return find.descendant(
    of: find.byType(AnimatedContainer),
    matching: find.text(Copy.feedback),
  );
}

Future<void> _pump(WidgetTester tester, AppFloatingButton button) async {
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
        body: Stack(children: <Widget>[const SizedBox.expand(), button]),
      ),
    ),
  );
}
