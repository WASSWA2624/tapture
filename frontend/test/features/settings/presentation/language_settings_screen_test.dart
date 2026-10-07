import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/features/settings/data/settings_store.dart';
import 'package:tapture/features/settings/domain/setting_keys.dart';
import 'package:tapture/features/settings/presentation/language_settings_screen.dart';
import 'package:tapture/features/settings/presentation/offline_switch.dart';
import 'package:tapture/features/settings/presentation/speech_settings_section.dart';

import '../../../support/screen_matrix.dart';

void main() {
  testWidgets('Language names the app language and the voice language', (
    WidgetTester tester,
  ) async {
    await _pump(tester, SettingsStore.fake());

    expect(find.text(Copy.settingsLanguageTitle), findsWidgets);
    expect(find.text(Copy.settingsAppLanguage), findsOneWidget);
    expect(find.text(Copy.settingsAppLanguageEffect), findsOneWidget);
    expect(find.byType(AppChoiceField<String>), findsOneWidget);
    expect(find.text(Copy.settingsVoiceLanguage), findsOneWidget);
    expect(find.text(Copy.languageEnglish), findsOneWidget);
    expect(find.text(Copy.languageFrench), findsNothing);
  });

  testWidgets('Language holds the speech settings below the voice language', (
    WidgetTester tester,
  ) async {
    await _pump(tester, SettingsStore.fake());

    expect(find.byType(SpeechSettingsSection), findsOneWidget);
    expect(find.text(Copy.settingsSpeechSection), findsOneWidget);
    expect(find.text(Copy.settingsSpeechQuality), findsOneWidget);
    expect(find.text(Copy.settingsSpeechModels), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(Copy.settingsSpeechSection)).dy,
      greaterThan(tester.getTopLeft(find.text(Copy.settingsVoiceLanguage)).dy),
    );
  });

  testWidgets('choosing a voice language stores it for dictation', (
    WidgetTester tester,
  ) async {
    final SettingsStore store = SettingsStore.fake();
    final ProviderContainer container = await _pump(tester, store);
    expect(
      container.read(voiceLanguageProvider),
      SettingKeys.voiceLanguage.defaultValue,
    );

    await tester.tap(find.text(Copy.languageEnglish));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'French');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppListTile, Copy.languageFrench));
    await tester.pumpAndSettle();

    expect(store.read(SettingKeys.voiceLanguage), 'fr');
    expect(container.read(voiceLanguageProvider), 'fr');
  });

  testWidgets('the voice language follows a write made elsewhere', (
    WidgetTester tester,
  ) async {
    final SettingsStore store = SettingsStore.fake();
    final ProviderContainer container = await _pump(tester, store);

    await tester.runAsync(() => store.write(SettingKeys.voiceLanguage, 'sw'));
    await tester.pumpAndSettle();

    expect(container.read(voiceLanguageProvider), 'sw');
  });

  testWidgets('cancelled search and failed save preserve the voice language', (WidgetTester tester) async {
    final SettingsStore store = SettingsStore.fake(failWrites: true);
    await _pump(tester, store);
    await tester.tap(find.text(Copy.languageEnglish));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'French');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(store.read(SettingKeys.voiceLanguage), 'en');
    await tester.tap(find.text(Copy.languageEnglish));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppListTile, Copy.languageFrench));
    await tester.pumpAndSettle();
    expect(store.read(SettingKeys.voiceLanguage), 'en');
    expect(find.text(Copy.languageEnglish), findsOneWidget);
  });

  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    testWidgets('language controls fit ${cell.description}', (WidgetTester tester) async {
      await _pump(tester, SettingsStore.fake(), cell: cell);
      expect(tester.takeException(), isNull);
      if (cell.size == const Size(393, 852)) {
        await expectLater(find.byKey(_golden), matchesGoldenFile(
          'goldens/language_collapsed_${cell.outdoor ? 'outdoor' : cell.brightness.name}_${cell.textScale.toInt()}x.png',
        ));
      }
      await tester.ensureVisible(find.text(Copy.settingsSpeechModels));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Copy.settingsSpeechModels));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

const ValueKey<String> _golden = ValueKey<String>('language-settings-golden');

Future<ProviderContainer> _pump(
  WidgetTester tester,
  SettingsStore store,
  {ScreenMatrix? cell}
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = cell?.size ?? const Size(393, 852);
  tester.platformDispatcher.textScaleFactorTestValue = cell?.textScale ?? 1;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  final ProviderContainer container = ProviderContainer(
    retry: (int _, Object _) => null,
    overrides: <Override>[offlineStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(brightness: cell?.brightness ?? Brightness.light, outdoor: cell?.outdoor ?? false),
        home: const RepaintBoundary(key: _golden, child: LanguageSettingsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}
