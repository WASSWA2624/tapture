import 'dart:convert';

import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/projects/projects.dart'
    show ProjectSettingsResolved;
import 'package:tapture/features/settings/settings.dart';

import '../domain/extraction_request.dart';
import '../domain/online_skip_rule.dart';
import '../domain/processing_job.dart';
import '../domain/request_batching.dart';
import '../domain/response_parser.dart';
import '../domain/response_repair.dart';
import 'caption_refinement_service.dart';
import 'job_writes.dart';
import 'on_device_stage.dart';
import 'online_budget.dart';
import 'online_completion.dart';
import 'online_transcripts.dart';
import 'photo_paths.dart';
import 'record_bundle.dart';
import 'response_store.dart';
import 'stage_settings.dart';
import 'stage_support.dart';

/// The online stage: one extraction request per batch of photos, stored as
/// it arrived before parsing, repaired at most once.
///
/// It is skipped, with the reason written on the job, when local work
/// already suffices, the device is offline by choice, the project has AI
/// off, or no provider is available.
final class OnlineStage {
  /// Creates the stage and its collaborators.
  const OnlineStage({
    required this._settings,
    required this._paths,
    required this._onDevice,
    required this._completion,
    required this._transcripts,
    required this._budget,
    required this._responses,
    required this._captionRefinement,
    required this._writes,
  });

  final StageSettings _settings;
  final PhotoPaths _paths;
  final OnDeviceStage _onDevice;
  final OnlineCompletion _completion;
  final OnlineTranscripts _transcripts;
  final OnlineBudget _budget;
  final ResponseStore _responses;
  final CaptionRefinementService _captionRefinement;
  final JobWrites _writes;

  /// Requests every batch not already parsed, then refines captions when
  /// the app setting asks for it.
  Future<void> run(
    ProcessingJob job,
    RecordBundle bundle,
    CancellationToken cancel,
  ) async {
    final List<SkipField> local = await _completion.forOnline(job, bundle);
    final String? localReason = OnlineSkipRule.reason(local);
    if (localReason != null) {
      await _writes.setSkip(job.id, localReason);
      return;
    }
    if (_settings.read(SettingKeys.offlineByChoice)) {
      await _writes.setSkip(job.id, 'Offline mode is on.');
      return;
    }
    final ProjectSettingsResolved projectSettings = _settings.project(bundle);
    if (!projectSettings.aiEnabled) {
      await _writes.setSkip(job.id, 'Online analysis is off for this project.');
      return;
    }
    final String ocrText = await _onDevice.text(bundle);
    final List<String> images = projectSettings.doNotSendImages
        ? const <String>[]
        : await _paths.compressed(bundle);
    final List<ExtractionField> fields = <ExtractionField>[
      for (final TemplateField field in bundle.fields)
        StageSupport.extractionField(field),
    ];
    final List<String> rows = <String>[
      for (final TemplateRow row in bundle.rows) row.label,
    ];
    final Map<String, String> context = StageSupport.stringMap(
      bundle.record.contextJson,
    );
    final String caption = bundle.captions
        .map((Caption row) => row.textRaw)
        .where((String value) => value.trim().isNotEmpty)
        .join('\n');
    final List<String> transcripts = await _transcripts.forJob(job, bundle);
    final selection = _settings.selection(AiOperation.extractFields);
    final AiService service = selection.provider.service;
    if (!service.isAvailable) {
      await _writes.setSkip(
        job.id,
        'No online provider is available. Local results were kept.',
      );
      return;
    }
    final List<List<String>> batches = RequestBatching.split(images);
    for (var index = 0; index < batches.length; index++) {
      final List<String> batch = batches[index];
      final String batchKey =
          '$index:${batch.map(StageSupport.basename).join('|')}';
      if (await _isBatchParsed(job.id, batchKey)) {
        continue;
      }
      final ExtractionRequest request = ExtractionRequest(
        template: bundle.template.name,
        fields: fields,
        context: context,
        predefinedRows: rows,
        caption: caption,
        ocrText: ocrText,
        images: batch,
        transcripts: transcripts,
      );
      await _requestOnce(
        job: job,
        bundle: bundle,
        service: service,
        request: request,
        batchKey: batchKey,
        providerId: selection.provider.id,
        modelId: selection.model.id,
      );
    }
    if (_settings.read(SettingKeys.aiRefineCaptions)) {
      final List<String> rejected = await _captionRefinement.refine(
        jobId: job.id,
        projectId: bundle.record.projectId,
        captions: bundle.captions,
        beforeRequest: () => _budget.require(job.id, bundle.record.projectId),
      );
      if (rejected.isNotEmpty) {
        await _writes.appendRejections(job.id, rejected);
      }
    }
  }

  Future<void> _requestOnce({
    required ProcessingJob job,
    required RecordBundle bundle,
    required AiService service,
    required ExtractionRequest request,
    required String batchKey,
    required String providerId,
    required String modelId,
  }) async {
    var repairs = 0;
    String? repairError;
    final ProcessingResult? pending = await _unparsedBatch(job.id, batchKey);
    if (pending != null) {
      final ParseOutcome parsed = ResponseParser.parse(
        pending.rawResponse,
        schema: StageSupport.schema(bundle.fields),
      );
      if (parsed.ok) {
        StageSupport.unwrap(await _responses.markParsed(pending.id));
        await _writes.setProvider(
          job.id,
          provider: StageSupport.summaryValue(
            pending.requestSummary,
            'provider',
          ),
          model: StageSupport.summaryValue(pending.requestSummary, 'model'),
        );
        return;
      }
      if (StageSupport.summaryBool(pending.requestSummary, 'repair')) {
        throw CorruptionFailure(
          message: parsed.error ?? 'The provider response is malformed.',
          recoveryAction: 'Inspect the stored response, then retry the job.',
        );
      }
      repairs = 1;
      repairError = parsed.error ?? 'The response is malformed.';
    }
    while (true) {
      await _budget.require(job.id, bundle.record.projectId);
      final ExtractFieldsRequest serviceRequest = request.toService();
      final Result<ExtractFieldsResult> result = await service.extractFields(
        ExtractFieldsRequest(
          templateLabel: serviceRequest.templateLabel,
          fieldLabels: serviceRequest.fieldLabels,
          ocrText: serviceRequest.ocrText,
          transcripts: serviceRequest.transcripts,
          captions: serviceRequest.captions,
          imagePaths: serviceRequest.imagePaths,
          context: serviceRequest.context,
          fieldSchema: serviceRequest.fieldSchema,
          predefinedRows: serviceRequest.predefinedRows,
          rules: serviceRequest.rules,
          repairError: repairError,
        ),
      );
      final ExtractFieldsResult extracted = StageSupport.unwrap(result);
      final String raw =
          extracted.rawResponse ??
          _canonicalResponse(extracted.fields, request);
      final String summary = jsonEncode(<String, Object?>{
        'kind': 'online',
        'batchKey': batchKey,
        'repair': repairError != null,
        'imageCount': request.images.length,
        'images': <String>[
          for (final String path in request.images) StageSupport.basename(path),
        ],
        'fieldCount': request.fields.length,
        'provider': providerId,
        'model': modelId,
        'promptVersion': extracted.promptVersion,
      });
      final ProcessingResult stored = StageSupport.unwrap(
        await _responses.save(
          jobId: job.id,
          requestSummary: summary,
          rawResponse: raw,
          parsedOk: false,
        ),
      );
      final ParseOutcome parsed = ResponseParser.parse(
        raw,
        schema: StageSupport.schema(bundle.fields),
      );
      if (parsed.ok) {
        StageSupport.unwrap(await _responses.markParsed(stored.id));
        await _writes.setProvider(job.id, provider: providerId, model: modelId);
        return;
      }
      if (!ResponseRepair.mayRetry(repairsUsed: repairs)) {
        throw CorruptionFailure(
          message: parsed.error ?? 'The provider response is malformed.',
          recoveryAction: 'Inspect the stored response, then retry the job.',
        );
      }
      repairs++;
      repairError = parsed.error;
    }
  }

  Future<bool> _isBatchParsed(String jobId, String batchKey) async {
    final List<ProcessingResult> responses = StageSupport.unwrap(
      await _responses.forJob(jobId),
    );
    return responses.any(
      (ProcessingResult response) =>
          response.parsedOk &&
          StageSupport.summaryValue(response.requestSummary, 'batchKey') ==
              batchKey,
    );
  }

  Future<ProcessingResult?> _unparsedBatch(
    String jobId,
    String batchKey,
  ) async {
    final List<ProcessingResult> responses = StageSupport.unwrap(
      await _responses.forJob(jobId),
    );
    for (final ProcessingResult response in responses.reversed) {
      if (!response.parsedOk &&
          StageSupport.summaryValue(response.requestSummary, 'batchKey') ==
              batchKey) {
        return response;
      }
    }
    return null;
  }
}

String _canonicalResponse(
  Map<String, String?> fields,
  ExtractionRequest request,
) {
  return jsonEncode(<String, Object?>{
    'fields': <String, Object?>{
      for (final MapEntry<String, String?> entry in fields.entries)
        entry.key: <String, Object?>{
          'value': entry.value,
          'confidence': 0,
          'evidence': _fallbackEvidence(entry.value, request),
        },
    },
  });
}

List<String> _fallbackEvidence(String? value, ExtractionRequest request) {
  if (value == null || value.trim().isEmpty) {
    return const <String>[];
  }
  final String needle = value.trim().toLowerCase();
  for (final String text in <String>[request.ocrText, request.caption]) {
    if (text.toLowerCase().contains(needle)) {
      return <String>[text];
    }
  }
  return const <String>[];
}
