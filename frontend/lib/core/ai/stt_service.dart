import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';

import 'stt_result.dart';

/// Speech to text on this device. The platform recogniser is reached only
/// here (FE-STR-11); the contract is task 131's.
abstract interface class SttService {
  /// The platform recogniser. The platform has one microphone session, so
  /// the app holds one of these.
  factory SttService() => _PluginSttService(SpeechToText());

  /// A stand-in that cannot listen. It is the default until [main] swaps in
  /// the platform one, so suites never open a microphone (FE-TEST-03).
  const factory SttService.unavailable() = _UnavailableSttService;

  /// The platform service over a scripted recogniser, so its session rules
  /// are tested without a microphone.
  @visibleForTesting
  factory SttService.withRecogniser(SpeechToText speech) = _PluginSttService;

  /// Whether this build has a recogniser to try. The microphone itself is
  /// only asked for on the first [listen].
  bool get isSupported;

  /// Listens in [languageTag] until silence, [stop] or [cancel].
  ///
  /// Emits an empty partial once the microphone is open, partials as words
  /// arrive, then at most one final result, then closes. Errors are
  /// [Failure]s carrying catalogue copy. A new listen ends the previous one
  /// first, handing over the words it had heard. Cancelling the subscription
  /// cancels the recognition. With [onDeviceOnly] speech never leaves the
  /// device; where that is impossible the listen fails (FE-SEC-04).
  Stream<SttResult> listen({
    required String languageTag,
    bool onDeviceOnly = false,
  });

  /// Stops listening. The words heard so far arrive as the final result.
  Future<void> stop();

  /// Stops listening and drops anything not yet final.
  Future<void> cancel();
}

/// The app's recogniser. The stand-in until [main] overrides it. Kept
/// alive: every text field on every screen shares the one session
/// (FE-STATE-09).
final Provider<SttService> sttServiceProvider = Provider<SttService>((Ref _) {
  return const SttService.unavailable();
});

final class _UnavailableSttService implements SttService {
  const _UnavailableSttService();

  @override
  bool get isSupported => false;

  @override
  Stream<SttResult> listen({
    required String languageTag,
    bool onDeviceOnly = false,
  }) {
    return Stream<SttResult>.error(
      const ProviderFailure(message: Copy.dictationUnavailable),
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

/// One listen, from the first subscriber to the final result.
final class _Session {
  _Session({required this.languageTag, required this.onDeviceOnly});

  final String languageTag;
  final bool onDeviceOnly;
  late final StreamController<SttResult> out;
  String heard = '';
  double? confidence;
  bool closed = false;
  Timer? settle;

  void partial() {
    if (!closed) {
      out.add(SttResult(text: heard, isFinal: false, languageTag: languageTag));
    }
  }

  /// Ends the listen. Words already heard are never dropped for an error.
  void finish({Failure? failure}) {
    if (closed) {
      return;
    }
    closed = true;
    settle?.cancel();
    if (heard.trim().isNotEmpty) {
      out.add(
        SttResult(
          text: heard,
          isFinal: true,
          languageTag: languageTag,
          confidence: confidence,
        ),
      );
    } else if (failure != null) {
      out.addError(failure);
    }
    unawaited(out.close());
  }
}

final class _PluginSttService implements SttService {
  _PluginSttService(this._speech);

  final SpeechToText _speech;
  Future<bool>? _ready;
  _Session? _active;
  bool _running = false;
  Completer<void>? _quiet;
  String? _initError;

  @override
  bool get isSupported {
    if (kIsWeb) {
      return true;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      TargetPlatform.linux || TargetPlatform.fuchsia => false,
    };
  }

  @override
  Stream<SttResult> listen({
    required String languageTag,
    bool onDeviceOnly = false,
  }) {
    final _Session session = _Session(
      languageTag: languageTag,
      onDeviceOnly: onDeviceOnly,
    );
    session.out = StreamController<SttResult>(
      onListen: () => unawaited(_start(session)),
      onCancel: () => _abandon(session),
    );
    return session.out.stream;
  }

  @override
  Future<void> stop() async {
    final _Session? session = _active;
    if (session == null || session.closed) {
      return;
    }
    session.settle ??= Timer(AppConstants.dictation.settle, session.finish);
    await _quietly(_speech.stop);
  }

  @override
  Future<void> cancel() async {
    final _Session? session = _active;
    _active = null;
    if (session != null) {
      session.heard = '';
      session.finish();
    }
    await _quietly(_speech.cancel);
  }

  Future<void> _start(_Session session) async {
    final _Session? previous = _active;
    _active = session;
    previous?.finish();
    if (_running) {
      await _quiesce();
    }
    if (kIsWeb && session.onDeviceOnly) {
      // The browser recogniser streams audio to its vendor (FE-SEC-04).
      session.finish(
        failure: const NetworkFailure(message: Copy.dictationOfflineOnly),
      );
      return;
    }
    final bool ready = await _initialise();
    if (!identical(_active, session) || session.closed) {
      return;
    }
    if (!ready) {
      final String? error = _initError ?? await _missingMicrophone();
      session.finish(failure: _failureFor(error, session));
      return;
    }
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          _onResult(session, result);
        },
        listenOptions: SpeechListenOptions(
          localeId: session.languageTag,
          onDevice: session.onDeviceOnly,
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          autoPunctuation: true,
          listenFor: AppConstants.dictation.listenFor,
          pauseFor: AppConstants.dictation.pauseFor,
        ),
      );
      _running = true;
      session.partial();
    } on ListenFailedException catch (error) {
      session.finish(failure: _failureFor(error.message ?? _failed, session));
    } on Object {
      session.finish(failure: _failureFor(_failed, session));
    }
  }

  /// The permission error name when a device recogniser exists but the
  /// microphone was refused, else null.
  Future<String?> _missingMicrophone() async {
    if (kIsWeb) {
      return null;
    }
    try {
      return await _speech.hasPermission ? null : _permissionErrors.first;
    } on Object {
      return null;
    }
  }

  void _abandon(_Session session) {
    final bool wasOpen = !session.closed;
    session.closed = true;
    session.settle?.cancel();
    if (wasOpen && identical(_active, session)) {
      _active = null;
      unawaited(_quietly(_speech.cancel));
    }
  }

  Future<bool> _initialise() {
    return _ready ??= _tryInitialise();
  }

  Future<bool> _tryInitialise() async {
    _initError = null;
    bool ready;
    try {
      ready = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        finalTimeout: AppConstants.dictation.settle,
      );
    } on Object {
      ready = false;
    }
    if (!ready) {
      // Refusal is asked again only on a later explicit tap (task 131).
      _ready = null;
    }
    return ready;
  }

  /// Cancels a running recognition and waits for the platform to say it
  /// has stopped, so the next start is not refused as already running.
  Future<void> _quiesce() async {
    final Completer<void> quiet = Completer<void>();
    _quiet = quiet;
    await _quietly(_speech.cancel);
    await quiet.future.timeout(AppConstants.dictation.settle, onTimeout: () {});
    _quiet = null;
    _running = false;
  }

  void _onResult(_Session session, SpeechRecognitionResult result) {
    if (session.closed) {
      return;
    }
    session.heard = result.recognizedWords;
    if (result.hasConfidenceRating) {
      session.confidence = result.confidence;
    }
    if (result.finalResult) {
      session.finish();
    } else {
      session.partial();
    }
  }

  void _onStatus(String status) {
    final bool stopped =
        status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus;
    if (!stopped) {
      return;
    }
    final Completer<void>? quiet = _quiet;
    if (quiet != null) {
      // This is the recognition being quietened, not the one about to start.
      if (!quiet.isCompleted) {
        quiet.complete();
      }
      return;
    }
    final _Session? session = _active;
    if (status == SpeechToText.doneStatus) {
      _running = false;
      session?.finish();
    } else if (session != null && !session.closed) {
      // The last words may still be on their way; wait for them briefly.
      session.settle ??= Timer(AppConstants.dictation.settle, session.finish);
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (_quiet != null) {
      // The abort of the recognition being quietened, not a new failure.
      return;
    }
    final _Session? session = _active;
    if (session == null || session.closed) {
      _initError = error.errorMsg;
      return;
    }
    _running = false;
    session.finish(failure: _failureFor(error.errorMsg, session));
  }
}

Future<void> _quietly(Future<void> Function() call) async {
  try {
    await call();
  } on Object {
    // Stopping a recogniser that already stopped is not a failure.
  }
}

/// Maps a platform error name onto catalogue copy.
Failure _failureFor(String? error, _Session session) {
  final String name = (error ?? '').toLowerCase();
  if (_matches(name, _permissionErrors)) {
    return const PermissionFailure(message: Copy.dictationNoMicrophone);
  }
  if (_matches(name, _silenceErrors)) {
    return const CancelledFailure(message: Copy.dictationNothingHeard);
  }
  if (session.onDeviceOnly &&
      _matches(name, <String>[..._networkErrors, ..._unsupportedErrors])) {
    return const NetworkFailure(message: Copy.dictationOfflineOnly);
  }
  if (_matches(name, _networkErrors)) {
    return const NetworkFailure(message: Copy.dictationNeedsConnection);
  }
  if (error == null || _matches(name, _unsupportedErrors)) {
    return const ProviderFailure(message: Copy.dictationUnavailable);
  }
  return const ProviderFailure(message: Copy.dictationFailed);
}

/// A listen that failed without naming why.
const String _failed = 'listen failed';

bool _matches(String name, List<String> fragments) {
  return fragments.any(name.contains);
}

const List<String> _permissionErrors = <String>[
  'permission',
  'not-allowed',
  'not_allowed',
];

const List<String> _silenceErrors = <String>[
  'no_match',
  'no-speech',
  'speech_timeout',
  'no_speech',
];

const List<String> _networkErrors = <String>['network', 'server'];

const List<String> _unsupportedErrors = <String>[
  'not supported',
  'not_supported',
  'not-supported',
  'language',
  'audio',
];
