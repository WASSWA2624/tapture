import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_page_layout_scope.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_email_field.dart';
import 'package:tapture/core/widgets/fields/app_phone_field.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';

import '../../support/a11y_matchers.dart';
import '../../support/pump_app.dart';
import '../../support/screen_fonts.dart';
import '../../support/screen_probe.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);

  testWidgets('compact fields wrap complete required and optional labels', (
    WidgetTester tester,
  ) async {
    _viewport(tester, const Size(320, 640), scale: 2);
    final TextEditingController email = TextEditingController();
    final TextEditingController phone = TextEditingController();
    addTearDown(email.dispose);
    addTearDown(phone.dispose);
    await pumpApp(
      tester,
      AppPage(
        title: 'Settings',
        layout: AppPageLayout.compact,
        scrollable: false,
        body: AppForm(
          fields: <Widget>[
            AppEmailField(
              label: 'Account email address',
              controller: email,
              requiredness: FieldRequiredness.required,
            ),
            AppPhoneField(
              label: 'Operator phone number',
              controller: phone,
              requiredness: FieldRequiredness.optional,
            ),
          ],
          submitLabel: 'Save',
          onSubmit: () async => true,
        ),
      ),
      useScreenFonts: true,
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppPrimaryAction).hitTestable(), findsOneWidget);
    expect(ScreenProbe.layoutIssues(tester), isEmpty);
  });

  for (final bool checkbox in <bool>[false, true]) {
    for (final double scale in <double>[1, 2]) {
      for (final ({Brightness brightness, bool outdoor}) theme
          in <({Brightness brightness, bool outdoor})>[
            (brightness: Brightness.light, outdoor: false),
            (brightness: Brightness.dark, outdoor: false),
            (brightness: Brightness.light, outdoor: true),
          ]) {
        testWidgets(
          'compact ${checkbox ? 'checkbox' : 'switch'} keeps its explanation '
          'readable and toggles at text $scale ${theme.brightness.name} '
          'outdoor=${theme.outdoor}',
          (WidgetTester tester) async {
            _viewport(tester, const Size(320, 640), scale: scale);
            const String title = 'Auto-fill dates and times';
            const String description =
                'New captures keep today’s date and the time they were made.';
            bool value = false;
            await pumpApp(
              tester,
              AppPage(
                title: 'Settings',
                layout: AppPageLayout.compact,
                body: StatefulBuilder(
                  builder: (BuildContext context, StateSetter update) =>
                      checkbox
                      ? AppSwitchTile.checkbox(
                          title: title,
                          description: description,
                          value: value,
                          onChanged: (bool next) => update(() => value = next),
                        )
                      : AppSwitchTile(
                          title: title,
                          description: description,
                          value: value,
                          onChanged: (bool next) => update(() => value = next),
                        ),
                ),
              ),
              brightness: theme.brightness,
              outdoor: theme.outdoor,
              useScreenFonts: true,
            );
            await tester.pumpAndSettle();
            final Finder tile = find.byType(AppSwitchTile);
            expect(tile, meetsTapTarget());
            expect(tile, hasSemanticLabel(title));
            expect(find.text(description), findsOneWidget);
            final Text label = tester.widget<Text>(find.text(title));
            expect(label.style!.fontSize, AppText.label.fontSize);
            for (final String text in <String>[title, description]) {
              final RenderParagraph paragraph = tester
                  .renderObject<RenderParagraph>(
                    find.descendant(
                      of: find.text(text),
                      matching: find.byType(RichText),
                    ),
                  );
              expect(paragraph.didExceedMaxLines, isFalse);
            }
            expect(
              tester
                  .getRect(tile)
                  .contains(
                    tester.getRect(find.text(description)).bottomCenter,
                  ),
              isTrue,
            );
            await tester.tap(find.text(description));
            await tester.pump();
            expect(value, isTrue);
            await tester.tap(find.text(title));
            await tester.pump();
            expect(value, isFalse);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'inherited compact forms match explicit spacing and retain edited values',
    (WidgetTester tester) async {
      _viewport(tester, const Size(393, 852));
      final ValueNotifier<({AppPageLayout layout, bool compact})> mode =
          ValueNotifier<({AppPageLayout layout, bool compact})>((
            layout: AppPageLayout.essentials,
            compact: false,
          ));
      final TextEditingController name = TextEditingController();
      final TextEditingController initials = TextEditingController();
      addTearDown(mode.dispose);
      addTearDown(name.dispose);
      addTearDown(initials.dispose);
      String? saved;
      await pumpApp(
        tester,
        ValueListenableBuilder<({AppPageLayout layout, bool compact})>(
          valueListenable: mode,
          builder: (BuildContext context, value, Widget? child) => AppPage(
            title: 'Profile',
            scrollable: false,
            layout: value.layout,
            body: AppForm(
              compact: value.compact,
              fields: <Widget>[
                AppTextField(label: 'Name', controller: name, dictation: false),
                AppTextField(
                  label: 'Initials',
                  controller: initials,
                  dictation: false,
                ),
              ],
              submitLabel: 'Save',
              onSubmit: () async {
                saved = '${name.text} (${initials.text})';
                return true;
              },
            ),
          ),
        ),
        useScreenFonts: true,
      );
      await tester.enterText(find.byType(TextField).first, 'Ada Lovelace');
      await tester.enterText(find.byType(TextField).last, 'AL');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final Element retained = tester.element(find.byType(AppTextField).first);
      final double regularTop = _fieldRect(tester, 0).top;
      mode.value = (layout: AppPageLayout.essentials, compact: true);
      await tester.pumpAndSettle();
      final Rect explicitFirst = _fieldRect(tester, 0);
      final Rect explicitLast = _fieldRect(tester, 1);
      final Rect explicitSubmit = tester.getRect(find.byType(AppPrimaryAction));
      expect(explicitFirst.top, lessThan(regularTop));
      expect(explicitLast.top - explicitFirst.bottom, Space.x2);
      mode.value = (layout: AppPageLayout.compact, compact: false);
      await tester.pumpAndSettle();
      expect(_fieldRect(tester, 0), explicitFirst);
      expect(_fieldRect(tester, 1), explicitLast);
      expect(tester.getRect(find.byType(AppPrimaryAction)), explicitSubmit);
      expect(tester.element(find.byType(AppTextField).first), same(retained));
      expect(name.text, 'Ada Lovelace');
      expect(initials.text, 'AL');
      expect(find.byType(AppPrimaryAction), meetsTapTarget());
      await tester.tap(find.byType(AppPrimaryAction));
      await tester.pumpAndSettle();
      expect(saved, 'Ada Lovelace (AL)');
      expect(tester.takeException(), isNull);
    },
  );

  for (final bool collapsible in <bool>[false, true]) {
    testWidgets(
      'compact ${collapsible ? 'disclosures' : 'headings'} inherit dense '
      'spacing while keeping large text complete',
      (WidgetTester tester) async {
        _viewport(tester, const Size(320, 640), scale: 2);
        bool toggled = false;
        const String title = 'Photo files and naming';
        Widget heading({required bool dense}) => AppSectionHeader(
          title: title,
          dense: dense,
          wrapText: true,
          expanded: collapsible ? false : null,
          onToggle: collapsible ? () => toggled = true : null,
        );
        await pumpApp(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  AppPageLayoutScope(
                    layout: AppPageLayout.compact,
                    child: heading(dense: false),
                  ),
                  AppPageLayoutScope(
                    layout: AppPageLayout.essentials,
                    child: heading(dense: true),
                  ),
                ],
              ),
            ),
          ),
          useScreenFonts: true,
        );
        final Finder headings = find.byType(AppSectionHeader);
        final Finder titles = find.text(title);
        expect(tester.getSize(headings.first), tester.getSize(headings.last));
        expect(
          tester.getTopLeft(titles.first).dy -
              tester.getTopLeft(headings.first).dy,
          tester.getTopLeft(titles.last).dy -
              tester.getTopLeft(headings.last).dy,
        );
        for (final Element element in titles.evaluate()) {
          final RenderParagraph paragraph = tester.renderObject(
            find.descendant(
              of: find.byElementPredicate((Element e) => identical(e, element)),
              matching: find.byType(RichText),
            ),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
        }
        if (collapsible) {
          expect(headings.first, meetsTapTarget());
          await tester.tap(headings.first);
          await tester.pump();
          expect(toggled, isTrue);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final Size size in <Size>[const Size(393, 852), const Size(1100, 800)]) {
    for (final AppPageLayout page in AppPageLayout.values) {
      testWidgets(
        'unspecified sheets inherit only compact from ${page.name} at $size',
        (WidgetTester tester) async {
          await _openSheet(tester, size: size, page: page);
          expect(
            AppPageLayoutScope.of(tester.element(find.text('Sheet content'))),
            page == AppPageLayout.compact
                ? AppPageLayout.compact
                : AppPageLayout.essentials,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
    for (final ({AppPageLayout page, AppPageLayout sheet}) selection
        in <({AppPageLayout page, AppPageLayout sheet})>[
          (page: AppPageLayout.compact, sheet: AppPageLayout.essentials),
          (page: AppPageLayout.essentials, sheet: AppPageLayout.compact),
          (page: AppPageLayout.compact, sheet: AppPageLayout.readingFirst),
          (page: AppPageLayout.readingFirst, sheet: AppPageLayout.compact),
        ]) {
      testWidgets('explicit ${selection.sheet.name} sheets override '
          '${selection.page.name} at $size', (WidgetTester tester) async {
        await _openSheet(
          tester,
          size: size,
          page: selection.page,
          override: selection.sheet,
        );
        expect(
          AppPageLayoutScope.of(tester.element(find.text('Sheet content'))),
          selection.sheet,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}

void _viewport(WidgetTester tester, Size size, {double scale = 1}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}

Rect _fieldRect(WidgetTester tester, int index) =>
    tester.getRect(find.byType(AppTextField).at(index));

Future<void> _openSheet(
  WidgetTester tester, {
  required Size size,
  required AppPageLayout page,
  AppPageLayout? override,
}) async {
  _viewport(tester, size);
  await pumpApp(
    tester,
    AppPage(
      title: 'Settings',
      layout: page,
      body: Builder(
        builder: (BuildContext context) => AppButton(
          label: 'Open',
          onPressed: () {
            if (override == null) {
              showAppSheet<void>(
                context,
                title: 'Choose a value',
                builder: (BuildContext _) => const Text('Sheet content'),
              );
            } else {
              showAppSheet<void>(
                context,
                title: 'Choose a value',
                layout: override,
                builder: (BuildContext _) => const Text('Sheet content'),
              );
            }
          },
        ),
      ),
    ),
    useScreenFonts: true,
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}
