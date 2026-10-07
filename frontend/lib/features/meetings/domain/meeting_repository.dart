import 'dart:typed_data';

import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/picked_document.dart';

import 'meeting.dart';
import 'meeting_attachment.dart';
import 'meeting_transcription.dart';

/// Persistence port for a meeting and the rows under it (task 017).
abstract interface class MeetingRepository {
  /// Stores [meeting] against [recordId], filing a new record under the
  /// installed template [templateId]. Without one, the project's installed
  /// meeting template is used.
  ///
  /// The first save preserves [notes] as the original and writes [transcript].
  /// Later saves keep both originals and every transcription version, while
  /// auditing changes to working [notes] and refined [minutes]. Legacy meetings
  /// snapshot their previous notes on the first write.
  Future<Result<MeetingRecord>> save(
    Meeting meeting, {
    required String recordId,
    String? templateId,
    String notes = '',
    String transcript = '',
    String minutes = '',
  });

  /// The meeting [id], or null when it is not on this device.
  Future<Result<MeetingRecord?>> read(String id);

  /// The id of the meeting filed on record [recordId], or null when the
  /// record is not a meeting.
  Future<Result<String?>> meetingOfRecord(String recordId);

  /// Where a new file named [name] on meeting [meetingId] is written, under
  /// the storage root.
  Future<Result<String>> storagePathFor(String meetingId, String name);

  /// Writes [bytes] as the file [name] and hangs it on meeting [meetingId].
  Future<Result<MeetingAttachment>> attachFile(
    String meetingId, {
    required String name,
    required String mimeType,
    required Uint8List bytes,
  });

  /// Copies the picked [document] into the project folder and hangs it on
  /// meeting [meetingId], keeping its name and reading its type from it.
  Future<Result<MeetingAttachment>> attachDocument(
    String meetingId,
    PickedDocument document,
  );

  /// Hangs a file already written at [storagePath] (from [storagePathFor])
  /// on meeting [meetingId], such as a recording, finished or interrupted.
  Future<Result<MeetingAttachment>> attachStored(
    String meetingId, {
    required String storagePath,
    required String mimeType,
    required int bytes,
    required String sha256,
    Duration? duration,
  });

  /// The bytes of [file] on meeting [meetingId].
  Future<Result<Uint8List>> readFile(String meetingId, MeetingAttachment file);

  /// A path to [file] that an on-device reader, such as OCR, can open.
  Future<Result<String>> servicePath(String meetingId, MeetingAttachment file);

  /// Transcribes the recording [file] chunk by chunk through
  /// [transcribeChunk], reporting each chunk to [onProgress], and stores the
  /// run as a new version. A failed chunk loses only itself; earlier
  /// versions and the raw transcript are never replaced.
  Future<Result<List<TranscriptVersion>>> transcribe(
    String meetingId,
    MeetingAttachment file, {
    required Future<Result<String>> Function(String clipPath) transcribeChunk,
    void Function(int done, int total)? onProgress,
  });
}

/// A stored meeting with immutable original notes, editable working notes,
/// refined minutes, the verbatim transcript, transcription runs and files.
typedef MeetingRecord = ({
  Meeting meeting,
  String originalNotes,
  String notes,
  String minutes,
  String transcript,
  List<TranscriptVersion> transcripts,
  List<MeetingAttachment> attachments,
});
