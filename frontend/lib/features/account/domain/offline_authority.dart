import 'package:tapture/core/backend/backend_config.dart';

import 'role_gate.dart';

/// What this device may do right now, answered from the cached session and
/// the clock, never from the network (task 024 step 24).
///
/// Work on the projects the device holds — capture, review and export,
/// editing included — is allowed in every state, including a device that
/// never signed in: nothing blocks capture. Only what genuinely needs the
/// server is withheld once the cached grant has lapsed: relay, the AI proxy
/// and a change of role or membership. The role matrix is [RoleGate]'s; this
/// adds only the time dimension.
final class OfflineAuthority {
  /// Creates the authority for [state]. [role] is the signed-in role, null
  /// when there is none or the server's role is unknown.
  const OfflineAuthority({required this.state, this.role, this.grantsExpireAt});

  /// How far the cached grant reaches now.
  final AuthorityState state;

  /// The signed-in role's gate, for the capabilities the server enforces.
  final RoleGate? role;

  /// When the cached grant stops covering the server-bound capabilities.
  final DateTime? grantsExpireAt;

  /// The capabilities that are the device's own and never wait on a grant.
  static const Set<RoleCapability> local = <RoleCapability>{
    RoleCapability.capture,
    RoleCapability.review,
    RoleCapability.export,
  };

  /// Whether [capability] may be offered now.
  bool may(RoleCapability capability) {
    if (local.contains(capability)) {
      return true;
    }
    if (!live) {
      return false;
    }
    return role?.allows(capability) ?? false;
  }

  /// Whether the cached grant still covers server-bound work.
  bool get live =>
      state == AuthorityState.fresh || state == AuthorityState.cachedValid;

  /// Why [capability] is withheld, or null when it is allowed.
  AuthorityRefusal? refusal(RoleCapability capability) {
    if (may(capability)) {
      return null;
    }
    return switch (state) {
      AuthorityState.neverSignedIn => AuthorityRefusal.signInNeeded,
      AuthorityState.cachedExpired => AuthorityRefusal.grantExpired,
      AuthorityState.fresh ||
      AuthorityState.cachedValid => AuthorityRefusal.notPermitted,
    };
  }
}

/// Why a server-bound capability is withheld, so the interface can say which
/// in plain language.
enum AuthorityRefusal {
  /// This device holds no sign-in.
  signInNeeded,

  /// The saved sign-in has lapsed; a fresh sign-in or refresh renews it.
  grantExpired,

  /// The signed-in role does not include it.
  notPermitted,
}
