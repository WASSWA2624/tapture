import 'package:tapture/core/location/geo_fix.dart';
import 'package:tapture/core/security/coordinate_policy.dart';

import 'audio_draft.dart';
import 'capture_session_key.dart';
import 'document_draft.dart';
import 'pending_audio_draft.dart';
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
    this.templateVersion,
    this.projectId = '',
    this.recordId,
    this.photos = const <PhotoDraft>[],
    this.audio = const <AudioDraft>[],
    this.documents = const <DocumentDraft>[],
    this.pendingAudio = const <PendingAudioDraft>[],
    this.captions = const <String, String>{},
    this.values = const <String, Object?>{},
    this.isDirty = false,
    this.editing = false,
    this.location,
    this.valueSources = const <String, String>{},
    this.lookupRows = const <String, String>{},
  });

  /// Fresh session id.
  final String id;

  /// Project this session belongs to.
  final String projectId;

  /// Template in force.
  final String templateId;

  /// Selected shape; null before selection and zero for legacy unknown drafts.
  final int? templateVersion;

  /// Context values frozen at session start / last apply.
  final Map<String, String> contextSnapshot;

  /// Persisted record id once a save has created one.
  final String? recordId;

  /// Photos in tray order.
  final List<PhotoDraft> photos;

  /// Durable audio evidence waiting to be linked to the record.
  final List<AudioDraft> audio;

  /// Original documents, rendered only when a page is requested.
  final List<DocumentDraft> documents;

  /// References saved before recording, retained until publication succeeds.
  final List<PendingAudioDraft> pendingAudio;

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

  /// Last fix completed during this session, including its reported accuracy.
  final GeoFix? location;

  /// Explicit provenance for values filled from a scan or a reference row.
  final Map<String, String> valueSources;

  /// Dataset row id for each field that remains linked to a lookup.
  final Map<String, String> lookupRows;

  /// Where the session is stored: its project for a new capture, and
  /// [CaptureSessionKey.edit] for an edit (D6).
  String get storageKey {
    return editing ? CaptureSessionKey.edit(recordId ?? id) : projectId;
  }

  /// Record-level caption text.
  String get recordCaption => captions[''] ?? captions['record'] ?? '';

  /// Whether at least one photo or document is present.
  bool get hasEvidence =>
      photos.isNotEmpty || audio.isNotEmpty || documents.isNotEmpty;

  /// Whether anything was captured that an interruption would lose:
  /// evidence, a typed value or caption text. Template and context alone
  /// are settings, not work.
  bool get hasContent {
    return hasEvidence ||
        pendingAudio.isNotEmpty ||
        values.isNotEmpty ||
        captions.values.any((String text) => text.isNotEmpty);
  }

  /// JSON for interrupted-session recovery.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'projectId': projectId,
      'templateId': templateId,
      'templateVersion': templateVersion,
      'contextSnapshot': contextSnapshot,
      'recordId': recordId,
      'photos': <Map<String, Object?>>[
        for (final PhotoDraft photo in photos) photo.toJson(),
      ],
      'audio': <Map<String, Object?>>[
        for (final AudioDraft clip in audio) clip.toJson(),
      ],
      'documents': <Map<String, Object?>>[
        for (final DocumentDraft document in documents) document.toJson(),
      ],
      'pendingAudio': <Map<String, Object?>>[
        for (final PendingAudioDraft clip in pendingAudio) clip.toJson(),
      ],
      'captions': captions,
      'values': values,
      'isDirty': isDirty,
      'editing': editing,
      'valueSources': valueSources,
      'lookupRows': lookupRows,
      if (location case final GeoFix fix)
        'location': <String, Object?>{
          'latitude': fix.latitude,
          'longitude': fix.longitude,
          'accuracyMetres': fix.accuracyMetres,
          'capturedAt': fix.capturedAt.toIso8601String(),
        },
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
      templateVersion: json.containsKey('templateVersion')
          ? json['templateVersion'] as int?
          : 0,
      contextSnapshot: context,
      recordId: json['recordId'] as String?,
      photos: photos,
      audio: audio,
      documents: <DocumentDraft>[
        for (final Object? row
            in json['documents'] as List<Object?>? ?? const <Object?>[])
          if (row is Map)
            DocumentDraft.fromJson(Map<String, Object?>.from(row)),
      ],
      pendingAudio: <PendingAudioDraft>[
        for (final Object? row
            in json['pendingAudio'] as List<Object?>? ?? const <Object?>[])
          if (row is Map)
            PendingAudioDraft.fromJson(Map<String, Object?>.from(row)),
      ],
      captions: captions,
      values: values,
      isDirty: json['isDirty'] as bool? ?? false,
      editing: json['editing'] as bool? ?? false,
      location: _location(json['location']),
      valueSources: Map<String, String>.from(
        json['valueSources'] as Map? ?? <String, String>{},
      ),
      lookupRows: Map<String, String>.from(
        json['lookupRows'] as Map? ?? <String, String>{},
      ),
    );
  }

  /// Removes captured coordinates while retaining every other draft value.
  CaptureSession withoutCoordinates(Set<String> fieldKeys) {
    bool keep(String key) =>
        !CoordinatePolicy.isKey(key) && !fieldKeys.contains(key);
    return copyWith(
      clearLocation: true,
      photos: <PhotoDraft>[
        for (final PhotoDraft photo in photos)
          photo.copyWith(clearCoordinates: true),
      ],
      contextSnapshot: <String, String>{
        for (final MapEntry<String, String> entry in contextSnapshot.entries)
          if (keep(entry.key)) entry.key: entry.value,
      },
      values: <String, Object?>{
        for (final MapEntry<String, Object?> entry in values.entries)
          if (keep(entry.key)) entry.key: entry.value,
      },
      valueSources: <String, String>{
        for (final MapEntry<String, String> entry in valueSources.entries)
          if (keep(entry.key)) entry.key: entry.value,
      },
      lookupRows: <String, String>{
        for (final MapEntry<String, String> entry in lookupRows.entries)
          if (keep(entry.key)) entry.key: entry.value,
      },
    );
  }

  /// Returns a copy with the provided fields replaced.
  CaptureSession copyWith({
    String? id,
    String? projectId,
    String? templateId,
    int? templateVersion,
    Map<String, String>? contextSnapshot,
    String? recordId,
    bool clearRecordId = false,
    List<PhotoDraft>? photos,
    List<AudioDraft>? audio,
    List<DocumentDraft>? documents,
    List<PendingAudioDraft>? pendingAudio,
    Map<String, String>? captions,
    Map<String, Object?>? values,
    bool? isDirty,
    bool? editing,
    GeoFix? location,
    bool clearLocation = false,
    Map<String, String>? valueSources,
    Map<String, String>? lookupRows,
  }) {
    return CaptureSession(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      templateId: templateId ?? this.templateId,
      templateVersion:
          templateVersion ??
          (templateId != null && templateId != this.templateId
              ? null
              : this.templateVersion),
      contextSnapshot: contextSnapshot ?? this.contextSnapshot,
      recordId: clearRecordId ? null : (recordId ?? this.recordId),
      photos: photos ?? this.photos,
      audio: audio ?? this.audio,
      documents: documents ?? this.documents,
      pendingAudio: pendingAudio ?? this.pendingAudio,
      captions: captions ?? this.captions,
      values: values ?? this.values,
      isDirty: isDirty ?? this.isDirty,
      editing: editing ?? this.editing,
      location: clearLocation ? null : (location ?? this.location),
      valueSources: valueSources ?? this.valueSources,
      lookupRows: lookupRows ?? this.lookupRows,
    );
  }

  static GeoFix? _location(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final Object? latitude = raw['latitude'];
    final Object? longitude = raw['longitude'];
    final Object? accuracy = raw['accuracyMetres'];
    final DateTime? capturedAt = DateTime.tryParse('${raw['capturedAt']}');
    if (latitude is! num ||
        longitude is! num ||
        accuracy is! num ||
        capturedAt == null) {
      return null;
    }
    return GeoFix(
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      accuracyMetres: accuracy.toDouble(),
      capturedAt: capturedAt,
    );
  }
}
