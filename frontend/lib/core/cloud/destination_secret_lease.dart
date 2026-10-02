/// A transfer's credential generation and copied secure session state.
/// Removing or replacing sign-in invalidates all writes from this lease.
final class DestinationSecretLease {
  /// Creates a transfer lease. These values stay in secure storage or memory.
  const DestinationSecretLease({
    required this.ref,
    required this.generation,
    required this.sessionKey,
    this.access,
    this.refresh,
    this.session,
  });

  /// Credential reference in the destination row.
  final String ref;

  /// Random generation rotated only by an explicit sign-in replacement.
  final String generation;

  /// Reserved secure slot for this destination and remote object.
  final String sessionKey;

  /// Copied access material.
  final String? access;

  /// Copied refresh material.
  final String? refresh;

  /// Copied provider checkpoint, including any signed upload URL.
  final String? session;
}
