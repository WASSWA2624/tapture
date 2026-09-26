import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'app/app.dart';
import 'app/provider_observer.dart' hide ProviderObserver;
import 'app/theme/settings_text_store.dart';
import 'app/widgets/status_line.dart';
import 'core/ai/ocr_service.dart';
import 'core/ai/provider_registry.dart';
import 'core/ai/stt_service.dart';
import 'core/audio/audio_recorder_plugin.dart';
import 'core/audio/audio_recorder_service.dart';
import 'core/db/app_database.dart';
import 'core/db/database_provider.dart';
import 'core/device/device_identity.dart';
import 'core/device/platform_facts.dart';
import 'core/files/download_service.dart';
import 'core/files/file_writer.dart';
import 'core/files/photo_picker.dart';
import 'core/files/screen_capture.dart';
import 'core/files/storage_root.dart';
import 'core/ids/uuid_service.dart';
import 'core/lifecycle/lifecycle.dart';
import 'core/logging/logger.dart';
import 'core/network/connectivity_service.dart';
import 'core/network/offline_now.dart';
import 'core/security/secure_storage.dart';
import 'core/time/clock.dart';
import 'core/widgets/fields/field_editor.dart';
import 'features/capture/capture.dart';
import 'features/context/data/context_repository_impl.dart';
import 'features/exports/data/export_repository_impl.dart';
import 'features/feedback/feedback.dart';
import 'features/feedback/presentation/feedback_providers.dart';
import 'features/processing/data/notifications.dart';
import 'features/processing/data/processing_repository_impl.dart';
import 'features/processing/data/processing_stage_worker.dart';
import 'features/processing/presentation/processing_controller.dart';
import 'features/processing/presentation/queue_providers.dart';
import 'features/projects/data/project_openable_file_lookup_factory.dart';
import 'features/projects/data/project_repository_impl.dart';
import 'features/projects/presentation/current_project.dart';
import 'features/projects/presentation/project_open_externally_action.dart'
    show projectOpenableFileLookupProvider;
import 'features/reference/data/reference_repository_impl.dart';
import 'features/settings/presentation/offline_switch.dart';
import 'features/settings/settings.dart';
import 'features/templates/data/template_repository_impl.dart';
import 'features/templates/presentation/field_editor_bindings.dart';

/// Errors captured for bootstrap tests; the same objects are also logged.
@visibleForTesting
final List<Object> debugBootstrapErrors = <Object>[];

LifecycleObserver? _lifecycleObserver;

/// Entry point for the Tapture application.
Future<void> main() async {
  await runZonedGuarded(_run, _handleZoneError);
}

Future<void> _run() async {
  // The binding is initialised in the guarded zone because runApp must run in
  // the zone that created it; otherwise Flutter reports a zone mismatch.
  WidgetsFlutterBinding.ensureInitialized();
  _installErrorHandlers();
  _installLifecycleObserver();
  final Logger logger = Logger(persist: true);
  Logger.current = logger;
  final PinLock lock = PinLock(
    storage: SecureStorage(),
    clock: const SystemClock(),
    biometrics: BiometricLock(),
  );
  // One database for the whole app. A second AppDatabase over the same file
  // races with the first -- drift warns about it, and the two connections can
  // corrupt the store. Suites never open it at all (FE-TEST-03).
  final AppDatabase? database = _runningUnderTest ? null : AppDatabase.open();
  final SettingsStore offlineStore = await _openOfflineStore(database);
  final StorageRoot storageRoot = StorageRoot(
    preferredPath: () async => offlineStore.read(SettingKeys.storageRootPath),
  );
  const SystemClock clock = SystemClock();
  final List<Override> overrides = <Override>[
    appLockProvider.overrideWith((Ref ref) => lock),
    offlineStoreProvider.overrideWith((Ref _) => offlineStore),
    projectSettingsStoreProvider.overrideWith((Ref _) => offlineStore),
    storageRootProvider.overrideWith((Ref _) => storageRoot),
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
  if (!_runningUnderTest) {
    final UuidV7Service ids = UuidV7Service(clock);
    final String id = await deviceId(clock: clock, ids: ids);
    final PlatformFacts facts = await platformFacts(clock: clock);
    final DeviceDescriptor device = await deviceDescriptor();
    final AppDatabase db = database!;
    final FileWriter evidenceWriter = FileWriter(storageRoot: storageRoot);
    final DriftPhotoRepository capturePhotos = DriftPhotoRepository(
      db: db,
      writer: evidenceWriter,
      clock: clock,
      deviceId: id,
      ids: ids,
      storageRoot: storageRoot,
    );
    final ProviderRegistry providerRegistry = ProviderRegistry.keyless();
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
      feedbackClockProvider.overrideWith((Ref _) => clock),
      providerRegistryProvider.overrideWith((Ref _) => providerRegistry),
      feedbackDeviceIdProvider.overrideWith((Ref _) => id),
      feedbackPlatformFactsProvider.overrideWith((Ref _) => facts),
      feedbackDeviceProvider.overrideWith((Ref _) => device),
      feedbackRepositoryProvider.overrideWith((Ref _) {
        return FeedbackRepositoryImpl.platform(clock: clock, ids: ids);
      }),
      feedbackDownloadsProvider.overrideWith((Ref _) => DownloadService()),
      downloadServiceProvider.overrideWith((Ref _) => DownloadService()),
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
      projectRepositoryProvider.overrideWith((Ref _) {
        return ProjectRepositoryImpl(
          db: db,
          clock: clock,
          deviceId: id,
          ids: ids,
          // Web stores no files; its project screens offer no photo.
          writer: kIsWeb ? null : evidenceWriter,
        );
      }),
      exportRepositoryProvider.overrideWith((Ref _) {
        return ExportRepositoryImpl(
          db: db,
          storageRoot: storageRoot,
          clock: clock,
          deviceId: id,
          ids: ids,
        );
      }),
      photoRepositoryProvider.overrideWith((Ref _) => capturePhotos),
      capturePersistenceProvider.overrideWith((Ref _) {
        return DriftCapturePersistence(
          db: db,
          photos: capturePhotos,
          clock: clock,
          deviceId: id,
          ids: ids,
        );
      }),
      captureRecordWriterProvider.overrideWith((Ref _) {
        return CaptureRecordWriter(
          db: db,
          clock: clock,
          deviceId: id,
          ids: ids,
        );
      }),
      audioRecorderServiceProvider.overrideWith((Ref _) {
        return kIsWeb
            ? const AudioRecorderService.unavailable()
            : AudioRecorderPlugin(
                writer: evidenceWriter,
                storageRoot: storageRoot,
              );
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
      appDatabaseProvider.overrideWith((Ref _) => db),
    ]);
  }
  runApp(
    ProviderScope(
      observers: Env.isDev
          ? <ProviderObserver>[AppProviderObserver(logger)]
          : const <ProviderObserver>[],
      overrides: overrides,
      child: const TaptureApp(),
    ),
  );
}

void _installErrorHandlers() {
  final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    _captureError(details.exception, details.stack ?? StackTrace.empty);
    previous?.call(details);
  };
}

void _installLifecycleObserver() {
  if (_lifecycleObserver != null) {
    return;
  }
  _lifecycleObserver = LifecycleObserver(onPauseFlush: _flushPendingWrites);
  WidgetsBinding.instance.addObserver(_lifecycleObserver!);
}

Future<SettingsStore> _openOfflineStore(AppDatabase? db) async {
  // Suites never open the on-disk database, so they arrive here without one
  // (FE-TEST-03). Production still honours a persisted choice at launch.
  if (db == null) {
    return SettingsStore.fake();
  }
  try {
    const SystemClock clock = SystemClock();
    return await SettingsStore.open(
      db: db,
      deviceId: await deviceId(clock: clock, ids: UuidV7Service(clock)),
      clock: clock,
    );
  } on Object {
    return SettingsStore.fake();
  }
}

Future<void> _flushPendingWrites() async {
  // Persistence is not on this task. The await keeps a later flush from
  // becoming a floating future on pause (FE-STATE-07, FE-CODE-07).
}

void _handleZoneError(Object error, StackTrace stackTrace) {
  _captureError(error, stackTrace);
}

bool get _runningUnderTest {
  if (const bool.fromEnvironment('FLUTTER_TEST')) {
    return true;
  }
  return WidgetsBinding.instance.runtimeType.toString().contains('Test');
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
