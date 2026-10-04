import 'noise_floor.dart';
import 'segmenter_phase.dart';
import 'speech_pipeline_config.dart';

/// Skips the voice detector over near-silence (spec §30.4.7).
///
/// A frame is quiet only when it is below the ceiling **and** within the
/// margin of the room's noise floor, so a far, quiet voice in a quiet room
/// still reaches the detector. A batch is gated only while no utterance is
/// building or open, and only when every frame in it is quiet. The share of
/// batches gated is reported for the session's stop summary.
final class EnergyGate {
  /// A gate with [config]'s ceiling, margin and floor span.
  EnergyGate({required SpeechPipelineConfig config})
    : _ceilingDbfs = config.energyGateCeilingDbfs,
      _marginDb = config.energyGateMarginDb,
      floor = NoiseFloor(
        spanSamples: config.samplesOf(config.noiseFloorWindow),
      );

  final double _ceilingDbfs;
  final double _marginDb;

  /// The room's noise floor the margin is measured from.
  final NoiseFloor floor;

  int _batches = 0;
  int _gatedBatches = 0;

  /// Adds the frame starting at sample [start] with level [dbfs] to the
  /// floor and reports whether that frame is quiet.
  bool observe(int start, double dbfs) {
    floor.add(start, dbfs);
    return isQuiet(dbfs);
  }

  /// Whether a frame at [dbfs] is quiet against the current floor.
  bool isQuiet(double dbfs) =>
      dbfs < _ceilingDbfs && dbfs < floor.dbfs + _marginDb;

  /// Decides one batch: gated when the segmenter is in
  /// [SegmenterPhase.silence] and [allQuiet] holds. Every decision is
  /// counted towards [gatedRatio].
  bool gates({required SegmenterPhase phase, required bool allQuiet}) {
    final bool gated = phase == SegmenterPhase.silence && allQuiet;
    _batches++;
    if (gated) {
      _gatedBatches++;
    }
    return gated;
  }

  /// Batches decided so far.
  int get batches => _batches;

  /// Batches that skipped the detector.
  int get gatedBatches => _gatedBatches;

  /// The share, from 0 to 1, of batches that skipped the detector; 0 before
  /// any batch.
  double get gatedRatio => _batches == 0 ? 0 : _gatedBatches / _batches;
}
