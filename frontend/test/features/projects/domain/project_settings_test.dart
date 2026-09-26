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
    refineCaptions: true,
    dailyRequestCap: 40,
    locale: 'en-UG',
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
    expect(
      builtInProjectSettingsDefaults.dailyRequestCap,
      AppConstants.processing.dailyRequestCap,
    );
    expect(builtInProjectSettingsDefaults.locale, AppConstants.defaultLanguage);
    expect(builtInProjectSettingsDefaults.refineCaptions, isFalse);
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

  test(
    'a missing template choice stays null and an unknown value is unset',
    () {
      expect(ProjectSettings.decode('{}').templateChoice, isNull);
      expect(
        ProjectSettings.decode('{"templateChoice": "sideways"}').templateChoice,
        isNull,
      );
      expect(
        ProjectSettings.decode('{"templateChoice": "manual"}').templateChoice,
        'manual',
      );
    },
  );

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

  test('the project photo round-trips and can be cleared', () {
    const ProjectSettings withPhoto = ProjectSettings(
      gpsEnabled: true,
      coverPhoto: (path: 'projects/alpha/cover/a.jpg', sha256: 'abc'),
    );
    final ProjectSettings read = ProjectSettings.decode(withPhoto.encode());
    expect(read, withPhoto);
    expect(read.coverPhoto?.path, 'projects/alpha/cover/a.jpg');

    final ProjectSettings other = read.copyWith(templateChoice: 'manual');
    expect(other.coverPhoto, read.coverPhoto);
    final ProjectSettings cleared = read.copyWith(clearCoverPhoto: true);
    expect(cleared.coverPhoto, isNull);
    expect(cleared.gpsEnabled, isTrue);
    expect(cleared.toJson().containsKey('coverPhoto'), isFalse);
  });

  test('a malformed project photo is ignored', () {
    expect(
      ProjectSettings.decode('{"coverPhoto": {"path": 3}}').coverPhoto,
      isNull,
    );
    expect(
      ProjectSettings.decode('{"coverPhoto": "a.jpg"}').coverPhoto,
      isNull,
    );
  });

  group('the processing settings', () {
    const ProjectSettings full = ProjectSettings(
      refineCaptions: false,
      dailyRequestCap: 12,
      locale: 'en-UG',
      providerSelection: <String, ({String provider, String model})>{
        'extractFields': (provider: 'openai', model: 'gpt-vision'),
        'transcribe': (provider: 'backend', model: 'default'),
      },
      templatePins: <String, String>{
        'room=Plant room': 'template-pump',
        'floor=2': 'template-motor',
      },
    );

    test('round-trip through the stored JSON', () {
      final ProjectSettings read = ProjectSettings.decode(full.encode());

      expect(read, full);
      expect(read.hashCode, full.hashCode);
      expect(read.providerSelection?['extractFields'], (
        provider: 'openai',
        model: 'gpt-vision',
      ));
      expect(read.templatePins?['floor=2'], 'template-motor');
    });

    test('differ when only a map entry differs', () {
      final ProjectSettings otherPin = full.copyWith(
        templatePins: <String, String>{'room=Plant room': 'template-motor'},
      );
      final ProjectSettings otherModel = full.copyWith(
        providerSelection: <String, ({String provider, String model})>{
          'extractFields': (provider: 'openai', model: 'gpt-other'),
          'transcribe': (provider: 'backend', model: 'default'),
        },
      );

      expect(otherPin, isNot(full));
      expect(otherModel, isNot(full));
    });

    test('an override wins, and an unset one inherits the app store', () {
      final ProjectSettingsResolved overridden = full.resolve(appOn);
      expect(overridden.refineCaptions, isFalse);
      expect(overridden.dailyRequestCap, 12);
      expect(overridden.locale, 'en-UG');

      final ProjectSettingsResolved inherited = ProjectSettings.defaults
          .resolve(appOn);
      expect(inherited.refineCaptions, isTrue);
      expect(inherited.dailyRequestCap, 40);
      expect(inherited.locale, 'en-UG');
      expect(
        ProjectSettings.defaults
            .copyWith(locale: 'fr')
            .resolve(builtInProjectSettingsDefaults)
            .locale,
        'fr',
      );
    });

    test('clearing each one unsets it and drops it from the JSON', () {
      final ProjectSettings cleared = full.copyWith(
        clearRefineCaptions: true,
        clearDailyRequestCap: true,
        clearLocale: true,
        clearProviderSelection: true,
        clearTemplatePins: true,
      );

      expect(cleared, ProjectSettings.defaults);
      expect(cleared.toJson(), isEmpty);
      expect(full.copyWith(templateChoice: 'manual').templatePins, {
        'room=Plant room': 'template-pump',
        'floor=2': 'template-motor',
      });
    });
  });
}
