import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/features/settings/domain/setting_keys.dart';

void main() {
  test('each key is declared once and listed in SettingKeys.names', () {
    final String source = File(
      'lib/features/settings/domain/setting_keys.dart',
    ).readAsStringSync();
    final List<String> declared = RegExp(
      r"SettingKey<[^>]+>\(\s*'([^']+)'",
    ).allMatches(source).map((Match match) => match.group(1)!).toList();

    expect(declared, isNotEmpty);
    expect(declared.toSet(), hasLength(declared.length));
    expect(SettingKeys.names, declared);
    expect(SettingKeys.names.toSet(), hasLength(SettingKeys.names.length));
  });

  test('defaults that exist on AppConstants are not restated', () {
    expect(SettingKeys.gpsEnabled.defaultValue, isFalse);
    expect(SettingKeys.storageRootPath.defaultValue, isNull);
    expect(SettingKeys.lastLocation.defaultValue, '');
    expect(SettingKeys.photoQuality.defaultValue, AppConstants.images.quality);
    expect(
      SettingKeys.folderStrategy.defaultValue,
      AppConstants.folders.defaultStrategy,
    );
    expect(SettingKeys.retentionDays.defaultValue, AppConstants.retention.days);
    expect(
      SettingKeys.confidenceHigh.defaultValue,
      AppConstants.confidence.high,
    );
    expect(
      SettingKeys.confidenceMedium.defaultValue,
      AppConstants.confidence.medium,
    );
    expect(
      SettingKeys.aiRowMatchThreshold.defaultValue,
      AppConstants.processing.fuzzyMatch,
    );
    expect(
      SettingKeys.aiDetectionConfident.defaultValue,
      AppConstants.processing.detectionConfident,
    );
    expect(
      SettingKeys.aiDetectionGap.defaultValue,
      AppConstants.processing.detectionGap,
    );
    expect(SettingKeys.aiProviderSelection.defaultValue, '{}');
    expect(SettingKeys.appLanguage.defaultValue, AppConstants.defaultLanguage);
  });

  test('no setting name looks like a secret', () {
    for (final String name in SettingKeys.names) {
      expect(name.toLowerCase().contains('secret'), isFalse);
      expect(name.toLowerCase().contains('token'), isFalse);
      expect(name.toLowerCase().contains('password'), isFalse);
      expect(name.toLowerCase().contains('credential'), isFalse);
    }
  });
}
