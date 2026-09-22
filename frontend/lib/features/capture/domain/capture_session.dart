import 'photo_draft.dart';

/// In-progress capture: evidence, captions and typed values for one record.
///
/// Serialised so an interrupted run can resume. Widgets never rebuild this
/// themselves — mutations go through the capture controller.
final class CaptureSession {
  /// Creates a session.
  const CaptureSession({
    required this.id,
    required this.templateId,
    required this.contextSnapshot,
    this.projectId = '',
    this.recordId,
    this.photos = const <PhotoDraft>[],
    this.captions = const <String, String>{},
    this.values = const <String, Object?>{},
    this.isDirty = false,
  });

  /// Fresh session id.
  final String id;

  /// Project this session belongs to.
  final String projectId;

  /// Template in force.
  final String templateId;

  /// Context values frozen at session start / last apply.
  final Map<String, String> contextSnapshot;

  /// Persisted record id once a save has created one.
  final String? recordId;

  /// Photos in tray order.
  final List<PhotoDraft> photos;

  /// Caption text keyed by photo id, plus `''` or `record` for the record
  /// caption.
  final Map<String, String> captions;

  /// Inline field values keyed by field key.
  final Map<String, Object?> values;

  /// Whether unsaved mutations exist beyond durable photo writes.
  final bool isDirty;

  /// Record-level caption text.
  String get recordCaption => captions[''] ?? captions['record'] ?? '';

  /// Whether at least one photo or document is present.
  bool get hasEvidence => photos.isNotEmpty;

  /// JSON for interrupted-session recovery.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'projectId': projectId,
      'templateId': templateId,
      'contextSnapshot': contextSnapshot,
      'recordId': recordId,
      'photos': <Map<String, Object?>>[
        for (final PhotoDraft photo in photos) photo.toJson(),
      ],
      'captions': captions,
      'values': values,
      'isDirty': isDirty,
    };
  }

  /// Restores a session from [toJson] output.
  static CaptureSession fromJson(Map<String, Object?> json) {
    final Object? photosRaw = json['photos'];
    final List<PhotoDraft> photos = <PhotoDraft>[];
    if (photosRaw is List<Object?>) {
      for (final Object? row in photosRaw) {
        if (row is Map<String, Object?>) {
          photos.add(PhotoDraft.fromJson(row));
        } else if (row is Map) {
          photos.add(PhotoDraft.fromJson(Map<String, Object?>.from(row)));
        }
      }
    }
    final Object? captionsRaw = json['captions'];
    final Map<String, String> captions = <String, String>{};
    if (captionsRaw is Map) {
      captionsRaw.forEach((Object? key, Object? value) {
        if (key is String && value is String) {
          captions[key] = value;
        }
      });
    }
    final Object? valuesRaw = json['values'];
    final Map<String, Object?> values = <String, Object?>{};
    if (valuesRaw is Map) {
      valuesRaw.forEach((Object? key, Object? value) {
        if (key is String) {
          values[key] = value;
        }
      });
    }
    final Object? contextRaw = json['contextSnapshot'];
    final Map<String, String> context = <String, String>{};
    if (contextRaw is Map) {
      contextRaw.forEach((Object? key, Object? value) {
        if (key is String && value is String) {
          context[key] = value;
        }
      });
    }
    return CaptureSession(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      templateId: json['templateId'] as String? ?? '',
      contextSnapshot: context,
      recordId: json['recordId'] as String?,
      photos: photos,
      captions: captions,
      values: values,
      isDirty: json['isDirty'] as bool? ?? false,
    );
  }

  /// Returns a copy with the provided fields replaced.
  CaptureSession copyWith({
    String? id,
    String? projectId,
    String? templateId,
    Map<String, String>? contextSnapshot,
    String? recordId,
    bool clearRecordId = false,
    List<PhotoDraft>? photos,
    Map<String, String>? captions,
    Map<String, Object?>? values,
    bool? isDirty,
  }) {
    return CaptureSession(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      templateId: templateId ?? this.templateId,
      contextSnapshot: contextSnapshot ?? this.contextSnapshot,
      recordId: clearRecordId ? null : (recordId ?? this.recordId),
      photos: photos ?? this.photos,
      captions: captions ?? this.captions,
      values: values ?? this.values,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}
