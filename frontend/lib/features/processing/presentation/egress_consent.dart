import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the operator has agreed, in this app session, to what the first
/// online call sends.
///
/// The preview is asked before the first online call of a session; once it
/// is accepted, later batches go ahead without asking again. A decline is
/// not remembered: the batch stops, every job stays claimable, and the next
/// Process asks again. A restart forgets the agreement.
final class EgressConsent extends Notifier<bool> {
  @override
  bool build() => false;

  /// Records that the preview was accepted.
  void grant() => state = true;
}

/// This session's agreement to online work. Kept alive for the app's life.
final NotifierProvider<EgressConsent, bool> egressConsentProvider =
    NotifierProvider<EgressConsent, bool>(EgressConsent.new);
