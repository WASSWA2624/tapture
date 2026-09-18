import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';

import '../../support/a11y_matchers.dart';

void main() {
  testWidgets('an icon button is a 48dp labelled target with a tooltip', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const AppIconButton(
        icon: Icons.search,
        semanticLabel: 'Search',
        tooltip: 'Search records',
        onPressed: _ignorePress,
      ),
    );

    expect(find.byType(AppIconButton), meetsTapTarget());
    expect(find.byType(AppIconButton), hasSemanticLabel('Search'));
    expect(find.byTooltip('Search records'), findsOneWidget);
    await expectNoA11yIssues(tester);
  });

  testWidgets('a disabled icon button still names itself', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const AppIconButton(
        icon: Icons.delete,
        semanticLabel: 'Delete',
        tooltip: 'Delete',
      ),
    );

    expect(find.byType(AppIconButton), meetsTapTarget());
    expect(find.byType(AppIconButton), hasSemanticLabel('Delete'));
  });

  testWidgets('a toggle is announced as selected and filled while on', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const AppIconButton(
        icon: Icons.mic,
        semanticLabel: 'Stop speaking',
        tooltip: 'Stop speaking',
        selected: true,
        onPressed: _ignorePress,
      ),
    );
    final IconButton button = tester.widget<IconButton>(
      find.byType(IconButton),
    );
    expect(button.isSelected, isTrue);
    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{}),
      isNot(Colors.transparent),
    );
    expect(
      tester.getSemantics(find.byType(IconButton)),
      isSemantics(isSelected: true, label: 'Stop speaking'),
    );
    expect(find.byType(AppIconButton), meetsTapTarget());
    await expectNoA11yIssues(tester);
  });

  testWidgets('a plain action is not a toggle', (WidgetTester tester) async {
    await _pump(
      tester,
      const AppIconButton(
        icon: Icons.search,
        semanticLabel: 'Search',
        tooltip: 'Search',
        onPressed: _ignorePress,
      ),
    );
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).isSelected,
      isNull,
    );
  });

  testWidgets('an outlined-off icon button has no side', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const AppIconButton(
        icon: Icons.mic,
        semanticLabel: 'Speak',
        tooltip: 'Speak',
        outlined: false,
        onPressed: _ignorePress,
      ),
    );
    final IconButton button = tester.widget<IconButton>(
      find.byType(IconButton),
    );
    // The widget's side wins over the theme's outline.
    expect(button.style?.side?.resolve(<WidgetState>{}), BorderSide.none);
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

void _ignorePress() {}
