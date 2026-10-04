import 'package:tapture/core/constants/app_constants.dart';

/// The format the device actually opened. The take itself is always
/// `AppConstants.audio`: 16 kHz mono PCM, converted from this when needed.
final class CaptureFormat {
  /// A device format of [inputSampleRate] Hz and [inputChannels] channels.
  const CaptureFormat({
    required this.inputSampleRate,
    required this.inputChannels,
  });

  /// Samples per second the microphone delivers.
  final int inputSampleRate;

  /// Interleaved channels the microphone delivers.
  final int inputChannels;

  /// Whether the device rate differs from the take's, so audio is resampled.
  bool get resampled => inputSampleRate != AppConstants.audio.sampleRate;

  /// Whether the device delivers more than one channel, so audio is mixed
  /// down to mono.
  bool get downmixed => inputChannels > AppConstants.audio.channels;
}
