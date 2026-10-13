import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section.dart';
import 'package:tapture/core/widgets/app_section_header.dart';

import '../../support/pump_app.dart';
import '../../support/screen_fonts.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);

  testWidgets(
    'section headings remain readable and accessible at 200 percent',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 500);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      const String title = 'Project settings and captured record defaults';
      bool opened = false;
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await pumpApp(
          tester,
          AppPage(
            title: 'Project',
            layout: AppPageLayout.sectioned,
            body: AppSection(
              title: title,
              children: <Widget>[
                AppButton(label: 'Open', onPressed: () => opened = true),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        final Finder heading = find.byType(AppSectionHeader);
        final SemanticsNode node = tester.getSemantics(heading);
        expect(node.label, title);
        expect(node.flagsCollection.isHeader, isTrue);
        final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.text(title),
            matching: find.byType(RichText),
          ),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
          tester.getBottomLeft(find.text(title)).dy,
          lessThan(tester.getTopLeft(find.byType(AppButton)).dy),
        );
        await tester.ensureVisible(find.byType(AppButton));
        await tester.pump();
        await tester.tap(find.text('Open'));
        await tester.pump();
        expect(opened, isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'nested section layouts preserve command order and outer sizing',
    (WidgetTester tester) async {
      final List<String> commands = <String>[];
      await pumpApp(
        tester,
        AppPage(
          title: 'Project',
          layout: AppPageLayout.sectioned,
          body: AppSection(
            title: 'Actions',
            children: <Widget>[
              AppPrimaryAction(
                label: 'First',
                onPressed: () => commands.add('First'),
              ),
              AppSection(
                layout: AppPageLayout.thumbReach,
                children: <Widget>[
                  AppPrimaryAction(
                    label: 'Middle',
                    onPressed: () => commands.add('Middle'),
                  ),
                ],
              ),
              AppPrimaryAction(
                label: 'Last',
                onPressed: () => commands.add('Last'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Finder first = find.widgetWithText(AppPrimaryAction, 'First');
      final Finder middle = find.widgetWithText(AppPrimaryAction, 'Middle');
      final Finder last = find.widgetWithText(AppPrimaryAction, 'Last');
      expect(tester.getSize(first).height, Sizes.controlHeight);
      expect(tester.getSize(middle).height, Sizes.primaryActionHeight);
      expect(tester.getSize(last).height, Sizes.controlHeight);
      expect(
        tester.getBottomLeft(first).dy,
        lessThan(tester.getTopLeft(middle).dy),
      );
      expect(
        tester.getBottomLeft(middle).dy,
        lessThan(tester.getTopLeft(last).dy),
      );
      for (final Finder command in <Finder>[first, middle, last]) {
        await tester.tap(command);
        await tester.pump();
      }
      expect(commands, <String>['First', 'Middle', 'Last']);
      expect(tester.takeException(), isNull);
    },
  );
}
