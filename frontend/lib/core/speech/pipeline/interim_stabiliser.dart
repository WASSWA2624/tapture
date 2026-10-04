import '../live_transcription_event.dart';
import 'word_sequence.dart';

/// Turns successive drafts of the open utterance into text that does not
/// flicker: LocalAgreement-2 (spec §30.4.7).
///
/// Words two drafts in a row agree on become stable, and stable text is
/// append-only. The last word of a draft is never stable, because the
/// window may end inside it. A draft that disagrees inside the stable part
/// does not revise it; its words after the stable part are tentative. The
/// final of the utterance supersedes all of it ([close]). Draft text is
/// display-only: never persisted and never logged.
final class InterimStabiliser {
  int? _utteranceId;
  final List<String> _stable = <String>[];
  List<String> _previous = const <String>[];
  String _shownStable = '';
  String _shownTentative = '';

  /// Takes [hypothesis], the words of a draft of utterance [utteranceId]
  /// covering audio from [startSample], and returns the draft to show, or
  /// null when nothing visible changed.
  InterimTranscript? accept(
    int utteranceId,
    int startSample,
    List<String> hypothesis,
  ) {
    if (_utteranceId != utteranceId) {
      _reset(utteranceId);
    }
    final int agree = WordSequence.commonPrefix(_previous, hypothesis);
    final int candidate = agree < hypothesis.length - 1
        ? agree
        : hypothesis.length - 1;
    if (WordSequence.commonPrefix(_stable, hypothesis) == _stable.length &&
        candidate > _stable.length) {
      _stable.addAll(hypothesis.sublist(_stable.length, candidate));
    }
    final List<String> tentative = _stable.length < hypothesis.length
        ? hypothesis.sublist(_stable.length)
        : const <String>[];
    _previous = List<String>.of(hypothesis);
    final String stable = _stable.join(' ');
    final String rest = tentative.join(' ');
    if (stable == _shownStable && rest == _shownTentative) {
      return null;
    }
    _shownStable = stable;
    _shownTentative = rest;
    return InterimTranscript(
      utteranceId: utteranceId,
      startSample: startSample,
      stable: stable,
      tentative: rest,
    );
  }

  /// Utterance [utteranceId] is final: its draft state is dropped.
  void close(int utteranceId) {
    if (_utteranceId == utteranceId) {
      _reset(null);
    }
  }

  void _reset(int? utteranceId) {
    _utteranceId = utteranceId;
    _stable.clear();
    _previous = const <String>[];
    _shownStable = '';
    _shownTentative = '';
  }
}
