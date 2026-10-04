import '../transcript_segment.dart';
import 'speech_pipeline_config.dart';
import 'utterance_boundary.dart';

/// The end of the transcript so far, passed to the next decode so whisper
/// keeps its punctuation, casing and spelling across utterances
/// (spec §30.4.7). Never logged.
///
/// The text is the last `promptCarryChars` characters, cut forward to a
/// word boundary. It is not passed for an utterance shorter than
/// `promptCarryMinUtterance` or quieter than `promptCarryMinDbfs`, where
/// whisper is likeliest to echo it, nor for one that continues a hard cut.
/// It is forgotten after a loop collapse, after an utterance that was only
/// hallucination, and after `promptResetGap` of audio without finalized
/// speech.
final class PromptCarry {
  /// An empty carry with [config]'s limits.
  PromptCarry({required SpeechPipelineConfig config})
    : _chars = config.promptCarryChars,
      _minSamples = config.samplesOf(config.promptCarryMinUtterance),
      _minDbfs = config.promptCarryMinDbfs,
      _resetSamples = config.samplesOf(config.promptResetGap);

  final int _chars;
  final int _minSamples;
  final double _minDbfs;
  final int _resetSamples;
  String _text = '';
  int? _lastSpeechEnd;

  /// The carried text: at most `promptCarryChars` characters, starting at a
  /// word.
  String get text => _text;

  /// The prompt for a decode of [utterance]: the carried text, or empty
  /// when the utterance is too short or too quiet to be given it, or
  /// continues a hard cut. Such an utterance starts by decoding again the
  /// seam the carried text ends with, which already gives whisper the
  /// context, and with the same words in its prompt whisper reads on from
  /// the prompt past the audio.
  String promptFor(UtteranceBoundary utterance) {
    final String prompt = promptAt(
      startSample: utterance.startSample,
      length: utterance.length,
      meanDbfs: utterance.evidence.meanDbfs(),
    );
    return utterance.seamFromSample == null ? prompt : '';
  }

  /// The prompt for audio of [length] samples from [startSample] with a
  /// mean level of [meanDbfs], when known. Forgets the carried text first
  /// when the audio starts `promptResetGap` after the last speech.
  String promptAt({
    required int startSample,
    required int length,
    double? meanDbfs,
  }) {
    final int? lastSpeech = _lastSpeechEnd;
    if (lastSpeech != null && startSample - lastSpeech >= _resetSamples) {
      reset();
    }
    if (length < _minSamples || (meanDbfs != null && meanDbfs < _minDbfs)) {
      return '';
    }
    return _text;
  }

  /// Adds [segments], the next finalized text, to the carry.
  void commit(List<TranscriptSegment> segments) {
    if (segments.isEmpty) {
      return;
    }
    final StringBuffer joined = StringBuffer(_text);
    for (final TranscriptSegment segment in segments) {
      final String text = segment.text.trim();
      if (text.isEmpty) {
        continue;
      }
      if (joined.isNotEmpty) {
        joined.write(' ');
      }
      joined.write(text);
    }
    _text = _tail(joined.toString());
    _lastSpeechEnd = segments.last.endSample;
  }

  /// Forgets the carried text.
  void reset() {
    _text = '';
  }

  String _tail(String text) {
    if (text.length <= _chars) {
      return text;
    }
    final int cut = text.length - _chars;
    if (text[cut - 1] == ' ') {
      return text.substring(cut);
    }
    final int space = text.indexOf(' ', cut);
    return space < 0 ? '' : text.substring(space + 1);
  }
}
