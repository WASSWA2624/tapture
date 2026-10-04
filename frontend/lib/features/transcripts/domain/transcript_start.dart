import 'transcript_owner_kind.dart';

/// What a transcript begins with, written durably before the microphone
/// opens (spec §30.4.6). [audioPath] is the storage-root-relative `.wav`
/// the take publishes to; [attachmentId] is known up front only when the
/// owner reserves one.
typedef TranscriptStart = ({
  String projectId,
  TranscriptOwnerKind ownerKind,
  String? ownerId,
  String? attachmentId,
  String audioPath,
  String title,
  String languageTag,
  String modelId,
  DateTime startedAt,
});
