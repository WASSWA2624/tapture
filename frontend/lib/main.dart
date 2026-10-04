import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:tapture/core/copy/copy.dart';

import 'app/app.dart';
import 'app/provider_observer.dart' hide ProviderObserver;
import 'app/theme/settings_text_store.dart';
import 'app/view_focus_coordinator.dart';
import 'app/widgets/status_line.dart';
import 'core/ai/ai_media_reader.dart';
import 'core/ai/ai_service.dart';
import 'core/ai/ocr_service.dart';
import 'core/ai/provider_registry.dart';
import 'core/ai/stt_service.dart';
import 'core/audio/audio_capture_service.dart';
import 'core/audio/audio_recorder_plugin.dart';
import 'core/audio/audio_recorder_service.dart';
import 'core/audio/microphone_access.dart';
import 'core/audio/microphone_arbiter.dart';
import 'core/audio/staged_take_recovery.dart';
import 'core/backend/backend_session.dart';
import 'core/backend/relay_package.dart';
import 'core/backend/relay_queue.dart';
import 'core/background/power_source.dart';
import 'core/barcode/barcode_scanner_service.dart';
import 'core/bundle/bundle_output.dart';
import 'core/camera/camera_service.dart';
import 'core/cloud/cloud_operation_policy.dart';
import 'core/cloud/destination_secrets.dart';
import 'core/concurrency/cancellation_token.dart';
import 'core/constants/app_constants.dart';
import 'core/db/app_database.dart';
import 'core/db/checkpoint.dart';
import 'core/db/database_provider.dart';
import 'core/db/integrity_check.dart';
import 'core/db/tables/device_profile.dart';
import 'core/device/device_identity.dart';
import 'core/device/platform_facts.dart';
import 'core/errors/failure.dart';
import 'core/errors/result.dart';
import 'core/files/blob_store.dart';
import 'core/files/bundled_assets.dart';
import 'core/files/cache_cleanup.dart';
import 'core/files/download_service.dart';
import 'core/files/evidence_purge.dart';
import 'core/files/file_reader.dart';
import 'core/files/file_relocation.dart';
import 'core/files/file_writer.dart';
import 'core/files/orphan_scanner.dart';
import 'core/files/photo_picker.dart';
import 'core/files/photo_privacy_service.dart';
import 'core/files/project_folders.dart';
import 'core/files/screen_capture.dart';
import 'core/files/storage_guard.dart';
import 'core/files/storage_root.dart';
import 'core/ids/uuid_service.dart';
import 'core/import/pdf_pages.dart';
import 'core/lifecycle/lifecycle.dart';
import 'core/location/location_service.dart';
import 'core/logging/logger.dart';
import 'core/network/connectivity_service.dart';
import 'core/network/offline_now.dart';
import 'core/permissions/permissions_service.dart';
import 'core/security/secure_storage.dart';
import 'core/speech/speech_device_probe.dart';
import 'core/speech/speech_engine.dart';
import 'core/speech/speech_engine_host.dart';
import 'core/speech/speech_model_store.dart';
import 'core/speech/speech_preferences.dart';
import 'core/time/clock.dart';
import 'core/widgets/fields/app_consent_field.dart';
import 'core/widgets/fields/field_editor.dart';
import 'features/account/account.dart';
import 'features/capture/capture.dart';
import 'features/cloud/cloud.dart'
    show cloudExportGuardProvider, cloudOperationPolicyProvider;
import 'features/cloud/data/destination_repository_impl.dart';
import 'features/cloud/data/export_upload_guard.dart';
import 'features/context/data/context_repository_impl.dart';
import 'features/exports/data/deliverable_repository_impl.dart';
import 'features/exports/data/export_repository_impl.dart';
import 'features/exports/domain/export_repository.dart';
import 'features/exports/domain/export_sharing_policy.dart';
import 'features/feedback/feedback.dart';
import 'features/feedback/presentation/feedback_providers.dart';
import 'features/import/import.dart'
    show RecordImportStoreImpl, recordImportStoreProvider;
import 'features/meetings/data/meeting_repository_impl.dart';
import 'features/meetings/domain/meeting_attachment.dart';
import 'features/merge/data/merge_repository_impl.dart';
import 'features/merge/merge.dart';
import 'features/processing/data/notifications.dart';
import 'features/processing/data/processing_repository_impl.dart';
import 'features/processing/data/processing_stage_worker.dart';
import 'features/processing/presentation/processing_batch_state.dart';
import 'features/processing/presentation/processing_controller.dart';
import 'features/processing/presentation/queue_providers.dart';
import 'features/processing/presentation/unattended_processing.dart';
import 'features/processing/processing.dart' show JobStage, ProcessingJob;
import 'features/projects/data/project_openable_file_lookup_factory.dart';
import 'features/projects/data/project_repository_impl.dart';
import 'features/projects/presentation/current_project.dart';
import 'features/projects/presentation/project_open_externally_action.dart'
    show projectOpenableFileLookupProvider;
import 'features/quality/quality.dart'
    show QualityRepositoryImpl, qualityRepositoryProvider;
import 'features/records/data/record_purge_store.dart';
import 'features/records/records.dart'
    show
        PurgeJob,
        PurgeReport,
        RecordRepositoryImpl,
        recordPurgeJobProvider,
        recordRepositoryProvider;
import 'features/reference/data/reference_repository_impl.dart';
import 'features/settings/presentation/ai_provider_settings_screen.dart'
    show providerKeyStorageProvider;
import 'features/settings/presentation/offline_switch.dart';
import 'features/settings/settings.dart';
import 'features/templates/data/template_repository_impl.dart';
import 'features/templates/presentation/field_editor_bindings.dart';
import 'features/transcripts/transcripts.dart'
    show
        TranscriptOwnerKind,
        TranscriptRecovery,
        TranscriptRepositoryImpl,
        TranscriptSummary,
        transcriptRepositoryProvider;

/// Errors captured for bootstrap tests; the same objects are also logged.
@visibleForTesting
final List<Object> debugBootstrapErrors = <Object>[];

LifecycleObserver? _lifecycleObserver;
ViewFocusCoordinator? _viewFocusCoordinator;

/// The open app database, flushed when the app goes to the background.
AppDatabase? _database;

/// Entry point for the Tapture application.
Future<void> main() async {
  await runZonedGuarded(_run, _handleZoneError);
}

/// Boots the production provider graph against stores owned by one fixture.
/// Call only in a fresh process, in the binding's zone. The caller unmounts the
/// app, awaits the returned shutdown callback, then closes/deletes its stores.
/// Platform services, secure-storage reads and database startup remain real.
@visibleForTesting
Future<AsyncCallback> runDeviceMetricsApp({
  required AppDatabase database,
  required SecureStorage secrets,
  required StorageRoot storageRoot,
  required Logger logger,
  required BlobStore relayStore,
  required BlobStore feedbackStore,
}) async {
  if (_database != null || _lifecycleObserver != null) {
    throw StateError('The isolated bootstrap requires a fresh app process.');
  }
  final _FixtureBootstrap fixture = _FixtureBootstrap(
    database: database,
    secrets: secrets,
    storageRoot: storageRoot,
    logger: logger,
    relayStore: relayStore,
    feedbackStore: feedbackStore,
  );
  final Logger previousLogger = Logger.current;
  final void Function(FlutterErrorDetails)? previousError =
      FlutterError.onError;
  var stopped = false;
  Future<void> shutdown() async {
    if (stopped) return;
    stopped = true;
    fixture.stopping = true;
    try {
      await Future.wait(fixture.maintenance);
      await _flushPendingWrites();
    } finally {
      _database = null;
      final LifecycleObserver? observer = _lifecycleObserver;
      if (observer != null) WidgetsBinding.instance.removeObserver(observer);
      _lifecycleObserver = null;
      _viewFocusCoordinator?.dispose();
      _viewFocusCoordinator = null;
      if (FlutterError.onError == fixture.errorHandler) {
        FlutterError.onError = previousError;
      }
      Logger.current = previousLogger;
    }
  }

  try {
    await _run(fixture: fixture);
    return shutdown;
  } on Object {
    await shutdown();
    rethrow;
  }
}

final class _FixtureBootstrap {
  _FixtureBootstrap({
    required this.database,
    required this.secrets,
    required this.storageRoot,
    required this.logger,
    required this.relayStore,
    required this.feedbackStore,
  });

  final AppDatabase database;
  final SecureStorage secrets;
  final StorageRoot storageRoot;
  final Logger logger;
  final BlobStore relayStore;
  final BlobStore feedbackStore;
  final List<Future<void>> maintenance = <Future<void>>[];
  void Function(FlutterErrorDetails)? errorHandler;
  bool stopping = false;
}

Future<void> _run({_FixtureBootstrap? fixture}) async {
  // The binding is initialised in the guarded zone because runApp must run in
  // the zone that created it; otherwise Flutter reports a zone mismatch.
  WidgetsFlutterBinding.ensureInitialized();
  _viewFocusCoordinator ??= ViewFocusCoordinator.install(
    WidgetsBinding.instance,
  );
  final void Function(FlutterErrorDetails) errorHandler =
      _installErrorHandlers();
  fixture?.errorHandler = errorHandler;
  _installLifecycleObserver();
  final Logger logger = fixture?.logger ?? Logger(persist: true);
  Logger.current = logger;
  final SecureStorage secrets = fixture?.secrets ?? SecureStorage();
  final PinLock lock = PinLock(
    storage: secrets,
    clock: const SystemClock(),
    biometrics: BiometricLock(),
  );
  // One database for the whole app. A second AppDatabase over the same file
  // races with the first -- drift warns about it, and the two connections can
  // corrupt the store. Suites never open it at all (FE-TEST-03). Its key is
  // read from secure storage when the file first opens: an encrypted
  // database reopens, a fresh install is encrypted from the start, and an
  // existing unencrypted one keeps opening as it is (task 004).
  final AppDatabase? database =
      fixture?.database ??
      (_runningUnderTest
          ? null
          : AppDatabase.open(keyStore: kIsWeb ? null : secrets));
  _database = database;
  const SystemClock clock = SystemClock();
  final UuidV7Service ids = UuidV7Service(clock);
  // The device id lives only in the profile row (task 078): resolved once
  // here, and every store below stamps with that one id.
  final String? profileId = database == null
      ? null
      : await resolveDeviceId(database, clock: clock, ids: ids);
  final SettingsStore offlineStore = await _openOfflineStore(
    database,
    profileId,
  );
  final StorageRoot storageRoot =
      fixture?.storageRoot ??
      StorageRoot(
        preferredPath: () async =>
            offlineStore.read(SettingKeys.storageRootPath),
      );
  final List<Override> overrides = <Override>[
    appLockProvider.overrideWith((Ref ref) => lock),
    offlineStoreProvider.overrideWith((Ref _) => offlineStore),
    projectSettingsStoreProvider.overrideWith((Ref _) => offlineStore),
    storageRootProvider.overrideWith((Ref _) => storageRoot),
    providerKeyStorageProvider.overrideWithValue(secrets),
    cloudOperationPolicyProvider.overrideWith((Ref ref) {
      final StreamController<void> changes = StreamController<void>.broadcast(
        sync: true,
      );
      var networkOffline =
          ref.read(networkStateProvider).asData?.value == null ||
          ref.read(networkStateProvider).asData?.value == NetworkState.offline;
      final StreamSubscription<NetworkState> network = ref
          .read(connectivityServiceProvider)
          .watch()
          .listen((NetworkState state) {
            networkOffline = state == NetworkState.offline;
            changes.add(null);
          });
      final StreamSubscription<SettingKey<Object?>> settings = offlineStore
          .changes()
          .listen((SettingKey<Object?> key) {
            if (key.name == SettingKeys.offlineByChoice.name ||
                key.name == SettingKeys.egressOff.name) {
              changes.add(null);
            }
          });
      ref.onDispose(() {
        unawaited(network.cancel());
        unawaited(settings.cancel());
        unawaited(changes.close());
      });
      return CloudOperationPolicy(
        offline: () =>
            networkOffline || offlineStore.read(SettingKeys.offlineByChoice),
        allowsUpload: (String id) => EgressSwitches.decode(
          offlineStore.read(SettingKeys.egressOff),
        ).allows(EgressSwitches.upload(id)),
        changes: changes.stream,
      );
    }),
    offlineNowProvider.overrideWith((Ref ref) {
      final AsyncValue<NetworkState> state = ref.watch(networkStateProvider);
      return state.asData?.value == NetworkState.offline;
    }),
    themeModeProvider.overrideWith(
      () => ThemeModeController.withStore(SettingsTextStore(offlineStore)),
    ),
    lifecycleObserverProvider.overrideWith((Ref ref) => _lifecycleObserver!),
    leaveGuardProvider.overrideWith((Ref _) => LeaveGuard()),
    fieldEditorBindingsProvider.overrideWithValue(templateFieldEditorBindings),
  ];
  if (fixture != null || !_runningUnderTest) {
    final String id = profileId!;
    // Read alongside the sign-in restore below rather than before it.
    final Future<PlatformFacts> factsRead = platformFacts(clock: clock);
    final Future<DeviceDescriptor> deviceRead = deviceDescriptor();
    final AppDatabase db = database!;
    // An interrupted undo may have moved evidence before its database
    // transaction committed. Reconcile those moves before exposing projects.
    final Result<void> mergeRecovery = await MergeRepositoryImpl(
      db: db,
      files: PackageFiles(storageRoot: storageRoot),
      clock: clock,
      deviceId: id,
    ).recoverInterruptedUndo();
    if (mergeRecovery case FailureResult<void>(:final Failure failure)) {
      logger.warn(
        'merge',
        'interrupted undo recovery needs a retry',
        error: failure,
      );
    }
    final FileWriter evidenceWriter = FileWriter(storageRoot: storageRoot);
    // Transcripts a closed app left live are settled before any session can
    // start, so a new session is never taken for a stale one (task 119).
    final TranscriptRepositoryImpl transcriptStore = TranscriptRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: id,
      ids: ids,
    );
    await _recoverTranscripts(
      transcriptStore,
      takes: kIsWeb
          ? StagedTakeRecovery.chunked(
              writer: evidenceWriter,
              store: BlobStore.platform(AppConstants.projectFiles.storeName),
            )
          : StagedTakeRecovery(
              writer: evidenceWriter,
              storageRoot: storageRoot,
            ),
      meetings: MeetingRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: id,
        ids: ids,
        storageRoot: storageRoot,
        writer: evidenceWriter,
      ),
      logger: logger,
    );
    final DriftPhotoRepository capturePhotos = DriftPhotoRepository(
      db: db,
      writer: evidenceWriter,
      reader: FileReader(storageRoot: storageRoot),
      clock: clock,
      deviceId: id,
      ids: ids,
      storageRoot: storageRoot,
    );
    final BackendSession backendSession = BackendSession(
      storage: secrets,
      clock: clock,
      deviceId: id,
      initialUrl: Env.backendUrl,
      offline: () => offlineStore.read(SettingKeys.offlineByChoice),
      linkAccount: (String accountId) => linkDeviceAccount(
        db,
        deviceId: id,
        accountId: accountId,
        clock: clock,
      ),
    );
    await backendSession.restore();
    final PlatformFacts facts = await factsRead;
    final DeviceDescriptor device = await deviceRead;
    // AI goes through the organisation's proxy by default: no key is ever
    // entered on the device (task 024 step 26).
    final AiService proxy = backendProxy(
      backendSession,
      AiMediaReader(
        files: FileReader(storageRoot: storageRoot),
        storageRoot: storageRoot,
      ),
    );
    // An operation switched off on the privacy page resolves to nothing, in
    // every registry the app builds (task 022).
    bool egressAllows(AiOperation operation) => EgressSwitches.decode(
      offlineStore.read(SettingKeys.egressOff),
    ).allows(EgressSwitches.ai(operation));
    final ProviderRegistry providerRegistry = ProviderRegistry.keyless(
      proxy: proxy,
      allows: egressAllows,
    );
    final ProcessingStageWorker processingWorker = ProcessingStageWorker(
      db: db,
      clock: clock,
      deviceId: id,
      ids: ids,
      storageRoot: storageRoot,
      ocr: OcrService(),
      providers: providerRegistry,
      settings: offlineStore,
    );
    overrides.addAll(<Override>[
      backendSessionProvider.overrideWith((Ref ref) {
        // Identity and grants refresh whenever the server may be reachable
        // again, not only at launch and on a 401: when a network comes back
        // and when the app returns to the foreground. The session honours
        // the offline switch itself, and a failed refresh keeps everything.
        NetworkState? last;
        final StreamSubscription<NetworkState> network = ref
            .read(connectivityServiceProvider)
            .watch()
            .listen((NetworkState next) {
              final bool regained =
                  last == NetworkState.offline && next != NetworkState.offline;
              last = next;
              if (regained) {
                unawaited(backendSession.refresh());
              }
            });
        final StreamSubscription<AppLifecycleState> resumed = ref
            .read(lifecycleObserverProvider)
            .states
            .listen((AppLifecycleState state) {
              if (state == AppLifecycleState.resumed) {
                unawaited(backendSession.refresh());
              }
            });
        ref.onDispose(() {
          unawaited(network.cancel());
          unawaited(resumed.cancel());
          unawaited(backendSession.dispose());
        });
        return backendSession;
      }),
      feedbackClockProvider.overrideWith((Ref _) => clock),
      providerRegistryProvider.overrideWith((Ref ref) {
        ref.watch(backendConfigProvider);
        // Bound to the open project, so Settings tests the proxy in the scope
        // the server authorises; with none open it reports unavailable.
        return ProviderRegistry.keyless(
          proxy: ProviderRegistry.keyless(proxy: proxy).resolve(
            projectId: ref.watch(currentProjectProvider) ?? '',
            operation: AiOperation.extractFields,
          ),
          allows: egressAllows,
        );
      }),
      relayQueueProvider.overrideWith((Ref _) {
        return RelayQueue(
          store: fixture?.relayStore ?? BlobStore.platform('relay'),
          secrets: secrets,
          ids: ids,
          send: RelayQueue.overBytes(backendSession.sendBytes),
          deviceId: id,
        );
      }),
      relayPackageProvider.overrideWith((Ref ref) {
        final ExportRepository? exports = ref.watch(exportRepositoryProvider);
        if (exports == null) {
          return null;
        }
        final FileReader files = FileReader(storageRoot: storageRoot);
        // The relay sends the same project package a person would export.
        Future<Result<Uint8List>> packageBytes(String projectId) async {
          final Result<ExportedPackage> written = await exports.exportProject(
            projectId,
            cancel: CancellationToken(),
          );
          final BundleOutput output;
          switch (written) {
            case FailureResult<ExportedPackage>(:final Failure failure):
              return FailureResult<Uint8List>(failure);
            case Success<ExportedPackage>(:final ExportedPackage value):
              output = value.package;
          }
          return readRelayPackage(output, files);
        }

        return packageBytes;
      }),
      feedbackDeviceIdProvider.overrideWith((Ref _) => id),
      feedbackPlatformFactsProvider.overrideWith((Ref _) => facts),
      feedbackDeviceProvider.overrideWith((Ref _) => device),
      feedbackRepositoryProvider.overrideWith((Ref _) {
        return fixture == null
            ? FeedbackRepositoryImpl.platform(clock: clock, ids: ids)
            : FeedbackRepositoryImpl(
                store: fixture.feedbackStore,
                clock: clock,
                ids: ids,
              );
      }),
      // Stored exports are found under the root the operator chose.
      feedbackDownloadsProvider.overrideWith(
        (Ref _) => DownloadService(storageRoot: storageRoot),
      ),
      downloadServiceProvider.overrideWith(
        (Ref _) => DownloadService(storageRoot: storageRoot),
      ),
      projectOpenableFileLookupProvider.overrideWith((Ref ref) {
        return createProjectOpenableFileLookup(
          templates: ref.watch(templateRepositoryProvider),
        );
      }),
      feedbackPhotosProvider.overrideWith((Ref _) => PhotoPicker()),
      feedbackScreenCaptureProvider.overrideWith((Ref _) => ScreenCapture()),
      sttServiceProvider.overrideWith((Ref ref) {
        final SttService speech = SttService();
        ref.onDispose(() => unawaited(speech.cancel()));
        return speech;
      }),
      // On-device speech (task 113): the platform's Whisper engine, the
      // models this build bundles or the operator imported, and the device
      // probe, under the one host that loads and releases the model.
      speechEngineProvider.overrideWith((Ref ref) {
        final SpeechEngine engine = SpeechEngine.platform();
        ref.onDispose(() => unawaited(engine.dispose()));
        return engine;
      }),
      speechModelStoreProvider.overrideWith(
        (Ref ref) => SpeechModelStore.platform(
          privateRoot: StorageRoot.private(),
          assets: BundledAssets.platform(),
          webEngine: kIsWeb ? ref.watch(speechEngineProvider) : null,
        ),
      ),
      speechDeviceProbeProvider.overrideWith(
        (Ref ref) => SpeechDeviceProbe.platform(
          engine: ref.watch(speechEngineProvider),
          power: PowerSource(),
        ),
      ),
      speechEngineHostProvider.overrideWith((Ref ref) {
        final LifecycleObserver lifecycle = ref.watch(
          lifecycleObserverProvider,
        );
        final SpeechEngineHost host = SpeechEngineHost(
          engine: ref.watch(speechEngineProvider),
          store: ref.watch(speechModelStoreProvider),
          probe: ref.watch(speechDeviceProbeProvider),
          quality: () => ref.read(speechQualityProvider),
          lifecycle: lifecycle.states,
          memoryPressure: lifecycle.memoryPressure,
          // The crash-loop marker survives the process it guards.
          attempts: BlobStore.platform('speech'),
          clock: clock,
          logger: logger,
        );
        ref.onDispose(() => unawaited(host.dispose()));
        return host;
      }),
      projectRepositoryProvider.overrideWith((Ref _) {
        return ProjectRepositoryImpl(
          db: db,
          clock: clock,
          deviceId: id,
          ids: ids,
          // Trees are made, discarded and recycled under the chosen root.
          storageRoot: storageRoot,
          // Web stores no files; its project screens offer no photo.
          writer: kIsWeb ? null : evidenceWriter,
        );
      }),
      recordRepositoryProvider.overrideWith((Ref ref) {
        return RecordRepositoryImpl(
          db: db,
          clock: clock,
          deviceId: id,
          ids: ids,
          operatorName: () => ref.read(currentOperatorProvider)?.name ?? '',
        );
      }),
      destinationRepositoryProvider.overrideWith((Ref _) {
        return DestinationRepositoryImpl(
          database: db,
          secrets: DestinationSecrets(secrets),
          clock: clock,
          deviceId: id,
          ids: ids,
        );
      }),
      exportRepositoryProvider.overrideWith((Ref ref) {
        return ExportRepositoryImpl(
          db: db,
          storageRoot: storageRoot,
          clock: clock,
          deviceId: id,
          ids: ids,
          templates: ref.watch(templateRepositoryProvider),
          excludeCoordinates: () async =>
              offlineStore.read(SettingKeys.excludeCoordinates),
          blurFaces: () async => offlineStore.read(SettingKeys.blurFaces),
        );
      }),
      cloudExportGuardProvider.overrideWith((Ref ref) {
        final ExportRepository? repository = ref.watch(
          exportRepositoryProvider,
        );
        if (repository case final ExportSharingPolicy policy) {
          final ExportUploadGuard guard = ExportUploadGuard(
            db: db,
            storage: storageRoot,
            policy: policy,
          );
          return guard.check;
        } else {
          return (String _) async => FailureResult<void>(
            StorageFailure(
              localizedMessage: Copy
                  .messages
                  .failureExportProtectionsAreUnavailableOnThisDevice,
            ),
          );
        }
      }),
      deliverableRepositoryProvider.overrideWith((Ref ref) {
        return DeliverableRepositoryImpl(
          db: db,
          storageRoot: storageRoot,
          records: ref.watch(recordRepositoryProvider),
          templates: ref.watch(templateRepositoryProvider),
          clock: clock,
          ids: ids,
          deviceId: id,
          excludeCoordinates: () async =>
              offlineStore.read(SettingKeys.excludeCoordinates),
          blurFaces: () async => offlineStore.read(SettingKeys.blurFaces),
          font: () async {
            final ByteData data = await rootBundle.load(
              'assets/fonts/NotoSans-Regular.ttf',
            );
            return data.buffer.asUint8List(
              data.offsetInBytes,
              data.lengthInBytes,
            );
          },
        );
      }),
      locationServiceProvider.overrideWith(
        (Ref ref) => LocationService(
          gpsEnabled: () =>
              ref.read(currentProjectDetailsProvider)?.settings.gpsEnabled ??
              offlineStore.read(SettingKeys.gpsEnabled),
        ),
      ),
      permissionsServiceProvider.overrideWith(
        (Ref ref) => PermissionsService(
          gpsEnabled: () =>
              ref.read(currentProjectDetailsProvider)?.settings.gpsEnabled ??
              offlineStore.read(SettingKeys.gpsEnabled),
        ),
      ),
      cameraServiceProvider.overrideWith((Ref _) => CameraService()),
      barcodeScannerServiceProvider.overrideWith(
        (Ref _) => BarcodeScannerService(),
      ),
      packageImportRepositoryProvider.overrideWith((Ref ref) {
        return PackageImportRepositoryImpl(
          db: db,
          files: PackageFiles(storageRoot: storageRoot),
          clock: clock,
          deviceId: id,
          ids: ids,
          guard: kIsWeb ? null : ref.watch(storageGuardProvider),
          // A browser has no folders; its files live in one store.
          folders: kIsWeb ? null : ProjectFolders(storageRoot: storageRoot),
        );
      }),
      photoRepositoryProvider.overrideWith((Ref _) => capturePhotos),
      photoPrivacyServiceProvider.overrideWith(
        (Ref ref) => PhotoPrivacyService(
          db: db,
          files: FileReader(storageRoot: storageRoot),
          writer: evidenceWriter,
          clock: clock,
          deviceId: id,
          operatorName: () => ref.read(currentOperatorProvider)?.name ?? id,
        ),
      ),
      consentClockProvider.overrideWithValue(clock),
      consentActorProvider.overrideWith((Ref ref) {
        final String name =
            ref.read(currentOperatorProvider)?.name.trim() ?? '';
        return name.isEmpty ? id : name;
      }),
      capturePersistenceProvider.overrideWith((Ref _) {
        return DriftCapturePersistence(
          db: db,
          photos: capturePhotos,
          clock: clock,
          deviceId: id,
          ids: ids,
        );
      }),
      // Storage > Check files walks the configured root and stamps what it
      // adopts or flags with the profile's device id.
      orphanScannerProvider.overrideWith((Ref _) {
        return OrphanScanner(
          db: db,
          storageRoot: storageRoot,
          clock: clock,
          deviceId: id,
          ids: ids,
        );
      }),
      // A browser keeps files in one store: there is no folder tree to move.
      fileRelocationProvider.overrideWith((Ref _) {
        return kIsWeb
            ? null
            : FileRelocation(
                db: db,
                storageRoot: storageRoot,
                clock: clock,
                deviceId: id,
                ids: ids,
              );
      }),
      captureRecordWriterProvider.overrideWith((Ref ref) {
        return CaptureRecordWriter(
          db: db,
          clock: clock,
          deviceId: id,
          ids: ids,
          operatorName: () => ref.read(currentOperatorProvider)?.name ?? '',
          autoFillDates: () => offlineStore.read(SettingKeys.autoFillDates),
          relocation: ref.watch(fileRelocationProvider),
        );
      }),
      captureDocumentRepositoryProvider.overrideWith(
        (Ref ref) => CaptureDocumentRepositoryImpl(
          db: db,
          writer: evidenceWriter,
          reader: ref.watch(fileReaderProvider),
          pages: ref.watch(pdfPagesProvider),
          ids: ids,
          clock: clock,
          deviceId: id,
        ),
      ),
      audioRecorderServiceProvider.overrideWith((Ref ref) {
        return kIsWeb
            ? const AudioRecorderService.unavailable()
            : AudioRecorderPlugin(
                writer: evidenceWriter,
                storageRoot: storageRoot,
                arbiter: ref.watch(microphoneArbiterProvider),
              );
      }),
      audioCaptureServiceProvider.overrideWith((Ref ref) {
        // A browser stages its takes as chunks in the project files' store
        // and publishes them through the same writer.
        return kIsWeb
            ? AudioCaptureService(
                writer: evidenceWriter,
                storageRoot: storageRoot,
                access: MicrophoneAccess.platform(
                  permissions: ref.watch(permissionsServiceProvider),
                ),
                arbiter: ref.watch(microphoneArbiterProvider),
              )
            : const AudioCaptureService.unavailable();
      }),
      processingRepositoryProvider.overrideWith((Ref ref) {
        return ProcessingRepositoryImpl(
          db: db,
          clock: clock,
          deviceId: id,
          ids: ids,
          settings: ref.watch(projectSettingsStoreProvider),
        );
      }),
      processingNotificationsProvider.overrideWith((Ref ref) {
        final Notifications notifications = Notifications.plugin(
          onTap: (String route) => ref.read(routerProvider).go(route),
        );
        return (int succeeded, int failed) {
          return notifications.reportBatch(
            succeeded: succeeded,
            failed: failed,
          );
        };
      }),
      processingStageWorkProvider.overrideWith(
        (Ref _) => processingWorker.perform,
      ),
      processingEgressSummaryProvider.overrideWith(
        (Ref _) => processingWorker.egressSummary,
      ),
      processingTemplateChoiceProvider.overrideWith(
        (Ref _) => processingWorker.templateChoice,
      ),
      processingTemplateAssistProvider.overrideWith(
        (Ref _) => processingWorker.templateAssist,
      ),
      unattendedProcessingProvider.overrideWith((Ref ref) {
        final SettingsStore settings = ref.watch(projectSettingsStoreProvider);
        // The batch controller stays alive while the paths listen.
        ref.listen<ProcessingBatchState>(
          processingControllerProvider,
          (ProcessingBatchState? _, ProcessingBatchState _) {},
        );
        ProcessingController batches() {
          return ref.read(processingControllerProvider.notifier);
        }

        final UnattendedProcessing paths = UnattendedProcessing(
          network: ref.read(connectivityServiceProvider).watch(),
          lifecycle: ref.read(lifecycleObserverProvider).states,
          charging: PowerSource().watchCharging(),
          settings: settings,
          underCap: () async {
            final Result<({int requests, int images})> usage = await ref
                .read(processingRepositoryProvider)
                .usageOn(clock.nowUtc());
            return usage.fold(
              (Failure _) => false,
              (({int requests, int images}) today) =>
                  today.requests < settings.read(SettingKeys.aiDailyRequestCap),
            );
          },
          // Turning automatic processing on is the consent to send; the
          // online stage still keeps each project's daily cap.
          processAll: () =>
              batches().process(confirmOnline: (ProcessingJob _) async => true),
          readOnDevice: () =>
              batches().process(stopAfter: JobStage.onDevice, notify: false),
          cancel: () => batches().cancel(),
        )..start();
        ref.onDispose(() => unawaited(paths.dispose()));
        return paths;
      }),
      templateRepositoryProvider.overrideWith((Ref _) {
        return TemplateRepositoryImpl(
          db: db,
          clock: clock,
          deviceId: id,
          ids: ids,
        );
      }),
      referenceRepositoryProvider.overrideWith((Ref _) {
        return ReferenceRepositoryImpl(
          db: db,
          clock: clock,
          deviceId: id,
          ids: ids,
        );
      }),
      contextRepositoryProvider.overrideWith((Ref _) {
        return ContextRepositoryImpl(
          db: db,
          clock: clock,
          deviceId: id,
          ids: ids,
        );
      }),
      meetingRepositoryProvider.overrideWith((Ref _) {
        return MeetingRepositoryImpl(
          db: db,
          clock: clock,
          deviceId: id,
          ids: ids,
          storageRoot: storageRoot,
          writer: evidenceWriter,
        );
      }),
      transcriptRepositoryProvider.overrideWith((Ref _) => transcriptStore),
      qualityRepositoryProvider.overrideWith((Ref ref) {
        return QualityRepositoryImpl(
          db: db,
          clock: clock,
          deviceId: id,
          ids: ids,
          templates: ref.watch(templateRepositoryProvider),
          operatorName: () => ref.read(currentOperatorProvider)?.name ?? '',
        );
      }),
      recordImportStoreProvider.overrideWith((Ref ref) {
        return RecordImportStoreImpl(
          db: db,
          clock: clock,
          deviceId: id,
          ids: ids,
          operatorName: () => ref.read(currentOperatorProvider)?.name ?? '',
        );
      }),
      appDatabaseProvider.overrideWith((Ref _) => db),
    ]);
    // The retention purge (task 014 step 7) runs once per launch, after the
    // first frame so startup never waits on it, over the window set now.
    final PurgeJob purgeJob = PurgeJob(
      store: RecordPurgeStore(
        db: db,
        files: EvidencePurge(storageRoot: storageRoot),
      ),
      clock: clock,
      retentionDays: offlineStore.read(SettingKeys.retentionDays),
    );
    overrides.add(recordPurgeJobProvider.overrideWithValue(purgeJob));
    // The startup integrity check (task 004) and the launch prune of `.cache`
    // (task 005 step 4) run after the first frame too, so cold start never
    // waits on them.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (fixture?.stopping == true) return;
      final List<Future<void>> work = <Future<void>>[
        _purgeExpiredRecords(purgeJob),
        _checkIntegrity(db, storageRoot),
        _pruneCache(storageRoot),
        _recordSpeechCrashes(),
        backendSession.refresh().then<void>((_) {}),
      ];
      fixture?.maintenance.addAll(work);
      for (final Future<void> future in work) {
        unawaited(future);
      }
    });
  }
  // The first redirect and a cold-start shared bundle must see the persisted
  // PIN before any project screen or inspection becomes reachable.
  await lock.hydrate();
  runApp(
    ProviderScope(
      observers: Env.isDev
          ? <ProviderObserver>[AppProviderObserver(logger)]
          : const <ProviderObserver>[],
      overrides: overrides,
      child: TaptureApp(receiveIncomingBundles: fixture == null),
    ),
  );
}

void Function(FlutterErrorDetails) _installErrorHandlers() {
  final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
  void handler(FlutterErrorDetails details) {
    _captureError(details.exception, details.stack ?? StackTrace.empty);
    previous?.call(details);
  }

  FlutterError.onError = handler;
  return handler;
}

void _installLifecycleObserver() {
  if (_lifecycleObserver != null) {
    return;
  }
  _lifecycleObserver = LifecycleObserver(onPauseFlush: _flushPendingWrites);
  WidgetsBinding.instance.addObserver(_lifecycleObserver!);
}

Future<SettingsStore> _openOfflineStore(AppDatabase? db, String? id) async {
  // Suites never open the on-disk database, so they arrive here without one
  // (FE-TEST-03). Production still honours a persisted choice at launch,
  // stamped with the profile's device id.
  if (db == null || id == null) {
    return SettingsStore.fake();
  }
  try {
    return await SettingsStore.open(
      db: db,
      deviceId: id,
      clock: const SystemClock(),
    );
  } on Object {
    return SettingsStore.fake();
  }
}

/// Settles the transcripts a closed app left live: recovers and files a
/// meeting's or a standalone recording's take, then marks each interrupted.
/// Never deletes a file; logs counts only.
Future<void> _recoverTranscripts(
  TranscriptRepositoryImpl store, {
  required AudioRecoveryService takes,
  required MeetingRepositoryImpl meetings,
  required Logger logger,
}) async {
  final Result<int> settled =
      await TranscriptRecovery(repository: store, logger: logger).run(
        recoverAudio: takes.recover,
        fileAudio: (TranscriptSummary item, AudioRecording audio) async {
          final String? meetingId = item.ownerId;
          switch (item.ownerKind) {
            case TranscriptOwnerKind.meeting when meetingId != null:
              final Result<MeetingAttachment> attached = await meetings
                  .attachStored(
                    meetingId,
                    storagePath: audio.relativePath,
                    mimeType: audio.mimeType,
                    bytes: audio.byteLength,
                    sha256: audio.sha256,
                    duration: audio.duration,
                  );
              return attached.map<String?>((MeetingAttachment file) => file.id);
            case TranscriptOwnerKind.standalone:
              final Result<String> filed = await store.fileStandaloneAudio(
                item.id,
                audio,
              );
              return filed.map<String?>((String attachment) => attachment);
            case TranscriptOwnerKind.meeting || TranscriptOwnerKind.capture:
              return const Success<String?>(null);
          }
        },
      );
  if (settled case FailureResult<int>(:final Failure failure)) {
    logger.warn('speech', 'stale recordings need a retry', error: failure);
  }
}

/// Runs the read-only integrity check once and logs what it found, as a
/// count only; nothing is repaired. Storage > Check files lists the findings.
Future<void> _checkIntegrity(AppDatabase db, StorageRoot storageRoot) async {
  final Logger logger = Logger.current;
  final Result<List<IntegrityFinding>> outcome = await runIntegrityCheck(
    db,
    files: FileReader(storageRoot: storageRoot),
  );
  switch (outcome) {
    case Success<List<IntegrityFinding>>(
      value: final List<IntegrityFinding> findings,
    ):
      final int broken = findings.length;
      if (broken == 0) {
        logger.info('integrity', 'no broken references');
      } else {
        logger.warn('integrity', '$broken broken references found');
      }
    case FailureResult<List<IntegrityFinding>>(:final Failure failure):
      logger.warn(
        'integrity',
        'the integrity check could not run',
        error: failure,
      );
  }
}

/// Bounds `.cache` by age then size once per launch, and logs the bytes
/// reclaimed. A browser keeps no cache folder.
Future<void> _pruneCache(StorageRoot storageRoot) async {
  if (kIsWeb) {
    return;
  }
  final Logger logger = Logger.current;
  final Result<int> pruned = await CacheCleanup(
    storageRoot: storageRoot,
  ).prune();
  switch (pruned) {
    case Success<int>(value: final int reclaimed):
      logger.info('cache', 'pruned $reclaimed bytes');
    case FailureResult<int>(:final Failure failure):
      logger.warn('cache', 'the cache could not be pruned', error: failure);
  }
}

/// Points the speech engine's fatal-abort record at
/// `<private>/speech/crash.log` and logs how many lines earlier runs left
/// there. Diagnostic only: the crash-loop decision is the host's marker.
Future<void> _recordSpeechCrashes() async {
  if (kIsWeb) {
    return;
  }
  final Logger logger = Logger.current;
  final Result<String> crashFile = (await StorageRoot.private().resolve()).map(
    (folder) => '${folder.path}/speech/crash.log',
  );
  switch (crashFile) {
    case Success<String>(value: final String path):
      final int? lines = await recordSpeechCrashes(path);
      if (lines == null) {
        logger.info('speech', 'no native engine to record crashes');
      } else {
        logger.info('speech', 'native crash record holds $lines lines');
      }
    case FailureResult<String>(:final Failure failure):
      logger.warn('speech', 'crash record not set up', error: failure);
  }
}

/// Runs the retention purge once and logs what it did, as counts only.
Future<void> _purgeExpiredRecords(PurgeJob job) async {
  final Logger logger = Logger.current;
  try {
    final Result<PurgeReport> outcome = await job.run();
    switch (outcome) {
      case Success<PurgeReport>(value: final PurgeReport report):
        logger.info('purge', report.summary);
      case FailureResult<PurgeReport>(:final Failure failure):
        logger.warn(
          'purge',
          'the retention purge could not run',
          error: failure,
        );
    }
  } on Object catch (error) {
    logger.warn('purge', 'the retention purge stopped', error: error);
  }
}

/// Awaited on pause (FE-STATE-07): folds the write-ahead log into the
/// database file, so what the app has confirmed is whole in that one file
/// before the OS may stop the process.
Future<void> _flushPendingWrites() async {
  final AppDatabase? db = _database;
  if (db != null) {
    final Result<void> flushed = await checkpointDatabase(db);
    if (flushed case FailureResult<void>(:final Failure failure)) {
      Logger.current.warn(
        'lifecycle',
        'the pause flush failed',
        error: failure,
      );
    }
  }
  await Logger.current.flush();
}

void _handleZoneError(Object error, StackTrace stackTrace) {
  _captureError(error, stackTrace);
}

bool get _runningUnderTest {
  if (const bool.fromEnvironment('FLUTTER_TEST')) {
    return true;
  }
  // An on-device integration run boots the real app so launch can be
  // measured; widget suites use a test binding and never touch the store.
  final String binding = WidgetsBinding.instance.runtimeType.toString();
  return binding.contains('Test') && !binding.contains('IntegrationTest');
}

void _captureError(Object error, StackTrace stackTrace) {
  debugBootstrapErrors.add(error);
  final Logger logger = Logger.current;
  logger.error(
    'bootstrap',
    'an uncaught error was captured $stackTrace',
    error: error,
  );
}
