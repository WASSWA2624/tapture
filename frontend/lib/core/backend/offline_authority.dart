import 'grant_cache.dart';

/// Answers from the cached grant. Capture never waits on the network.
final class OfflineAuthority {
  /// Creates an authority for one [state].
  const OfflineAuthority(this.state);

  /// The cached grant.
  final AuthorityState state;

  /// Whether [capability] is allowed in [state].
  bool may(WorkCapability capability) {
    if (state == AuthorityState.neverSignedIn) return false;
    return switch (capability) {
      WorkCapability.capture ||
      WorkCapability.review ||
      WorkCapability.edit ||
      WorkCapability.export => true,
      WorkCapability.relay ||
      WorkCapability.aiProxy ||
      WorkCapability.roleChange =>
        state == AuthorityState.fresh || state == AuthorityState.cachedValid,
    };
  }

  /// Plain reason when [may] is false. Null when the action is allowed.
  String? refusal(WorkCapability capability) {
    if (may(capability)) return null;
    if (state == AuthorityState.neverSignedIn) {
      return 'Sign in to continue.';
    }
    return 'The saved sign-in has expired for relay, analysis and role changes.';
  }
}

/// Work the device may do without waiting on the server.
enum WorkCapability {
  /// Creating a record.
  capture,

  /// Reviewing a record.
  review,

  /// Editing a record.
  edit,

  /// Exporting on the device.
  export,

  /// Sending a change package.
  relay,

  /// Calling the analysis proxy.
  aiProxy,

  /// Changing a person's role.
  roleChange,
}
