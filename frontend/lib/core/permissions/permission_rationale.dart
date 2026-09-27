import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/permissions/permissions_service.dart';

/// Why one platform permission exists, and the sentence shown before the prompt.
final class PermissionRationale {
  /// Creates a rationale.
  const PermissionRationale({
    required this.permission,
    required this.feature,
    required this.message,
  });

  /// The permission this sentence is for.
  final AppPermission permission;

  /// The shipped feature that needs it.
  final String feature;

  /// Sentence shown before the system prompt.
  final String message;

  /// The rationale for [permission].
  static PermissionRationale of(AppPermission permission) {
    return _entries[permission]!;
  }

  /// Every permission this app can ask for.
  static List<PermissionRationale> get all => _entries.values.toList();
}

const Map<AppPermission, PermissionRationale> _entries =
    <AppPermission, PermissionRationale>{
      AppPermission.camera: PermissionRationale(
        permission: AppPermission.camera,
        feature: 'capture',
        message: Copy.permissionCamera,
      ),
      AppPermission.microphone: PermissionRationale(
        permission: AppPermission.microphone,
        feature: 'dictation',
        message: Copy.permissionMicrophone,
      ),
      AppPermission.location: PermissionRationale(
        permission: AppPermission.location,
        feature: 'location',
        message: Copy.permissionLocation,
      ),
      AppPermission.storage: PermissionRationale(
        permission: AppPermission.storage,
        feature: 'import',
        message: Copy.permissionStorage,
      ),
    };

/// One declaration the review could not match.
typedef PermissionFinding = ({String file, int line, String message});

/// Compares [manifest] and [plist] text with [PermissionRationale].
///
/// Every declared permission needs one rationale, and every rationale needs
/// a declaration. Findings name the file and line.
List<PermissionFinding> reviewPermissionDeclarations({
  required String manifestName,
  required String manifest,
  required String plistName,
  required String plist,
}) {
  final List<PermissionFinding> findings = <PermissionFinding>[];
  final Set<AppPermission> declared = <AppPermission>{};
  findings.addAll(
    _scan(
      name: manifestName,
      text: manifest,
      pattern: RegExp(r'android:name="(android\.permission\.[^"]+)"'),
      declared: declared,
    ),
  );
  findings.addAll(
    _scan(
      name: plistName,
      text: plist,
      pattern: RegExp(r'<(NS\w+UsageDescription)>'),
      declared: declared,
    ),
  );
  for (final AppPermission permission in AppPermission.values) {
    if (!declared.contains(permission)) {
      findings.add((
        file: manifestName,
        line: 1,
        message: '${permission.name} has a rationale and no declaration',
      ));
    }
  }
  return findings;
}

const Map<String, AppPermission> _names = <String, AppPermission>{
  'android.permission.CAMERA': AppPermission.camera,
  'android.permission.RECORD_AUDIO': AppPermission.microphone,
  'android.permission.ACCESS_FINE_LOCATION': AppPermission.location,
  'android.permission.ACCESS_COARSE_LOCATION': AppPermission.location,
  'android.permission.READ_MEDIA_IMAGES': AppPermission.storage,
  'android.permission.READ_EXTERNAL_STORAGE': AppPermission.storage,
  'NSCameraUsageDescription': AppPermission.camera,
  'NSMicrophoneUsageDescription': AppPermission.microphone,
  'NSSpeechRecognitionUsageDescription': AppPermission.microphone,
  'NSPhotoLibraryUsageDescription': AppPermission.storage,
  'NSLocationWhenInUseUsageDescription': AppPermission.location,
};

List<PermissionFinding> _scan({
  required String name,
  required String text,
  required RegExp pattern,
  required Set<AppPermission> declared,
}) {
  final List<PermissionFinding> findings = <PermissionFinding>[];
  final List<String> lines = text.split('\n');
  for (var index = 0; index < lines.length; index++) {
    final RegExpMatch? match = pattern.firstMatch(lines[index]);
    if (match == null) {
      continue;
    }
    final String token = match.group(1)!;
    final AppPermission? permission = _names[token];
    if (permission == null) {
      findings.add((
        file: name,
        line: index + 1,
        message: '$token has no rationale',
      ));
      continue;
    }
    declared.add(permission);
  }
  return findings;
}
