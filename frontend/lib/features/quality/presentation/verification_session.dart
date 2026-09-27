import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/features/projects/projects.dart'
    show projectSettingsStoreProvider;
import 'package:tapture/features/settings/settings.dart';

/// Whether verification mode is on for this session, over the project setting.
final verificationSessionProvider = NotifierProvider<VerificationSession, bool>(
  VerificationSession.new,
);

/// Session override for verification mode. Starts from the project setting.
final class VerificationSession extends Notifier<bool> {
  @override
  bool build() {
    return ref
        .watch(projectSettingsStoreProvider)
        .read(SettingKeys.verificationMode);
  }

  /// Turns verification on or off for this session and remembers it.
  Future<void> set(bool value) async {
    state = value;
    await ref
        .read(projectSettingsStoreProvider)
        .write(SettingKeys.verificationMode, value);
  }
}
