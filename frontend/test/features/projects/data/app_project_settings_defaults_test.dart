import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/settings/settings.dart';

void main() {
  test('an empty store yields the built-in defaults', () {
    final ProjectSettingsDefaults defaults = appProjectSettingsDefaults(
      SettingsStore.fake(),
    );

    expect(defaults, builtInProjectSettingsDefaults);
  });

  test('every stored app value reaches the project defaults', () {
    final ProjectSettingsDefaults defaults = appProjectSettingsDefaults(
      SettingsStore.fake(
        stored: <String, Object?>{
          SettingKeys.aiDoNotSendImages.name: true,
          SettingKeys.gpsEnabled.name: true,
          SettingKeys.folderStrategy.name: 'flat',
          SettingKeys.confidenceHigh.name: 0.9,
          SettingKeys.confidenceMedium.name: 0.6,
          SettingKeys.aiRefineCaptions.name: true,
          SettingKeys.aiDailyRequestCap.name: 30,
          SettingKeys.appLanguage.name: 'en-UG',
        },
      ),
    );

    expect(defaults.doNotSendImages, isTrue);
    expect(defaults.gpsEnabled, isTrue);
    expect(defaults.folderStrategy, 'flat');
    expect(defaults.confidenceHigh, 0.9);
    expect(defaults.confidenceMedium, 0.6);
    expect(defaults.refineCaptions, isTrue);
    expect(defaults.dailyRequestCap, 30);
    expect(defaults.locale, 'en-UG');
    expect(defaults.aiEnabled, builtInProjectSettingsDefaults.aiEnabled);
    expect(
      defaults.refineColumns,
      builtInProjectSettingsDefaults.refineColumns,
    );
  });
}
