import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/widgets/app_page_layout.dart';
import 'package:tapture/core/widgets/app_page_layout_scope.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';

import '../../support/pump_app.dart';
import '../../support/screen_fonts.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);

  testWidgets(
    'standalone actions use Essentials and nested scopes override it',
    (WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(
          body: Column(
            children: <Widget>[
              AppPrimaryAction(label: 'Default', onPressed: _noop),
              AppPageLayoutScope(
                layout: AppPageLayout.thumbReach,
                child: Column(
                  children: <Widget>[
                    AppPrimaryAction(label: 'Outer', onPressed: _noop),
                    AppPageLayoutScope(
                      layout: AppPageLayout.essentials,
                      child: AppPrimaryAction(label: 'Inner', onPressed: _noop),
                    ),
                    AppPrimaryAction(label: 'After', onPressed: _noop),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getSize(find.widgetWithText(AppPrimaryAction, 'Default')).height,
        Sizes.controlHeight,
      );
      expect(
        tester.getSize(find.widgetWithText(AppPrimaryAction, 'Outer')).height,
        Sizes.primaryActionHeight,
      );
      expect(
        tester.getSize(find.widgetWithText(AppPrimaryAction, 'Inner')).height,
        Sizes.controlHeight,
      );
      expect(
        tester.getSize(find.widgetWithText(AppPrimaryAction, 'After')).height,
        Sizes.primaryActionHeight,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'changing layout updates retained descendants without losing a draft',
    (WidgetTester tester) async {
      final ValueNotifier<AppPageLayout> layout = ValueNotifier<AppPageLayout>(
        AppPageLayout.essentials,
      );
      final TextEditingController controller = TextEditingController();
      addTearDown(layout.dispose);
      addTearDown(controller.dispose);
      String? submitted;
      final Widget content = Column(
        children: <Widget>[
          AppTextField(label: 'Name', controller: controller, dictation: false),
          AppPrimaryAction(
            label: 'Save',
            onPressed: () => submitted = controller.text,
          ),
        ],
      );
      await pumpApp(
        tester,
        Scaffold(
          body: ValueListenableBuilder<AppPageLayout>(
            valueListenable: layout,
            child: content,
            builder:
                (BuildContext context, AppPageLayout value, Widget? child) =>
                    AppPageLayoutScope(layout: value, child: child!),
          ),
        ),
      );
      final Finder save = find.widgetWithText(AppPrimaryAction, 'Save');
      final Element input = tester.element(find.byType(AppTextField));
      await tester.enterText(find.byType(TextField), 'Retained value');
      expect(tester.getSize(save).height, Sizes.controlHeight);
      layout.value = AppPageLayout.thumbReach;
      await tester.pump();
      expect(tester.getSize(save).height, Sizes.primaryActionHeight);
      expect(tester.element(find.byType(AppTextField)), same(input));
      expect(controller.text, 'Retained value');
      layout.value = AppPageLayout.compact;
      await tester.pump();
      expect(tester.getSize(save).height, Sizes.controlHeight);
      expect(tester.element(find.byType(AppTextField)), same(input));
      await tester.tap(save);
      await tester.pump();
      expect(submitted, 'Retained value');
      expect(tester.takeException(), isNull);
    },
  );
}

void _noop() {}
