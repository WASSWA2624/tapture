import 'dart:convert';

import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/extraction_request.dart';
import '../domain/processing_job.dart';
import '../domain/response_parser.dart';
import '../domain/response_repair.dart';
import 'extraction_responses.dart';
import 'job_writes.dart';
import 'online_budget.dart';
import 'processing_snapshot.dart';
import 'record_bundle.dart';
import 'response_store.dart';
import 'stage_support.dart';

/// Executes a bounded extraction/repair pair against one frozen source version.
final class OnlineExtraction {
  /// Reuses the queue's budget, raw response store and provenance writer.
  const OnlineExtraction({
    required this._budget,
    required this._responses,
    required this._writes,
  });

  final OnlineBudget _budget;
  final ResponseStore _responses;
  final JobWrites _writes;

  /// Cached replies skip sending. Source changes never commit stale proposals.
  Future<void> run({
    required ProcessingJob job,
    required RecordBundle bundle,
    required AiService service,
    required ExtractionRequest request,
    required int batch,
    required String revision,
    required String sourceRevision,
    required String privacyRevision,
    required String providerId,
    required String modelId,
    required CancellationToken cancel,
    double approvedMaxCost = 0,
    required Future<bool> Function() isCurrent,
  }) async {
    final String batchKey = batch.toString();
    final ProcessingResult? pending = await ExtractionResponses(
      _responses,
    ).latest(job, revision: revision, batchKey: batchKey);
    if (pending?.parsedOk ?? false) {
      if (!await isCurrent()) throw Failure.from(_changed);
      await ExtractionResponses(_responses).replay(job, pending!);
      return;
    }
    var repairs = 0;
    String? repairError;
    if (pending != null) {
      final ParseOutcome parsed = ResponseParser.parse(
        pending.rawResponse,
        schema: StageSupport.schema(bundle.fields),
      );
      if (parsed.ok) {
        if (cancel.isCancelled) throw const CancelledFailure();
        if (!await isCurrent()) throw Failure.from(_changed);
        StageSupport.unwrap(await _responses.markParsed(pending.id));
        return;
      }
      if (StageSupport.summaryBool(pending.requestSummary, 'repair')) {
        throw Failure.from(_malformed(parsed.error));
      }
      repairs = 1;
      repairError = parsed.error;
    }
    while (true) {
      if (cancel.isCancelled) throw const CancelledFailure();
      if (!await isCurrent()) throw Failure.from(_changed);
      final String idempotencyKey = ProcessingSnapshot.requestId(
        revision: revision,
        recordId: bundle.record.id,
        generation: job.requestGeneration,
        batch: batch,
        repair: repairs,
      );
      if (!await ExtractionResponses(
        _responses,
      ).hasAttempt(job, idempotencyKey)) {
        await _budget.require(job.id, bundle);
      }
      if (cancel.isCancelled) throw const CancelledFailure();
      final ExtractFieldsRequest base = request.toService();
      await ExtractionResponses(_responses).begin(
        job: job,
        summary: <String, Object?>{
          'idempotencyKey': idempotencyKey,
          'projectRevision': revision,
          'sourceRevision': sourceRevision,
          'privacyRevision': privacyRevision,
          'requestGeneration': job.requestGeneration,
          'batchKey': batchKey,
          'repair': repairError != null,
          'imageCount': request.images.length,
          'provider': providerId,
          'model': modelId,
          'promptVersion': ProcessingSnapshot.promptVersion,
          'sourceSnapshot': request.sources,
          'schemaSnapshot': base.fieldSchema,
          'contextSnapshot': base.context,
          'templateId': bundle.template.id,
          'templateVersion': bundle.template.version,
        },
      );
      if (cancel.isCancelled) throw const CancelledFailure();
      final Result<ExtractFieldsResult> result = await service.extractFields(
        ExtractFieldsRequest(
          templateLabel: base.templateLabel,
          fieldLabels: base.fieldLabels,
          ocrText: base.ocrText,
          transcripts: base.transcripts,
          captions: base.captions,
          imagePaths: base.imagePaths,
          context: base.context,
          fieldSchema: base.fieldSchema,
          predefinedRows: base.predefinedRows,
          rules: base.rules,
          sources: base.sources,
          projectRevision: revision,
          recordId: bundle.record.id,
          idempotencyKey: idempotencyKey,
          cancellationToken: cancel,
          approvedMaxCost: approvedMaxCost,
          repairError: repairError,
        ),
      );
      final ExtractFieldsResult extracted = StageSupport.unwrap(result);
      final String raw =
          extracted.rawResponse ??
          ExtractionResponses.canonical(extracted.fields, request);
      final String provider = extracted.provider ?? providerId;
      final String model = extracted.model ?? modelId;
      final ProcessingResult stored = StageSupport.unwrap(
        await _responses.save(
          jobId: job.id,
          requestSummary: jsonEncode(<String, Object?>{
            'kind': 'online',
            'requestGeneration': job.requestGeneration,
            'batchKey': batchKey,
            'projectRevision': revision,
            'sourceRevision': sourceRevision,
            'privacyRevision': privacyRevision,
            'idempotencyKey': idempotencyKey,
            'sources': ExtractionResponses.references(request.sources),
            'repair': repairError != null,
            'imageCount': request.images.length,
            'images': <String>[
              for (final String path in request.images)
                StageSupport.basename(path),
            ],
            'fieldCount': request.fields.length,
            'provider': provider,
            'model': model,
            'promptVersion': ProcessingSnapshot.promptVersion,
            if (extracted.billingKind != null)
              'billingKind': extracted.billingKind,
            if (extracted.usage != null) 'usage': extracted.usage!.toJson(),
          }),
          rawResponse: raw,
          parsedOk: false,
        ),
      );
      // Store the original reply even when cancellation or an edit raced it.
      if (cancel.isCancelled) throw const CancelledFailure();
      if (!await isCurrent()) throw Failure.from(_changed);
      final ParseOutcome parsed = ResponseParser.parse(
        raw,
        schema: StageSupport.schema(bundle.fields),
      );
      if (parsed.ok) {
        StageSupport.unwrap(await _responses.markParsed(stored.id));
        await _writes.setProvider(job.id, provider: provider, model: model);
        return;
      }
      if (!ResponseRepair.mayRetry(repairsUsed: repairs)) {
        throw Failure.from(_malformed(parsed.error));
      }
      repairs++;
      repairError = parsed.error;
    }
  }
}

CorruptionFailure _malformed(String? error) => CorruptionFailure(
  message: error ?? 'The provider response is malformed.',
  recoveryAction: 'Inspect the stored response, then retry the job.',
);

const CancelledFailure _changed = CancelledFailure(
  message: 'The evidence changed during analysis.',
  recoveryAction: 'Resume processing to analyse the current evidence.',
);
