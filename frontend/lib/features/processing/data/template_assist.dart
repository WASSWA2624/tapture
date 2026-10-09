import 'dart:convert';

import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/features/projects/projects.dart'
    show ProjectSettingsResolved;
import 'package:tapture/features/settings/settings.dart';

import '../domain/extraction_request.dart';
import '../domain/processing_job.dart';
import '../domain/response_parser.dart';
import '../domain/template_choice_needed.dart';
import 'extraction_responses.dart';
import 'on_device_stage.dart';
import 'online_budget.dart';
import 'processing_snapshot.dart';
import 'record_bundle.dart';
import 'record_bundle_loader.dart';
import 'response_store.dart';
import 'stage_settings.dart';
import 'stage_support.dart';

/// The model's turn in template detection: asked only after local scoring
/// failed to decide, and only about the shortlist it produced.
///
/// One text-only request through the project's extraction provider, counted
/// against the daily cap and stored as it arrived before parsing. Anything
/// short of a clean answer from the shortlist — no provider, offline, AI
/// off, the cap reached, a failed call or an unreadable reply — leaves the
/// question for the operator.
final class TemplateAssist {
  /// Creates the assist.
  const TemplateAssist({
    required this._loader,
    required this._settings,
    required this._onDevice,
    required this._budget,
    required this._responses,
  });

  final RecordBundleLoader _loader;
  final StageSettings _settings;
  final OnDeviceStage _onDevice;
  final OnlineBudget _budget;
  final ResponseStore _responses;

  /// The template the model chose from [needed]'s shortlist, or null.
  Future<String?> choose(
    ProcessingJob job,
    TemplateChoiceNeeded needed, [
    CancellationToken? cancel,
  ]) async {
    if (needed.shortlist.isEmpty ||
        _settings.read(SettingKeys.offlineByChoice) ||
        (cancel?.isCancelled ?? false)) {
      return null;
    }
    try {
      final RecordBundle bundle = await _loader.load(needed.recordId);
      final ProjectSettingsResolved project = _settings.project(bundle);
      if (!project.aiEnabled) {
        return null;
      }
      final choice = _settings.selection(bundle, AiOperation.extractFields);
      final AiService service = choice.provider.service;
      if (!service.isAvailable) {
        return null;
      }
      final List<String> labels = <String>[
        for (final ({String templateId, String label}) option
            in needed.shortlist)
          option.label,
      ];
      final double approvedMaxCost = _settings.read(
        SettingKeys.aiRequestMaxCost,
      );
      final String scope = _settings.egressScope(bundle);
      final String sourceRevision = await ProcessingSnapshot.sourceRevision(
        bundle,
        privacyRevision: '',
      );
      if ((needed.sourceRevision != null &&
              needed.sourceRevision != sourceRevision) ||
          (needed.recordRevision != null &&
              needed.recordRevision != bundle.record.rev) ||
          (needed.analysisScope != null && needed.analysisScope != scope)) {
        return null;
      }
      final List<Map<String, Object?>> sources = await _onDevice.sources(
        bundle,
      );
      final String revision = await ProcessingSnapshot.auxiliaryRevision(
        <String, Object?>{
          'operation': 'detectTemplate',
          'sourceRevision': sourceRevision,
          'scope': scope,
          'sources': sources,
          'options': <Map<String, String>>[
            for (final option in needed.shortlist)
              <String, String>{'id': option.templateId, 'label': option.label},
          ],
        },
      );
      final ExtractionResponses checkpoints = ExtractionResponses(_responses);
      final ProcessingResult? cached = await checkpoints.latest(
        job,
        revision: revision,
        batchKey: 'detectTemplate',
      );
      if (cached != null) {
        if (!await _isCurrent(bundle, sourceRevision, scope, cancel)) {
          return null;
        }
        final String? answer = _answer(cached.rawResponse, labels, needed);
        if (answer != null && !cached.parsedOk) {
          StageSupport.unwrap(await _responses.markParsed(cached.id));
        }
        if (!await _isCurrent(bundle, sourceRevision, scope, cancel)) {
          return null;
        }
        return answer;
      }
      final String identity = ProcessingSnapshot.requestId(
        revision: revision,
        recordId: bundle.record.id,
        generation: job.requestGeneration,
        batch: 0,
        repair: 0,
      );
      if (!await checkpoints.hasAttempt(job, identity)) {
        await _budget.require(job.id, bundle);
      }
      if (cancel?.isCancelled ?? false) return null;
      await checkpoints.begin(
        job: job,
        summary: <String, Object?>{
          'operation': 'detectTemplate',
          'batchKey': 'detectTemplate',
          'imageCount': 0,
          'projectRevision': revision,
          'idempotencyKey': identity,
          'requestGeneration': job.requestGeneration,
          'sourceRevision': sourceRevision,
          'provider': choice.provider.id,
          'model': choice.model.id,
        },
      );
      if (cancel?.isCancelled ?? false) return null;
      final ExtractFieldsResult result = StageSupport.unwrap(
        await service.extractFields(
          ExtractFieldsRequest(
            templateLabel: _field,
            fieldLabels: const <String>[_field],
            ocrText: await _onDevice.text(bundle),
            transcripts: const <String>[],
            captions: <String>[
              for (final Caption caption in bundle.captions)
                if (caption.textRaw.trim().isNotEmpty) caption.textRaw,
            ],
            imagePaths: const <String>[],
            context: StageSupport.extractionContext(bundle),
            fieldSchema: <Map<String, Object?>>[
              <String, Object?>{
                'key': _field,
                'type': 'choice',
                'required': true,
                'options': labels,
              },
            ],
            predefinedRows: const <String>[],
            rules: ExtractionRequest.defaultRules,
            sources: sources,
            projectRevision: revision,
            recordId: bundle.record.id,
            idempotencyKey: identity,
            approvedMaxCost: approvedMaxCost,
            cancellationToken: cancel,
          ),
        ),
      );
      final String raw =
          result.rawResponse ??
          jsonEncode(<String, Object?>{
            'fields': <String, Object?>{
              _field: <String, Object?>{
                'value': result.fields[_field],
                'confidence': 0,
              },
            },
          });
      final ProcessingResult stored = StageSupport.unwrap(
        await _responses.save(
          jobId: job.id,
          requestSummary: jsonEncode(<String, Object?>{
            'kind': 'online',
            'operation': 'detectTemplate',
            'batchKey': 'detectTemplate',
            'projectRevision': revision,
            'idempotencyKey': identity,
            'requestGeneration': job.requestGeneration,
            'imageCount': 0,
            'optionCount': labels.length,
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
      if (cancel?.isCancelled ?? false) return null;
      if (!await _isCurrent(bundle, sourceRevision, scope, cancel)) {
        return null;
      }
      final String? answer = _answer(raw, labels, needed);
      if (answer == null) return null;
      StageSupport.unwrap(await _responses.markParsed(stored.id));
      if (!await _isCurrent(bundle, sourceRevision, scope, cancel)) {
        return null;
      }
      return answer;
    } on Failure {
      // The cap, the network or the provider said no: the operator decides.
      return null;
    }
  }

  Future<bool> _isCurrent(
    RecordBundle original,
    String revision,
    String scope,
    CancellationToken? cancel,
  ) async {
    if (cancel?.isCancelled ?? false) return false;
    final RecordBundle current = await _loader.load(original.record.id);
    return !(cancel?.isCancelled ?? false) &&
        current.record.rev == original.record.rev &&
        _settings.egressScope(current) == scope &&
        await ProcessingSnapshot.sourceRevision(current, privacyRevision: '') ==
            revision;
  }
}

String? _answer(String raw, List<String> labels, TemplateChoiceNeeded needed) {
  final ParseOutcome parsed = ResponseParser.parse(
    raw,
    schema: <FieldSchema>[
      (
        key: _field,
        type: 'choice',
        requiredField: true,
        pattern: null,
        options: labels,
      ),
    ],
  );
  if (!parsed.ok) return null;
  final String? answer = parsed.fields[_field]?.value?.trim().toLowerCase();
  for (final option in needed.shortlist) {
    if (option.label.trim().toLowerCase() == answer) return option.templateId;
  }
  return null;
}

/// The one field the assist asks about, quoted as data.
const String _field = 'template';
