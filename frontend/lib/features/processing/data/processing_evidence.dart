import 'package:tapture/core/ai/ocr_result.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/captions.dart';

import '../domain/evidence_linking.dart';
import 'ocr_cache.dart';
import 'photo_paths.dart';
import 'record_bundle.dart';
import 'stage_support.dart';

/// Resolves provider citations against actual retained caption/photo/audio IDs.
final class ProcessingEvidence {
  /// Shares OCR and the privacy-specific photo cache with processing.
  const ProcessingEvidence({required this._cache, this._paths});

  final OcrCache _cache;
  final PhotoPaths? _paths;

  /// Current local evidence catalogue; a provider cannot create a source here.
  Future<Map<String, Map<String, Object?>>> catalogue(
    RecordBundle bundle,
    List<ProcessingResult> responses,
  ) async {
    final Map<String, Map<String, Object?>> result =
        <String, Map<String, Object?>>{};
    for (final Photo photo in bundle.photos) {
      result['photo:${photo.id}'] = <String, Object?>{
        'id': 'photo:${photo.id}',
        'kind': 'photo',
        'photoId': photo.id,
      };
      final OcrResult? ocr = StageSupport.unwrap(
        await _cache.lookup(
          contentHash:
              await _paths?.ocrContentHash(bundle, photo) ?? photo.sha256,
          perceptualHash: '',
        ),
      );
      if (ocr != null) {
        result['ocr:${photo.id}'] = <String, Object?>{
          'id': 'ocr:${photo.id}',
          'kind': 'ocr',
          'photoId': photo.id,
          'text': ocr.text,
        };
      }
    }
    for (final Caption caption in bundle.captions) {
      result['caption:${caption.id}'] = <String, Object?>{
        'id': 'caption:${caption.id}',
        'kind': 'caption',
        if (caption.ownerType == CaptionOwnerType.photo)
          'photoId': caption.ownerId,
        'text': caption.textRefined ?? caption.textRaw,
      };
    }
    for (final Attachment audio in bundle.audio) {
      String? text;
      String? transcriptId;
      for (final TranscriptRow transcript
          in bundle.deviceTranscripts.reversed) {
        if (transcript.attachmentId != audio.id) continue;
        transcriptId = transcript.id;
        final List<TranscriptSegmentRow> segments =
            bundle.transcriptSegments
                .where(
                  (TranscriptSegmentRow row) =>
                      row.transcriptId == transcript.id,
                )
                .toList()
              ..sort((TranscriptSegmentRow a, TranscriptSegmentRow b) {
                final int time = a.startMs.compareTo(b.startMs);
                return time == 0 ? a.seq.compareTo(b.seq) : time;
              });
        text =
            transcript.textEdited ??
            segments.map((TranscriptSegmentRow row) => row.textRaw).join(' ');
        break;
      }
      for (final ProcessingResult response in responses.reversed) {
        if (text != null) break;
        if (StageSupport.summaryValue(response.requestSummary, 'kind') ==
                'transcript' &&
            StageSupport.summaryValue(
                  response.requestSummary,
                  'attachmentId',
                ) ==
                audio.id &&
            StageSupport.summaryValue(response.requestSummary, 'source') !=
                'device') {
          text = response.rawResponse;
        }
      }
      if (text != null) {
        result['audio:${audio.id}'] = <String, Object?>{
          'id': 'audio:${audio.id}',
          'kind': 'transcript',
          'attachmentId': audio.id,
          'photoIds': bundle.audioPhotoIds[audio.id] ?? const <String>[],
          'transcriptId': ?transcriptId,
          'text': text,
        };
      }
    }
    return result;
  }

  /// Every reference must resolve to a source supplied in the stored request.
  /// Legacy snippets are accepted only when found verbatim in retained text.
  static List<EvidenceDraft> resolve({
    required String value,
    required List<String> references,
    required Map<String, Map<String, Object?>> catalogue,
    required String requestSummary,
    required double confidence,
  }) {
    final Object? summary = StageSupport.json(requestSummary);
    final Object? rawSources = summary is Map ? summary['sources'] : null;
    final Set<String>? supplied = rawSources is List
        ? <String>{
            for (final Object? source in rawSources)
              if (source is Map && source['id'] is String)
                source['id'] as String,
          }
        : null;
    final List<EvidenceDraft> result = <EvidenceDraft>[];
    final Set<String> used = <String>{};
    for (final String reference in references) {
      Map<String, Object?>? source = catalogue[reference];
      if (source == null && supplied == null) {
        source = catalogue['photo:$reference'];
        source ??= catalogue.values.where((Map<String, Object?> entry) {
          final Object? text = entry['text'];
          return text is String &&
              reference.trim().isNotEmpty &&
              text.toLowerCase().contains(reference.toLowerCase());
        }).firstOrNull;
      }
      if (source == null ||
          (supplied != null && !supplied.contains(reference))) {
        return const <EvidenceDraft>[];
      }
      final String id = source['id']! as String;
      if (!used.add(id)) continue;
      final Object? text = source['text'];
      // Source IDs alone are not proof for digital text that lacks the value.
      if (text is String &&
          !text.toLowerCase().contains(value.trim().toLowerCase())) {
        return const <EvidenceDraft>[];
      }
      final String snippet = text is String ? '$id\n$text' : id;
      final String? photoId = source['photoId'] as String?;
      final List<Object?>? photoIds = source['photoIds'] as List<Object?>?;
      result.addAll(
        EvidenceLinking.forValue(
          photoId: photoId,
          snippet: snippet,
          confidence: confidence,
        ),
      );
      if (photoIds != null) {
        for (final Object? linked in photoIds) {
          if (linked is String && catalogue.containsKey('photo:$linked')) {
            result.addAll(
              EvidenceLinking.forValue(
                photoId: linked,
                snippet: snippet,
                confidence: confidence,
              ),
            );
          }
        }
      }
    }
    return result;
  }
}
