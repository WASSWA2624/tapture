import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/outdoor_theme.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_section_header.dart';

import '../../support/screen_matrix.dart';

void main() {
  for (final bool anchored in <bool>[false, true]) {
    testWidgets(
      'group headings preserve selection indices (anchored: $anchored)',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        try {
          for (int selected = 0; selected < 3; selected++) {
            final List<int> chosen = <int>[];
            await _pump(tester, chosen.add, anchored: anchored);
            await tester.tap(find.byKey(const ValueKey<String>('open')));
            await tester.pumpAndSettle();
            expect(find.byType(AppSectionHeader), findsNWidgets(2));
            final List<PopupMenuItem<int>> entries = tester
                .widgetList<PopupMenuItem<int>>(find.byType(PopupMenuItem<int>))
                .toList();
            expect(
              entries
                  .where((entry) => entry.enabled)
                  .map((entry) => entry.value),
              <int>[0, 1, 2],
            );
            for (final Element heading
                in find.byType(AppSectionHeader).evaluate()) {
              final SemanticsNode node = tester.getSemantics(
                find.byWidget(heading.widget),
              );
              expect(node.flagsCollection.isHeader, isTrue);
              expect(
                node.getSemanticsData().hasAction(SemanticsAction.tap),
                isFalse,
              );
            }
            await tester.tap(find.text('Capture and review'));
            await tester.pumpAndSettle();
            expect(chosen, isEmpty);
            expect(find.byType(AppSectionHeader), findsNWidgets(2));
            await tester.tap(find.byKey(ValueKey<String>('command-$selected')));
            await tester.pumpAndSettle();
            expect(chosen, <int>[selected]);
            expect(find.byType(AppSectionHeader), findsNothing);
          }
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets('keyboard traversal skips headings and Escape dismisses', (
    WidgetTester tester,
  ) async {
    final List<int> chosen = <int>[];
    await _pump(tester, chosen.add);
    await tester.tap(find.byKey(const ValueKey<String>('open')));
    await tester.pumpAndSettle();
    Focus.of(tester.element(find.text(_labels.first))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chosen, <int>[2]);
    expect(find.byType(AppSectionHeader), findsNothing);
    await tester.tap(find.byKey(const ValueKey<String>('open')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(chosen, <int>[2]);
    expect(find.byType(AppSectionHeader), findsNothing);
  });

  for (final TargetPlatform platform in TargetPlatform.values) {
    testWidgets(
      'grouped labels wrap across the matrix on ${platform.name}',
      (WidgetTester tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final ScreenMatrix cell in ScreenMatrix.cells) {
          final List<int> chosen = <int>[];
          await _pump(tester, chosen.add, cell: cell);
          await tester.tap(find.byKey(const ValueKey<String>('open')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: cell.description);
          for (int index = 0; index < _labels.length; index++) {
            final Finder item = find.byKey(ValueKey<String>('command-$index'));
            expect(
              tester.getSize(item).height,
              greaterThanOrEqualTo(Sizes.minTapTarget),
            );
            final RenderParagraph label = tester.renderObject<RenderParagraph>(
              find.text(_labels[index]),
            );
            expect(label.didExceedMaxLines, isFalse, reason: cell.description);
          }
          await tester.ensureVisible(find.text(_labels.last));
          await tester.pumpAndSettle();
          await tester.tap(find.text(_labels.last));
          await tester.pumpAndSettle();
          expect(chosen, <int>[2], reason: cell.description);
          expect(tester.takeException(), isNull, reason: cell.description);
        }
      },
      variant: TargetPlatformVariant.only(platform),
    );
  }
}

const List<String> _labels = <String>[
  'Transcribe',
  'Start meeting',
  'Configure the context hierarchy for this project',
];

Future<void> _pump(
  WidgetTester tester,
  void Function(int) selected, {
  bool anchored = false,
  ScreenMatrix? cell,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = cell?.size ?? const Size(400, 800);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final ThemeData theme = cell?.outdoor == true
      ? buildOutdoorTheme(Brightness.light)
      : buildTheme(brightness: cell?.brightness ?? Brightness.light);
  final List<AppOverflowAction> actions = <AppOverflowAction>[
    for (int index = 0; index < _labels.length; index++)
      AppOverflowAction(
        key: ValueKey<String>('command-$index'),
        sectionLabel: index < 2 ? 'Capture and review' : 'Project setup',
        label: _labels[index],
        onTap: () => selected(index),
      ),
  ];
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      theme: theme,
      builder: (BuildContext context, Widget? child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(cell?.textScale ?? 1)),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: Builder(
            builder: (BuildContext context) => anchored
                ? TextButton(
                    key: const ValueKey<String>('open'),
                    onPressed: () => unawaited(
                      showAppOverflowActions(
                        context,
                        anchor: const Rect.fromLTWH(300, 0, 48, 48),
                        items: actions,
                      ),
                    ),
                    child: const Text('Open'),
                  )
                : AppOverflowMenu(
                    key: const ValueKey<String>('open'),
                    items: actions,
                  ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
