import 'dart:convert';

import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/captions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/caption_refinement.dart';
import 'response_store.dart';

/// Refines raw captions beside their originals and reuses crash-saved output.
final class CaptionRefinementService {
  /// Creates the refinement coordinator.
  CaptionRefinementService({
    required AppDatabase db,
    required Clock clock,
    required String deviceId,
    required IdService ids,
    required this._providers,
  }) : _db = db,
       _clock = clock,
       _deviceId = deviceId,
       _ids = ids,
       _responses = ResponseStore(
         db: db,
         clock: clock,
         deviceId: deviceId,
         ids: ids,
       );

  final AppDatabase _db;
  final Clock _clock;
  final String _deviceId;
  final IdService _ids;
  final ProviderRegistry _providers;
  final ResponseStore _responses;

  /// Refines every still-raw [caption] and returns rejected-change reasons.
  ///
  /// [beforeRequest] enforces the same daily budget as field extraction.
  Future<List<String>> refine({
    required String jobId,
    required String projectId,
    required List<Caption> captions,
    required Future<void> Function() beforeRequest,
  }) async {
    final AiService service = _providers.resolve(
      projectId: projectId,
      operation: AiOperation.refineText,
    );
    if (!service.isAvailable) {
      return const <String>[];
    }
    final List<ProcessingResult> stored = _value(
      await _responses.forJob(jobId),
    );
    final List<String> rejected = <String>[];
    for (final Caption caption in captions) {
      if (caption.textRefined != null || caption.textRaw.trim().isEmpty) {
        continue;
      }
      final String batchKey = 'caption:${caption.id}';
      final ProcessingResult? prior = stored
          .where(
            (ProcessingResult row) =>
                _summaryValue(row.requestSummary, 'batchKey') == batchKey,
          )
          .lastOrNull;
      if (prior != null) {
        final String? proposed = _refinedText(prior.rawResponse);
        if (proposed != null) {
          final String? reason = await _apply(caption, proposed);
          if (reason != null) {
            rejected.add(reason);
          }
          if (!prior.parsedOk) {
            _value(await _responses.markParsed(prior.id));
          }
          continue;
        }
      }
      await beforeRequest();
      final RefineTextResult result = _value(
        await service.refineText(
          RefineTextRequest(raw: caption.textRaw, style: RefineStyle.caption),
        ),
      );
      final String raw =
          result.rawResponse ??
          jsonEncode(<String, String>{'text': result.text});
      final ProcessingResult response = _value(
        await _responses.save(
          jobId: jobId,
          requestSummary: jsonEncode(<String, Object?>{
            'kind': 'online',
            'operation': 'refineText',
            'batchKey': batchKey,
            'repair': false,
            'imageCount': 0,
            'provider': result.provider,
            'model': result.model,
            'promptVersion': result.promptVersion,
          }),
          rawResponse: raw,
          parsedOk: false,
        ),
      );
      final String? proposed = _refinedText(raw);
      if (proposed == null) {
        rejected.add('The refined caption response could not be read.');
        _value(await _responses.markParsed(response.id));
        continue;
      }
      final String? reason = await _apply(caption, proposed);
      if (reason != null) {
        rejected.add(reason);
      }
      _value(await _responses.markParsed(response.id));
    }
    return rejected;
  }

  Future<String?> _apply(Caption caption, String proposed) async {
    final CaptionOutcome outcome = CaptionRefinement.refine(
      raw: caption.textRaw,
      proposed: proposed,
    );
    final String? refined = outcome.refined;
    if (!outcome.accepted || refined == null) {
      return outcome.reason ?? 'The refined caption was rejected.';
    }
    _value(
      await writeCaptionRefined(
        _db,
        id: caption.id,
        textRefined: refined,
        clock: _clock,
        deviceId: _deviceId,
        ids: _ids,
      ),
    );
    return null;
  }
}

T _value<T>(Result<T> result) {
  return result.fold(
    (Failure failure) => throw Failure.from(failure),
    (T value) => value,
  );
}

String? _refinedText(String raw) {
  try {
    final Object? decoded = jsonDecode(raw);
    if (decoded is Map && decoded['text'] is String) {
      return decoded['text'] as String;
    }
  } on FormatException {
    return null;
  }
  return null;
}

String? _summaryValue(String raw, String key) {
  try {
    final Object? decoded = jsonDecode(raw);
    if (decoded is Map && decoded[key] is String) {
      return decoded[key] as String;
    }
  } on FormatException {
    return null;
  }
  return null;
}
