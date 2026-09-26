import 'package:tapture/core/ai/ocr_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/settings/settings.dart';

import '../domain/processing_job.dart';
import 'caption_refinement_service.dart';
import 'detect_stage.dart';
import 'egress_summary.dart';
import 'job_writes.dart';
import 'normalise_stage.dart';
import 'ocr_cache.dart';
import 'on_device_stage.dart';
import 'online_budget.dart';
import 'online_completion.dart';
import 'online_stage.dart';
import 'online_transcripts.dart';
import 'photo_paths.dart';
import 'prepare_stage.dart';
import 'proposal_collector.dart';
import 'record_bundle.dart';
import 'record_bundle_loader.dart';
import 'response_store.dart';
import 'stage_settings.dart';
import 'validate_stage.dart';

/// Production implementation for the six processing stages.
///
/// Originals are read only. Derived images live in the disposable cache,
/// OCR is cached by content and perceptual hash, provider responses are
/// stored before parsing, and validation writes proposals plus evidence.
/// Each stage is its own collaborator; this type loads the record and
/// dispatches to the one asked for.
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
    final StageSettings stageSettings = StageSettings(
      settings: settings,
      providers: providers,
    );
    final RecordBundleLoader loader = RecordBundleLoader(db: db);
    final PhotoPaths paths = PhotoPaths(storageRoot: storageRoot);
    final OcrCache cache = OcrCache(
      db: db,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    );
    final ResponseStore responses = ResponseStore(
      db: db,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    );
    final JobWrites writes = JobWrites(db: db);
    final OnlineBudget budget = OnlineBudget(
      db: db,
      clock: clock,
      settings: stageSettings,
      writes: writes,
    );
    final ProposalCollector collector = ProposalCollector(
      cache: cache,
      responses: responses,
    );
    final OnlineCompletion completion = OnlineCompletion(
      collector: collector,
      settings: stageSettings,
    );
    final OnDeviceStage onDevice = OnDeviceStage(
      ocr: ocr,
      cache: cache,
      paths: paths,
    );
    return ProcessingStageWorker._(
      loader: loader,
      prepare: PrepareStage(storageRoot: storageRoot, paths: paths),
      onDevice: onDevice,
      detect: const DetectStage(),
      online: OnlineStage(
        settings: stageSettings,
        paths: paths,
        onDevice: onDevice,
        completion: completion,
        transcripts: OnlineTranscripts(
          storageRoot: storageRoot,
          responses: responses,
          settings: stageSettings,
          budget: budget,
        ),
        budget: budget,
        responses: responses,
        captionRefinement: CaptionRefinementService(
          db: db,
          clock: clock,
          deviceId: deviceId,
          ids: ids,
          providers: providers,
        ),
        writes: writes,
      ),
      normalise: NormaliseStage(
        db: db,
        clock: clock,
        deviceId: deviceId,
        onDevice: onDevice,
      ),
      validate: ValidateStage(
        db: db,
        clock: clock,
        deviceId: deviceId,
        ids: ids,
        settings: stageSettings,
        collector: collector,
        writes: writes,
      ),
      egress: EgressSummary(
        loader: loader,
        settings: stageSettings,
        paths: paths,
        onDevice: onDevice,
        completion: completion,
      ),
    );
  }

  ProcessingStageWorker._({
    required this._loader,
    required this._prepare,
    required this._onDevice,
    required this._detect,
    required this._online,
    required this._normalise,
    required this._validate,
    required this._egress,
  });

  final RecordBundleLoader _loader;
  final PrepareStage _prepare;
  final OnDeviceStage _onDevice;
  final DetectStage _detect;
  final OnlineStage _online;
  final NormaliseStage _normalise;
  final ValidateStage _validate;
  final EgressSummary _egress;

  /// Runs one persisted stage. [cancel] reaches the stage; a fresh token is
  /// used when none is given.
  Future<void> perform(
    JobStage stage,
    ProcessingJob job, [
    CancellationToken? cancel,
  ]) async {
    final CancellationToken token = cancel ?? CancellationToken();
    final RecordBundle bundle = await _loader.load(job.recordId);
    switch (stage) {
      case JobStage.prepare:
        await _prepare.run(bundle, token);
      case JobStage.onDevice:
        await _onDevice.run(bundle, token);
      case JobStage.detect:
        await _detect.run(bundle, token);
      case JobStage.online:
        await _online.run(job, bundle, token);
      case JobStage.normalise:
        await _normalise.run(bundle, token);
      case JobStage.validate:
        await _validate.run(job, bundle, token);
    }
  }

  /// Exact payload summary shown before the first provider call.
  Future<({int imageCount, int payloadBytes})> egressSummary(
    ProcessingJob job,
  ) {
    return _egress.summarise(job);
  }
}
