import 'package:tapture/core/background/background_policy.dart';
import 'package:tapture/core/network/connectivity_service.dart';

/// Starts processing when a connection appears, and only when that is allowed.
///
/// Off unless the setting is on. A metered network is refused when Wi-Fi
/// only is set. The daily cap and the foreground both hold it.
final class AutoProcess {
  /// Whether a connectivity change should start a batch.
  static bool shouldStart({
    required bool enabled,
    required bool wifiOnly,
    required NetworkState? previous,
    required NetworkState next,
    required bool foreground,
    required bool underCap,
  }) {
    if (!enabled || !underCap || previous == null) {
      return false;
    }
    final bool gained =
        previous != next &&
        (previous == NetworkState.offline ||
            (wifiOnly &&
                previous == NetworkState.metered &&
                next == NetworkState.online));
    if (!gained) {
      return false;
    }
    return const BackgroundPolicy().mayRun(
      charging: false,
      idle: false,
      net: next,
      foreground: foreground,
      automatic: true,
      wifiOnly: wifiOnly,
    );
  }
}
