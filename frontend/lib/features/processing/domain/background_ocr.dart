import 'package:tapture/core/background/background_policy.dart';
import 'package:tapture/core/network/connectivity_service.dart';

/// On-device reading while the device is charging and idle.
///
/// Off unless the setting is on. A resume (the app in the foreground) stops
/// it at once. This path makes no network call.
final class BackgroundOcr {
  /// Whether opportunistic reading may run.
  static bool shouldRun({
    required bool enabled,
    required bool charging,
    required bool idle,
    required bool foreground,
  }) {
    if (!enabled) {
      return false;
    }
    return const BackgroundPolicy().mayRun(
      charging: charging,
      idle: idle,
      net: NetworkState.offline,
      foreground: foreground,
    );
  }
}
