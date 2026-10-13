import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_action_dock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_page_layout_scope.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';

import '../../support/pump_app.dart';
import '../../support/screen_fonts.dart';
import '../../support/screen_matrix.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);

  for (final AppPageLayout layout in AppPageLayout.values) {
    for (final ScreenMatrix cell in ScreenMatrix.cells) {
      testWidgets(
        '${layout.name} keeps actions reachable in ${cell.description}',
        (WidgetTester tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = cell.size;
          tester.platformDispatcher.textScaleFactorTestValue = cell.textScale;
          addTearDown(() {
            tester.view.resetDevicePixelRatio();
            tester.view.resetPhysicalSize();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });
          await pumpApp(
            tester,
            _sample(layout),
            brightness: cell.brightness,
            outdoor: cell.outdoor,
            useScreenFonts: true,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final Finder save = find.byType(AppPrimaryAction);
          await tester.ensureVisible(save);
          await tester.pump();
          expect(
            tester.getSize(save).height,
            greaterThanOrEqualTo(Sizes.minTapTarget),
          );
          expect(save.hitTestable(), findsOneWidget);
          expect(
            AppPageLayoutScope.of(tester.element(find.byType(AppListTile))),
            layout,
          );
        },
      );
    }
  }

  testWidgets(
    'readable rows put complete metadata and actions after the title',
    (WidgetTester tester) async {
      await pumpApp(
        tester,
        _sample(AppPageLayout.readingFirst),
        useScreenFonts: true,
      );
      await tester.pumpAndSettle();
      final double title = tester
          .getBottomLeft(find.text('A long field label that stays readable'))
          .dy;
      expect(
        tester.getTopLeft(find.text('Captured source and value')).dy,
        greaterThan(title),
      );
      expect(
        tester.getTopLeft(find.text('Edit')).dy,
        greaterThan(
          tester.getBottomLeft(find.text('Captured source and value')).dy,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'grouped nested text fields retain errors and the dirty guard after a failed save',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => Scaffold(
            body: AppButton(
              label: 'Open',
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => AppPage(
                    title: 'Edit',
                    layout: AppPageLayout.sectioned,
                    scrollable: false,
                    body: AppForm(
                      guardUnsaved: true,
                      fields: <Widget>[
                        AppSection(
                          title: 'Details',
                          children: <Widget>[
                            AppTextField(
                              label: 'Name',
                              controller: controller,
                              errorText: 'Required',
                              dictation: false,
                            ),
                          ],
                        ),
                      ],
                      submitLabel: 'Save',
                      onSubmit: () async => false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        useScreenFonts: true,
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Name: Required'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Retained value');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(controller.text, 'Retained value');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
    },
  );

  testWidgets(
    'short action docks scroll every command without hiding the body',
    (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: SizedBox(
            height: 120,
            child: Align(
              alignment: Alignment.topCenter,
              child: AppActionDock(
                maxHeight: 80,
                child: Column(
                  children: <Widget>[
                    AppButton(label: 'First'),
                    AppButton(label: 'Last'),
                  ],
                ),
              ),
            ),
          ),
        ),
        useScreenFonts: true,
      );
      expect(
        tester.getSize(find.byType(AppActionDock)).height,
        lessThanOrEqualTo(80),
      );
      await tester.ensureVisible(find.text('Last'));
      await tester.pump();
      expect(find.text('Last').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _sample(AppPageLayout layout) => AppPage(
  title: 'Project',
  layout: layout,
  footer: const AppPrimaryAction(label: 'Save', onPressed: _noop),
  body: const AppSection(
    title: 'Fields',
    children: <Widget>[
      AppListTile(
        title: 'A long field label that stays readable',
        subtitle: 'Captured source and value',
        leading: Icon(AppIcons.records),
        wrapText: true,
        status: AppStatusPill(status: RecordStatus.needsReview),
        trailing: AppButton(
          label: 'Edit',
          variant: AppButtonVariant.secondary,
          onPressed: _noop,
        ),
        onTap: _noop,
      ),
    ],
  ),
);

void _noop() {}
