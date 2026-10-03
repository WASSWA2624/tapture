/// Durable identity and ownership saved before the microphone starts writing.
final class PendingAudioDraft {
  /// Creates a reference to a take that has not yet been finalised.
  PendingAudioDraft({
    required this.id,
    required this.projectId,
    required this.relativePath,
    required this.storageRelativePath,
    List<String> photoIds = const <String>[],
  }) : photoIds = List<String>.unmodifiable(photoIds);

  /// Attachment identity, retained across recovery.
  final String id;

  /// Owning project.
  final String projectId;

  /// Path relative to the project folder.
  final String relativePath;

  /// Recorder path relative to the storage root.
  final String storageRelativePath;

  /// Photos selected when the take started.
  final List<String> photoIds;

  /// Interrupted-session JSON.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'projectId': projectId,
    'relativePath': relativePath,
    'storageRelativePath': storageRelativePath,
    'photoIds': photoIds,
  };

  /// Restores the durable microphone reference.
  static PendingAudioDraft fromJson(Map<String, Object?> json) {
    return PendingAudioDraft(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      relativePath: json['relativePath'] as String? ?? '',
      storageRelativePath: json['storageRelativePath'] as String? ?? '',
      photoIds: <String>[
        for (final Object? id in json['photoIds'] as List<Object?>? ?? const [])
          if (id is String) id,
      ],
    );
  }
}
