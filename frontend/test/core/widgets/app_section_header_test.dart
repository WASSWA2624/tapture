import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';

import '../../support/a11y_matchers.dart';

void main() {
  testWidgets('default section headings keep their two-line limit', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const AppSectionHeader(title: 'Records'));
    final Text title = tester.widget<Text>(find.text('Records'));
    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);
  });

  for (final bool collapsible in <bool>[false, true]) {
    testWidgets('wrapped long headings remain complete at text 2 '
        'with collapsible=$collapsible', (WidgetTester tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      const String title =
          'A long section name that must remain fully readable';
      bool toggled = false;
      await _pump(
        tester,
        AppSectionHeader(
          title: title,
          wrapText: true,
          expanded: collapsible ? false : null,
          onToggle: collapsible ? () => toggled = true : null,
        ),
      );
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text(title), matching: find.byType(RichText)),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(find.byType(AppSectionHeader), meetsTapTarget());
      expect(find.byType(AppSectionHeader), hasSemanticLabel(title));
      expect(tester.takeException(), isNull);
      if (collapsible) {
        expect(find.byType(AppSectionHeader).hitTestable(), findsOneWidget);
        await tester.tap(find.byType(AppSectionHeader));
        await tester.pumpAndSettle();
        expect(toggled, isTrue);
      }
    });
  }

  testWidgets('the heading and optional action both render', (
    WidgetTester tester,
  ) async {
    bool pressed = false;
    await _pump(
      tester,
      AppSectionHeader(
        title: 'Records',
        action: AppIconButton(
          icon: Icons.filter_list,
          semanticLabel: 'Filter records',
          tooltip: 'Filter records',
          onPressed: () => pressed = true,
        ),
      ),
    );

    expect(find.text('Records'), findsOneWidget);
    expect(find.byType(AppSectionHeader), hasSemanticLabel('Records'));
    await tester.tap(find.byTooltip('Filter records'));
    await tester.pump();
    expect(pressed, isTrue);
  });

  testWidgets('a collapsible heading toggles and says whether it is open', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    bool open = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AppSectionHeader(
                title: 'Assets',
                expanded: open,
                onToggle: () => setState(() => open = !open),
              );
            },
          ),
        ),
      ),
    );

    expect(find.byIcon(AppIcons.expand), findsOneWidget);
    expect(find.byType(AppSectionHeader), meetsTapTarget());
    expect(
      tester.getSemantics(find.byType(AppSectionHeader)),
      matchesSemantics(
        label: 'Assets',
        isHeader: true,
        isButton: true,
        hasExpandedState: true,
        isExpanded: false,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.byType(AppSectionHeader));
    await tester.pump();
    expect(open, isTrue);
    expect(find.byIcon(AppIcons.collapse), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(AppSectionHeader)),
      matchesSemantics(
        label: 'Assets',
        isHeader: true,
        isButton: true,
        hasExpandedState: true,
        isExpanded: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('a plain heading has no toggle glyph', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const AppSectionHeader(title: 'Records'));
    expect(find.byIcon(AppIcons.expand), findsNothing);
    expect(find.byIcon(AppIcons.collapse), findsNothing);
  });

  testWidgets('the heading stays usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness: Brightness.light),
        home: const AppPage(
          title: 'Header',
          body: AppSectionHeader(
            title: 'A long section name that must wrap rather than clip',
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await expectNoA11yIssues(tester);
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
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(Space.x4), child: child),
      ),
    ),
  );
}
