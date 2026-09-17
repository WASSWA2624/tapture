import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/forms/keep_focused_visible.dart';

void main() {
  testWidgets('the focused field stays above a simulated keyboard inset', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 640);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });

    final FocusNode last = FocusNode();
    addTearDown(last.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(
          resizeToAvoidBottomInset: true,
          body: KeepFocusedVisible(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 480),
                  TextField(
                    key: const Key('last'),
                    focusNode: last,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  const SizedBox(height: 480),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    last.requestFocus();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final Rect field = tester.getRect(find.byKey(const Key('last')));
    const double keyboardTop = 640 - 300;
    expect(field.bottom, lessThanOrEqualTo(keyboardTop + 1));
    expect(
      field.intersect(const Rect.fromLTWH(0, 0, 400, keyboardTop)).height,
      greaterThan(0),
    );
  });
}
