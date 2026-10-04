import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/ai/platform_recogniser_policy.dart';
import 'package:tapture/core/ai/stt_result.dart';
import 'package:tapture/core/ai/stt_service.dart';
import 'package:tapture/core/audio/microphone_arbiter.dart';
import 'package:tapture/core/audio/microphone_lease.dart';
import 'package:tapture/core/audio/microphone_owner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'live_transcription_service.dart';
import 'speech_failures.dart';
import 'speech_preferences.dart';
import 'speech_readiness.dart';
import 'speech_readiness_notifier.dart';
import 'whisper_stt_service.dart';

/// Field dictation that never sends speech off the device (FE-SEC-04,
/// spec §24): each listen uses Whisper when it is ready; else the platform
/// recogniser, on device only and only where [PlatformRecogniserPolicy]
/// proves it stays there; else it fails with `dictationOfflineOnly`.
final class RoutedSttService implements SttService {
  /// Routes between [whisper] (made on its first use), read as ready
  /// through [whisperReady] at every listen, and [platform], gated by
  /// [policy] and holding the microphone through [arbiter].
  RoutedSttService({
    SttService Function()? whisper,
    this._platform,
    required this._policy,
    required this._whisperReady,
    required this._arbiter,
  }) : _makeWhisper = whisper;

  final SttService Function()? _makeWhisper;
  final SttService? _platform;
  final PlatformRecogniserPolicy _policy;
  final bool Function() _whisperReady;
  final MicrophoneArbiter _arbiter;
  SttService? _whisper;
  _Route? _active;

  @override
  bool get isSupported => true;

  @override
  Stream<SttResult> listen({
    required String languageTag,
    bool onDeviceOnly = false,
  }) {
    late final _Route route;
    route = _Route(
      StreamController<SttResult>(
        onListen: () => unawaited(_begin(route, languageTag, onDeviceOnly)),
        onCancel: () => route.abandon(),
      ),
    );
    return route.out.stream;
  }

  @override
  Future<void> stop() async {
    await _active?.stop();
  }

  @override
  Future<void> cancel() async {
    final _Route? active = _active;
    _active = null;
    await active?.cancel();
  }

  Future<void> _begin(
    _Route route,
    String languageTag,
    bool onDeviceOnly,
  ) async {
    final _Route? previous = _active;
    _active = route;
    final SttService? target = await _targetFor();
    if (route.ended) {
      return;
    }
    if (target == null) {
      route.fail(speechOfflineOnly());
      return;
    }
    // A listen on another recogniser hands its words over first.
    if (previous != null && !identical(previous.target, target)) {
      await previous.stop();
    }
    if (route.ended) {
      return;
    }
    if (identical(target, _platform)) {
      final MicrophoneLease? held = previous?.lease;
      if (held != null && held.isActive) {
        // The platform hands the previous listen over itself; the
        // microphone stays with dictation.
        previous!.lease = null;
        route.lease = held;
      } else {
        final Result<MicrophoneLease> claimed = await _arbiter.claim(
          MicrophoneOwner.dictation,
          onPreempted: target.stop,
        );
        switch (claimed) {
          case FailureResult<MicrophoneLease>(:final Failure failure):
            route.fail(failure);
            return;
          case Success<MicrophoneLease>(value: final MicrophoneLease lease):
            route.lease = lease;
        }
      }
      if (route.ended) {
        route.lease?.release();
        return;
      }
      // Whatever the field asked, the platform recogniser stays on device.
      route.follow(
        target,
        target.listen(languageTag: languageTag, onDeviceOnly: true),
      );
      return;
    }
    route.follow(
      target,
      target.listen(languageTag: languageTag, onDeviceOnly: onDeviceOnly),
    );
  }

  /// Whisper when it is ready; else the platform recogniser when it keeps
  /// speech on device; else null.
  Future<SttService?> _targetFor() async {
    final SttService Function()? makeWhisper = _makeWhisper;
    if (makeWhisper != null && _whisperReady()) {
      return _whisper ??= makeWhisper();
    }
    final SttService? platform = _platform;
    if (platform != null && await _policy.keepsSpeechOnDevice()) {
      return platform;
    }
    return null;
  }
}

/// One listen through the router: the recogniser chosen and its stream.
final class _Route {
  _Route(this.out);

  final StreamController<SttResult> out;
  SttService? target;
  MicrophoneLease? lease;
  StreamSubscription<SttResult>? _inner;
  bool ended = false;
  bool _stopRequested = false;

  /// Forwards [results] from [chosen] until they end.
  void follow(SttService chosen, Stream<SttResult> results) {
    target = chosen;
    _inner = results.listen(out.add, onError: out.addError, onDone: _end);
    if (_stopRequested) {
      unawaited(chosen.stop());
    }
  }

  /// Ends the listen with [failure] and no words.
  void fail(Failure failure) {
    if (ended) {
      return;
    }
    out.addError(failure);
    _end();
  }

  Future<void> stop() async {
    final SttService? chosen = target;
    if (ended) {
      return;
    }
    if (chosen == null) {
      _stopRequested = true;
      return;
    }
    await chosen.stop();
  }

  Future<void> cancel() async {
    final SttService? chosen = target;
    if (ended) {
      return;
    }
    _end();
    await chosen?.cancel();
  }

  /// The subscriber went away: the recognition is cancelled with it.
  void abandon() {
    if (ended) {
      return;
    }
    ended = true;
    lease?.release();
    unawaited(_inner?.cancel());
  }

  void _end() {
    if (ended) {
      return;
    }
    ended = true;
    lease?.release();
    unawaited(_inner?.cancel());
    unawaited(out.close());
  }
}

/// The platform recogniser, or null where the build has none (the web,
/// Linux). `main` overrides it; kept alive with the one session the
/// platform allows.
final Provider<SttService?> platformRecogniserProvider = Provider<SttService?>(
  (Ref _) => null,
);

/// What field dictation uses: the routed on-device service whenever any
/// engine is usable, else the unavailable stand-in. A new instance only
/// when "any engine usable" flips, so microphones appear and disappear
/// without a listen losing its service; Whisper's readiness is read again
/// at every listen.
final Provider<SttService> dictationSttProvider = Provider<SttService>((
  Ref ref,
) {
  final SttService? platform = ref.watch(platformRecogniserProvider);
  final bool usable =
      platform != null ||
      ref.watch(speechReadinessProvider.select((SpeechReadiness r) => r.ready));
  if (!usable) {
    return const SttService.unavailable();
  }
  final LiveTranscriptionService live = ref.watch(
    liveTranscriptionServiceProvider,
  );
  final RoutedSttService routed = RoutedSttService(
    whisper: () => WhisperSttService(
      service: live,
      languageFallback: () => ref.mounted
          ? ref.read(speechLanguageProvider)
          : AppConstants.defaultLanguage,
    ),
    platform: platform,
    policy: PlatformRecogniserPolicy.platform(),
    whisperReady: () => ref.mounted && ref.read(speechReadinessProvider).ready,
    arbiter: ref.watch(microphoneArbiterProvider),
  );
  // A listen running when the routing changes hands its words over.
  ref.onDispose(() => unawaited(routed.stop()));
  return routed;
});
