import 'package:flutter/foundation.dart';

import 'microphone_owner.dart';

/// What a streaming capture records, for whom, and where it keeps it.
final class AudioCaptureRequest {
  /// A capture claimed by [owner].
  ///
  /// [relativePath] is the storage-root-relative `.wav` the take is
  /// published to; null keeps the audio in memory only and requires
  /// [maxDuration], which bounds that memory. [onPreempted] runs when
  /// evidence capture takes the microphone from this one.
  const AudioCaptureRequest({
    required this.owner,
    this.relativePath,
    this.maxDuration,
    this.onPreempted,
  });

  /// Who holds the microphone for this capture.
  final MicrophoneOwner owner;

  /// Where the take is published, or null for a memory-only capture.
  final String? relativePath;

  /// The longest audio a memory-only capture keeps.
  final Duration? maxDuration;

  /// Called when another owner takes the microphone. Without it the capture
  /// stops itself.
  final VoidCallback? onPreempted;
}
