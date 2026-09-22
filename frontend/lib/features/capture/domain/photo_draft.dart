import 'package:tapture/features/capture/domain/photo_repository.dart';

/// One photograph or imported page in a capture session tray.
final class PhotoDraft {
  /// Creates a draft.
  const PhotoDraft({
    required this.id,
    required this.projectId,
    required this.relativePath,
    required this.sha256,
    this.recordId,
    this.photoType = 'other',
    this.sortOrder = 0,
    this.originalFilename = '',
    this.width = 0,
    this.height = 0,
    this.fileSize = 0,
    this.mimeType = 'image/jpeg',
    this.rotationDegrees = 0,
    this.processingState = 'ready',
    this.hasCaption = false,
    this.supersededBy,
    this.derivedFrom,
  });

  /// Merge id.
  final String id;

  /// Owning project.
  final String projectId;

  /// Filed record, if any.
  final String? recordId;

  /// Path relative to the project folder.
  final String relativePath;

  /// Content hash. Immutable for the original bytes.
  final String sha256;

  /// Spec photo type key (front, serial, …).
  final String photoType;

  /// Order in the tray / export.
  final int sortOrder;

  /// Filename as captured or imported.
  final String originalFilename;

  /// Pixel width.
  final int width;

  /// Pixel height.
  final int height;

  /// Byte size.
  final int fileSize;

  /// MIME type.
  final String mimeType;

  /// Display rotation metadata only; original file unchanged.
  final int rotationDegrees;

  /// Tray processing badge: ready, scoring, warning.
  final String processingState;

  /// Whether a caption row exists.
  final bool hasCaption;

  /// Retake successor id, when superseded.
  final String? supersededBy;

  /// Parent photo id for crop / perspective derived files.
  final String? derivedFrom;

  /// Narrow [PhotoAsset] view for the existing repository typedef.
  PhotoAsset get asAsset => (
    id: id,
    projectId: projectId,
    recordId: recordId,
    relativePath: relativePath,
    sha256: sha256,
  );

  /// JSON for session persistence.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'projectId': projectId,
      'recordId': recordId,
      'relativePath': relativePath,
      'sha256': sha256,
      'photoType': photoType,
      'sortOrder': sortOrder,
      'originalFilename': originalFilename,
      'width': width,
      'height': height,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'rotationDegrees': rotationDegrees,
      'processingState': processingState,
      'hasCaption': hasCaption,
      'supersededBy': supersededBy,
      'derivedFrom': derivedFrom,
    };
  }

  /// Restores from [toJson].
  static PhotoDraft fromJson(Map<String, Object?> json) {
    return PhotoDraft(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      recordId: json['recordId'] as String?,
      relativePath: json['relativePath'] as String? ?? '',
      sha256: json['sha256'] as String? ?? '',
      photoType: json['photoType'] as String? ?? 'other',
      sortOrder: json['sortOrder'] as int? ?? 0,
      originalFilename: json['originalFilename'] as String? ?? '',
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      fileSize: json['fileSize'] as int? ?? 0,
      mimeType: json['mimeType'] as String? ?? 'image/jpeg',
      rotationDegrees: json['rotationDegrees'] as int? ?? 0,
      processingState: json['processingState'] as String? ?? 'ready',
      hasCaption: json['hasCaption'] as bool? ?? false,
      supersededBy: json['supersededBy'] as String?,
      derivedFrom: json['derivedFrom'] as String?,
    );
  }

  /// Returns a copy with the provided fields replaced.
  PhotoDraft copyWith({
    String? id,
    String? projectId,
    String? recordId,
    bool clearRecordId = false,
    String? relativePath,
    String? sha256,
    String? photoType,
    int? sortOrder,
    String? originalFilename,
    int? width,
    int? height,
    int? fileSize,
    String? mimeType,
    int? rotationDegrees,
    String? processingState,
    bool? hasCaption,
    String? supersededBy,
    String? derivedFrom,
  }) {
    return PhotoDraft(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      recordId: clearRecordId ? null : (recordId ?? this.recordId),
      relativePath: relativePath ?? this.relativePath,
      sha256: sha256 ?? this.sha256,
      photoType: photoType ?? this.photoType,
      sortOrder: sortOrder ?? this.sortOrder,
      originalFilename: originalFilename ?? this.originalFilename,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      processingState: processingState ?? this.processingState,
      hasCaption: hasCaption ?? this.hasCaption,
      supersededBy: supersededBy ?? this.supersededBy,
      derivedFrom: derivedFrom ?? this.derivedFrom,
    );
  }
}
