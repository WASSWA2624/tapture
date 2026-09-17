import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';

import '../../support/a11y_matchers.dart';

void main() {
  testWidgets('the control is a 48dp labelled icon with no visible text', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const AppOverflowMenu(
        key: ValueKey<String>('app-overflow'),
        items: <AppOverflowAction>[
          AppOverflowAction(label: Copy.save, onTap: _ignore),
        ],
      ),
    );

    expect(find.byType(AppOverflowMenu), meetsTapTarget());
    expect(find.byType(AppOverflowMenu), hasSemanticLabel(Copy.overflowMenu));
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.text(Copy.save), findsNothing);
    await expectNoA11yIssues(tester);
  });

  testWidgets('opening the menu shows a labelled row and fires onTap', (
    WidgetTester tester,
  ) async {
    bool tapped = false;
    await _pump(
      tester,
      AppOverflowMenu(
        key: const ValueKey<String>('app-overflow'),
        items: <AppOverflowAction>[
          AppOverflowAction(
            key: const ValueKey<String>('overflow-save'),
            icon: Icons.save_outlined,
            label: Copy.save,
            onTap: () => tapped = true,
          ),
        ],
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('app-overflow')));
    await tester.pumpAndSettle();

    expect(find.text(Copy.save), findsOneWidget);
    expect(find.byIcon(Icons.save_outlined), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('overflow-save')));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
    expect(find.text(Copy.save), findsNothing);
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
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void _ignore() {}
