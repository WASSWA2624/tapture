import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/forms/app_form.dart';

import '../support/a11y_matchers.dart';
import '../support/pump_app.dart';
import '../support/screen_fonts.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);

  for (final ({String name, Brightness brightness, bool outdoor}) theme
      in <({String name, Brightness brightness, bool outdoor})>[
        (name: 'light', brightness: Brightness.light, outdoor: false),
        (name: 'dark', brightness: Brightness.dark, outdoor: false),
        (name: 'outdoor', brightness: Brightness.light, outdoor: true),
      ]) {
    testWidgets('compact settings catalogue in ${theme.name}', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 852);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      });
      await pumpApp(
        tester,
        const _CompactCatalogue(),
        brightness: theme.brightness,
        outdoor: theme.outdoor,
        useScreenFonts: true,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(AppPage),
        matchesGoldenFile('goldens/compact_settings_${theme.name}.png'),
      );
      await expectNoA11yIssues(tester);
    });
  }
}

class _CompactCatalogue extends StatefulWidget {
  const _CompactCatalogue();

  @override
  State<_CompactCatalogue> createState() => _CompactCatalogueState();
}

class _CompactCatalogueState extends State<_CompactCatalogue> {
  final TextEditingController _name = TextEditingController(text: 'Ada');
  final TextEditingController _initials = TextEditingController(text: 'AL');

  @override
  void dispose() {
    _name.dispose();
    _initials.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Settings',
    leading: const Icon(AppIcons.settings),
    layout: AppPageLayout.compact,
    body: AppSection(
      title: 'Capture defaults',
      children: <Widget>[
        const AppSwitchTile(
          title: 'Auto-fill dates and times',
          description: 'Use today’s date and the capture time.',
          value: true,
          onChanged: _ignore,
        ),
        const AppSwitchTile(
          title: 'GPS capture',
          description: 'Include location only when enabled.',
          value: false,
          onChanged: _ignore,
        ),
        const AppSwitchTile(
          title: 'Disabled setting',
          description: 'The explanation stays visible.',
          value: false,
          enabled: false,
          onChanged: _ignore,
        ),
        AppForm(
          fields: <Widget>[
            AppSection(
              title: 'Operator profile',
              children: <Widget>[
                AppTextField(
                  label: 'Name',
                  controller: _name,
                  dictation: false,
                ),
                AppTextField(
                  label: 'Initials',
                  controller: _initials,
                  dictation: false,
                ),
              ],
            ),
          ],
          submitLabel: 'Save',
          onSubmit: () async => true,
        ),
      ],
    ),
  );
}

void _ignore(bool _) {}
