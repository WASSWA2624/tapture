import 'dart:io';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';

import 'audio_recording.dart';
import 'wav_take.dart';

/// Suffix of a take that is still being written. It sits beside the
/// target, never under `.cache`, because it is the only copy until it is
/// published.
const String stagedTakeSuffix = '.recording';

/// [relativePath] with forward slashes, refused with a [ValidationFailure]
/// when it could leave the storage folder. [FileWriter] applies the same
/// rule to every target.
String stagedTakePath(String relativePath) {
  final String relative = relativePath.replaceAll(r'\', '/').trim();
  final List<String> parts = relative.split('/');
  if (relative.isEmpty ||
      relative.startsWith('/') ||
      relative.contains(':') ||
      parts.any((String part) => part.isEmpty || part == '.' || part == '..')) {
    throw ValidationFailure(
      localizedMessage: Copy.messages.audioPathOutsideStorage,
      localizedRecovery: Copy.messages.audioStartFailedRecovery,
    );
  }
  return relative;
}

/// Publishes the finished take [staging] at [relativePath] through
/// [FileWriter.adoptStaged]: the raw take itself is renamed into place, so
/// it is never copied and never removed before it is published.
///
/// The duration comes from the take's samples, or [fallback] when its
/// header cannot be read. On failure [staging] stays where it is, for the
/// next attempt and the orphan report.
Future<Result<AudioRecording>> publishStagedTake({
  required FileWriter writer,
  required File staging,
  required String relativePath,
  Duration fallback = Duration.zero,
}) async {
  try {
    final Duration duration =
        (await WavTake.read(staging))?.duration ?? fallback;
    final Result<WrittenFile> adopted = await writer.adoptStaged(
      staging,
      relativePath,
    );
    return adopted.map((WrittenFile file) {
      return AudioRecording(
        relativePath: file.relativePath,
        sha256: file.sha256,
        byteLength: file.byteLength,
        duration: duration,
        mimeType: stagedTakeMimeType,
      );
    });
  } on Object catch (error) {
    return FailureResult<AudioRecording>(Failure.from(error));
  }
}

/// The media type of every take.
const String stagedTakeMimeType = 'audio/wav';

/// The length of [samples] samples of 16 kHz mono audio, exact to the
/// microsecond, as [WavTake.duration] measures a published take.
Duration stagedTakeDuration(int samples) {
  return AppConstants.microsecond *
      (samples *
          Duration.microsecondsPerSecond ~/
          AppConstants.audio.sampleRate);
}
