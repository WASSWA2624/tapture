import 'dart:convert';

import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/hash/hashing_service.dart';

import '../domain/extraction_request.dart';
import 'record_bundle.dart';

/// Content identity of the captured schema, evidence and explicit source links.
abstract final class ProcessingSnapshot {
  /// Version of the extraction and grounding contract.
  static const String promptVersion = 'grounded-record-v2';

  /// Exact auxiliary operation input and explicit account/model selection.
  static Future<String> auxiliaryRevision(Map<String, Object?> content) =>
      _hash(<String, Object?>{'promptVersion': promptVersion, ...content});

  /// Hashes original and edited source content, independent of job lifecycle.
  static Future<String> sourceRevision(
    RecordBundle bundle, {
    required String privacyRevision,
  }) => _hash(_content(bundle, privacyRevision));

  /// Hashes the exact extraction inputs, including derived text and selection.
  static Future<String> revision(
    RecordBundle bundle, {
    required String privacyRevision,
    required List<Map<String, Object?>> sources,
    required String provider,
    required String model,
    required String language,
    required bool holdImages,
    double maxCost = 0,
  }) => _hash(<String, Object?>{
    'content': _content(bundle, privacyRevision),
    'sources': sources,
    'provider': provider,
    'model': model,
    'language': language,
    'holdImages': holdImages,
    'maxCost': maxCost,
  });

  /// One stable provider identity; an operator retry deliberately starts anew.
  static String requestId({
    required String revision,
    required String recordId,
    required int generation,
    required int batch,
    required int repair,
  }) => HashingService.sha256OfString(
    jsonEncode(<Object?>[
      promptVersion,
      recordId,
      revision,
      generation,
      batch,
      repair,
    ]),
  );

  static Future<String> _hash(Map<String, Object?> content) async =>
      (await runIsolate<Map<String, Object?>, String>(
        _hashContent,
        content,
      )).getOrThrow();

  static Map<String, Object?> _content(
    RecordBundle bundle,
    String privacyRevision,
  ) => <String, Object?>{
    'promptVersion': promptVersion,
    'rules': ExtractionRequest.defaultRules,
    'projectId': bundle.project.id,
    'projectSettings': bundle.project.settings,
    'recordId': bundle.record.id,
    'templateVersion': bundle.record.templateVersion,
    'context': bundle.record.contextJson,
    'template': bundle.template.toJson(),
    'fields': <Map<String, Object?>>[
      for (final TemplateField field in bundle.fields) field.toJson(),
    ],
    'rows': <Map<String, Object?>>[
      for (final TemplateRow row in bundle.rows) row.toJson(),
    ],
    'photos': <Map<String, Object?>>[
      for (final Photo photo in bundle.photos)
        <String, Object?>{
          'id': photo.id,
          'sha256': photo.sha256,
          'order': photo.sortOrder,
          'kind': photo.photoType,
        },
    ],
    'captions': <Map<String, Object?>>[
      for (final Caption caption in bundle.captions)
        <String, Object?>{
          'id': caption.id,
          'ownerType': caption.ownerType.name,
          'ownerId': caption.ownerId,
          'raw': caption.textRaw,
          'edited': caption.textRefined,
        },
    ],
    'audio': <Map<String, Object?>>[
      for (final Attachment audio in bundle.audio)
        <String, Object?>{
          'id': audio.id,
          'sha256': audio.sha256,
          'photoIds': bundle.audioPhotoIds[audio.id] ?? const <String>[],
        },
    ],
    'deviceTranscripts': <Map<String, Object?>>[
      for (final TranscriptRow row in bundle.deviceTranscripts)
        <String, Object?>{
          'id': row.id,
          'attachmentId': row.attachmentId,
          'editedText': row.textEdited,
          'model': row.modelId,
        },
    ],
    'segments': <Map<String, Object?>>[
      for (final TranscriptSegmentRow row in bundle.transcriptSegments)
        <String, Object?>{
          'id': row.id,
          'transcriptId': row.transcriptId,
          'seq': row.seq,
          'startMs': row.startMs,
          'endMs': row.endMs,
          'text': row.textRaw,
        },
    ],
    'privacy': privacyRevision,
  };
}

String _hashContent(Map<String, Object?> content) =>
    HashingService.sha256OfString(jsonEncode(_canonical(content)));

Object? _canonical(Object? value) {
  if (value is Map<String, Object?>) {
    final List<String> keys = value.keys.toList()..sort();
    return <String, Object?>{
      for (final String key in keys) key: _canonical(value[key]),
    };
  }
  if (value is List<Object?>) {
    return <Object?>[for (final Object? entry in value) _canonical(entry)];
  }
  return value;
}
