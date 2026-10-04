import 'microphone_owner.dart';

/// The right to open the microphone, granted by `MicrophoneArbiter.claim`.
///
/// The holder releases it when it closes the microphone. Releasing twice is
/// harmless, and a lease the arbiter revoked is already inactive.
final class MicrophoneLease {
  /// A lease for [owner] that tells [onRelease] when it ends. Only the
  /// arbiter creates one.
  MicrophoneLease(this.owner, {required this._onRelease});

  /// Who holds the microphone through this lease.
  final MicrophoneOwner owner;

  final void Function(MicrophoneLease) _onRelease;
  bool _active = true;

  /// Whether the microphone is still held through this lease.
  bool get isActive => _active;

  /// Gives the microphone back. Idempotent.
  void release() {
    if (!_active) {
      return;
    }
    _active = false;
    _onRelease(this);
  }
}
