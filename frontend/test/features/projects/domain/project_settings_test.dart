import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/features/projects/domain/project_settings.dart';

void main() {
  test('built-in defaults match AppConstants', () {
    expect(
      ProjectSettings.defaults.folderStrategy,
      AppConstants.folders.defaultStrategy,
    );
    expect(
      ProjectSettings.defaults.confidenceHigh,
      AppConstants.confidence.high,
    );
    expect(
      ProjectSettings.defaults.confidenceMedium,
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

  test('known keys override defaults and a wrong type is defaulted', () {
    final ProjectSettings settings = ProjectSettings.decode(
      '{"aiEnabled": false, "folderStrategy": "flat",'
      ' "photoFolderStrategy": "byTemplate",'
      ' "confidenceHigh": 1, "confidenceMedium": "high",'
      ' "refinedColumns": false}',
    );
    expect(settings.aiEnabled, isFalse);
    expect(settings.folderStrategy, 'flat');
    expect(settings.confidenceHigh, 1);
    expect(settings.confidenceMedium, AppConstants.confidence.medium);
    expect(settings.refineColumns, isFalse);
  });

  test('an unknown folder strategy becomes the default', () {
    expect(
      ProjectSettings.decode('{"folderStrategy": "../etc"}').folderStrategy,
      AppConstants.folders.defaultStrategy,
    );
  });

  test('encode round-trips a complete object', () {
    const ProjectSettings settings = ProjectSettings(
      aiEnabled: false,
      folderStrategy: 'byCaptureDate',
    );
    expect(ProjectSettings.decode(settings.encode()), settings);
  });
}
