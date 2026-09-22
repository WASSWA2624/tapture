import 'package:tapture/core/network/connectivity_service.dart';

/// The gate every unattended job consults.
///
/// Nothing runs while the app is in the foreground. On-device reading also
/// needs charging and idle. Automatic processing needs a network the
/// settings allow.
final class BackgroundPolicy {
  /// Creates the gate.
  const BackgroundPolicy();

  /// Whether a background job may run.
  ///
  /// [automatic] selects the connectivity rule. Otherwise the job is
  /// on-device reading and needs [charging] and [idle].
  bool mayRun({
    required bool charging,
    required bool idle,
    required NetworkState net,
    required bool foreground,
    bool automatic = false,
    bool wifiOnly = true,
  }) {
    if (foreground) {
      return false;
    }
    if (automatic) {
      if (net == NetworkState.offline) {
        return false;
      }
      if (wifiOnly && net != NetworkState.online) {
        return false;
      }
      return true;
    }
    return charging && idle;
  }
}
