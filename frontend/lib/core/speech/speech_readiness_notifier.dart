import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'speech_availability.dart';
import 'speech_engine_host.dart';
import 'speech_preferences.dart';
import 'speech_readiness.dart';

/// Keeps [SpeechReadiness] current for the voice language: it starts
/// [SpeechReadiness.notReady], then asks the host (which never loads a
/// model) and asks again on every host change. A new language or quality
/// rebuilds it.
final class SpeechReadinessNotifier extends Notifier<SpeechReadiness> {
  /// Counts checks, so only the newest answer is kept.
  int _checks = 0;

  @override
  SpeechReadiness build() {
    final SpeechEngineHost host = ref.watch(speechEngineHostProvider);
    final String languageTag = ref.watch(speechLanguageProvider);
    ref.watch(speechQualityProvider);
    final StreamSubscription<void> changes = host.changes.listen(
      (void _) => unawaited(_check(host, languageTag)),
    );
    ref.onDispose(changes.cancel);
    unawaited(_check(host, languageTag));
    return SpeechReadiness.notReady;
  }

  /// Checks again now, as after a model was imported or verified.
  Future<void> refresh() => _check(
    ref.read(speechEngineHostProvider),
    ref.read(speechLanguageProvider),
  );

  Future<void> _check(SpeechEngineHost host, String languageTag) async {
    final int check = ++_checks;
    final SpeechAvailability availability = await host.availability(
      languageTag: languageTag,
    );
    if (check == _checks && ref.mounted) {
      state = SpeechReadiness.from(availability);
    }
  }
}

/// Whether on-device speech is ready for the voice language now.
final NotifierProvider<SpeechReadinessNotifier, SpeechReadiness>
speechReadinessProvider =
    NotifierProvider<SpeechReadinessNotifier, SpeechReadiness>(
      SpeechReadinessNotifier.new,
    );
