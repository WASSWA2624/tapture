import 'dart:convert';

import 'package:tapture/core/db/app_database.dart';

import '../domain/extraction_request.dart';
import '../domain/processing_job.dart';
import 'response_store.dart';
import 'stage_support.dart';

/// Durable extraction checkpoints scoped to exact content and batch identity.
final class ExtractionResponses {
  /// Reuses the append-only response store.
  const ExtractionResponses(this._store);

  final ResponseStore _store;

  /// A resumed identity already consumes a request slot; it cannot bill again.
  Future<bool> hasAttempt(ProcessingJob job, String identity) async =>
      StageSupport.unwrap(await _store.forJob(job.id)).any(
        (ProcessingResult row) =>
            StageSupport.summaryValue(row.requestSummary, 'kind') ==
                'attempt' &&
            StageSupport.summaryValue(row.requestSummary, 'idempotencyKey') ==
                identity,
      );

  /// Latest response for this snapshot and operator retry generation.
  Future<ProcessingResult?> latest(
    ProcessingJob job, {
    required String revision,
    required String batchKey,
    String kind = 'online',
  }) async {
    final List<ProcessingResult> responses = StageSupport.unwrap(
      await _store.forJob(job.id),
    );
    for (final ProcessingResult response in responses.reversed) {
      final Object? summary = StageSupport.json(response.requestSummary);
      if (summary is Map &&
          summary['kind'] == kind &&
          summary['projectRevision'] == revision &&
          summary['batchKey'] == batchKey &&
          (response.parsedOk ||
              (summary['requestGeneration'] ?? 0) == job.requestGeneration)) {
        return response;
      }
    }
    return null;
  }

  /// Binds an unchanged successful cached reply to the current local generation.
  Future<void> replay(ProcessingJob job, ProcessingResult cached) async {
    final Object? decoded = StageSupport.json(cached.requestSummary);
    if (decoded is! Map<String, Object?> ||
        (decoded['requestGeneration'] ?? 0) == job.requestGeneration) {
      return;
    }
    final Map<String, Object?> summary = Map<String, Object?>.of(decoded)
      ..remove('usage')
      ..addAll(<String, Object?>{
        'kind': 'cache',
        'cacheOf': cached.id,
        'requestGeneration': job.requestGeneration,
      });
    StageSupport.unwrap(
      await _store.save(
        jobId: job.id,
        requestSummary: jsonEncode(summary),
        rawResponse: cached.rawResponse,
        parsedOk: true,
      ),
    );
  }

  /// Persists the immutable input snapshot before any remote dispatch.
  Future<void> begin({
    required ProcessingJob job,
    required Map<String, Object?> summary,
  }) async {
    final List<ProcessingResult> rows = StageSupport.unwrap(
      await _store.forJob(job.id),
    );
    if (rows.any(
      (ProcessingResult row) =>
          StageSupport.summaryValue(row.requestSummary, 'idempotencyKey') ==
              summary['idempotencyKey'] &&
          StageSupport.summaryValue(row.requestSummary, 'kind') == 'attempt',
    )) {
      return;
    }
    StageSupport.unwrap(
      await _store.save(
        jobId: job.id,
        requestSummary: jsonEncode(<String, Object?>{
          ...summary,
          'kind': 'attempt',
        }),
        rawResponse: '',
        parsedOk: false,
      ),
    );
  }

  /// Adapter fakes may return fields only; evidence is still resolved locally.
  static String canonical(
    Map<String, String?> fields,
    ExtractionRequest request,
  ) => jsonEncode(<String, Object?>{
    'fields': <String, Object?>{
      for (final MapEntry<String, String?> entry in fields.entries)
        entry.key: <String, Object?>{
          'value': entry.value,
          'confidence': 0,
          'evidence': <String>[
            if (entry.value != null && entry.value!.trim().isNotEmpty)
              for (final Map<String, Object?> source in request.sources)
                if (source['text'] case final String text)
                  if (text.toLowerCase().contains(
                    entry.value!.trim().toLowerCase(),
                  ))
                    source['id']! as String,
          ],
        },
    },
  });

  /// Shape and identities only; content already lives in durable local sources.
  static List<Map<String, Object?>> references(
    List<Map<String, Object?>> sources,
  ) => <Map<String, Object?>>[
    for (final Map<String, Object?> source in sources)
      Map<String, Object?>.of(source)..remove('text'),
  ];
}
