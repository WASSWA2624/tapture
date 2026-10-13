import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section.dart';

import '../../../support/pump_app.dart';
import '../../../support/screen_fonts.dart';
import '../fakes/fake_template_repository.dart';
import 'template_sectioned_fixtures.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);

  for (final Size size in <Size>[
    const Size(320, 640),
    const Size(390, 844),
    const Size(390, 300),
    const Size(800, 1280),
    const Size(800, 500),
    const Size(1200, 1600),
    const Size(1200, 800),
  ]) {
    for (final double scale in <double>[1, 2]) {
      for (final ({String name, Widget screen, bool preview}) view
          in sectionedViews()) {
        testWidgets(
          '${view.name} keeps sectioned content reachable at $size x$scale',
          (WidgetTester tester) async {
            final FakeTemplateRepository templates = FakeTemplateRepository();
            addTearDown(templates.dispose);
            await templates.save(sectionedTemplate());
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = size;
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            final SemanticsHandle semantics = tester.ensureSemantics();
            try {
              await pumpApp(
                tester,
                view.screen,
                useScreenFonts: true,
                overrides: sectionedOverrides(templates),
              );
              await tester.pumpAndSettle();
              if (view.preview) {
                await tester.enterText(
                  find.byType(EditableText),
                  sectionedTemplateName,
                );
                await tester.pumpAndSettle();
                final Finder row = find.widgetWithText(
                  AppListTile,
                  sectionedTemplateName,
                );
                await _reveal(tester, row);
                await _tapVisible(tester, row);
                await tester.pumpAndSettle();
              }
              if (view.name == 'Required columns') {
                final Finder expand = find.text(Copy.requiredColumnShowGroup);
                await _reveal(tester, expand);
                await _tapVisible(tester, expand);
                await tester.pumpAndSettle();
                expect(find.text(Copy.requiredColumnHideGroup), findsOneWidget);
              }
              if (view.name == 'Aliases' ||
                  view.name == 'Spreadsheet mapping') {
                final Finder row = find.byKey(
                  ValueKey<String>(
                    view.name == 'Aliases' ? 'alias-asset' : 'xlsx-col-0',
                  ),
                );
                await _reveal(tester, row);
                await _tapVisible(tester, row);
                await tester.pumpAndSettle();
                expect(find.byType(EditableText), findsWidgets);
              }
              expect(
                tester.widget<AppPage>(find.byType(AppPage)).layout,
                AppPageLayout.sectioned,
              );
              expect(find.byType(AppSection), findsWidgets);
              expect(tester.takeException(), isNull);
              final Finder scrollable = find.byType(Scrollable).first;
              await tester.drag(scrollable, const Offset(0, -500));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(templates.count, 1);
            } finally {
              semantics.dispose();
            }
          },
        );
      }
    }
  }
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder target) async {
  final Rect visible = tester
      .getRect(target)
      .intersect(tester.getRect(find.byType(Scrollable).first));
  expect(visible.isEmpty, isFalse);
  await tester.tapAt(visible.center);
}
