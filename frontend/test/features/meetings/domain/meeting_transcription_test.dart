import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/meetings/domain/meeting_transcription.dart';

void main() {
  test('long audio is split into chunks and empty audio is none', () {
    expect(MeetingTranscription.chunkCount(0), 0);
    expect(MeetingTranscription.chunkCount(25, chunkBytes: 10), 3);
  });

  test('a failed chunk keeps the chunks that succeeded', () {
    final List<TranscriptVersion> versions = MeetingTranscription.fold(
      existing: const <TranscriptVersion>[],
      chunks: const <TranscriptChunk>[
        (index: 0, text: 'Opened.', failed: false),
        (index: 1, text: '', failed: true),
        (index: 2, text: 'Closed.', failed: false),
      ],
    );
    expect(versions.single.text, 'Opened.\nClosed.');
    expect(versions.single.failedChunks, <int>[1]);
  });

  test('a repeat run adds a version and replaces none', () {
    const TranscriptVersion first = (
      version: 1,
      text: 'First.',
      failedChunks: <int>[],
    );
    final List<TranscriptVersion> versions = MeetingTranscription.fold(
      existing: const <TranscriptVersion>[first],
      chunks: const <TranscriptChunk>[
        (index: 0, text: 'Second.', failed: false),
      ],
    );
    expect(versions.first.text, 'First.');
    expect(versions.last.version, 2);
    expect(versions.last.text, 'Second.');
  });
}
