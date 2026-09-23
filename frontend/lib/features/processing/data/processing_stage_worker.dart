import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/ocr_block.dart';
import 'package:tapture/core/ai/ocr_result.dart';
import 'package:tapture/core/ai/ocr_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/attachment_owners.dart';
import 'package:tapture/core/db/tables/attachments.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/field_evidence.dart';
import 'package:tapture/core/db/tables/processing.dart'
    show ProcessingJobStatus;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/compressed_copy.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/project_folders.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/hash/perceptual_hash.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/normalise/choices.dart';
import 'package:tapture/core/normalise/dates.dart';
import 'package:tapture/core/normalise/units.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/projects/projects.dart'
    show
        ProjectSettings,
        ProjectSettingsResolved,
        builtInProjectSettingsDefaults;
import 'package:tapture/features/settings/settings.dart';

import '../domain/confidence.dart';
import '../domain/evidence_linking.dart';
import '../domain/extraction_request.dart';
import '../domain/identifier_extraction.dart';
import '../domain/image_preprocess.dart';
import '../domain/no_invention_guard.dart';
import '../domain/online_skip_rule.dart';
import '../domain/processing_job.dart';
import '../domain/proposal_application.dart';
import '../domain/provenance.dart';
import '../domain/request_batching.dart';
import '../domain/response_parser.dart';
import '../domain/response_repair.dart';
import '../domain/row_matching.dart';
import 'caption_refinement_service.dart';
import 'ocr_cache.dart';
import 'processing_repository_impl.dart';
import 'response_store.dart';

/// Production implementation for the six processing stages.
///
/// Originals are read only. Derived images live in the disposable cache,
/// OCR is cached by content and perceptual hash, provider responses are
/// stored before parsing, and validation writes proposals plus evidence.
final class ProcessingStageWorker {
  /// Creates the local-first worker.
  factory ProcessingStageWorker({
    required AppDatabase db,
    required Clock clock,
    required String deviceId,
    required IdService ids,
    required StorageRoot storageRoot,
    required OcrService ocr,
    required ProviderRegistry providers,
    required SettingsStore settings,
  }) {
    return ProcessingStageWorker._(
      db: db,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
      storageRoot: storageRoot,
      ocr: ocr,
      providers: providers,
      settings: settings,
    );
  }

  ProcessingStageWorker._({
    required AppDatabase db,
    required Clock clock,
    required String deviceId,
    required IdService ids,
    required StorageRoot storageRoot,
    required this._ocr,
    required ProviderRegistry providers,
    required this._settings,
  }) : _db = db,
       _clock = clock,
       _deviceId = deviceId,
       _ids = ids,
       _storageRoot = storageRoot,
       _providers = providers,
       _folders = ProjectFolders(storageRoot: storageRoot),
       _compressed = CompressedCopy(storageRoot: storageRoot),
       _writer = FileWriter(storageRoot: storageRoot),
       _cache = OcrCache(db: db, clock: clock, deviceId: deviceId, ids: ids),
       _captionRefinement = CaptionRefinementService(
         db: db,
         clock: clock,
         deviceId: deviceId,
         ids: ids,
         providers: providers,
       ),
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
  final StorageRoot _storageRoot;
  final OcrService _ocr;
  final ProviderRegistry _providers;
  final SettingsStore _settings;
  final ProjectFolders _folders;
  final CompressedCopy _compressed;
  final FileWriter _writer;
  final OcrCache _cache;
  final CaptionRefinementService _captionRefinement;
  final ResponseStore _responses;

  /// Runs one persisted stage.
  Future<void> perform(JobStage stage, ProcessingJob job) async {
    final _Bundle bundle = await _bundle(job.recordId);
    switch (stage) {
      case JobStage.prepare:
        await _prepare(bundle);
      case JobStage.onDevice:
        await _readOnDevice(bundle);
      case JobStage.detect:
        _ensureTemplate(bundle);
      case JobStage.online:
        await _extractOnline(job, bundle);
      case JobStage.normalise:
        await _matchRow(bundle);
      case JobStage.validate:
        await _apply(job, bundle);
    }
  }

  /// Exact payload summary shown before the first provider call.
  Future<({int imageCount, int payloadBytes})> egressSummary(
    ProcessingJob job,
  ) async {
    final _Bundle bundle = await _bundle(job.recordId);
    final ProjectSettingsResolved settings = _projectSettings(bundle);
    if (OnlineSkipRule.reason(await _completionForOnline(job, bundle)) !=
            null ||
        _settings.read(SettingKeys.offlineByChoice) ||
        !settings.aiEnabled ||
        !_selection(AiOperation.extractFields).provider.service.isAvailable) {
      return (imageCount: 0, payloadBytes: 0);
    }
    final List<String> images = settings.doNotSendImages
        ? const <String>[]
        : await _compressedPaths(bundle);
    var bytes = utf8.encode(await _ocrText(bundle)).length;
    bytes += utf8.encode(bundle.template.name).length;
    for (final TemplateField field in bundle.fields) {
      bytes += utf8.encode(field.label).length;
    }
    for (final Caption caption in bundle.captions) {
      bytes += utf8.encode(caption.textRaw).length;
    }
    for (final MapEntry<String, String> entry in _stringMap(
      bundle.record.contextJson,
    ).entries) {
      bytes += utf8.encode(entry.key).length;
      bytes += utf8.encode(entry.value).length;
    }
    for (final TemplateRow row in bundle.rows) {
      bytes += utf8.encode(row.label).length;
    }
    for (final String rule in ExtractionRequest.defaultRules) {
      bytes += utf8.encode(rule).length;
    }
    for (final String path in images) {
      final File file = File(path);
      if (await file.exists()) {
        bytes += await file.length();
      }
    }
    return (imageCount: images.length, payloadBytes: bytes);
  }

  Future<void> _prepare(_Bundle bundle) async {
    for (final Photo photo in bundle.photos) {
      final String source = await _sourcePath(bundle, photo);
      final written = _value(await _compressed.reduce(source));
      final String destination = '${written.relativePath}.ocr.jpg';
      final Directory root = _value(await _storageRoot.resolve());
      if (await File('${root.path}/$destination').exists()) {
        continue;
      }
      final Uint8List reduced = await File(
        '${root.path}/${written.relativePath}',
      ).readAsBytes();
      final Uint8List prepared = _value(
        await ImagePreprocess.prepareOffThread(reduced),
      );
      if (prepared.isEmpty) {
        throw const ValidationFailure(
          message: 'That photo could not be prepared for reading.',
          recoveryAction: 'Use another photo or enter the value by hand.',
        );
      }
      _value(
        await _writer.write(Stream<List<int>>.value(prepared), destination),
      );
    }
  }

  Future<void> _readOnDevice(_Bundle bundle) async {
    for (final Photo photo in bundle.photos) {
      final String path = await _preparedPath(bundle, photo);
      final Uint8List bytes = await File(path).readAsBytes();
      final String perceptual = _value(
        await PerceptualHash.ofBytesOffThread(bytes),
      );
      final OcrResult? cached = _value(
        await _cache.lookup(
          contentHash: photo.sha256,
          perceptualHash: perceptual,
        ),
      );
      if (cached != null) {
        continue;
      }
      final OcrResult result = await _ocr.recognise(path);
      _value(
        await _cache.put(
          contentHash: photo.sha256,
          perceptualHash: perceptual,
          result: result,
        ),
      );
    }
  }

  void _ensureTemplate(_Bundle bundle) {
    if (bundle.template.id.isEmpty) {
      throw const ValidationFailure(
        message: 'This record has no template.',
        recoveryAction: 'Choose a template, then retry processing.',
      );
    }
  }

  Future<void> _extractOnline(ProcessingJob job, _Bundle bundle) async {
    final List<SkipField> local = await _completionForOnline(job, bundle);
    final String? localReason = OnlineSkipRule.reason(local);
    if (localReason != null) {
      await _setSkip(job.id, localReason);
      return;
    }
    if (_settings.read(SettingKeys.offlineByChoice)) {
      await _setSkip(job.id, 'Offline mode is on.');
      return;
    }
    final ProjectSettingsResolved projectSettings = _projectSettings(bundle);
    if (!projectSettings.aiEnabled) {
      await _setSkip(job.id, 'Online analysis is off for this project.');
      return;
    }
    final String ocrText = await _ocrText(bundle);
    final List<String> images = projectSettings.doNotSendImages
        ? const <String>[]
        : await _compressedPaths(bundle);
    final List<ExtractionField> fields = <ExtractionField>[
      for (final TemplateField field in bundle.fields) _extractionField(field),
    ];
    final List<String> rows = <String>[
      for (final TemplateRow row in bundle.rows) row.label,
    ];
    final Map<String, String> context = _stringMap(bundle.record.contextJson);
    final String caption = bundle.captions
        .map((Caption row) => row.textRaw)
        .where((String value) => value.trim().isNotEmpty)
        .join('\n');
    final List<String> transcripts = await _transcripts(job, bundle);
    final selection = _selection(AiOperation.extractFields);
    final AiService service = selection.provider.service;
    if (!service.isAvailable) {
      await _setSkip(
        job.id,
        'No online provider is available. Local results were kept.',
      );
      return;
    }
    final List<List<String>> batches = RequestBatching.split(images);
    for (var index = 0; index < batches.length; index++) {
      final List<String> batch = batches[index];
      final String batchKey = '$index:${batch.map(_basename).join('|')}';
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
        beforeRequest: () => _requireBudget(job.id, bundle.record.projectId),
      );
      if (rejected.isNotEmpty) {
        await _appendRejections(job.id, rejected);
      }
    }
  }

  Future<void> _requestOnce({
    required ProcessingJob job,
    required _Bundle bundle,
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
        schema: <FieldSchema>[
          for (final TemplateField field in bundle.fields) _schema(field),
        ],
      );
      if (parsed.ok) {
        _value(await _responses.markParsed(pending.id));
        await _setProvider(
          job.id,
          provider: _summaryValue(pending.requestSummary, 'provider'),
          model: _summaryValue(pending.requestSummary, 'model'),
        );
        return;
      }
      if (_summaryBool(pending.requestSummary, 'repair')) {
        throw CorruptionFailure(
          message: parsed.error ?? 'The provider response is malformed.',
          recoveryAction: 'Inspect the stored response, then retry the job.',
        );
      }
      repairs = 1;
      repairError = parsed.error ?? 'The response is malformed.';
    }
    while (true) {
      await _requireBudget(job.id, bundle.record.projectId);
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
      final ExtractFieldsResult extracted = _value(result);
      final String raw =
          extracted.rawResponse ??
          _canonicalResponse(extracted.fields, request);
      final String summary = jsonEncode(<String, Object?>{
        'kind': 'online',
        'batchKey': batchKey,
        'repair': repairError != null,
        'imageCount': request.images.length,
        'images': <String>[
          for (final String path in request.images) _basename(path),
        ],
        'fieldCount': request.fields.length,
        'provider': providerId,
        'model': modelId,
        'promptVersion': extracted.promptVersion,
      });
      final ProcessingResult stored = _value(
        await _responses.save(
          jobId: job.id,
          requestSummary: summary,
          rawResponse: raw,
          parsedOk: false,
        ),
      );
      final ParseOutcome parsed = ResponseParser.parse(
        raw,
        schema: <FieldSchema>[
          for (final TemplateField field in bundle.fields) _schema(field),
        ],
      );
      if (parsed.ok) {
        _value(await _responses.markParsed(stored.id));
        await _setProvider(job.id, provider: providerId, model: modelId);
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
    final List<ProcessingResult> responses = _value(
      await _responses.forJob(jobId),
    );
    return responses.any(
      (ProcessingResult response) =>
          response.parsedOk &&
          _summaryValue(response.requestSummary, 'batchKey') == batchKey,
    );
  }

  Future<ProcessingResult?> _unparsedBatch(
    String jobId,
    String batchKey,
  ) async {
    final List<ProcessingResult> responses = _value(
      await _responses.forJob(jobId),
    );
    for (final ProcessingResult response in responses.reversed) {
      if (!response.parsedOk &&
          _summaryValue(response.requestSummary, 'batchKey') == batchKey) {
        return response;
      }
    }
    return null;
  }

  Future<void> _requireBudget(String jobId, String projectId) async {
    final int used = await _onlineRequestsToday(projectId);
    final int cap = _settings.read(SettingKeys.aiDailyRequestCap);
    if (used < cap) {
      return;
    }
    final String message =
        "Today's limit of $cap requests is used. "
        'It resets at ${_nextUtcDay().toIso8601String()}.';
    await _setQueueMessage(jobId, message);
    throw CancelledFailure(
      message: message,
      recoveryAction: 'Processing will be available after the daily reset.',
    );
  }

  Future<void> _matchRow(_Bundle bundle) async {
    if (bundle.record.templateRowId != null || bundle.rows.isEmpty) {
      return;
    }
    final RowMatch? match = await RowMatching.match(
      query: await _ocrText(bundle),
      rows: <MatchableRow>[
        for (final TemplateRow row in bundle.rows)
          (id: row.id, label: row.label, aliases: _strings(row.aliases)),
      ],
    );
    if (match == null) {
      return;
    }
    await _db.transaction(() async {
      await (_db.update(_db.records)
            ..where(($RecordsTable table) => table.id.equals(bundle.record.id)))
          .write(
            RecordsCompanion(
              templateRowId: Value<String>(match.id),
              rowMatchStrategy: Value<String>(match.strategy),
              rowMatchScore: Value<double>(match.score),
              updatedAt: Value<DateTime>(_clock.nowUtc()),
              updatedByDevice: Value<String>(_deviceId),
              rev: Value<int>(bundle.record.rev + 1),
            ),
          );
      await appendAudit(
        _db,
        entityType: 'records',
        entityId: bundle.record.id,
        action: AuditAction.updated,
        fieldKey: 'templateRowId',
        previousValue: bundle.record.templateRowId,
        newValue: match.id,
        reason: jsonEncode(<String, Object>{
          'method': match.strategy,
          'score': match.score,
        }),
        clock: _clock,
        device: _deviceId,
      );
    });
  }

  Future<void> _apply(ProcessingJob job, _Bundle bundle) async {
    final List<ExistingValue> existing = <ExistingValue>[
      for (final RecordField field in bundle.existing)
        (
          fieldKey: field.fieldKey,
          capturedValue: field.valueRaw,
          verified: field.verified,
          source: field.source,
        ),
    ];
    final _ProposalSelection selection = await _proposals(job, bundle);
    final ProjectSettingsResolved settings = _projectSettings(bundle);
    final ApplicationPlan plan = ProposalApplication.apply(
      proposals: selection.proposals,
      existing: existing,
      high: settings.confidenceHigh,
      medium: settings.confidenceMedium,
      requiredKeys: <String>[
        for (final TemplateField field in bundle.fields)
          if (field.isRequired) field.fieldKey,
      ],
    );
    final List<String> priorRejections = await _rejectionsForJob(job.id);
    await _db.transaction(() async {
      for (final ProposalWrite write in plan.writes) {
        final TemplateField field = bundle.fields.firstWhere(
          (TemplateField value) => value.fieldKey == write.fieldKey,
        );
        final ({String raw, String? normalised}) value = _normalise(
          write.proposed ?? '',
          field,
        );
        final RecordField stored = _value(
          await insertProcessingProposal(
            _db,
            recordId: bundle.record.id,
            fieldKey: write.fieldKey,
            rawValue: value.raw,
            normalisedValue: value.normalised,
            confidence: write.confidence,
            confidenceBand: write.band.name,
            source: write.provenance.source,
            method: write.provenance.method,
            provider: write.provenance.provider,
            model: write.provenance.model,
            promptVersion: write.provenance.promptVersion,
            clock: _clock,
            deviceId: _deviceId,
            ids: _ids,
            auditReason: jsonEncode(Provenance.asAudit(write.provenance)),
          ),
        );
        for (final EvidenceDraft evidence in write.evidence) {
          _value(
            await insertFieldEvidence(
              _db,
              row: FieldEvidenceCompanion(
                recordFieldId: Value<String>(stored.id),
                sourceType: Value<FieldEvidenceSource>(
                  _evidenceSource(evidence.sourceType),
                ),
                photoId: Value<String?>(evidence.photoId),
                region: Value<String?>(evidence.regionJson),
                snippet: Value<String?>(evidence.snippet),
                confidence: Value<double?>(evidence.confidence),
              ),
              clock: _clock,
              deviceId: _deviceId,
              ids: _ids,
            ),
          );
        }
      }
      await (_db.update(_db.records)
            ..where(($RecordsTable table) => table.id.equals(bundle.record.id)))
          .write(RecordsCompanion(status: Value<String>(plan.status)));
      await (_db.update(
        _db.processing,
      )..where(($ProcessingTable table) => table.id.equals(job.id))).write(
        ProcessingCompanion(
          rejections: Value<String?>(
            priorRejections.isEmpty &&
                    selection.rejections.isEmpty &&
                    plan.skips.isEmpty
                ? null
                : jsonEncode(
                    <String>{
                      ...priorRejections,
                      ...selection.rejections,
                      ...plan.skips,
                    }.toList(),
                  ),
          ),
        ),
      );
    });
  }

  Future<_ProposalSelection> _proposals(
    ProcessingJob job,
    _Bundle bundle,
  ) async {
    final List<ProposedValue> proposals = <ProposedValue>[];
    final List<String> rejections = <String>[];
    final Set<String> proposedKeys = <String>{};
    final List<IdentityField> identity = _identityFields(bundle);
    for (final Photo photo in bundle.photos) {
      final OcrResult? ocr = _value(
        await _cache.lookup(contentHash: photo.sha256, perceptualHash: ''),
      );
      if (ocr == null) {
        continue;
      }
      final List<PlateBlock> blocks = <PlateBlock>[
        for (final block in ocr.blocks)
          (
            text: block.text,
            top: block.bounds.top,
            confidence: block.confidence,
          ),
      ];
      for (final IdentifierCandidate candidate in IdentifierExtraction.extract(
        text: ocr.text,
        blocks: blocks,
        fields: identity,
      )) {
        if (!proposedKeys.add(candidate.fieldKey)) {
          continue;
        }
        final field = bundle.fields.firstWhere(
          (TemplateField value) => value.fieldKey == candidate.fieldKey,
        );
        final GuardOutcome guarded = NoInventionGuard.check(
          fieldKey: candidate.fieldKey,
          value: candidate.value,
          evidence: <String>[candidate.blockText],
          evidenceRequired: true,
          pattern: _pattern(field),
          options: _optionValues(field.options),
        );
        if (guarded.value == null) {
          if (guarded.rejection case final GuardRejection rejection) {
            rejections.add(rejection.reason);
          }
          continue;
        }
        final OcrBlock? origin = ocr.blocks
            .where((OcrBlock block) => block.text == candidate.blockText)
            .firstOrNull;
        proposals.add((
          fieldKey: candidate.fieldKey,
          value: guarded.value,
          confidence: candidate.confidence,
          evidence: EvidenceLinking.forValue(
            photoId: photo.id,
            regionJson: origin == null ? null : _region(origin),
            snippet: candidate.blockText,
            confidence: candidate.confidence,
          ),
          provenance: Provenance.stamp(
            source: 'ocr',
            method: 'identifier-pattern',
            provider: 'on-device',
            model: 'ml-kit-text-recognition',
            promptVersion: 'local-1',
          ),
        ));
      }
    }
    final List<ProcessingResult> responses = _value(
      await _responses.forJob(job.id),
    );
    for (final ProcessingResult response in responses.reversed) {
      if (!response.parsedOk) {
        continue;
      }
      final ParseOutcome parsed = ResponseParser.parse(
        response.rawResponse,
        schema: <FieldSchema>[
          for (final TemplateField field in bundle.fields) _schema(field),
        ],
      );
      if (!parsed.ok) {
        continue;
      }
      for (final ParsedField parsedField in parsed.fields.values) {
        if (!proposedKeys.add(parsedField.key)) {
          continue;
        }
        final TemplateField field = bundle.fields.firstWhere(
          (TemplateField value) => value.fieldKey == parsedField.key,
        );
        final GuardOutcome guarded = NoInventionGuard.check(
          fieldKey: parsedField.key,
          value: parsedField.value,
          evidence: parsedField.evidence,
          evidenceRequired: true,
          pattern: _pattern(field),
          options: _optionValues(field.options),
        );
        if (guarded.value == null) {
          if (guarded.rejection case final GuardRejection rejection) {
            rejections.add(rejection.reason);
          }
          continue;
        }
        final Photo? photo = bundle.photos.firstOrNull;
        proposals.add((
          fieldKey: parsedField.key,
          value: guarded.value,
          confidence: parsedField.confidence,
          evidence: EvidenceLinking.forValue(
            photoId: photo?.id,
            snippet: parsedField.evidence.join('\n'),
            confidence: parsedField.confidence,
          ),
          provenance: Provenance.stamp(
            source: 'extraction',
            method: 'provider',
            provider:
                _summaryValue(response.requestSummary, 'provider') ??
                job.provider ??
                'backend',
            model:
                _summaryValue(response.requestSummary, 'model') ??
                job.model ??
                '',
            promptVersion:
                _summaryValue(response.requestSummary, 'promptVersion') ??
                'extraction-1',
          ),
        ));
      }
    }
    return (proposals: proposals, rejections: rejections);
  }

  Future<_Bundle> _bundle(String recordId) async {
    final RecordRow? record =
        await (_db.select(_db.records)
              ..where(($RecordsTable table) => table.id.equals(recordId)))
            .getSingleOrNull();
    if (record == null) {
      throw const StorageFailure(
        message: 'That record is no longer on this device.',
        recoveryAction: 'Refresh the queue and try again.',
      );
    }
    final Project? project =
        await (_db.select(_db.projects)..where(
              ($ProjectsTable table) => table.id.equals(record.projectId),
            ))
            .getSingleOrNull();
    final Template? template =
        await (_db.select(_db.templates)..where(
              ($TemplatesTable table) => table.id.equals(record.templateId),
            ))
            .getSingleOrNull();
    if (project == null || template == null) {
      throw const ValidationFailure(
        message: 'This record is missing its project or template.',
        recoveryAction: 'Restore it, then retry processing.',
      );
    }
    final List<AttachmentOwner> audioOwners =
        await (_db.select(_db.attachmentOwners)..where(
              ($AttachmentOwnersTable table) =>
                  table.ownerType.equalsValue(AttachmentOwnerType.record) &
                  table.ownerId.equals(record.id),
            ))
            .get();
    final List<String> attachmentIds = <String>[
      for (final AttachmentOwner owner in audioOwners) owner.attachmentId,
    ];
    return _Bundle(
      record: record,
      project: project,
      template: template,
      fields:
          await (_db.select(_db.templateFields)
                ..where(
                  ($TemplateFieldsTable table) =>
                      table.templateId.equals(template.id),
                )
                ..orderBy(<OrderClauseGenerator<$TemplateFieldsTable>>[
                  ($TemplateFieldsTable table) =>
                      OrderingTerm.asc(table.sortOrder),
                ]))
              .get(),
      rows:
          await (_db.select(_db.templateRows)..where(
                ($TemplateRowsTable table) =>
                    table.templateId.equals(template.id),
              ))
              .get(),
      photos:
          await (_db.select(_db.photos)
                ..where(
                  ($PhotosTable table) => table.recordId.equals(record.id),
                )
                ..orderBy(<OrderClauseGenerator<$PhotosTable>>[
                  ($PhotosTable table) => OrderingTerm.asc(table.sortOrder),
                ]))
              .get(),
      captions:
          await (_db.select(_db.captions)..where(
                ($CaptionsTable table) =>
                    (table.ownerId.equals(record.id)) |
                    table.ownerId.isInQuery(
                      _db.selectOnly(_db.photos)
                        ..addColumns(<Expression<Object>>[_db.photos.id])
                        ..where(_db.photos.recordId.equals(record.id)),
                    ),
              ))
              .get(),
      audio: attachmentIds.isEmpty
          ? const <Attachment>[]
          : await (_db.select(_db.attachments)..where(
                  ($AttachmentsTable table) =>
                      table.id.isIn(attachmentIds) &
                      table.kind.equalsValue(AttachmentKind.audio),
                ))
                .get(),
      existing:
          await (_db.select(_db.recordFields)..where(
                ($RecordFieldsTable table) => table.recordId.equals(record.id),
              ))
              .get(),
    );
  }

  Future<List<String>> _transcripts(ProcessingJob job, _Bundle bundle) async {
    if (bundle.audio.isEmpty) {
      return const <String>[];
    }
    final selection = _selection(AiOperation.transcribe);
    final AiService service = selection.provider.service;
    if (!service.isAvailable) {
      return const <String>[];
    }
    final List<ProcessingResult> existing = _value(
      await _responses.forJob(job.id),
    );
    final Directory directory = _value(await _folders.resolve(bundle.project));
    final List<String> transcripts = <String>[];
    for (final Attachment audio in bundle.audio) {
      ProcessingResult? stored;
      for (final ProcessingResult response in existing) {
        if (response.parsedOk &&
            _summaryValue(response.requestSummary, 'kind') == 'transcript' &&
            _summaryValue(response.requestSummary, 'attachmentId') ==
                audio.id) {
          stored = response;
          break;
        }
      }
      if (stored != null) {
        transcripts.add(stored.rawResponse);
        continue;
      }
      await _requireBudget(job.id, bundle.record.projectId);
      final TranscribeResult transcribed = _value(
        await service.transcribe(
          TranscribeRequest(
            clipPath: '${directory.path}/${audio.relativePath}',
            languageCode: _settings.read(SettingKeys.voiceLanguage),
          ),
        ),
      );
      _value(
        await _responses.save(
          jobId: job.id,
          requestSummary: jsonEncode(<String, Object?>{
            'kind': 'transcript',
            'attachmentId': audio.id,
            'provider': selection.provider.id,
            'model': selection.model.id,
          }),
          rawResponse: transcribed.text,
          parsedOk: true,
        ),
      );
      transcripts.add(transcribed.text);
    }
    return transcripts;
  }

  Future<String> _sourcePath(_Bundle bundle, Photo photo) async {
    final Directory directory = _value(await _folders.resolve(bundle.project));
    return '${directory.path}/${photo.relativePath}';
  }

  ({ProviderDescriptor provider, ModelDescriptor model, bool fellBack})
  _selection(AiOperation operation) {
    return _providers.validateSelection(
      providerId: _settings.read(SettingKeys.aiProvider),
      modelId: _settings.read(SettingKeys.aiModel),
      operation: operation,
    );
  }

  Future<String> _preparedPath(_Bundle bundle, Photo photo) async {
    final String source = await _sourcePath(bundle, photo);
    final written = _value(await _compressed.reduce(source));
    final Directory root = _value(await _storageRoot.resolve());
    return '${root.path}/${written.relativePath}.ocr.jpg';
  }

  Future<List<String>> _compressedPaths(_Bundle bundle) async {
    final Directory root = _value(await _storageRoot.resolve());
    return <String>[
      for (final Photo photo in bundle.photos)
        '${root.path}/${_value(await _compressed.reduce(await _sourcePath(bundle, photo))).relativePath}',
    ];
  }

  Future<String> _ocrText(_Bundle bundle) async {
    final List<String> text = <String>[];
    for (final Photo photo in bundle.photos) {
      final OcrResult? result = _value(
        await _cache.lookup(contentHash: photo.sha256, perceptualHash: ''),
      );
      if (result != null && result.text.trim().isNotEmpty) {
        text.add(result.text);
      }
    }
    return text.join('\n');
  }

  Future<List<SkipField>> _localCompletion(_Bundle bundle) async {
    final Map<String, RecordField> existing = <String, RecordField>{
      for (final RecordField field in bundle.existing) field.fieldKey: field,
    };
    return <SkipField>[
      for (final TemplateField field in bundle.fields)
        (
          requiredField: field.isRequired,
          value: existing[field.fieldKey]?.valueRaw,
          band:
              existing[field.fieldKey]?.verified == true ||
                  _isManual(existing[field.fieldKey]?.source)
              ? ConfidenceBand.high
              : _band(existing[field.fieldKey]?.confidence, bundle),
        ),
    ];
  }

  Future<List<SkipField>> _completionForOnline(
    ProcessingJob job,
    _Bundle bundle,
  ) async {
    final List<SkipField> stored = await _localCompletion(bundle);
    final Map<String, ProposedValue> proposed = <String, ProposedValue>{
      for (final ProposedValue value in (await _proposals(
        job,
        bundle,
      )).proposals)
        value.fieldKey: value,
    };
    final ProjectSettingsResolved settings = _projectSettings(bundle);
    return <SkipField>[
      for (var index = 0; index < bundle.fields.length; index++)
        if (stored[index].value != null &&
            stored[index].value!.trim().isNotEmpty)
          stored[index]
        else
          (
            requiredField: bundle.fields[index].isRequired,
            value: proposed[bundle.fields[index].fieldKey]?.value,
            band: proposed[bundle.fields[index].fieldKey] == null
                ? null
                : Confidence.band(
                    score: proposed[bundle.fields[index].fieldKey]!.confidence,
                    high: settings.confidenceHigh,
                    medium: settings.confidenceMedium,
                  ),
          ),
    ];
  }

  ConfidenceBand? _band(double? score, _Bundle bundle) {
    if (score == null) {
      return null;
    }
    final ProjectSettingsResolved settings = _projectSettings(bundle);
    return Confidence.band(
      score: score,
      high: settings.confidenceHigh,
      medium: settings.confidenceMedium,
    );
  }

  ProjectSettingsResolved _projectSettings(_Bundle bundle) {
    return ProjectSettings.decode(bundle.project.settings).resolve((
      aiEnabled: builtInProjectSettingsDefaults.aiEnabled,
      doNotSendImages: _settings.read(SettingKeys.aiDoNotSendImages),
      gpsEnabled: _settings.read(SettingKeys.gpsEnabled),
      folderStrategy: _settings.read(SettingKeys.folderStrategy),
      confidenceHigh: _settings.read(SettingKeys.confidenceHigh),
      confidenceMedium: _settings.read(SettingKeys.confidenceMedium),
      refineColumns: builtInProjectSettingsDefaults.refineColumns,
    ));
  }

  Future<int> _onlineRequestsToday(String projectId) async {
    final DateTime now = _clock.nowUtc();
    final DateTime start = DateTime.utc(now.year, now.month, now.day);
    final DateTime end = start.add(AppConstants.processing.dayWindow);
    final QueryRow row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM processing_results pr '
          'JOIN processing_jobs pj ON pj.id = pr.job_id '
          'JOIN records r ON r.id = pj.record_id '
          'WHERE r.project_id = ? AND pr.created_at >= ? '
          'AND pr.created_at < ? AND pr.request_summary LIKE ?',
          variables: <Variable<Object>>[
            Variable<String>(projectId),
            Variable<DateTime>(start),
            Variable<DateTime>(end),
            const Variable<String>('%"kind":"online"%'),
          ],
          readsFrom: <ResultSetImplementation<Object?, Object?>>{
            _db.processingResults,
            _db.processing,
            _db.records,
          },
        )
        .getSingle();
    return row.read<int>('c');
  }

  Future<void> _setSkip(String jobId, String reason) async {
    await (_db.update(_db.processing)
          ..where(($ProcessingTable table) => table.id.equals(jobId)))
        .write(ProcessingCompanion(skipReason: Value<String>(reason)));
  }

  Future<void> _setProvider(
    String jobId, {
    String? provider,
    String? model,
  }) async {
    await (_db.update(
      _db.processing,
    )..where(($ProcessingTable table) => table.id.equals(jobId))).write(
      ProcessingCompanion(
        provider: Value<String?>(provider),
        model: Value<String?>(model),
      ),
    );
  }

  Future<void> _setQueueMessage(String jobId, String message) async {
    await (_db.update(
      _db.processing,
    )..where(($ProcessingTable table) => table.id.equals(jobId))).write(
      ProcessingCompanion(
        status: const Value<ProcessingJobStatus>(ProcessingJobStatus.queued),
        lastError: Value<String>(message),
        leaseExpiresAt: const Value<DateTime?>(null),
      ),
    );
  }

  Future<void> _appendRejections(String jobId, List<String> rejected) async {
    final ProcessingJobRow? row =
        await (_db.select(_db.processing)
              ..where(($ProcessingTable table) => table.id.equals(jobId)))
            .getSingleOrNull();
    if (row == null) {
      return;
    }
    final List<String> combined = <String>{
      ..._strings(row.rejections ?? '[]'),
      ...rejected,
    }.toList();
    await (_db.update(_db.processing)
          ..where(($ProcessingTable table) => table.id.equals(jobId)))
        .write(ProcessingCompanion(rejections: Value(jsonEncode(combined))));
  }

  Future<List<String>> _rejectionsForJob(String jobId) async {
    final ProcessingJobRow? row =
        await (_db.select(_db.processing)
              ..where(($ProcessingTable table) => table.id.equals(jobId)))
            .getSingleOrNull();
    return _strings(row?.rejections ?? '[]');
  }

  DateTime _nextUtcDay() {
    final DateTime now = _clock.nowUtc();
    return DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).add(AppConstants.processing.dayWindow);
  }
}

final class _Bundle {
  const _Bundle({
    required this.record,
    required this.project,
    required this.template,
    required this.fields,
    required this.rows,
    required this.photos,
    required this.captions,
    required this.audio,
    required this.existing,
  });

  final RecordRow record;
  final Project project;
  final Template template;
  final List<TemplateField> fields;
  final List<TemplateRow> rows;
  final List<Photo> photos;
  final List<Caption> captions;
  final List<Attachment> audio;
  final List<RecordField> existing;
}

typedef _ProposalSelection = ({
  List<ProposedValue> proposals,
  List<String> rejections,
});

T _value<T>(Result<T> result) {
  return result.fold(
    (Failure failure) => throw Failure.from(failure),
    (T value) => value,
  );
}

ExtractionField _extractionField(TemplateField field) {
  return (
    key: field.fieldKey,
    type: field.type,
    requiredField: field.isRequired,
    pattern: _pattern(field),
    options: _optionValues(field.options),
    optionsHint: null,
  );
}

FieldSchema _schema(TemplateField field) {
  return (
    key: field.fieldKey,
    type: field.type,
    requiredField: field.isRequired,
    pattern: _pattern(field),
    options: _optionLabels(field.options),
  );
}

List<IdentityField> _identityFields(_Bundle bundle) {
  final Set<String> keys = _strings(bundle.template.identityFields).toSet();
  return <IdentityField>[
    for (final TemplateField field in bundle.fields)
      if (keys.contains(field.fieldKey) && _pattern(field) != null)
        (fieldKey: field.fieldKey, pattern: _pattern(field)!),
  ];
}

String? _pattern(TemplateField field) {
  final Object? decoded = _json(field.validation);
  if (decoded is Map && decoded['pattern'] is String) {
    return decoded['pattern'] as String;
  }
  return null;
}

List<String> _optionLabels(String raw) {
  final Object? decoded = _json(raw);
  if (decoded is! List) {
    return const <String>[];
  }
  return <String>[
    for (final Object? item in decoded)
      if (item is String)
        item
      else if (item is Map && item['label'] is String)
        item['label'] as String,
  ];
}

List<String> _optionValues(String raw) {
  final List<ChoiceOption> options = _choiceOptions(raw);
  return <String>[
    for (final ChoiceOption option in options) ...<String>[
      option.label,
      if (option.code case final String code) code,
      ...option.aliases,
    ],
  ];
}

List<ChoiceOption> _choiceOptions(String raw) {
  final Object? decoded = _json(raw);
  if (decoded is! List) {
    return const <ChoiceOption>[];
  }
  return <ChoiceOption>[
    for (final Object? item in decoded)
      if (item is String)
        (label: item, code: null, aliases: const <String>[])
      else if (item is Map && item['label'] is String)
        (
          label: item['label'] as String,
          code: item['code'] is String ? item['code'] as String : null,
          aliases: item['aliases'] is List
              ? <String>[
                  for (final Object? alias in item['aliases'] as List)
                    if (alias is String) alias,
                ]
              : const <String>[],
        ),
  ];
}

({String raw, String? normalised}) _normalise(String raw, TemplateField field) {
  if (field.unit != null && field.unit!.isNotEmpty) {
    final UnitValue? converted = Units.convert(raw, targetUnit: field.unit!);
    if (converted != null) {
      return (raw: converted.original, normalised: converted.stored);
    }
  }
  final List<ChoiceOption> options = _choiceOptions(field.options);
  if (options.isNotEmpty) {
    final ChoiceMatch? choice = Choices.match(raw, options: options);
    if (choice != null) {
      return (raw: choice.original, normalised: choice.label);
    }
  }
  if (field.type.toLowerCase() == 'date') {
    final DateValue? date = Dates.parse(raw, locale: 'en-UG');
    if (date != null) {
      return (raw: date.original, normalised: date.stored);
    }
  }
  return (raw: raw, normalised: null);
}

FieldEvidenceSource _evidenceSource(String source) {
  return switch (source) {
    'document' => FieldEvidenceSource.document,
    'transcript' => FieldEvidenceSource.transcript,
    _ => FieldEvidenceSource.photo,
  };
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

Object? _json(String raw) {
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}

List<String> _strings(String raw) {
  final Object? decoded = _json(raw);
  if (decoded is! List) {
    return const <String>[];
  }
  return <String>[
    for (final Object? item in decoded)
      if (item is String) item,
  ];
}

Map<String, String> _stringMap(String raw) {
  final Object? decoded = _json(raw);
  if (decoded is! Map) {
    return const <String, String>{};
  }
  return <String, String>{
    for (final MapEntry<Object?, Object?> entry in decoded.entries)
      if (entry.key is String && entry.value is String)
        entry.key! as String: entry.value! as String,
  };
}

bool _isManual(String? source) {
  final String folded = source?.toLowerCase() ?? '';
  return folded == 'manual' || folded == 'typed';
}

String _basename(String path) {
  return path.replaceAll('\\', '/').split('/').last;
}

String _region(OcrBlock block) {
  return jsonEncode(<String, double>{
    'left': block.bounds.left,
    'top': block.bounds.top,
    'right': block.bounds.right,
    'bottom': block.bounds.bottom,
  });
}

String? _summaryValue(String raw, String key) {
  final Object? decoded = _json(raw);
  if (decoded is! Map) {
    return null;
  }
  final Object? value = decoded[key];
  return value is String && value.isNotEmpty ? value : null;
}

bool _summaryBool(String raw, String key) {
  final Object? decoded = _json(raw);
  return decoded is Map && decoded[key] == true;
}
