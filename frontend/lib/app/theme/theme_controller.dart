import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/files/files.dart';

/// The type this file is named for (FE-STR-06). The contract name is
/// [ThemeModeController].
typedef ThemeController = ThemeModeController;

/// Which appearance the application shell should show.
enum AppThemeMode {
  /// Follow the platform brightness.
  system,

  /// Always the light palette.
  light,

  /// Always the dark palette.
  dark,

  /// High-contrast outdoor palettes; still follows platform brightness.
  outdoor,
}

/// Reads and writes [AppThemeMode] through a [TextStore].
///
/// Kept alive for the process: the shell watches this on every frame, so
/// disposing it would flash the default mode (FE-STATE-09).
final class ThemeModeController extends Notifier<AppThemeMode> {
  /// Production: reads the on-disk preference store.
  ThemeModeController() : this.withStore(TextStore.file());

  /// Tests pass a fake so they never touch the filesystem (FE-TEST-03).
  ThemeModeController.withStore(this._store);

  final TextStore _store;

  @override
  AppThemeMode build() => _decode(_store.read());

  /// Persists [mode] and then updates the interface (FE-STATE-07).
  Future<void> setMode(AppThemeMode mode) async {
    await _store.write(mode.name);
    state = mode;
  }

  AppThemeMode _decode(String? raw) {
    for (final AppThemeMode mode in AppThemeMode.values) {
      if (mode.name == raw) {
        return mode;
      }
    }
    return AppThemeMode.system;
  }
}

/// The active appearance. Not autoDispose: see [ThemeModeController].
final NotifierProvider<ThemeModeController, AppThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeController, AppThemeMode>(
      ThemeModeController.new,
    );
