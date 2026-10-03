/// An original document durably copied before it appears in a capture.
final class DocumentDraft {
  /// Creates a document draft with immutable source-file metadata.
  const DocumentDraft({
    required this.id,
    required this.projectId,
    required this.relativePath,
    required this.originalFilename,
    required this.sha256,
    required this.fileSize,
    required this.pageCount,
    this.mimeType = 'application/pdf',
  });

  /// Attachment identity.
  final String id;

  /// Owning project.
  final String projectId;

  /// Path relative to its project folder.
  final String relativePath;

  /// Name chosen by the operator, preserved as metadata.
  final String originalFilename;

  /// Hash of the original bytes.
  final String sha256;

  /// Original byte count.
  final int fileSize;

  /// Validated number of pages, absent for formats without pages.
  final int? pageCount;

  /// Original media type.
  final String mimeType;

  /// Whether this original has PDF pages the viewer can render.
  bool get canRenderPages =>
      mimeType == 'application/pdf' && (pageCount ?? 0) > 0;

  /// Recovery metadata without copying document contents into settings.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'projectId': projectId,
    'relativePath': relativePath,
    'originalFilename': originalFilename,
    'sha256': sha256,
    'fileSize': fileSize,
    'pageCount': pageCount,
    'mimeType': mimeType,
  };

  /// Restores a persisted capture attachment.
  static DocumentDraft fromJson(Map<String, Object?> json) => DocumentDraft(
    id: json['id'] as String,
    projectId: json['projectId'] as String,
    relativePath: json['relativePath'] as String,
    originalFilename: json['originalFilename'] as String? ?? '',
    sha256: json['sha256'] as String,
    fileSize: json['fileSize'] as int,
    pageCount: json['pageCount'] as int?,
    mimeType: json['mimeType'] as String? ?? 'application/pdf',
  );
}
