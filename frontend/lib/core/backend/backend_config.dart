/// The organisation server this install talks to, and nothing it stores.
final class BackendConfig {
  /// Creates a configuration. [organisationId] is absent until enrolment.
  const BackendConfig({
    required this.baseUrl,
    this.organisationId,
    this.accountEmail,
    this.accountId,
    this.role,
    this.aiAvailable = false,
    this.grants = const <String, String?>{},
    this.state = EnrolmentState.notEnrolled,
    this.grantValidUntil,
    this.reachable = true,
  });

  /// Server address. An administrator may set it once for a self-hosted install.
  final String baseUrl;

  /// Organisation identifier. Held only beside the session secret.
  final String? organisationId;

  /// Signed-in address, for the settings screen.
  final String? accountEmail;

  /// Cached account identity; never replaces the captured operator name.
  final String? accountId;

  /// Server role, interpreted by the account feature's one role gate.
  final String? role;

  /// Whether the organisation reported a configured AI provider at refresh.
  final bool aiAvailable;

  /// Project membership and optional context scope from the cached grant.
  final Map<String, String?> grants;

  /// Current enrolment state.
  final EnrolmentState state;

  /// When the cached grant stops covering relay and analysis.
  final DateTime? grantValidUntil;

  /// False draws one quiet status line. It does not change what work is allowed.
  final bool reachable;

  /// True until the first successful sign-in, and again after revocation.
  bool get needsSignIn =>
      state == EnrolmentState.notEnrolled || state == EnrolmentState.revoked;

  /// Advances the machine. An event that does not apply leaves the state.
  BackendConfig apply(EnrolmentEvent event) {
    final EnrolmentState next = switch ((state, event)) {
      (EnrolmentState.notEnrolled, EnrolmentEvent.start) =>
        EnrolmentState.enrolling,
      (EnrolmentState.revoked, EnrolmentEvent.start) =>
        EnrolmentState.enrolling,
      (EnrolmentState.enrolling, EnrolmentEvent.succeed) =>
        EnrolmentState.enrolled,
      (EnrolmentState.enrolling, EnrolmentEvent.fail) =>
        EnrolmentState.notEnrolled,
      (EnrolmentState.enrolled, EnrolmentEvent.revoke) =>
        EnrolmentState.revoked,
      _ => state,
    };
    return BackendConfig(
      baseUrl: baseUrl,
      organisationId: organisationId,
      accountEmail: accountEmail,
      accountId: accountId,
      role: role,
      aiAvailable: aiAvailable,
      grants: grants,
      state: next,
      grantValidUntil: grantValidUntil,
      reachable: reachable,
    );
  }

  /// Keeps the name captured before enrolment and adds the account id.
  static ({String operatorName, String accountId}) linkOperator({
    required String operatorName,
    required String accountId,
  }) {
    return (operatorName: operatorName, accountId: accountId);
  }
}

/// How far enrolment has gone. The address lives with this state, never in
/// the database.
enum EnrolmentState {
  /// This install has never signed in.
  notEnrolled,

  /// A sign-in is in flight.
  enrolling,

  /// A grant is cached and the device can work.
  enrolled,

  /// The server or the operator ended the grant.
  revoked,
}

/// What the enrolment machine may do next.
enum EnrolmentEvent {
  /// Begin sign-in.
  start,

  /// The server accepted the password.
  succeed,

  /// The attempt failed before a grant existed.
  fail,

  /// The grant was withdrawn.
  revoke,
}
