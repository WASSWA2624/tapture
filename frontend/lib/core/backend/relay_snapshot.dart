/// Durable local relay counters plus the latest server settings and inbox.
final class RelaySnapshot {
  /// Creates a project view without copying any project content into metadata.
  const RelaySnapshot({
    required this.queued,
    required this.sent,
    required this.purged,
    required this.hasKey,
    required this.enabled,
    required this.neverRelay,
    required this.incoming,
  });

  /// Ciphertext packages waiting on this device.
  final int queued;

  /// Packages accepted by the server, including those later purged.
  final int sent;

  /// Sent packages the server no longer holds after acknowledgement or expiry.
  final int purged;

  /// Whether this device can encrypt and decrypt this project's relay packages.
  final bool hasKey;

  /// Server-enforced project switch, off by default.
  final bool enabled;

  /// Permanent policy that prevents sending.
  final bool neverRelay;

  /// Package ids awaiting the person's import/merge approval.
  final List<String> incoming;
}
