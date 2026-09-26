import 'package:tapture/features/settings/settings.dart';

import '../domain/project_settings.dart';

/// The app-store values an unset project setting falls back to.
///
/// The one place [ProjectSettingsDefaults] is read from [store], so the
/// project settings screen and processing resolve a project the same way.
/// Keys the store does not carry use [builtInProjectSettingsDefaults].
ProjectSettingsDefaults appProjectSettingsDefaults(SettingsStore store) {
  return (
    aiEnabled: builtInProjectSettingsDefaults.aiEnabled,
    doNotSendImages: store.read(SettingKeys.aiDoNotSendImages),
    gpsEnabled: store.read(SettingKeys.gpsEnabled),
    folderStrategy: store.read(SettingKeys.folderStrategy),
    confidenceHigh: store.read(SettingKeys.confidenceHigh),
    confidenceMedium: store.read(SettingKeys.confidenceMedium),
    refineColumns: builtInProjectSettingsDefaults.refineColumns,
    refineCaptions: store.read(SettingKeys.aiRefineCaptions),
    dailyRequestCap: store.read(SettingKeys.aiDailyRequestCap),
    locale: store.read(SettingKeys.appLanguage),
  );
}
