import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/permissions/permission_rationale.dart';
import 'package:tapture/core/permissions/permissions_service.dart';

void main() {
  test('each permission has one feature and one sentence', () {
    final PermissionsService fake = PermissionsService.fake();
    expect(fake, isA<PermissionsService>());
    final Set<String> features = <String>{};
    for (final AppPermission permission in AppPermission.values) {
      final PermissionRationale rationale = PermissionRationale.of(permission);
      expect(rationale.permission, permission);
      expect(rationale.feature, isNotEmpty);
      expect(rationale.message, isNotEmpty);
      expect(features.add(rationale.feature), isTrue);
    }
  });

  test('the shipped manifest and plist match the rationales', () {
    final List<PermissionFinding> findings = reviewPermissionDeclarations(
      manifestName: 'AndroidManifest.xml',
      manifest: File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync(),
      plistName: 'Info.plist',
      plist: File('ios/Runner/Info.plist').readAsStringSync(),
    );
    expect(findings, isEmpty);
  });

  test('an extra declaration and a missing one are both reported', () {
    const String manifest = '''
<manifest>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.BLUETOOTH"/>
</manifest>
''';
    const String plist = '''
<dict>
	<key>NSCameraUsageDescription</key>
	<key>NSMicrophoneUsageDescription</key>
	<key>NSPhotoLibraryUsageDescription</key>
</dict>
''';
    final List<PermissionFinding> findings = reviewPermissionDeclarations(
      manifestName: 'fixture.xml',
      manifest: manifest,
      plistName: 'fixture.plist',
      plist: plist,
    );
    expect(
      findings.any(
        (PermissionFinding hit) => hit.message.contains('BLUETOOTH'),
      ),
      isTrue,
    );
    expect(
      findings.any(
        (PermissionFinding hit) =>
            hit.message.contains('location has a rationale'),
      ),
      isTrue,
    );
    expect(findings.length, greaterThan(1));
  });
}
