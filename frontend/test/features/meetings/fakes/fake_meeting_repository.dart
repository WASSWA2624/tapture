import 'dart:typed_data';

import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/features/meetings/domain/meeting.dart';
import 'package:tapture/features/meetings/domain/meeting_attachment.dart';
import 'package:tapture/features/meetings/domain/meeting_repository.dart';
import 'package:tapture/features/meetings/domain/meeting_transcription.dart';

/// In-memory [MeetingRepository] for presentation tests that must not open
/// a database (FE-STATE-10).
///
/// It holds the [records] a test seeds, hands out one take path per
/// [storagePathFor] call and records every [attachStored] call in
/// [stored]. A failure set in [attachFailure] is returned once by the next
/// [attachStored], and one in [readFailure] by every [read].
final class FakeMeetingRepository implements MeetingRepository {
  /// Meetings by id.
  final Map<String, MeetingRecord> records = <String, MeetingRecord>{};

  /// Files hung on a meeting through [attachStored], in order.
  final List<({String meetingId, MeetingAttachment file, String sha256})>
  stored = <({String meetingId, MeetingAttachment file, String sha256})>[];

  /// Returned once by the next [attachStored], when set.
  Failure? attachFailure;

  /// Returned by every [read] instead of a meeting, while set.
  Failure? readFailure;

  /// Returned by every [save] while set, after [beforeSave] completes.
  Failure? saveFailure;

  /// Optional pause before a save, for serialisation and pending-edit tests.
  Future<void> Function()? beforeSave;

  int _paths = 0;

  /// Seeds [meeting] with [notes], [transcript] and online [versions].
  void seed(
    Meeting meeting, {
    String notes = '',
    String? originalNotes,
    String minutes = '',
    String transcript = '',
    List<TranscriptVersion> versions = const <TranscriptVersion>[],
  }) {
    records[meeting.id] = (
      meeting: meeting,
      originalNotes: originalNotes ?? notes,
      notes: notes,
      minutes: minutes,
      transcript: transcript,
      transcripts: versions,
      attachments: const <MeetingAttachment>[],
    );
  }

  @override
  Future<Result<MeetingRecord>> save(
    Meeting meeting, {
    required String recordId,
    String? templateId,
    String notes = '',
    String transcript = '',
    String minutes = '',
  }) async {
    await beforeSave?.call();
    final Failure? failure = saveFailure;
    if (failure != null) {
      return FailureResult<MeetingRecord>(failure);
    }
    final MeetingRecord? previous = records[meeting.id];
    records[meeting.id] = (
      meeting: meeting.copyWith(recordId: recordId),
      originalNotes: previous?.originalNotes ?? notes,
      notes: notes,
      minutes: minutes,
      transcript: previous?.transcript ?? transcript,
      transcripts: previous?.transcripts ?? const <TranscriptVersion>[],
      attachments: previous?.attachments ?? const <MeetingAttachment>[],
    );
    return Success<MeetingRecord>(records[meeting.id]!);
  }

  @override
  Future<Result<MeetingRecord?>> read(String id) async {
    final Failure? failure = readFailure;
    if (failure != null) {
      return FailureResult<MeetingRecord?>(failure);
    }
    return Success<MeetingRecord?>(records[id]);
  }

  @override
  Future<Result<String?>> meetingOfRecord(String recordId) async {
    for (final MeetingRecord record in records.values) {
      if (record.meeting.recordId == recordId) {
        return Success<String?>(record.meeting.id);
      }
    }
    return const Success<String?>(null);
  }

  @override
  Future<Result<String>> storagePathFor(String meetingId, String name) async {
    _paths++;
    return Success<String>('projects/alpha/meetings/$meetingId/$_paths/$name');
  }

  @override
  Future<Result<MeetingAttachment>> attachFile(
    String meetingId, {
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    return const FailureResult<MeetingAttachment>(ValidationFailure());
  }

  @override
  Future<Result<MeetingAttachment>> attachDocument(
    String meetingId,
    PickedDocument document,
  ) async {
    return const FailureResult<MeetingAttachment>(ValidationFailure());
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
    final Failure? failure = attachFailure;
    if (failure != null) {
      attachFailure = null;
      return FailureResult<MeetingAttachment>(failure);
    }
    final MeetingAttachment file = MeetingAttachment(
      id: 'attachment-${stored.length + 1}',
      relativePath: storagePath,
      mimeType: mimeType,
      bytes: bytes,
      duration: duration,
    );
    stored.add((meetingId: meetingId, file: file, sha256: sha256));
    return Success<MeetingAttachment>(file);
  }

  @override
  Future<Result<Uint8List>> readFile(
    String meetingId,
    MeetingAttachment file,
  ) async {
    return const FailureResult<Uint8List>(ValidationFailure());
  }

  @override
  Future<Result<String>> servicePath(
    String meetingId,
    MeetingAttachment file,
  ) async {
    return const FailureResult<String>(ValidationFailure());
  }

  @override
  Future<Result<List<TranscriptVersion>>> transcribe(
    String meetingId,
    MeetingAttachment file, {
    required Future<Result<String>> Function(String clipPath) transcribeChunk,
    void Function(int done, int total)? onProgress,
  }) async {
    return const FailureResult<List<TranscriptVersion>>(ValidationFailure());
  }
}
