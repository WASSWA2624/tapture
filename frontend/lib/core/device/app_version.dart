/// The version this binary was built as, from `frontend/pubspec.yaml`.
///
/// Flutter hands `--build-name` and `--build-number` to the native projects
/// only, so Dart reads them from a define a release build may pass
/// (`--dart-define=APP_VERSION=1.2.0 --dart-define=APP_BUILD=7`). Without
/// one the defaults below apply; they are pubspec.yaml's `version:` line, and
/// `device_identity_test.dart` fails the suite the moment the two differ.
library;

/// The version name: pubspec.yaml's `version:` before the `+`.
const String appVersionName = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.0.0',
);

/// The build number: pubspec.yaml's `version:` after the `+`.
const String appBuildNumber = String.fromEnvironment(
  'APP_BUILD',
  defaultValue: '1',
);
