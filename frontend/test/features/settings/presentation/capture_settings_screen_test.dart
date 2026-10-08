import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';
import 'package:tapture/features/settings/data/settings_store.dart';
import 'package:tapture/features/settings/domain/setting_keys.dart';
import 'package:tapture/features/settings/presentation/capture_settings_screen.dart';

import '../../../support/screen_fonts.dart';
import '../../../support/screen_matrix.dart';

void main() {
  setUpAll(ScreenFonts.load);
  testWidgets(
    'primary controls remain visible and advanced groups start closed',
    (WidgetTester tester) async {
      final SettingsStore store = SettingsStore.fake();
      await _pump(tester, store: store);
      expect(find.text(Copy.settingsCamera), findsOneWidget);
      expect(find.text(Copy.settingsAutoFillDates), findsOneWidget);
      expect(find.text(Copy.gpsPrivacyCapture), findsOneWidget);
      expect(find.text(Copy.settingsGpsWhyOff), findsOneWidget);
      expect(find.text(Copy.settingsPhotoQuality), findsNothing);
      expect(find.text(Copy.settingsContextAutoClear), findsNothing);
      expect(
        find.text(
          Copy.settingsPhotoFilesSummary(
            Copy.settingsQualityStandard,
            Copy.settingsFolderByContext,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          Copy.settingsProjectContextsSummary(Copy.projectOff, Copy.projectOff),
        ),
        findsOneWidget,
      );
      await _tap(tester, find.text(Copy.gpsPrivacyCapture));
      expect(store.read(SettingKeys.gpsEnabled), isTrue);
      await _tap(tester, find.text(Copy.settingsPhotoFiles));
      expect(
        find.text(Copy.settingsFolderStrategyNewFilesOnly),
        findsOneWidget,
      );
      expect(find.text(Copy.settingsNamingPattern), findsOneWidget);
      expect(find.text(Copy.settingsQualitySmaller), findsNothing);
      await _tap(tester, find.text(Copy.settingsQualityStandard));
      await _tap(tester, find.text(Copy.settingsQualitySmaller).last);
      expect(
        store.read(SettingKeys.photoQuality),
        isNot(SettingKeys.photoQuality.defaultValue),
      );
      await _tap(tester, find.text(Copy.settingsFolderByContext));
      await _tap(tester, find.text(Copy.settingsFolderByTemplate).last);
      expect(store.read(SettingKeys.folderStrategy), 'byTemplate');
      await _tap(tester, find.text(Copy.settingsPhotoFiles));
      expect(
        find.text(
          Copy.settingsPhotoFilesSummary(
            Copy.settingsQualitySmaller,
            Copy.settingsFolderByTemplate,
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('conditional context selectors preserve hidden values', (
    WidgetTester tester,
  ) async {
    final SettingsStore store = SettingsStore.fake(
      stored: <String, Object?>{
        SettingKeys.contextAutoClearSeconds.name: 900,
        SettingKeys.contextMovementMetres.name: 250,
      },
    );
    await _pump(tester, store: store);
    await _tap(tester, find.text(Copy.settingsProjectContexts));
    expect(find.text(Copy.settingsContextIdle), findsNothing);
    expect(find.text(Copy.settingsContextDistance), findsNothing);
    await _tap(tester, find.text(Copy.settingsContextAutoClear));
    expect(find.text(Copy.settingsContextIdleOption(15)), findsOneWidget);
    await _tap(tester, find.text(Copy.settingsContextMovement));
    expect(find.text(Copy.settingsContextDistanceOption(250)), findsOneWidget);
    await _tap(tester, find.text(Copy.settingsContextAutoClear));
    await _tap(tester, find.text(Copy.settingsContextMovement));
    expect(find.text(Copy.settingsContextIdle), findsNothing);
    expect(find.text(Copy.settingsContextDistance), findsNothing);
    expect(store.read(SettingKeys.contextAutoClearSeconds), 900);
    expect(store.read(SettingKeys.contextMovementMetres), 250);
    await _tap(tester, find.text(Copy.settingsProjectContexts));
    await _tap(tester, find.text(Copy.settingsProjectContexts));
    expect(store.read(SettingKeys.contextAutoClearSeconds), 900);
    expect(store.read(SettingKeys.contextMovementMetres), 250);
  });

  testWidgets('failed choice writes retain selection and show the failure', (
    WidgetTester tester,
  ) async {
    final SettingsStore store = SettingsStore.fake(failWrites: true);
    await _pump(tester, store: store);
    await _tap(tester, find.text(Copy.settingsPhotoFiles));
    await _tap(tester, find.text(Copy.settingsQualityStandard));
    await _tap(tester, find.text(Copy.settingsQualitySmaller).last);
    expect(
      store.read(SettingKeys.photoQuality),
      SettingKeys.photoQuality.defaultValue,
    );
    expect(find.text(Copy.settingsQualityStandard), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('failed naming write retains the open form and typed value', (
    WidgetTester tester,
  ) async {
    final SettingsStore store = SettingsStore.fake(failWrites: true);
    await _pump(tester, store: store);
    await _tap(tester, find.text(Copy.settingsPhotoFiles));
    await _tap(tester, find.text(Copy.settingsNamingPattern));
    await tester.enterText(find.byType(TextField), 'retained-{date}');
    await _tap(tester, find.text(Copy.save));
    expect(find.text(Copy.settingsNamingEdit), findsOneWidget);
    expect(find.text('retained-{date}'), findsOneWidget);
    expect(
      store.read(SettingKeys.namingPattern),
      SettingKeys.namingPattern.defaultValue,
    );
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('expanded groups survive resize but close after leaving', (
    WidgetTester tester,
  ) async {
    await _pump(tester, store: SettingsStore.fake());
    await _tap(tester, find.text(Copy.settingsPhotoFiles));
    tester.view.physicalSize = const Size(800, 600);
    await tester.pumpAndSettle();
    expect(find.text(Copy.settingsPhotoQuality), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await _pump(tester, store: SettingsStore.fake());
    expect(find.text(Copy.settingsPhotoQuality), findsNothing);
  });

  testWidgets('loading renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(tester, pending: true);
    expect(find.byType(AppSkeleton), findsOneWidget);
  });
  testWidgets('an empty snapshot renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(tester, store: SettingsStore.fake(), missing: true);
    expect(find.byType(AppEmptyState), findsOneWidget);
  });
  testWidgets('a failed load renders through AsyncValueView', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      failWith: Exception('Capture defaults could not be read.'),
    );
    expect(find.byType(AppErrorState), findsOneWidget);
  });

  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets(
      'capture disclosures fit ${cell.description}',
      (WidgetTester tester) async {
        await _pump(tester, store: SettingsStore.fake(), cell: cell);
        expect(tester.takeException(), isNull);
        if (cell.size == const Size(393, 852) &&
            Theme.of(
                  tester.element(find.byType(CaptureSettingsScreen)),
                ).platform ==
                TargetPlatform.android) {
          await expectLater(
            find.byKey(_golden),
            matchesGoldenFile(
              'goldens/capture_collapsed_${cell.outdoor ? 'outdoor' : cell.brightness.name}_${cell.textScale.toInt()}x.png',
            ),
          );
        }
        if (cell.goldenCorner case final String corner
            when Theme.of(
                  tester.element(find.byType(CaptureSettingsScreen)),
                ).platform ==
                TargetPlatform.android) {
          await expectLater(
            find.byKey(_golden),
            matchesGoldenFile(
              'goldens/capture_collapsed_${corner}_${cell.outdoor ? 'outdoor' : cell.brightness.name}.png',
            ),
          );
        }
        await _tap(tester, find.text(Copy.settingsPhotoFiles));
        await _tap(tester, find.text(Copy.settingsProjectContexts));
        await _tap(tester, find.text(Copy.settingsContextAutoClear));
        await _tap(tester, find.text(Copy.settingsContextMovement));
        expect(find.text(Copy.settingsContextIdle), findsOneWidget);
        expect(find.text(Copy.settingsContextDistance), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.all(),
    );
  }

  testWidgets(
    'pseudo-locale disclosures remain reachable in compact landscape at text 2',
    (WidgetTester tester) async {
      await _pump(
        tester,
        store: SettingsStore.fake(),
        locale: const Locale('en', 'XA'),
        cell: const ScreenMatrix(Size(393, 320), 2, Brightness.light, false),
      );
      final LocalizedCopy copy = Copy.of(
        tester.element(find.byType(CaptureSettingsScreen)),
      );
      await _tap(tester, find.text(copy.settingsPhotoFiles));
      expect(find.text(copy.settingsNamingPattern), findsOneWidget);
      await _tap(tester, find.text(copy.settingsProjectContexts));
      await _tap(tester, find.text(copy.settingsContextAutoClear));
      expect(find.text(copy.settingsContextIdle), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

const ValueKey<String> _golden = ValueKey<String>('capture-settings-golden');

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester, {
  SettingsStore? store,
  bool missing = false,
  Object? failWith,
  bool pending = false,
  ScreenMatrix? cell,
  Locale locale = const Locale('en'),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = cell?.size ?? const Size(393, 852);
  tester.platformDispatcher.textScaleFactorTestValue = cell?.textScale ?? 1;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await tester.pumpWidget(
    ProviderScope(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        captureSettingsOverride(
          store: store,
          missing: missing,
          failWith: failWith,
          pending: pending,
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ScreenFonts.theme(
          buildTheme(
            brightness: cell?.brightness ?? Brightness.light,
            outdoor: cell?.outdoor ?? false,
          ),
        ),
        home: const RepaintBoundary(
          key: _golden,
          child: CaptureSettingsScreen(),
        ),
      ),
    ),
  );
  if (pending) {
    await tester.pump();
  } else {
    await tester.pumpAndSettle();
  }
}
