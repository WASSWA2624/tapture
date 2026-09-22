/// The settings feature: the settings someone can change.
library;

export 'data/biometric_lock.dart';
export 'data/pin_lock.dart';
export 'data/settings_store.dart';
export 'domain/app_lock.dart';
export 'domain/operator_profile.dart';
export 'domain/setting_key.dart';
export 'domain/setting_keys.dart';
export 'presentation/about_screen.dart';
export 'presentation/licences_screen.dart';
export 'presentation/operator_profile_screen.dart';

// Capture, storage, the lock screen and the offline switch import this
// barrel for SettingsStore so they never import data/ (FE-STR-04).
// SettingsScreen is exported from presentation/presentation.dart so
// that import cannot cycle.
