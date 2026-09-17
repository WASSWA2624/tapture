import 'dart:io';

import 'package:tapture/core/constants/app_constants.dart';

/// A writable path for the theme-mode preference until the settings store
/// exists.
String defaultPreferencesPath() {
  return preferencePath(AppConstants.preferences.themeMode);
}

/// Temp-dir file named for a preference key (FE-CODE-09).
String preferencePath(String key) {
  return '${Directory.systemTemp.path}/tapture-prefs/$key';
}

/// The file contents, or null when it is missing or empty.
String? readTextFile(String path) {
  if (path.isEmpty) {
    return null;
  }
  final File file = File(path);
  if (!file.existsSync()) {
    return null;
  }
  final String text = file.readAsStringSync().trim();
  if (text.isEmpty) {
    return null;
  }
  return text;
}

/// Writes [contents]. Overwrites; never deletes (FE-SEC-08).
void writeTextFile(String path, String contents) {
  if (path.isEmpty) {
    return;
  }
  final File file = File(path);
  if (!file.parent.existsSync()) {
    file.parent.createSync(recursive: true);
  }
  file.writeAsStringSync(contents);
}
