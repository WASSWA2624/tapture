import 'audio_draft.dart';
import 'capture_session_key.dart';
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
    this.audio = const <AudioDraft>[],
    this.captions = const <String, String>{},
    this.values = const <String, Object?>{},
    this.isDirty = false,
    this.editing = false,
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

  /// Durable audio evidence waiting to be linked to the record.
  final List<AudioDraft> audio;

  /// Caption text keyed by photo id, plus `''` or `record` for the record
  /// caption.
  final Map<String, String> captions;

  /// Inline field values keyed by field key.
  final Map<String, Object?> values;

  /// Whether unsaved mutations exist beyond durable photo writes.
  final bool isDirty;

  /// Whether this session edits the saved record [recordId] rather than
  /// capturing a new one (FBK0000148).
  final bool editing;

  /// Where the session is stored: its project for a new capture, and
  /// [CaptureSessionKey.edit] for an edit (D6).
  String get storageKey {
    return editing ? CaptureSessionKey.edit(recordId ?? id) : projectId;
  }

  /// Record-level caption text.
  String get recordCaption => captions[''] ?? captions['record'] ?? '';

  /// Whether at least one photo or document is present.
  bool get hasEvidence => photos.isNotEmpty || audio.isNotEmpty;

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
      'audio': <Map<String, Object?>>[
        for (final AudioDraft clip in audio) clip.toJson(),
      ],
      'captions': captions,
      'values': values,
      'isDirty': isDirty,
      'editing': editing,
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
    final List<AudioDraft> audio = <AudioDraft>[
      for (final Object? row
          in json['audio'] as List<Object?>? ?? const <Object?>[])
        if (row is Map) AudioDraft.fromJson(Map<String, Object?>.from(row)),
    ];
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
      audio: audio,
      captions: captions,
      values: values,
      isDirty: json['isDirty'] as bool? ?? false,
      editing: json['editing'] as bool? ?? false,
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
    List<AudioDraft>? audio,
    Map<String, String>? captions,
    Map<String, Object?>? values,
    bool? isDirty,
    bool? editing,
  }) {
    return CaptureSession(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      templateId: templateId ?? this.templateId,
      contextSnapshot: contextSnapshot ?? this.contextSnapshot,
      recordId: clearRecordId ? null : (recordId ?? this.recordId),
      photos: photos ?? this.photos,
      audio: audio ?? this.audio,
      captions: captions ?? this.captions,
      values: values ?? this.values,
      isDirty: isDirty ?? this.isDirty,
      editing: editing ?? this.editing,
    );
  }
}
