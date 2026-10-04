/// Who a transcript belongs to, stored as the value's name (spec §30.4.6).
enum TranscriptOwnerKind {
  /// A caption recording on a record being captured. Its take is owned by
  /// the capture, which files and links the audio itself.
  capture,

  /// A meeting's recording, filed on the meeting.
  meeting,

  /// A recording made on the Transcribe screen, owned by no record.
  standalone,
}
