import 'dart:convert';

import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/features/projects/projects.dart'
    show ProjectSettingsResolved;
import 'package:tapture/features/settings/settings.dart';

import '../domain/extraction_request.dart';
import '../domain/processing_job.dart';
import '../domain/response_parser.dart';
import '../domain/template_choice_needed.dart';
import 'on_device_stage.dart';
import 'online_budget.dart';
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
  Future<String?> choose(ProcessingJob job, TemplateChoiceNeeded needed) async {
    if (needed.shortlist.isEmpty ||
        _settings.read(SettingKeys.offlineByChoice)) {
      return null;
    }
    try {
      final RecordBundle bundle = await _loader.load(needed.recordId);
      final ProjectSettingsResolved project = _settings.project(bundle);
      if (!project.aiEnabled) {
        return null;
      }
      final AiService service = _settings
          .selection(bundle, AiOperation.extractFields)
          .provider
          .service;
      if (!service.isAvailable) {
        return null;
      }
      final List<String> labels = <String>[
        for (final ({String templateId, String label}) option
            in needed.shortlist)
          option.label,
      ];
      await _budget.require(job.id, bundle);
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
            context: StageSupport.stringMap(bundle.record.contextJson),
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
            'imageCount': 0,
            'optionCount': labels.length,
            'provider': result.provider,
            'model': result.model,
            'promptVersion': result.promptVersion,
          }),
          rawResponse: raw,
          parsedOk: false,
        ),
      );
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
      if (!parsed.ok) {
        return null;
      }
      StageSupport.unwrap(await _responses.markParsed(stored.id));
      final String? answer = parsed.fields[_field]?.value?.trim().toLowerCase();
      for (final ({String templateId, String label}) option
          in needed.shortlist) {
        if (option.label.trim().toLowerCase() == answer) {
          return option.templateId;
        }
      }
      return null;
    } on Failure {
      // The cap, the network or the provider said no: the operator decides.
      return null;
    }
  }
}

/// The one field the assist asks about, quoted as data.
const String _field = 'template';
