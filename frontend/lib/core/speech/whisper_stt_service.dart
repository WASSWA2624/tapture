import 'dart:async';
import 'dart:collection';

import 'package:tapture/core/ai/stt_result.dart';
import 'package:tapture/core/ai/stt_service.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/logging/logger.dart';

import 'live_transcription_event.dart';
import 'live_transcription_phase.dart';
import 'live_transcription_request.dart';
import 'live_transcription_result.dart';
import 'live_transcription_service.dart';
import 'live_transcription_session.dart';
import 'pipeline/word_sequence.dart';
import 'speech_text.dart';
import 'stop_reason.dart';
import 'transcript_segment.dart';
import 'transcription_kind.dart';

/// Field dictation on the on-device Whisper session (spec §24, §30.4.5),
/// behind the unchanged [SttService] contract.
///
/// Each listen is one memory-only dictation session. An empty partial
/// follows the microphone opening, even while the model still loads, so an
/// early Stop transcribes what was buffered. Partials are the finished
/// utterances plus the open utterance's stable words: tentative words are
/// never shown, and each utterance's final is aligned to the words already
/// shown, so a word once emitted never changes and a field that skips the
/// words its operator kept stays aligned. Words heard are never dropped
/// except by [cancel]; errors are raised only when nothing was heard.
final class WhisperSttService implements SttService {
  /// Dictation over [service]. A listen that names no language uses
  /// [languageFallback] (the app default when omitted).
  WhisperSttService({
    required this._service,
    String Function()? languageFallback,
    Logger? logger,
  }) : _languageFallback = languageFallback ?? _defaultLanguage,
       _logger = logger ?? Logger.current;

  final LiveTranscriptionService _service;
  final String Function() _languageFallback;
  final Logger _logger;
  _Listen? _active;

  @override
  bool get isSupported => true;

  /// Listens until silence, [stop] or [cancel]. [onDeviceOnly] is always
  /// met: Whisper runs on the device and has no network path.
  @override
  Stream<SttResult> listen({
    required String languageTag,
    bool onDeviceOnly = false,
  }) {
    final String language = languageTag.trim().isEmpty
        ? _languageFallback()
        : languageTag;
    return _Listen(this, language).out.stream;
  }

  @override
  Future<void> stop() async {
    await _active?.stop();
  }

  @override
  Future<void> cancel() async {
    final _Listen? active = _active;
    _active = null;
    await active?.close(keepWords: false);
  }
}

String _defaultLanguage() => AppConstants.defaultLanguage;

/// One utterance of a listen: its draft and, once decoded, its finals.
final class _Utterance {
  /// Words two drafts agreed on; only ever extended.
  List<String> stable = const <String>[];

  /// The rest of the latest draft. Never emitted as a partial.
  List<String> tentative = const <String>[];

  /// How many [stable] words a partial has shown.
  int shown = 0;

  /// Its final segments, as they arrive.
  final List<TranscriptSegment> segments = <TranscriptSegment>[];

  /// Whether every segment has arrived.
  bool finalized = false;

  /// The words this utterance adds to the listen: the shown words, then
  /// what its final says after them. Before a final, the whole draft.
  List<String> get words {
    final List<String> kept = stable.sublist(0, shown);
    if (!finalized && segments.isEmpty) {
      return <String>[...stable, ...tentative];
    }
    return _aligned(kept, <String>[
      for (final TranscriptSegment segment in segments)
        ...WordSequence.words(segment.text),
    ]);
  }
}

/// One listen, from its subscriber to its final result.
final class _Listen {
  _Listen(this._owner, this.languageTag) {
    out = StreamController<SttResult>(
      onListen: () => unawaited(_begin()),
      onCancel: _abandon,
    );
  }

  final WhisperSttService _owner;

  /// The language requested.
  final String languageTag;

  /// What the subscriber receives.
  late final StreamController<SttResult> out;

  final Stopwatch _clock = Stopwatch();

  /// Words of the utterances finished, in order. Only ever appended.
  final List<String> _committed = <String>[];

  /// Utterances not yet committed, by id.
  final SplayTreeMap<int, _Utterance> _open = SplayTreeMap<int, _Utterance>();

  final List<double> _confidences = <double>[];
  Future<Result<LiveTranscriptionSession>>? _starting;
  LiveTranscriptionSession? _session;
  StreamSubscription<LiveTranscriptionEvent>? _events;
  String? _shown;
  Timer? _gate;
  bool _dirty = false;
  Timer? _bound;
  bool _stopRequested = false;
  bool _closed = false;

  Logger get _log => _owner._logger;

  Future<void> _begin() async {
    final _Listen? previous = _owner._active;
    _owner._active = this;
    _clock.start();
    // A new listen hands the previous one's words over and frees the
    // microphone before claiming it.
    await previous?.close(keepWords: true);
    if (_closed) {
      return;
    }
    final Future<Result<LiveTranscriptionSession>> starting = _starting = _owner
        ._service
        .start(
          LiveTranscriptionRequest(
            kind: TranscriptionKind.dictation,
            languageTag: languageTag,
            autoStopAfterSilence: AppConstants.dictation.pauseFor,
            maxDuration: AppConstants.dictation.listenFor,
          ),
        );
    final Result<LiveTranscriptionSession> started = await starting;
    switch (started) {
      case FailureResult<LiveTranscriptionSession>(:final Failure failure):
        _finish(failure: failure, how: 'refused');
      case Success<LiveTranscriptionSession>(
        value: final LiveTranscriptionSession session,
      ):
        if (_closed) {
          unawaited(session.cancel());
          return;
        }
        _session = session;
        _events = session.events.listen(
          _onEvent,
          onDone: () => unawaited(_onEnded(session)),
        );
        // The microphone is open: the field shows it is listening.
        _emitPartial();
        _gate = Timer(AppConstants.transcripts.partialInterval, _onGate);
        if (_stopRequested) {
          unawaited(stop());
        }
    }
  }

  void _onEvent(LiveTranscriptionEvent event) {
    if (_closed) {
      return;
    }
    switch (event) {
      case InterimTranscript(
        :final int utteranceId,
        :final String stable,
        :final String tentative,
      ):
        final _Utterance utterance = _open.putIfAbsent(
          utteranceId,
          _Utterance.new,
        );
        final List<String> agreed = WordSequence.words(stable);
        if (WordSequence.commonPrefix(agreed, utterance.stable) >=
            utterance.shown) {
          utterance.stable = agreed;
        }
        utterance.tentative = WordSequence.words(tentative);
        _schedule();
      case SegmentFinalized(:final TranscriptSegment segment):
        _open
            .putIfAbsent(segment.utteranceId, _Utterance.new)
            .segments
            .add(segment);
        final double? confidence = segment.confidence;
        if (confidence != null) {
          _confidences.add(confidence);
        }
      case UtteranceFinalized(:final int utteranceId):
        _open.putIfAbsent(utteranceId, _Utterance.new).finalized = true;
        _commitFinished();
        _schedule();
      case TranscriptionStateChanged(:final LiveTranscriptionPhase phase)
          when phase == LiveTranscriptionPhase.stopping ||
              phase == LiveTranscriptionPhase.draining:
        // Stopped by silence, length or the operator: the last words are
        // waited for, but not forever.
        _armBound();
      case TranscriptionStateChanged(:final LiveTranscriptionPhase phase)
          when phase == LiveTranscriptionPhase.completed ||
              phase == LiveTranscriptionPhase.failed ||
              phase == LiveTranscriptionPhase.cancelled:
        // The session's last event: every final has been reported.
        final LiveTranscriptionSession? session = _session;
        if (session != null) {
          unawaited(_onEnded(session));
        }
      case _:
        break;
    }
  }

  /// Commits finished utterances in order. One finished out of order waits
  /// for those before it, so shown words never move.
  void _commitFinished() {
    while (_open.isNotEmpty) {
      final int first = _open.firstKey()!;
      final _Utterance utterance = _open[first]!;
      if (!utterance.finalized) {
        return;
      }
      _committed.addAll(utterance.words);
      _open.remove(first);
    }
  }

  /// A partial now, or at the end of the current interval.
  void _schedule() {
    if (_session == null) {
      return;
    }
    if (_gate?.isActive ?? false) {
      _dirty = true;
      return;
    }
    if (_emitPartial()) {
      _gate = Timer(AppConstants.transcripts.partialInterval, _onGate);
    }
  }

  void _onGate() {
    if (_closed || !_dirty) {
      return;
    }
    _dirty = false;
    if (_emitPartial()) {
      _gate = Timer(AppConstants.transcripts.partialInterval, _onGate);
    }
  }

  /// Emits the finished words and the first open utterance's stable
  /// words, unless that is what was last emitted. Returns whether it did.
  bool _emitPartial() {
    if (_closed) {
      return false;
    }
    final _Utterance? open = _open.isEmpty ? null : _open[_open.firstKey()];
    final String text = SpeechText.join(<String>[
      ..._committed,
      ...?open?.stable,
    ]);
    if (text == _shown) {
      return false;
    }
    if (open != null) {
      open.shown = open.stable.length;
    }
    _shown = text;
    out.add(SttResult(text: text, isFinal: false, languageTag: languageTag));
    return true;
  }

  void _armBound() {
    if (_bound != null || _closed) {
      return;
    }
    _bound = Timer(AppConstants.transcripts.dictationFinalize, () {
      final LiveTranscriptionSession? session = _session;
      _finish(how: 'bound');
      if (session != null) {
        unawaited(session.cancel());
      }
    });
  }

  /// Stops capture; the words still being decoded arrive as the final,
  /// within `AppConstants.transcripts.dictationFinalize`.
  Future<void> stop() async {
    if (_closed) {
      return;
    }
    final LiveTranscriptionSession? session = _session;
    if (session == null) {
      _stopRequested = true;
      return;
    }
    _armBound();
    // A stop that fails fails the session, which ends the listen.
    await session.stop();
  }

  /// Ends the listen now and frees the microphone: with the words heard as
  /// the final when [keepWords], else with nothing.
  Future<void> close({required bool keepWords}) =>
      _end(keepWords: keepWords, deliver: true);

  /// The subscriber went away: unfinal words are dropped, and nothing more
  /// is delivered.
  void _abandon() {
    unawaited(_end(keepWords: false, deliver: false));
  }

  Future<void> _end({required bool keepWords, required bool deliver}) async {
    if (_closed) {
      return;
    }
    if (!keepWords) {
      _committed.clear();
      _open.clear();
    }
    final Future<Result<LiveTranscriptionSession>>? starting = _starting;
    _finish(
      how: keepWords ? 'handed over' : (deliver ? 'cancelled' : 'abandoned'),
      deliver: deliver,
    );
    if (starting != null) {
      final Result<LiveTranscriptionSession> started = await starting;
      if (started case Success<LiveTranscriptionSession>(
        value: final LiveTranscriptionSession session,
      )) {
        await session.cancel();
      }
    }
  }

  Future<void> _onEnded(LiveTranscriptionSession session) async {
    if (_closed) {
      return;
    }
    final Result<LiveTranscriptionResult> done = await session.done;
    switch (done) {
      case Success<LiveTranscriptionResult>(
        value: final LiveTranscriptionResult result,
      ):
        final bool timedOut =
            result.stopReason == StopReason.silence ||
            result.stopReason == StopReason.maxDuration;
        _finish(
          failure: timedOut
              ? CancelledFailure(
                  localizedMessage: Copy.messages.dictationNothingHeard,
                )
              : null,
          language: result.languageTag,
          how: result.stopReason.name,
        );
      case FailureResult<LiveTranscriptionResult>(:final Failure failure):
        // A cancelled session was ended on purpose: it explains nothing.
        _finish(
          failure: failure is CancelledFailure ? null : failure,
          how: 'failed',
        );
    }
  }

  /// Ends the listen once: the words heard as the final, else [failure]
  /// explained when nothing was heard, then the stream closes.
  void _finish({
    Failure? failure,
    String? language,
    required String how,
    bool deliver = true,
  }) {
    if (_closed) {
      return;
    }
    _closed = true;
    _gate?.cancel();
    _bound?.cancel();
    unawaited(_events?.cancel());
    if (identical(_owner._active, this)) {
      _owner._active = null;
    }
    // A subscriber that went away gets nothing more: closing now would
    // re-enter its cancel.
    if (deliver) {
      final String heard = SpeechText.join(<String>[
        ..._committed,
        for (final _Utterance utterance in _open.values) ...utterance.words,
      ]);
      if (heard.isNotEmpty) {
        out.add(
          SttResult(
            text: heard,
            isFinal: true,
            languageTag: language ?? languageTag,
            confidence: _confidences.isEmpty
                ? null
                : _confidences.reduce((double a, double b) => a + b) /
                      _confidences.length,
          ),
        );
      } else if (failure != null) {
        out.addError(_explained(failure));
      }
      unawaited(out.close());
    }
    _log.info(
      _tag,
      'dictation ended ($how) after ${_clock.elapsedMilliseconds} ms',
    );
  }
}

/// The failure a field explains when nothing was heard (spec §24).
Failure _explained(Failure failure) {
  return switch (failure) {
    PermissionFailure() => PermissionFailure(
      localizedMessage: Copy.messages.dictationNoMicrophone,
    ),
    ProviderFailure(:final LocalizedMessage? localizedMessage)
        when localizedMessage?.key == _unexplained =>
      ProviderFailure(localizedMessage: Copy.messages.dictationFailed),
    _ => failure,
  };
}

/// The key of a provider failure that says nothing specific.
final String? _unexplained = const ProviderFailure().localizedMessage?.key;

/// [shown] followed by what [heard] says after them: [heard]'s words that
/// line up with [shown] (by `WordSequence.key`) are skipped, so the words
/// already emitted never change and none is repeated.
///
/// Where the final diverges inside [shown], the cut follows the last word
/// both agree on plus the shown words after it, one final word each.
List<String> _aligned(List<String> shown, List<String> heard) {
  if (shown.isEmpty) {
    return heard;
  }
  final int common = WordSequence.commonPrefix(shown, heard);
  if (common == shown.length) {
    return <String>[...shown, ...heard.sublist(common)];
  }
  final List<String> a = WordSequence.keys(shown);
  final List<String> b = WordSequence.keys(heard);
  // Longest common subsequence, to find where the shown words end in the
  // final.
  final List<List<int>> length = List<List<int>>.generate(
    a.length + 1,
    (int _) => List<int>.filled(b.length + 1, 0),
  );
  for (int i = a.length - 1; i >= 0; i--) {
    for (int j = b.length - 1; j >= 0; j--) {
      length[i][j] = a[i] == b[j]
          ? length[i + 1][j + 1] + 1
          : (length[i + 1][j] >= length[i][j + 1]
                ? length[i + 1][j]
                : length[i][j + 1]);
    }
  }
  int lastShown = -1;
  int lastHeard = -1;
  int i = 0;
  int j = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      lastShown = i;
      lastHeard = j;
      i++;
      j++;
    } else if (length[i + 1][j] >= length[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  final int cut = lastHeard + 1 + (shown.length - 1 - lastShown);
  return <String>[...shown, if (cut < heard.length) ...heard.sublist(cut)];
}

const String _tag = 'speech';
