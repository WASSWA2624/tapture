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
    this.captureSessionId = '',
    this.storedFilename = '',
    this.photoType = 'other',
    this.sortOrder = 0,
    this.originalFilename = '',
    this.width = 0,
    this.height = 0,
    this.fileSize = 0,
    this.mimeType = 'image/jpeg',
    this.capturedAt,
    this.gpsLat,
    this.gpsLon,
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

  /// Interrupted session that owns the unfiled evidence.
  final String captureSessionId;

  /// Filename generated for storage under the project tree.
  final String storedFilename;

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

  /// Capture time. Production writes it once with the original evidence.
  final DateTime? capturedAt;

  /// Optional capture coordinates.
  final double? gpsLat;
  final double? gpsLon;

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
      'captureSessionId': captureSessionId,
      'storedFilename': storedFilename,
      'relativePath': relativePath,
      'sha256': sha256,
      'photoType': photoType,
      'sortOrder': sortOrder,
      'originalFilename': originalFilename,
      'width': width,
      'height': height,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'capturedAt': capturedAt?.toIso8601String(),
      'gpsLat': gpsLat,
      'gpsLon': gpsLon,
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
      captureSessionId: json['captureSessionId'] as String? ?? '',
      storedFilename: json['storedFilename'] as String? ?? '',
      relativePath: json['relativePath'] as String? ?? '',
      sha256: json['sha256'] as String? ?? '',
      photoType: json['photoType'] as String? ?? 'other',
      sortOrder: json['sortOrder'] as int? ?? 0,
      originalFilename: json['originalFilename'] as String? ?? '',
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      fileSize: json['fileSize'] as int? ?? 0,
      mimeType: json['mimeType'] as String? ?? 'image/jpeg',
      capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? ''),
      gpsLat: (json['gpsLat'] as num?)?.toDouble(),
      gpsLon: (json['gpsLon'] as num?)?.toDouble(),
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
    String? captureSessionId,
    String? storedFilename,
    String? relativePath,
    String? sha256,
    String? photoType,
    int? sortOrder,
    String? originalFilename,
    int? width,
    int? height,
    int? fileSize,
    String? mimeType,
    DateTime? capturedAt,
    double? gpsLat,
    double? gpsLon,
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
      captureSessionId: captureSessionId ?? this.captureSessionId,
      storedFilename: storedFilename ?? this.storedFilename,
      relativePath: relativePath ?? this.relativePath,
      sha256: sha256 ?? this.sha256,
      photoType: photoType ?? this.photoType,
      sortOrder: sortOrder ?? this.sortOrder,
      originalFilename: originalFilename ?? this.originalFilename,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      capturedAt: capturedAt ?? this.capturedAt,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLon: gpsLon ?? this.gpsLon,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      processingState: processingState ?? this.processingState,
      hasCaption: hasCaption ?? this.hasCaption,
      supersededBy: supersededBy ?? this.supersededBy,
      derivedFrom: derivedFrom ?? this.derivedFrom,
    );
  }
}
