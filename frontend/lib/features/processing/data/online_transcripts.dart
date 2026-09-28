import 'dart:convert';

import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/features/settings/settings.dart';

import '../domain/processing_job.dart';
import 'online_budget.dart';
import 'photo_paths.dart';
import 'record_bundle.dart';
import 'response_store.dart';
import 'stage_settings.dart';
import 'stage_support.dart';

/// Transcripts of a record's audio, requested once and then read back from
/// the stored responses.
final class OnlineTranscripts {
  /// Creates the reader over the stored [responses].
  OnlineTranscripts({
    required StorageRoot storageRoot,
    required this._responses,
    required this._settings,
    required this._budget,
    PhotoPaths? paths,
    FileReader? files,
  }) : _paths = paths ?? PhotoPaths(storageRoot: storageRoot, files: files);

  final PhotoPaths _paths;
  final ResponseStore _responses;
  final StageSettings _settings;
  final OnlineBudget _budget;

  /// One transcript per audio clip, empty when no provider can transcribe.
  Future<List<String>> forJob(ProcessingJob job, RecordBundle bundle) async {
    if (bundle.audio.isEmpty) {
      return const <String>[];
    }
    final selection = _settings.selection(bundle, AiOperation.transcribe);
    final AiService service = selection.provider.service;
    if (!service.isAvailable) {
      return const <String>[];
    }
    final List<ProcessingResult> existing = StageSupport.unwrap(
      await _responses.forJob(job.id),
    );
    final List<String> transcripts = <String>[];
    for (final Attachment audio in bundle.audio) {
      ProcessingResult? stored;
      for (final ProcessingResult response in existing) {
        if (response.parsedOk &&
            StageSupport.summaryValue(response.requestSummary, 'kind') ==
                'transcript' &&
            StageSupport.summaryValue(
                  response.requestSummary,
                  'attachmentId',
                ) ==
                audio.id) {
          stored = response;
          break;
        }
      }
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
}
