import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'the release variant shrinks, splits and signs from the environment',
    () {
      final String gradle = File(
        'android/app/build.gradle.kts',
      ).readAsStringSync();
      expect(gradle.contains('isMinifyEnabled = true'), isTrue);
      expect(gradle.contains('isShrinkResources = true'), isTrue);
      expect(gradle.contains('TAPTURE_KEYSTORE'), isTrue);
      expect(gradle.contains('signingConfigs.getByName("release")'), isTrue);
      expect(gradle.contains('signingConfigs.getByName("debug")'), isTrue);
      final String example = File(
        'android/key.properties.example',
      ).readAsStringSync();
      expect(example.contains('storePassword='), isTrue);
      expect(RegExp(r'storePassword=.+').hasMatch(example), isFalse);
      expect(
        Directory('android').listSync(recursive: true).any((
          FileSystemEntity entity,
        ) {
          return entity.path.endsWith('.jks') ||
              entity.path.endsWith('.keystore');
        }),
        isFalse,
      );
    },
  );
}
