part of 'audio_capture_event.dart';

/// The device opened, or switched to, [format]. The take stays 16 kHz mono.
final class CaptureFormatChanged extends AudioCaptureEvent {
  /// The device now delivers [format].
  const CaptureFormatChanged(this.format);

  /// What the device delivers.
  final CaptureFormat format;
}
