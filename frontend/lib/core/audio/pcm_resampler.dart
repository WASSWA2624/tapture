import 'dart:math' as math;
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';

/// Streaming rational-ratio resampler for 16-bit mono PCM: a polyphase
/// windowed-sinc filter (Kaiser window) that brings a 48 or 44.1 kHz
/// microphone to the take's 16 kHz.
///
/// With `g = gcd(inputRate, outputRate)` the filter has `L = outputRate / g`
/// phases and steps `M = inputRate / g` input samples per `L` outputs.
/// Output `n` sits at input position `n·M/L`, computed in integers, so the
/// timeline never drifts however long a take runs, and the kernel is
/// centred on it, so there is no group delay: an impulse at input 0 peaks
/// at output 0. Each phase is normalised to unity gain at DC. Feeding the
/// same input in chunks of any size gives the same samples as one call.
final class PcmResampler {
  /// A resampler from [inputRate] to [outputRate] Hz, by default the take's
  /// `AppConstants.audio.sampleRate`.
  ///
  /// Throws an [ArgumentError] when a rate is not positive or the ratio
  /// needs more than `AppConstants.speechPipeline.resamplerMaxPhases`
  /// phases.
  factory PcmResampler({required int inputRate, int? outputRate}) {
    return PcmResampler._build(
      inputRate,
      outputRate ?? AppConstants.audio.sampleRate,
    );
  }

  factory PcmResampler._build(int inputRate, int outputRate) {
    if (inputRate <= 0 || outputRate <= 0) {
      throw ArgumentError.value(inputRate, 'inputRate', 'must be positive');
    }
    final int divisor = _gcd(inputRate, outputRate);
    final int phases = outputRate ~/ divisor;
    final int step = inputRate ~/ divisor;
    if (phases > AppConstants.speechPipeline.resamplerMaxPhases) {
      throw ArgumentError.value(
        inputRate,
        'inputRate',
        'needs $phases phases to reach $outputRate Hz',
      );
    }
    // Cutoff as a fraction of the input rate (cycles per input sample,
    // doubled): sinc zero crossings fall every 1/bandwidth input samples.
    final double bandwidth =
        AppConstants.speechPipeline.resamplerCutoffRatio *
        math.min(inputRate, outputRate) /
        inputRate;
    final double halfWidth =
        AppConstants.speechPipeline.resamplerZeroCrossings / bandwidth;
    final int reach = halfWidth.ceil();
    final int taps = 2 * reach + 1;
    final Float64List table = Float64List(phases * taps);
    final double beta = AppConstants.speechPipeline.resamplerKaiserBeta;
    final double norm = _besselI0(beta);
    for (int phase = 0; phase < phases; phase++) {
      final double fraction = phase / phases;
      var sum = 0.0;
      for (int tap = 0; tap < taps; tap++) {
        final double distance = fraction - (tap - reach);
        if (distance.abs() >= halfWidth) {
          continue;
        }
        final double ratio = distance / halfWidth;
        final double window =
            _besselI0(beta * math.sqrt(1 - ratio * ratio)) / norm;
        final double weight = bandwidth * _sinc(bandwidth * distance) * window;
        table[phase * taps + tap] = weight;
        sum += weight;
      }
      for (int tap = 0; tap < taps; tap++) {
        table[phase * taps + tap] /= sum;
      }
    }
    return PcmResampler._(
      inputRate: inputRate,
      outputRate: outputRate,
      phases: phases,
      step: step,
      reach: reach,
      taps: taps,
      table: table,
    );
  }

  PcmResampler._({
    required this.inputRate,
    required this.outputRate,
    required this.phases,
    required this._step,
    required int reach,
    required this._taps,
    required this._table,
  }) : _reach = reach,
       // The input before the take began is silence.
       _history = Float64List(reach),
       _historyStart = -reach;

  /// Samples per second in.
  final int inputRate;

  /// Samples per second out.
  final int outputRate;

  /// Polyphase branches, `L`.
  final int phases;

  final int _step;
  final int _reach;
  final int _taps;
  final Float64List _table;
  Float64List _history;
  int _historyStart;
  int _received = 0;
  int _next = 0;
  bool _flushed = false;

  /// Input samples taken so far.
  int get inputSamples => _received;

  /// Output samples produced so far.
  int get outputSamples => _next;

  /// Resamples [input], keeping the history the filter needs across calls.
  /// Returns every output whose input is complete. Throws a [StateError]
  /// after [flush].
  Int16List process(Int16List input) {
    if (_flushed) {
      throw StateError('The resampler was flushed.');
    }
    final Float64List grown = Float64List(_history.length + input.length);
    grown.setRange(0, _history.length, _history);
    for (int index = 0; index < input.length; index++) {
      grown[_history.length + index] = input[index].toDouble();
    }
    _history = grown;
    _received += input.length;
    return _produce(_received);
  }

  /// Ends the stream: the input after the last sample is treated as
  /// silence, and the remaining outputs, up to the one at the last input
  /// position, are returned.
  Int16List flush() {
    if (_flushed) {
      return Int16List(0);
    }
    _flushed = true;
    final Float64List padded = Float64List(_history.length + _reach);
    padded.setRange(0, _history.length, _history);
    _history = padded;
    return _produce(_received + _reach, stopAt: _received);
  }

  /// Produces outputs while their taps lie before [available], and, when
  /// [stopAt] is given, while their position lies before it.
  Int16List _produce(int available, {int? stopAt}) {
    final List<int> out = <int>[];
    while (true) {
      final int position = _next * _step;
      final int base = position ~/ phases;
      if (base + _reach >= available) {
        break;
      }
      if (stopAt != null && position >= stopAt * phases) {
        break;
      }
      final int phase = position - base * phases;
      final int tableOffset = phase * _taps;
      final int historyOffset = base - _reach - _historyStart;
      var sum = 0.0;
      for (int tap = 0; tap < _taps; tap++) {
        sum += _table[tableOffset + tap] * _history[historyOffset + tap];
      }
      out.add(sum.round().clamp(_minSample, _maxSample));
      _next++;
    }
    final int keepFrom = (_next * _step) ~/ phases - _reach;
    final int drop = keepFrom - _historyStart;
    if (drop > 0) {
      _history = Float64List.sublistView(_history, drop);
      _historyStart = keepFrom;
    }
    return Int16List.fromList(out);
  }
}

const int _minSample = -32768;
const int _maxSample = 32767;

/// `sin(πx)/(πx)`, one at zero.
double _sinc(double x) {
  if (x == 0) {
    return 1;
  }
  final double angle = math.pi * x;
  return math.sin(angle) / angle;
}

/// The zeroth-order modified Bessel function of the first kind, by its
/// power series.
double _besselI0(double x) {
  var sum = 1.0;
  var term = 1.0;
  final double half = x / 2;
  for (int k = 1; k < 200; k++) {
    term *= (half / k) * (half / k);
    sum += term;
    if (term < sum * 1e-16) {
      break;
    }
  }
  return sum;
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
