import 'dart:convert';

import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/transcripts/transcripts.dart'
    show Transcript, TranscriptRepository, TranscriptSummary;

import '../domain/processing_job.dart';
import 'extraction_responses.dart';
import 'online_budget.dart';
import 'photo_paths.dart';
import 'processing_snapshot.dart';
import 'record_bundle.dart';
import 'response_store.dart';
import 'stage_settings.dart';
import 'stage_support.dart';

/// Transcripts of a record's audio: the clip's on-device transcript when
/// one is complete, else a stored online response, else one online request
/// (spec §30.1). Processing never runs speech recognition itself.
final class OnlineTranscripts {
  /// Creates the reader over the stored [responses] and the on-device
  /// [deviceTranscripts].
  OnlineTranscripts({
    required StorageRoot storageRoot,
    required this._responses,
    required this._settings,
    required this._budget,
    required this._deviceTranscripts,
    PhotoPaths? paths,
    FileReader? files,
  }) : _paths = paths ?? PhotoPaths(storageRoot: storageRoot, files: files);

  final PhotoPaths _paths;
  final ResponseStore _responses;
  final StageSettings _settings;
  final OnlineBudget _budget;
  final TranscriptRepository _deviceTranscripts;

  /// One transcript per audio clip that has one.
  ///
  /// A clip's complete on-device transcript is used as it reads, edit
  /// first, with no provider call and no charge against the daily cap; a
  /// live or interrupted one is not. Any other clip is transcribed online
  /// once and read back from the stored response after, and is left out
  /// when no provider can transcribe.
  Future<List<String>> forJob(
    ProcessingJob job,
    RecordBundle bundle,
  ) async => <String>[
    for (final Map<String, Object?> source in await sourcesForJob(job, bundle))
      source['text']! as String,
  ];

  /// Grounded transcript sources, retaining clip and explicit photo owners.
  /// [allowOnline] is false when checking a snapshot for changes.
  Future<List<Map<String, Object?>>> sourcesForJob(
    ProcessingJob job,
    RecordBundle bundle, {
    bool allowOnline = true,
    CancellationToken? cancel,
    Future<void> Function()? beforeRequest,
  }) async {
    if (bundle.audio.isEmpty) {
      return const <Map<String, Object?>>[];
    }
    final selection = _settings.selection(bundle, AiOperation.transcribe);
    final AiService service = selection.provider.service;
    final double approvedMaxCost = _settings.read(SettingKeys.aiRequestMaxCost);
    final List<ProcessingResult> existing = StageSupport.unwrap(
      await _responses.forJob(job.id),
    );
    final List<Map<String, Object?>> transcripts = <Map<String, Object?>>[];
    for (final Attachment audio in bundle.audio) {
      if (cancel?.isCancelled ?? false) throw const CancelledFailure();
      final String? onDevice = await _onDevice(job, audio, existing);
      if (onDevice != null) {
        final TranscriptSummary? completed = StageSupport.unwrap(
          await _deviceTranscripts.completedForAttachment(audio.id),
        );
        transcripts.add(_source(bundle, audio, onDevice, completed?.id));
        continue;
      }
      final String language = _settings.read(SettingKeys.voiceLanguage);
      final String revision =
          await ProcessingSnapshot.auxiliaryRevision(<String, Object?>{
            'operation': 'transcribe',
            'projectId': bundle.project.id,
            'recordId': bundle.record.id,
            'attachmentId': audio.id,
            'sha256': audio.sha256,
            'photoIds': bundle.audioPhotoIds[audio.id] ?? const <String>[],
            'provider': selection.provider.id,
            'model': selection.model.id,
            'language': language,
            'maxCost': approvedMaxCost,
          });
      final ProcessingResult? stored = await ExtractionResponses(_responses)
          .latest(
            job,
            revision: revision,
            batchKey: 'audio:${audio.id}',
            kind: 'transcript',
          );
      if (stored != null) {
        transcripts.add(_source(bundle, audio, stored.rawResponse, null));
        continue;
      }
      if (!allowOnline || !service.isAvailable) continue;
      await beforeRequest?.call();
      final String idempotencyKey = ProcessingSnapshot.requestId(
        revision: revision,
        recordId: bundle.record.id,
        generation: job.requestGeneration,
        batch: 0,
        repair: 0,
      );
      if (!await ExtractionResponses(
        _responses,
      ).hasAttempt(job, idempotencyKey)) {
        await _budget.require(job.id, bundle);
      }
      if (cancel?.isCancelled ?? false) throw const CancelledFailure();
      final String relative =
          'projects/${bundle.project.folderName}/${audio.relativePath}';
      StageSupport.unwrap(await _paths.read(relative));
      await ExtractionResponses(_responses).begin(
        job: job,
        summary: <String, Object?>{
          'operation': 'transcribe',
          'attachmentId': audio.id,
          'batchKey': 'audio:${audio.id}',
          'projectRevision': revision,
          'idempotencyKey': idempotencyKey,
          'requestGeneration': job.requestGeneration,
          'provider': selection.provider.id,
          'model': selection.model.id,
          'imageCount': 0,
          'language': language,
        },
      );
      if (cancel?.isCancelled ?? false) throw const CancelledFailure();
      final TranscribeResult transcribed = StageSupport.unwrap(
        await service.transcribe(
          TranscribeRequest(
            clipPath: await _paths.servicePath(relative),
            languageCode: language,
            cancellationToken: cancel,
            projectRevision: revision,
            recordId: bundle.record.id,
            idempotencyKey: idempotencyKey,
            approvedMaxCost: approvedMaxCost,
          ),
        ),
      );
      StageSupport.unwrap(
        await _responses.save(
          jobId: job.id,
          requestSummary: jsonEncode(<String, Object?>{
            'kind': 'transcript',
            'operation': 'transcribe',
            'attachmentId': audio.id,
            'batchKey': 'audio:${audio.id}',
            'projectRevision': revision,
            'idempotencyKey': idempotencyKey,
            'requestGeneration': job.requestGeneration,
            'provider': transcribed.provider ?? selection.provider.id,
            'model': transcribed.model ?? selection.model.id,
            'billingKind': ?transcribed.billingKind,
            if (transcribed.usage != null) 'usage': transcribed.usage!.toJson(),
          }),
          rawResponse: transcribed.text,
          parsedOk: true,
        ),
      );
      if (cancel?.isCancelled ?? false) throw const CancelledFailure();
      transcripts.add(_source(bundle, audio, transcribed.text, null));
    }
    return transcripts;
  }

  static Map<String, Object?> _source(
    RecordBundle bundle,
    Attachment audio,
    String text,
    String? transcriptId,
  ) => <String, Object?>{
    'id': 'audio:${audio.id}',
    'kind': 'transcript',
    'attachmentId': audio.id,
    'sha256': audio.sha256,
    'photoIds': bundle.audioPhotoIds[audio.id] ?? const <String>[],
    'text': text,
    'transcriptId': ?transcriptId,
  };

  /// The display text of [audio]'s complete on-device transcript, or null.
  /// Its use is recorded once per distinct text as a `device` response, so
  /// the job shows what stood in for the clip.
  Future<String?> _onDevice(
    ProcessingJob job,
    Attachment audio,
    List<ProcessingResult> existing,
  ) async {
    final TranscriptSummary? completed = StageSupport.unwrap(
      await _deviceTranscripts.completedForAttachment(audio.id),
    );
    if (completed == null) {
      return null;
    }
    final Transcript? transcript = StageSupport.unwrap(
      await _deviceTranscripts.read(completed.id),
    );
    if (transcript == null) {
      return null;
    }
    final String text = transcript.displayText;
    final bool recorded = existing.any(
      (ProcessingResult response) =>
          _isTranscriptOf(response, audio.id) &&
          _isDevice(response) &&
          StageSupport.summaryValue(response.requestSummary, 'transcriptId') ==
              completed.id &&
          response.rawResponse == text,
    );
    if (!recorded) {
      StageSupport.unwrap(
        await _responses.save(
          jobId: job.id,
          requestSummary: jsonEncode(<String, Object?>{
            'kind': 'transcript',
            'attachmentId': audio.id,
            'source': 'device',
            'transcriptId': completed.id,
            'model': completed.modelId,
          }),
          rawResponse: text,
          parsedOk: true,
        ),
      );
    }
    return text;
  }

  static bool _isTranscriptOf(ProcessingResult response, String attachmentId) {
    return response.parsedOk &&
        StageSupport.summaryValue(response.requestSummary, 'kind') ==
            'transcript' &&
        StageSupport.summaryValue(response.requestSummary, 'attachmentId') ==
            attachmentId;
  }

  static bool _isDevice(ProcessingResult response) {
    return StageSupport.summaryValue(response.requestSummary, 'source') ==
        'device';
  }
}
