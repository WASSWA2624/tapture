import 'package:tapture/core/errors/failure.dart';

import 'capture_format.dart';
import 'capture_pause_reason.dart';

part 'capture_failed.dart';
part 'capture_format_changed.dart';
part 'capture_level.dart';
part 'capture_paused.dart';
part 'capture_resumed.dart';

/// Something that happened to a streaming capture besides its audio.
///
/// Variants live in this library so the type can stay sealed while each
/// class keeps its own file.
sealed class AudioCaptureEvent {
  /// Creates an event.
  const AudioCaptureEvent();
}
