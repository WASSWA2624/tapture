import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/features/meetings/domain/meeting.dart';
import 'package:tapture/features/meetings/domain/meeting_attachment.dart';
import 'package:tapture/features/meetings/domain/meeting_repository.dart';
import 'package:tapture/features/meetings/domain/meeting_transcription.dart';

void main() {
  test('a save can be read back, and a later transcript is ignored', () async {
    final _Memory memory = _Memory();
    final Result<MeetingRecord> saved = await memory.save(
      Meeting(
        id: '',
        projectId: 'p1',
        title: 'Kick-off',
        startedAt: DateTime.utc(2026, 9, 27),
      ),
      recordId: 'r1',
      transcript: 'verbatim',
    );
    final MeetingRecord stored = (saved as Success<MeetingRecord>).value;
    final Result<MeetingRecord> again = await memory.save(
      stored.meeting,
      recordId: 'r1',
      transcript: 'replaced',
      minutes: 'refined',
    );
    final MeetingRecord next = (again as Success<MeetingRecord>).value;
    expect(next.transcript, 'verbatim');
    expect(next.minutes, 'refined');
    expect(
      (await memory.read('missing') as Success<MeetingRecord?>).value,
      isNull,
    );
  });
}

final class _Memory implements MeetingRepository {
  MeetingRecord? _stored;

  @override
  Future<Result<MeetingRecord>> save(
    Meeting meeting, {
    required String recordId,
    String? templateId,
    String notes = '',
    String transcript = '',
    String minutes = '',
  }) async {
    final String id = meeting.id.isEmpty ? 'm1' : meeting.id;
    _stored = (
      meeting: meeting.copyWith(id: id, recordId: recordId),
      originalNotes: _stored?.originalNotes ?? notes,
      notes: notes,
      minutes: minutes,
      transcript: _stored?.transcript ?? transcript,
      transcripts: const <TranscriptVersion>[],
      attachments: const <MeetingAttachment>[],
    );
    return Success<MeetingRecord>(_stored!);
  }

  @override
  Future<Result<MeetingRecord?>> read(String id) async {
    final MeetingRecord? stored = _stored;
    if (stored == null || stored.meeting.id != id) {
      return const Success<MeetingRecord?>(null);
    }
    return Success<MeetingRecord?>(stored);
  }

  @override
  Future<Result<String?>> meetingOfRecord(String recordId) async {
    final MeetingRecord? stored = _stored;
    if (stored == null || stored.meeting.recordId != recordId) {
      return const Success<String?>(null);
    }
    return Success<String?>(stored.meeting.id);
  }

  @override
  Future<Result<String>> storagePathFor(String meetingId, String name) async {
    return Success<String>('meetings/$meetingId/$name');
  }

  @override
  Future<Result<MeetingAttachment>> attachFile(
    String meetingId, {
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    return Success<MeetingAttachment>(
      MeetingAttachment(
        id: 'file',
        relativePath: name,
        mimeType: mimeType,
        bytes: bytes.length,
      ),
    );
  }

  @override
  Future<Result<MeetingAttachment>> attachDocument(
    String meetingId,
    PickedDocument document,
  ) async {
    return Success<MeetingAttachment>(
      MeetingAttachment(
        id: 'doc',
        relativePath: document.name,
        mimeType: 'application/octet-stream',
        bytes: 0,
      ),
    );
  }

  @override
  Future<Result<MeetingAttachment>> attachStored(
    String meetingId, {
    required String storagePath,
    required String mimeType,
    required int bytes,
    required String sha256,
    Duration? duration,
  }) async {
    return Success<MeetingAttachment>(
      MeetingAttachment(
        id: 'stored',
        relativePath: storagePath,
        mimeType: mimeType,
        bytes: bytes,
        duration: duration,
      ),
    );
  }

  @override
  Future<Result<Uint8List>> readFile(
    String meetingId,
    MeetingAttachment file,
  ) async {
    return Success<Uint8List>(Uint8List(0));
  }

  @override
  Future<Result<String>> servicePath(
    String meetingId,
    MeetingAttachment file,
  ) async {
    return Success<String>(file.relativePath);
  }

  @override
  Future<Result<List<TranscriptVersion>>> transcribe(
    String meetingId,
    MeetingAttachment file, {
    required Future<Result<String>> Function(String clipPath) transcribeChunk,
    void Function(int done, int total)? onProgress,
  }) async {
    return const Success<List<TranscriptVersion>>(<TranscriptVersion>[]);
  }
}
