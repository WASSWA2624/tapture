import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/captions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/security/untrusted_text.dart';
import 'package:tapture/features/projects/projects.dart'
    show ProjectSettingsResolved;
import 'package:tapture/features/settings/settings.dart';

import '../domain/extraction_request.dart';
import '../domain/online_skip_rule.dart';
import '../domain/processing_job.dart';
import '../domain/request_batching.dart';
import 'caption_refinement_service.dart';
import 'job_writes.dart';
import 'on_device_stage.dart';
import 'online_budget.dart';
import 'online_completion.dart';
import 'online_extraction.dart';
import 'online_transcripts.dart';
import 'photo_paths.dart';
import 'processing_snapshot.dart';
import 'record_bundle.dart';
import 'record_bundle_loader.dart';
import 'response_store.dart';
import 'stage_settings.dart';
import 'stage_support.dart';

/// Extraction of a versioned local record with explicit evidence relationships.
final class OnlineStage {
  /// Creates the stage over the existing local queue and evidence stores.
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
    this._loader,
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
  final RecordBundleLoader? _loader;

  /// Rebuilds identity without dispatching; proposal/cache readers use it too.
  Future<String> currentRevision(ProcessingJob job, RecordBundle bundle) async {
    final selection = _settings.selection(bundle, AiOperation.extractFields);
    return _revision(
      bundle,
      await _sources(
        job,
        bundle,
        allowOnline: false,
        cancel: CancellationToken(),
      ),
      await _paths.privacyRevision(bundle),
      selection.provider.id,
      selection.model.id,
    );
  }

  /// Offline or unavailable analysis remains queued, with local evidence intact.
  Future<void> run(
    ProcessingJob job,
    RecordBundle bundle,
    CancellationToken cancel,
  ) async {
    _check(cancel);
    final List<SkipField> local = await _completion.forOnline(job, bundle);
    final String? localReason = OnlineSkipRule.reason(local);
    if (localReason != null) {
      await _writes.setSkip(job.id, localReason);
      return;
    }
    if (_settings.read(SettingKeys.offlineByChoice)) {
      throw const CancelledFailure(
        message: 'Analysis is queued while offline mode is on.',
        recoveryAction: 'Continue capturing, then resume analysis when ready.',
      );
    }
    final ProjectSettingsResolved projectSettings = _settings.project(bundle);
    if (!projectSettings.aiEnabled) {
      await _writes.setSkip(job.id, 'Online analysis is off for this project.');
      return;
    }
    final selection = _settings.selection(bundle, AiOperation.extractFields);
    final AiService service = selection.provider.service;
    if (!service.isAvailable || selection.fellBack) {
      throw const CancelledFailure(
        message: 'The selected analysis provider or model is unavailable.',
        recoveryAction:
            'Check the selection, then resume this queued analysis.',
      );
    }
    final String scope = _settings.egressScope(bundle);
    final double approvedMaxCost = _settings.read(SettingKeys.aiRequestMaxCost);
    Future<void> verifyScope() async {
      _check(cancel);
      final RecordBundle current =
          await _loader?.load(bundle.record.id) ?? bundle;
      if (_settings.egressScope(current) != scope) {
        throw const CancelledFailure(
          message: 'The selected account, model or spending limit changed.',
          recoveryAction: 'Resume processing to preview the updated selection.',
        );
      }
    }

    if (_settings.read(SettingKeys.aiRefineCaptions)) {
      final List<String> rejected = await _captionRefinement.refine(
        jobId: job.id,
        job: job,
        project: bundle.project,
        captions: bundle.captions,
        cancel: cancel,
        beforeRequest: () async {
          _check(cancel);
          await verifyScope();
          await _budget.require(job.id, bundle);
        },
      );
      if (rejected.isNotEmpty) await _writes.appendRejections(job.id, rejected);
      bundle = await _loader?.load(bundle.record.id) ?? bundle;
    }
    _check(cancel);
    final String privacyRevision = await _paths.privacyRevision(bundle);
    final List<Map<String, Object?>> sources = await _sources(
      job,
      bundle,
      allowOnline: true,
      cancel: cancel,
      beforeRequest: verifyScope,
    );
    _check(cancel);
    final String revision = await _revision(
      bundle,
      sources,
      privacyRevision,
      selection.provider.id,
      selection.model.id,
      approvedMaxCost: approvedMaxCost,
    );
    final String sourceRevision = await ProcessingSnapshot.sourceRevision(
      bundle,
      privacyRevision: '',
    );
    final List<String> images = projectSettings.doNotSendImages
        ? const <String>[]
        : await _paths.compressed(bundle, cancel: cancel);
    final List<List<String>> batches = RequestBatching.split(images);
    final OnlineExtraction extraction = OnlineExtraction(
      budget: _budget,
      responses: _responses,
      writes: _writes,
    );
    for (var index = 0; index < batches.length; index++) {
      _check(cancel);
      final List<String> batch = batches[index];
      final Set<String> photoIds = images.isEmpty
          ? <String>{}
          : <String>{
              for (var offset = 0; offset < batch.length; offset++)
                bundle.photos[index * ExtractionRequest.imageCap + offset].id,
            };
      final List<Map<String, Object?>> batchSources = <Map<String, Object?>>[
        for (final Map<String, Object?> source in sources)
          if (source['kind'] != 'photo' || photoIds.contains(source['photoId']))
            <String, Object?>{
              ...source,
              if (source['kind'] == 'photo')
                'imageIndex':
                    bundle.photos.indexWhere(
                      (Photo photo) => photo.id == source['photoId'],
                    ) -
                    index * ExtractionRequest.imageCap,
            },
      ];
      final ExtractionRequest request = ExtractionRequest(
        template: bundle.template.name,
        fields: <ExtractionField>[
          for (final TemplateField field in StageSupport.extractionFields(
            bundle,
          ))
            StageSupport.extractionField(field),
        ],
        context: StageSupport.extractionContext(bundle),
        predefinedRows: <String>[
          for (final TemplateRow row in bundle.rows) row.label,
        ],
        caption: const UntrustedText(''),
        ocrText: const UntrustedText(''),
        images: batch,
        sources: batchSources,
        basis: projectSettings.doNotSendImages ? Copy.egressTextOnly : '',
      );
      await extraction.run(
        job: job,
        bundle: bundle,
        service: service,
        request: request,
        batch: index,
        revision: revision,
        sourceRevision: sourceRevision,
        privacyRevision: privacyRevision,
        providerId: selection.provider.id,
        modelId: selection.model.id,
        cancel: cancel,
        approvedMaxCost: approvedMaxCost,
        isCurrent: () async {
          _check(cancel);
          final RecordBundle current =
              await _loader?.load(bundle.record.id) ?? bundle;
          if (_settings.egressScope(current) != scope) return false;
          final choice = _settings.selection(
            current,
            AiOperation.extractFields,
          );
          if (!choice.provider.service.isAvailable || choice.fellBack) {
            return false;
          }
          final List<Map<String, Object?>> currentSources = await _sources(
            job,
            current,
            allowOnline: false,
            cancel: cancel,
          );
          return await _revision(
                current,
                currentSources,
                await _paths.privacyRevision(current),
                choice.provider.id,
                choice.model.id,
              ) ==
              revision;
        },
      );
    }
    _check(cancel);
  }

  Future<String> _revision(
    RecordBundle bundle,
    List<Map<String, Object?>> sources,
    String privacy,
    String provider,
    String model, {
    double? approvedMaxCost,
  }) => ProcessingSnapshot.revision(
    bundle,
    privacyRevision: privacy,
    sources: sources,
    provider: provider,
    model: model,
    language: _settings.read(SettingKeys.voiceLanguage),
    holdImages: _settings.project(bundle).doNotSendImages,
    maxCost: approvedMaxCost ?? _settings.read(SettingKeys.aiRequestMaxCost),
  );

  Future<List<Map<String, Object?>>> _sources(
    ProcessingJob job,
    RecordBundle bundle, {
    required bool allowOnline,
    required CancellationToken cancel,
    Future<void> Function()? beforeRequest,
  }) async => <Map<String, Object?>>[
    if (!_settings.project(bundle).doNotSendImages)
      for (final Photo photo in bundle.photos)
        <String, Object?>{
          'id': 'photo:${photo.id}',
          'kind': 'photo',
          'photoId': photo.id,
          'sha256': await _paths.ocrContentHash(bundle, photo, cancel: cancel),
        },
    ...await _onDevice.sources(bundle),
    for (final Caption caption in bundle.captions)
      <String, Object?>{
        'id': 'caption:${caption.id}',
        'kind': 'caption',
        'ownerType': caption.ownerType.name,
        'ownerId': caption.ownerId,
        if (caption.ownerType == CaptionOwnerType.photo)
          'photoId': caption.ownerId,
        'text': caption.textRefined ?? caption.textRaw,
      },
    ...await _transcripts.sourcesForJob(
      job,
      bundle,
      allowOnline: allowOnline,
      cancel: cancel,
      beforeRequest: beforeRequest,
    ),
  ];
}

void _check(CancellationToken cancel) {
  if (cancel.isCancelled) throw const CancelledFailure();
}
