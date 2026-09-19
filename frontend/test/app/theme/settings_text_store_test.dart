import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/settings_text_store.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/files/files.dart';
import 'package:tapture/features/settings/settings.dart';

void main() {
  test(
    'a written mode round-trips through a new store over the same fake',
    () async {
      final SettingsStore settings = SettingsStore.fake();
      final SettingsTextStore first = SettingsTextStore(
        settings,
        legacy: TextStore.memory(),
      );
      expect(first.read(), isNull);
      await first.write('outdoor');

      final SettingsTextStore restarted = SettingsTextStore(
        settings,
        legacy: TextStore.memory(),
      );
      expect(restarted.read(), 'outdoor');
      expect(settings.read(SettingKeys.themeMode), 'outdoor');
    },
  );

  test('an unset key uses the legacy value until the next write', () async {
    final SettingsStore settings = SettingsStore.fake();
    final Map<String, String> legacyBacking = <String, String>{};
    final TextStore legacy = TextStore.memory(legacyBacking);
    await legacy.write('dark');

    final SettingsTextStore first = SettingsTextStore(settings, legacy: legacy);
    expect(first.read(), 'dark');
    expect(settings.read(SettingKeys.themeMode), 'system');

    await first.write('light');
    expect(first.read(), 'light');
    expect(legacy.read(), 'dark');
    expect(legacyBacking[AppConstants.preferences.themeMode], 'dark');

    final SettingsTextStore restarted = SettingsTextStore(
      settings,
      legacy: legacy,
    );
    expect(restarted.read(), 'light');
    expect(legacy.read(), 'dark');
  });

  test('a stored value wins over a different legacy value', () async {
    final SettingsStore settings = SettingsStore.fake(
      stored: <String, Object?>{SettingKeys.themeMode.name: 'light'},
    );
    final TextStore legacy = TextStore.memory();
    await legacy.write('dark');

    final SettingsTextStore store = SettingsTextStore(settings, legacy: legacy);
    expect(store.read(), 'light');
  });
}
