import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/permissions/permissions_service.dart';

/// Why one platform permission exists, and the sentence shown before the prompt.
///
/// This is the one copy of each sentence: the permission gates show it before
/// the system asks, and a refusal reported by [PermissionsService] carries it.
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

final Map<AppPermission, PermissionRationale> _entries =
    <AppPermission, PermissionRationale>{
      AppPermission.camera: PermissionRationale(
        permission: AppPermission.camera,
        feature: 'capture',
        message: Copy.captureCameraReason,
      ),
      AppPermission.microphone: PermissionRationale(
        permission: AppPermission.microphone,
        feature: 'dictation',
        message: Copy.captureMicReason,
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
      AppPermission.notifications: PermissionRationale(
        permission: AppPermission.notifications,
        feature: 'processing notifications',
        message: Copy.permissionNotifications,
      ),
    };

/// One declaration the review could not match.
typedef PermissionFinding = ({String file, int line, String message});

/// One declaration file: its name in findings and its text.
typedef DeclarationFile = ({String name, String text});

/// Compares the Android manifest and the iOS plist with [PermissionRationale].
///
/// [libraryManifests] are the manifests plug-ins merge into [manifest] at
/// build time. A declaration the app manifest marks `tools:node="remove"` is
/// dropped from the merge, as the manifest merger drops it. Every remaining
/// runtime declaration needs one rationale, and every rationale needs a
/// declaration on each platform that asks for it. Install-time permissions
/// the system grants without a prompt need a named feature instead. Every
/// finding names its file and line; the review never stops at the first.
List<PermissionFinding> reviewPermissionDeclarations({
  required String manifestName,
  required String manifest,
  required String plistName,
  required String plist,
  List<DeclarationFile> libraryManifests = const <DeclarationFile>[],
}) {
  final List<PermissionFinding> findings = <PermissionFinding>[];
  final Set<String> removed = <String>{
    for (final _Declaration declaration in _manifestDeclarations(manifest))
      if (declaration.removed) declaration.name,
  };
  final Set<AppPermission> onAndroid = <AppPermission>{};
  final String? receiverPermission = _receiverPermissionOf(manifest);
  for (final DeclarationFile file in <DeclarationFile>[
    (name: manifestName, text: manifest),
    ...libraryManifests,
  ]) {
    for (final _Declaration declaration in _manifestDeclarations(file.text)) {
      if (declaration.removed || removed.contains(declaration.name)) {
        continue;
      }
      final AppPermission? permission = _android[declaration.name];
      if (permission != null) {
        onAndroid.add(permission);
      } else if (!_installTime.containsKey(declaration.name) &&
          declaration.name != receiverPermission) {
        findings.add((
          file: file.name,
          line: declaration.line,
          message: '${declaration.name} has no rationale',
        ));
      }
    }
  }
  final Set<AppPermission> onIos = <AppPermission>{};
  for (final _Declaration declaration in _plistDeclarations(plist)) {
    final AppPermission? permission = _ios[declaration.name];
    if (permission == null && !_sdkIos.containsKey(declaration.name)) {
      findings.add((
        file: plistName,
        line: declaration.line,
        message: '${declaration.name} has no rationale',
      ));
    } else if (permission != null) {
      onIos.add(permission);
    }
  }
  for (final AppPermission permission in AppPermission.values) {
    if (!onAndroid.contains(permission)) {
      findings.add((
        file: manifestName,
        line: 1,
        message: '${permission.name} has a rationale and no declaration',
      ));
    }
    if (_ios.containsValue(permission) && !onIos.contains(permission)) {
      findings.add((
        file: plistName,
        line: 1,
        message: '${permission.name} has a rationale and no declaration',
      ));
    }
  }
  return findings;
}

/// Android runtime permissions, each behind one rationale.
const Map<String, AppPermission> _android = <String, AppPermission>{
  'android.permission.CAMERA': AppPermission.camera,
  'android.permission.RECORD_AUDIO': AppPermission.microphone,
  'android.permission.ACCESS_FINE_LOCATION': AppPermission.location,
  'android.permission.ACCESS_COARSE_LOCATION': AppPermission.location,
  'android.permission.READ_MEDIA_IMAGES': AppPermission.storage,
  'android.permission.READ_EXTERNAL_STORAGE': AppPermission.storage,
  'android.permission.WRITE_EXTERNAL_STORAGE': AppPermission.storage,
  'android.permission.POST_NOTIFICATIONS': AppPermission.notifications,
};

/// Install-time Android permissions: granted without a prompt, so there is
/// no sentence to show, only the shipped feature that needs each one.
const Map<String, String> _installTime = <String, String>{
  'android.permission.INTERNET':
      'sign-in, analysis and uploads, each only when turned on',
  'android.permission.ACCESS_NETWORK_STATE': 'the offline status line',
  'android.permission.VIBRATE': 'processing notifications',
  'android.permission.USE_BIOMETRIC': 'explicit biometric app-lock unlock',
  'android.permission.USE_FINGERPRINT':
      'explicit biometric app-lock unlock on earlier Android versions',
};

/// iOS usage descriptions, each behind one rationale.
const Map<String, AppPermission> _ios = <String, AppPermission>{
  'NSCameraUsageDescription': AppPermission.camera,
  'NSMicrophoneUsageDescription': AppPermission.microphone,
  'NSSpeechRecognitionUsageDescription': AppPermission.microphone,
  'NSPhotoLibraryUsageDescription': AppPermission.storage,
  'NSLocationWhenInUseUsageDescription': AppPermission.location,
};

/// SDK-owned biometric access has its own system prompt, started only by the
/// explicit app-lock action. It is not requested through permission_handler.
const Map<String, String> _sdkIos = <String, String>{
  'NSFaceIDUsageDescription': 'explicit biometric app-lock unlock',
};

/// One declared permission and the line it starts on.
typedef _Declaration = ({String name, int line, bool removed});

/// Every `<uses-permission>` element in [manifest], however it is wrapped.
List<_Declaration> _manifestDeclarations(String manifest) {
  return <_Declaration>[
    for (final RegExpMatch element in _usesPermission.allMatches(manifest))
      if (_androidName.firstMatch(element.group(0)!)
          case final RegExpMatch name)
        (
          name: name.group(1)!,
          line: _lineOf(manifest, element.start),
          removed: element.group(0)!.contains(_removeMarker),
        ),
  ];
}

/// AndroidX protects dynamically registered app receivers with this app-owned
/// signature permission. It is never a runtime permission or a user prompt.
String? _receiverPermissionOf(String manifest) {
  final String? package = _manifestPackage.firstMatch(manifest)?.group(1);
  if (package == null) return null;
  final String expected = '$package.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION';
  for (final RegExpMatch declaration in _permission.allMatches(manifest)) {
    final String element = declaration.group(0)!;
    if (_androidName.firstMatch(element)?.group(1) == expected &&
        _signature.hasMatch(element)) {
      return expected;
    }
  }
  return null;
}

/// Every usage-description key in [plist].
List<_Declaration> _plistDeclarations(String plist) {
  return <_Declaration>[
    for (final RegExpMatch key in _usageKey.allMatches(plist))
      (name: key.group(1)!, line: _lineOf(plist, key.start), removed: false),
  ];
}

int _lineOf(String text, int offset) {
  return '\n'.allMatches(text.substring(0, offset)).length + 1;
}

final RegExp _usesPermission = RegExp(r'<uses-permission\b[^>]*>');
final RegExp _permission = RegExp(r'<permission\b[^>]*>');
final RegExp _manifestPackage = RegExp(r'<manifest\b[^>]*\bpackage="([^"]+)"');
final RegExp _signature = RegExp(r'android:protectionLevel="signature"');
final RegExp _androidName = RegExp(r'android:name="([^"]+)"');
final RegExp _usageKey = RegExp(r'<key>(NS\w+UsageDescription)</key>');
const String _removeMarker = 'tools:node="remove"';
