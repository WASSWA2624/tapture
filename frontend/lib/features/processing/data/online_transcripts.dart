import 'dart:convert';

import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/transcripts/transcripts.dart'
    show Transcript, TranscriptRepository, TranscriptSummary;

import '../domain/processing_job.dart';
import 'online_budget.dart';
import 'photo_paths.dart';
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
  Future<List<String>> forJob(ProcessingJob job, RecordBundle bundle) async {
    if (bundle.audio.isEmpty) {
      return const <String>[];
    }
    final selection = _settings.selection(bundle, AiOperation.transcribe);
    final AiService service = selection.provider.service;
    final List<ProcessingResult> existing = StageSupport.unwrap(
      await _responses.forJob(job.id),
    );
    final List<String> transcripts = <String>[];
    for (final Attachment audio in bundle.audio) {
      final String? onDevice = await _onDevice(job, audio, existing);
      if (onDevice != null) {
        transcripts.add(onDevice);
        continue;
      }
      if (!service.isAvailable) {
        continue;
      }
      final ProcessingResult? stored = _storedOnline(existing, audio.id);
      if (stored != null) {
        transcripts.add(stored.rawResponse);
        continue;
      }
      await _budget.require(job.id, bundle);
      final String relative =
          'projects/${bundle.project.folderName}/${audio.relativePath}';
      StageSupport.unwrap(await _paths.read(relative));
      final TranscribeResult transcribed = StageSupport.unwrap(
        await service.transcribe(
          TranscribeRequest(
            clipPath: await _paths.servicePath(relative),
            languageCode: _settings.read(SettingKeys.voiceLanguage),
          ),
        ),
      );
      StageSupport.unwrap(
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

  /// The stored online transcript of [attachmentId], or null. A `device`
  /// response is never read back here: the on-device transcript itself is
  /// read afresh each time.
  static ProcessingResult? _storedOnline(
    List<ProcessingResult> existing,
    String attachmentId,
  ) {
    for (final ProcessingResult response in existing) {
      if (_isTranscriptOf(response, attachmentId) && !_isDevice(response)) {
        return response;
      }
    }
    return null;
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
