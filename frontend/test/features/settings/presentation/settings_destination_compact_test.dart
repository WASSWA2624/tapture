import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_page_layout_scope.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/features/settings/data/settings_store.dart';
import 'package:tapture/features/settings/domain/operator_profile.dart';
import 'package:tapture/features/settings/domain/setting_keys.dart';
import 'package:tapture/features/settings/presentation/about_screen.dart';
import 'package:tapture/features/settings/presentation/capture_settings_screen.dart';
import 'package:tapture/features/settings/presentation/operator_profile_screen.dart';

import '../../../support/a11y_matchers.dart';
import '../../../support/pump_app.dart';
import '../../../support/screen_fonts.dart';

void main() {
  setUpAll(ScreenFonts.loadForApp);

  testWidgets(
    'compact capture disclosures and failed naming save keep controls reachable at large text',
    (WidgetTester tester) async {
      _largeText(tester, const Size(393, 852));
      final SettingsStore store = SettingsStore.fake(failWrites: true);
      await pumpApp(
        tester,
        const CaptureSettingsScreen(),
        overrides: <Override>[captureSettingsOverride(store: store)],
        useScreenFonts: true,
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.text(Copy.settingsPhotoFiles));
      final Finder header = find.widgetWithText(
        AppSectionHeader,
        Copy.settingsPhotoFiles,
      );
      expect(header, meetsTapTarget());
      expect(
        find.text(Copy.settingsFolderStrategyNewFilesOnly),
        findsOneWidget,
      );
      final Finder naming = find.widgetWithText(
        AppListTile,
        Copy.settingsNamingPattern,
      );
      expect(tester.widget<AppListTile>(naming).wrapText, isTrue);
      await _tap(tester, naming);
      expect(
        tester.widget<AppBottomSheet>(find.byType(AppBottomSheet)).layout,
        AppPageLayout.compact,
      );
      await tester.enterText(find.byType(TextField), 'retained-{date}');
      final Finder save = find.byType(AppPrimaryAction);
      await tester.ensureVisible(save);
      expect(save, meetsTapTarget());
      await _tap(tester, save);
      expect(find.text('retained-{date}'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        store.read(SettingKeys.namingPattern),
        SettingKeys.namingPattern.defaultValue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact profile failure retains typed identity and reachable save in short landscape',
    (WidgetTester tester) async {
      _largeText(tester, const Size(852, 393));
      await pumpApp(
        tester,
        const OperatorProfileScreen(),
        overrides: <Override>[
          operatorProfileOverride(
            load: () async => const OperatorProfile(name: 'Ada', initials: 'A'),
            save: (_) async => const FailureResult<OperatorProfile>(
              StorageFailure(message: 'The profile could not be stored.'),
            ),
          ),
        ],
        useScreenFonts: true,
      );
      await tester.pumpAndSettle();
      final Finder name = find.byWidgetPredicate(
        (Widget widget) =>
            widget is AppTextField && widget.label == Copy.operatorName,
      );
      expect(
        AppPageLayoutScope.of(tester.element(name)),
        AppPageLayout.compact,
      );
      await tester.ensureVisible(name);
      await tester.enterText(
        find.descendant(of: name, matching: find.byType(TextField)),
        'Bea',
      );
      await tester.pumpAndSettle();
      final Finder save = find.byType(AppPrimaryAction);
      await tester.ensureVisible(save);
      expect(save, meetsTapTarget());
      expect(save.hitTestable(), findsOneWidget);
      await _tap(tester, save);
      expect(find.text('Bea'), findsOneWidget);
      expect(find.text('The profile could not be stored.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact About rows show complete metadata at large text and remain tappable',
    (WidgetTester tester) async {
      _largeText(tester, const Size(393, 852));
      const String version =
          'A long application version with verified local release metadata';
      await pumpApp(
        tester,
        const AboutScreen(),
        overrides: <Override>[
          aboutOverride(load: () async => (version: version, build: '42')),
        ],
        useScreenFonts: true,
      );
      await tester.pumpAndSettle();
      final Finder metadata = find.text(version);
      expect(tester.widget<Text>(metadata).maxLines, isNull);
      final Finder licences = find.widgetWithText(
        AppListTile,
        Copy.settingsLicences,
      );
      await tester.ensureVisible(licences);
      expect(licences, meetsTapTarget());
      expect(
        AppPageLayoutScope.of(tester.element(licences)),
        AppPageLayout.compact,
      );
      expect(find.text(Copy.settingsLicencesEffect), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _largeText(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}
