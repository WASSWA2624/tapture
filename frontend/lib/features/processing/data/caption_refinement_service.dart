import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:tapture/core/ai/ai_operation.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/captions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/caption_refinement.dart';
import '../domain/processing_job.dart';
import 'extraction_responses.dart';
import 'processing_job_mapper.dart';
import 'processing_snapshot.dart';
import 'provider_selection.dart';
import 'response_store.dart';

/// Refines raw captions beside their originals and reuses crash-saved output.
final class CaptionRefinementService {
  /// Creates the refinement coordinator.
  CaptionRefinementService({
    required AppDatabase db,
    required Clock clock,
    required String deviceId,
    required IdService ids,
    required this._selection,
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
  final ProviderSelection _selection;
  final ResponseStore _responses;

  /// Refines every still-raw [caption] and returns rejected-change reasons.
  ///
  /// The provider is the one [project] selects for refining text.
  /// [beforeRequest] enforces the same daily budget as field extraction.
  Future<List<String>> refine({
    required String jobId,
    required Project project,
    required List<Caption> captions,
    required Future<void> Function() beforeRequest,
    CancellationToken? cancel,
    ProcessingJob? job,
  }) async {
    final choice = _selection.resolve(project, AiOperation.refineText);
    final AiService service = choice.provider.service;
    final double approvedMaxCost = _selection.maxCost;
    if (!service.isAvailable) {
      return const <String>[];
    }
    job ??= ProcessingJobMapper.toJob(
      await (_db.select(
        _db.processing,
      )..where(($ProcessingTable row) => row.id.equals(jobId))).getSingle(),
    );
    final List<String> rejected = <String>[];
    for (final Caption caption in captions) {
      if (cancel?.isCancelled ?? false) throw const CancelledFailure();
      if (caption.textRefined != null || caption.textRaw.trim().isEmpty) {
        continue;
      }
      final String batchKey = 'caption:${caption.id}';
      final String revision =
          await ProcessingSnapshot.auxiliaryRevision(<String, Object?>{
            'operation': 'refineText',
            'recordId': job.recordId,
            'projectId': project.id,
            'captionId': caption.id,
            'ownerType': caption.ownerType.name,
            'ownerId': caption.ownerId,
            'raw': caption.textRaw,
            'style': RefineStyle.caption.name,
            'provider': choice.provider.id,
            'model': choice.model.id,
            'maxCost': approvedMaxCost,
          });
      final ProcessingResult? prior = await ExtractionResponses(
        _responses,
      ).latest(job, revision: revision, batchKey: batchKey);
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
      final String identity = ProcessingSnapshot.requestId(
        revision: revision,
        recordId: job.recordId,
        generation: job.requestGeneration,
        batch: 0,
        repair: 0,
      );
      if (!await ExtractionResponses(_responses).hasAttempt(job, identity)) {
        await beforeRequest();
      }
      await ExtractionResponses(_responses).begin(
        job: job,
        summary: <String, Object?>{
          'operation': 'refineText',
          'batchKey': batchKey,
          'projectRevision': revision,
          'idempotencyKey': identity,
          'requestGeneration': job.requestGeneration,
          'imageCount': 0,
          'provider': choice.provider.id,
          'model': choice.model.id,
          'sourceSnapshot': <String, Object?>{
            'captionId': caption.id,
            'raw': caption.textRaw,
          },
        },
      );
      if (cancel?.isCancelled ?? false) throw const CancelledFailure();
      final RefineTextResult result = _value(
        await service.refineText(
          RefineTextRequest(
            raw: caption.textRaw,
            style: RefineStyle.caption,
            cancellationToken: cancel,
            projectRevision: revision,
            recordId: job.recordId,
            idempotencyKey: identity,
            approvedMaxCost: approvedMaxCost,
          ),
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
            'projectRevision': revision,
            'idempotencyKey': identity,
            'requestGeneration': job.requestGeneration,
            'repair': false,
            'imageCount': 0,
            'provider': result.provider,
            'model': result.model,
            'promptVersion': result.promptVersion,
            'billingKind': ?result.billingKind,
            if (result.usage != null) 'usage': result.usage!.toJson(),
          }),
          rawResponse: raw,
          parsedOk: false,
        ),
      );
      if (cancel?.isCancelled ?? false) throw const CancelledFailure();
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
    await _db.transaction(() async {
      final Caption? current =
          await (_db.select(_db.captions)
                ..where(($CaptionsTable row) => row.id.equals(caption.id)))
              .getSingleOrNull();
      final bool deleted =
          await (_db.select(_db.tombstones)..where(
                ($TombstonesTable row) =>
                    row.entityType.equals('captions') &
                    row.entityId.equals(caption.id),
              ))
              .getSingleOrNull() !=
          null;
      if (deleted ||
          current == null ||
          current.rev != caption.rev ||
          current.ownerType != caption.ownerType ||
          current.ownerId != caption.ownerId ||
          current.textRaw != caption.textRaw ||
          current.textRefined != caption.textRefined) {
        throw const CancelledFailure(
          message: 'The caption changed before refinement could be applied.',
          recoveryAction: 'Resume processing to use the current caption.',
        );
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
    });
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
    if (decoded is! Map && decoded is! List) {
      return raw.trim().isEmpty ? null : raw;
    }
  } on FormatException {
    return raw.trim().isEmpty ? null : raw;
  }
  return null;
}
