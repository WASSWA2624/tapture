import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the operator has agreed to this session's selected billing scope.
///
/// The preview is asked before the first online call of a session; once it
/// is accepted, later batches with the same provider, model and cost ceiling
/// go ahead without asking again. A changed selection asks again. A decline is
/// not remembered: the batch stops, every job stays claimable, and the next
/// Process asks again. A restart forgets the agreement.
final class EgressConsent extends Notifier<bool> {
  String? _scope;
  @override
  bool build() => false;

  /// Records that the preview was accepted.
  void grant({String scope = ''}) {
    _scope = scope;
    state = true;
  }

  /// Whether the accepted preview covers this exact provider and cost scope.
  bool covers(String scope) => state && _scope == scope;
}

/// This session's agreement to online work. Kept alive for the app's life.
final NotifierProvider<EgressConsent, bool> egressConsentProvider =
    NotifierProvider<EgressConsent, bool>(EgressConsent.new);
