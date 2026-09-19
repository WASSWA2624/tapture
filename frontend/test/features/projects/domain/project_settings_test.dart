import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/features/projects/domain/project_settings.dart';

void main() {
  const ProjectSettingsDefaults appOn = (
    aiEnabled: true,
    doNotSendImages: false,
    gpsEnabled: true,
    folderStrategy: 'byTemplate',
    confidenceHigh: 0.9,
    confidenceMedium: 0.4,
    refineColumns: false,
  );

  test('built-in defaults match AppConstants', () {
    expect(
      builtInProjectSettingsDefaults.folderStrategy,
      AppConstants.folders.defaultStrategy,
    );
    expect(
      builtInProjectSettingsDefaults.confidenceHigh,
      AppConstants.confidence.high,
    );
    expect(
      builtInProjectSettingsDefaults.confidenceMedium,
      AppConstants.confidence.medium,
    );
  });

  test('unknown or missing JSON loads as defaults instead of throwing', () {
    expect(ProjectSettings.decode(''), ProjectSettings.defaults);
    expect(ProjectSettings.decode('{'), ProjectSettings.defaults);
    expect(ProjectSettings.decode('[]'), ProjectSettings.defaults);
    expect(ProjectSettings.decode('1'), ProjectSettings.defaults);
    expect(ProjectSettings.decode('"x"'), ProjectSettings.defaults);
    expect(ProjectSettings.decode('{}'), ProjectSettings.defaults);
    expect(ProjectSettings.fromJson(null), ProjectSettings.defaults);
    expect(
      ProjectSettings.decode('{"unknown": true, "aiEnabled": "no"}'),
      ProjectSettings.defaults,
    );
  });

  test('known keys override defaults and a wrong type is unset', () {
    final ProjectSettings settings = ProjectSettings.decode(
      '{"aiEnabled": false, "folderStrategy": "flat",'
      ' "photoFolderStrategy": "byTemplate",'
      ' "confidenceHigh": 1, "confidenceMedium": "high",'
      ' "refinedColumns": false}',
    );
    expect(settings.aiEnabled, isFalse);
    expect(settings.folderStrategy, 'flat');
    expect(settings.confidenceHigh, 1);
    expect(settings.confidenceMedium, isNull);
    expect(settings.refineColumns, isFalse);
  });

  test('an unknown folder strategy is unset', () {
    expect(
      ProjectSettings.decode('{"folderStrategy": "../etc"}').folderStrategy,
      isNull,
    );
  });

  test('encode round-trips a complete object', () {
    const ProjectSettings settings = ProjectSettings(
      aiEnabled: false,
      folderStrategy: 'byCaptureDate',
    );
    expect(ProjectSettings.decode(settings.encode()), settings);
  });

  test('an override wins and clearing it falls back to the app default', () {
    const ProjectSettings overridden = ProjectSettings(
      aiEnabled: false,
      doNotSendImages: true,
      gpsEnabled: false,
    );
    final ProjectSettingsResolved resolved = overridden.resolve(appOn);
    expect(resolved.aiEnabled, isFalse);
    expect(resolved.doNotSendImages, isTrue);
    expect(resolved.gpsEnabled, isFalse);
    expect(resolved.folderStrategy, appOn.folderStrategy);
    expect(overridden.allowsProviderCalls(appOn), isFalse);
    expect(overridden.allowsImageEgress(appOn), isFalse);

    final ProjectSettings cleared = overridden.copyWith(
      clearAiEnabled: true,
      clearDoNotSendImages: true,
      clearGpsEnabled: true,
    );
    expect(cleared.aiEnabled, isNull);
    expect(cleared.doNotSendImages, isNull);
    expect(cleared.gpsEnabled, isNull);
    expect(cleared.resolve(appOn).aiEnabled, isTrue);
    expect(cleared.resolve(appOn).doNotSendImages, isFalse);
    expect(cleared.resolve(appOn).gpsEnabled, isTrue);
    expect(cleared.allowsProviderCalls(appOn), isTrue);
    expect(cleared.allowsImageEgress(appOn), isTrue);
  });
}
