import 'package:tapture/core/files/files.dart';
import 'package:tapture/features/settings/settings.dart';

/// Theme-mode [TextStore] backed by [SettingsStore].
///
/// When [SettingKeys.themeMode] has never been written, [read] returns the
/// legacy temp-dir value so an upgrade keeps the last choice. That file is
/// never deleted.
final class SettingsTextStore implements TextStore {
  /// Creates the adapter. [legacy] is the old temp-dir store; tests pass
  /// [TextStore.memory].
  SettingsTextStore(this._settings, {TextStore? legacy})
    : _legacy = legacy ?? TextStore.file();

  final SettingsStore _settings;
  final TextStore _legacy;

  /// Same wire name as [SettingKeys.themeMode], with an empty default so a
  /// missing key is distinct from a stored `'system'`.
  static final SettingKey<String> _ifMissing = SettingKey<String>(
    SettingKeys.themeMode.name,
    '',
  );

  @override
  String? read() {
    final String stored = _settings.read(_ifMissing);
    if (stored.isNotEmpty) {
      return stored;
    }
    return _legacy.read();
  }

  @override
  Future<void> write(String contents) async {
    await _settings.write(SettingKeys.themeMode, contents);
  }
}
