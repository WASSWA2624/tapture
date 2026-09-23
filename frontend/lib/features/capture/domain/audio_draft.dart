/// One durable audio clip awaiting record creation.
final class AudioDraft {
  /// Creates a clip draft after the recorder has flushed its file.
  const AudioDraft({
    required this.id,
    required this.projectId,
    required this.relativePath,
    required this.mimeType,
    required this.fileSize,
    required this.sha256,
    required this.durationMs,
    this.photoIds = const <String>[],
  });

  /// Attachment id.
  final String id;

  /// Owning project.
  final String projectId;

  /// Path relative to the project folder.
  final String relativePath;

  /// Encoded media type.
  final String mimeType;

  /// Durable byte count.
  final int fileSize;

  /// Hash of original audio bytes.
  final String sha256;

  /// Recorded duration.
  final int durationMs;

  /// Photos for which the clip is evidence. Record ownership is implicit.
  final List<String> photoIds;

  /// Recovery JSON.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'projectId': projectId,
    'relativePath': relativePath,
    'mimeType': mimeType,
    'fileSize': fileSize,
    'sha256': sha256,
    'durationMs': durationMs,
    'photoIds': photoIds,
  };

  /// Restores recovery JSON.
  static AudioDraft fromJson(Map<String, Object?> json) {
    return AudioDraft(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      relativePath: json['relativePath'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'audio/wav',
      fileSize: json['fileSize'] as int? ?? 0,
      sha256: json['sha256'] as String? ?? '',
      durationMs: json['durationMs'] as int? ?? 0,
      photoIds: <String>[
        for (final Object? id in json['photoIds'] as List<Object?>? ?? const [])
          if (id is String) id,
      ],
    );
  }
}
