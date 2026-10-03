/// One file hung on a meeting: an agenda, a report, a handout, a photo of a
/// whiteboard or an attendance sheet, or a recording (task 017).
///
/// The file itself stays in the project folder; this is its row.
final class MeetingAttachment {
  /// Creates an attachment. [relativePath] is under the project folder.
  const MeetingAttachment({
    required this.id,
    required this.relativePath,
    required this.mimeType,
    required this.bytes,
    this.duration,
  });

  /// Attachment row id.
  final String id;

  /// Path under the project folder. Its last segment is the file's name.
  final String relativePath;

  /// Stored media type.
  final String mimeType;

  /// Stored size in bytes.
  final int bytes;

  /// Length of a recording, when known.
  final Duration? duration;

  /// The file's name, as it was picked or recorded.
  String get name => relativePath.split('/').last;

  /// What the file is, from its media type.
  MeetingAttachmentKind get kind {
    if (mimeType.startsWith('audio/')) {
      return MeetingAttachmentKind.recording;
    }
    if (mimeType.startsWith('image/')) {
      return MeetingAttachmentKind.photo;
    }
    return MeetingAttachmentKind.document;
  }

  @override
  bool operator ==(Object other) {
    return other is MeetingAttachment &&
        other.id == id &&
        other.relativePath == relativePath &&
        other.mimeType == mimeType &&
        other.bytes == bytes &&
        other.duration == duration;
  }

  @override
  int get hashCode => Object.hash(id, relativePath, mimeType, bytes, duration);
}

/// The kinds of file a meeting keeps in its one attachment list.
enum MeetingAttachmentKind {
  /// An agenda, report or handout.
  document,

  /// A photographed handout, whiteboard or attendance sheet.
  photo,

  /// A recording of the meeting, including one that was interrupted.
  recording,
}
