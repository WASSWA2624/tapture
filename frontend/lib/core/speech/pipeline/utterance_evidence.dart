import 'dart:typed_data';

import 'package:tapture/core/audio/pcm_level_meter.dart';

/// What the voice detector and the level meter saw over one utterance,
/// frame by frame, so the assembler can judge a decode against the audio
/// without reading it again (spec §30.4.7).
///
/// Two bytes a frame: the speech probability quantised to 1/255 and the
/// level rounded to whole dBFS. Frames are contiguous from [firstStart].
final class UtteranceEvidence {
  /// Evidence for frames of [frameSamples] samples starting at
  /// [firstStart], with quantised [probabilities] and [levels].
  UtteranceEvidence({
    required this.firstStart,
    required this.frameSamples,
    required Uint8List probabilities,
    required Int8List levels,
  }) : assert(probabilities.length == levels.length, 'one level per frame'),
       _probabilities = probabilities,
       _levels = levels;

  /// Evidence holding no frame, from [firstStart].
  UtteranceEvidence.empty({
    required this.firstStart,
    required this.frameSamples,
  }) : _probabilities = Uint8List(0),
       _levels = Int8List(0);

  /// The first sample of the first frame.
  final int firstStart;

  /// Samples per frame.
  final int frameSamples;

  final Uint8List _probabilities;
  final Int8List _levels;

  /// Frames held.
  int get length => _probabilities.length;

  /// The sample after the last frame.
  int get endSample => firstStart + length * frameSamples;

  /// The first sample of frame [index].
  int startOf(int index) => firstStart + index * frameSamples;

  /// Frame [index]'s speech probability, to 1/255.
  double probabilityAt(int index) => _probabilities[index] / 255;

  /// Frame [index]'s level in whole dBFS.
  int dbfsAt(int index) => _levels[index];

  /// The mean level, in dBFS, of the frames overlapping samples
  /// `[from, to)`, by default all of them; [emptyDbfs] when none does.
  double meanDbfs({
    int? from,
    int? to,
    double emptyDbfs = PcmLevelMeter.floorDbfs,
  }) {
    final (int first, int last) = _range(from, to);
    if (last <= first) {
      return emptyDbfs;
    }
    int sum = 0;
    for (int index = first; index < last; index++) {
      sum += _levels[index];
    }
    return sum / (last - first);
  }

  /// The share, from 0 to 1, of the frames overlapping `[from, to)` whose
  /// probability reaches [threshold]; 0 when none overlaps.
  double speechRatio(double threshold, {int? from, int? to}) {
    final (int first, int last) = _range(from, to);
    if (last <= first) {
      return 0;
    }
    return _speechFrames(threshold, first, last) / (last - first);
  }

  /// Samples of the frames whose probability reaches [threshold]: how much
  /// speech the detector heard.
  int speechSamples(double threshold) =>
      _speechFrames(threshold, 0, length) * frameSamples;

  /// Quantises probability [p] to the byte this evidence stores.
  static int quantiseProbability(double p) => (p * 255).round().clamp(0, 255);

  /// Rounds level [dbfs] to the byte this evidence stores.
  static int quantiseLevel(double dbfs) => dbfs.round().clamp(-128, 127);

  int _speechFrames(double threshold, int first, int last) {
    final int quantised = quantiseProbability(threshold);
    int count = 0;
    for (int index = first; index < last; index++) {
      if (_probabilities[index] >= quantised) {
        count++;
      }
    }
    return count;
  }

  (int, int) _range(int? from, int? to) {
    final int start = from ?? firstStart;
    final int end = to ?? endSample;
    final int first = ((start - firstStart) ~/ frameSamples).clamp(0, length);
    final int last = ((end - firstStart + frameSamples - 1) ~/ frameSamples)
        .clamp(0, length);
    return (first, last);
  }
}
