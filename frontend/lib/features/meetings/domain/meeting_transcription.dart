import 'package:tapture/core/constants/app_constants.dart';

/// Splits a recording into chunks and folds a run into a new version.
///
/// A failed chunk drops only itself. Versions already stored stay as they
/// were.
final class MeetingTranscription {
  /// How many chunks [byteLength] becomes. Zero bytes is no chunk.
  static int chunkCount(int byteLength, {int? chunkBytes}) {
    final int size = chunkBytes ?? AppConstants.meetings.transcriptChunkBytes;
    if (byteLength <= 0 || size <= 0) {
      return 0;
    }
    return (byteLength + size - 1) ~/ size;
  }

  /// Adds one version built from [chunks]. [existing] is returned unchanged
  /// ahead of that version.
  static List<TranscriptVersion> fold({
    required List<TranscriptVersion> existing,
    required List<TranscriptChunk> chunks,
  }) {
    final StringBuffer text = StringBuffer();
    final List<int> failed = <int>[];
    for (final TranscriptChunk chunk in chunks) {
      if (chunk.failed) {
        failed.add(chunk.index);
        continue;
      }
      if (text.isNotEmpty && chunk.text.isNotEmpty) {
        text.write('\n');
      }
      text.write(chunk.text);
    }
    return <TranscriptVersion>[
      ...existing,
      (
        version: existing.length + 1,
        text: text.toString(),
        failedChunks: List<int>.unmodifiable(failed),
      ),
    ];
  }
}

/// One chunk of a long recording after transcription was attempted.
typedef TranscriptChunk = ({int index, String text, bool failed});

/// One stored run. A later run is another version; none is replaced.
typedef TranscriptVersion = ({
  int version,
  String text,
  List<int> failedChunks,
});
