import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/core/widgets/responsive/responsive_builder.dart';

void main() {
  testWidgets('ResponsiveBuilder uses each builder at its width', (
    WidgetTester tester,
  ) async {
    await _pumpBuilder(
      tester,
      width: 400,
      compact: (_) => const Text('compact'),
      medium: (_) => const Text('medium'),
      expanded: (_) => const Text('expanded'),
    );
    expect(find.text('compact'), findsOneWidget);

    await _pumpBuilder(
      tester,
      width: 800,
      compact: (_) => const Text('compact'),
      medium: (_) => const Text('medium'),
      expanded: (_) => const Text('expanded'),
    );
    expect(find.text('medium'), findsOneWidget);

    await _pumpBuilder(
      tester,
      width: 1200,
      compact: (_) => const Text('compact'),
      medium: (_) => const Text('medium'),
      expanded: (_) => const Text('expanded'),
    );
    expect(find.text('expanded'), findsOneWidget);
  });

  testWidgets('omitted builders fall back to the next smaller class', (
    WidgetTester tester,
  ) async {
    await _pumpBuilder(
      tester,
      width: 800,
      compact: (_) => const Text('compact'),
    );
    expect(find.text('compact'), findsOneWidget);

    await _pumpBuilder(
      tester,
      width: 1200,
      compact: (_) => const Text('compact'),
      medium: (_) => const Text('medium'),
    );
    expect(find.text('medium'), findsOneWidget);

    await _pumpBuilder(
      tester,
      width: 1200,
      compact: (_) => const Text('compact'),
      expanded: (_) => const Text('expanded'),
    );
    expect(find.text('expanded'), findsOneWidget);
  });

  testWidgets('a two-pane layout is one extra builder on expanded', (
    WidgetTester tester,
  ) async {
    Widget twoPane(BuildContext context) {
      final int panes = context.responsive(compact: 1, expanded: 2);
      return Text('$panes');
    }

    await _pumpBuilder(tester, width: 400, compact: twoPane);
    expect(find.text('1'), findsOneWidget);

    await _pumpBuilder(tester, width: 1200, compact: twoPane);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('resizing reuses the compact tree so field text is not lost', (
    WidgetTester tester,
  ) async {
    await _pumpBuilder(tester, width: 400, compact: (_) => const TextField());
    await tester.enterText(find.byType(TextField), 'in progress');

    tester.view.physicalSize = const Size(800, 800);
    await tester.pump();

    expect(find.text('in progress'), findsOneWidget);
  });
}

Future<void> _pumpBuilder(
  WidgetTester tester, {
  required double width,
  required WidgetBuilder compact,
  WidgetBuilder? medium,
  WidgetBuilder? expanded,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ResponsiveBuilder(
          compact: compact,
          medium: medium,
          expanded: expanded,
        ),
      ),
    ),
  );
}
