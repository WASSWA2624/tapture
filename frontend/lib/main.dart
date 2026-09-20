import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import 'app/app.dart';
import 'app/provider_observer.dart' hide ProviderObserver;
import 'app/theme/settings_text_store.dart';
import 'core/ai/stt_service.dart';
import 'core/db/app_database.dart';
import 'core/device/device_identity.dart';
import 'core/device/platform_facts.dart';
import 'core/files/download_service.dart';
import 'core/files/photo_picker.dart';
import 'core/files/screen_capture.dart';
import 'core/ids/uuid_service.dart';
import 'core/lifecycle/lifecycle.dart';
import 'core/logging/logger.dart';
import 'core/security/secure_storage.dart';
import 'core/time/clock.dart';
import 'core/widgets/fields/field_editor.dart';
import 'features/feedback/feedback.dart';
import 'features/feedback/presentation/feedback_providers.dart';
import 'features/projects/data/project_openable_file_lookup_factory.dart';
import 'features/projects/data/project_repository_impl.dart';
import 'features/projects/presentation/current_project.dart';
import 'features/projects/presentation/project_open_externally_action.dart'
    show projectOpenableFileLookupProvider;
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
  final SettingsStore offlineStore = await _openOfflineStore();
  const SystemClock clock = SystemClock();
  final List<Override> overrides = <Override>[
    appLockProvider.overrideWith((Ref ref) => lock),
    offlineStoreProvider.overrideWith((Ref _) => offlineStore),
    projectSettingsStoreProvider.overrideWith((Ref _) => offlineStore),
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
    final AppDatabase db = AppDatabase.open();
    overrides.addAll(<Override>[
      feedbackClockProvider.overrideWith((Ref _) => clock),
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
        );
      }),
      templateRepositoryProvider.overrideWith((Ref _) {
        return TemplateRepositoryImpl(
          db: db,
          clock: clock,
          deviceId: id,
          ids: ids,
        );
      }),
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

Future<SettingsStore> _openOfflineStore() async {
  // Suites never open the on-disk database (FE-TEST-03). Production still
  // honours a persisted choice at launch.
  if (_runningUnderTest) {
    return SettingsStore.fake();
  }
  try {
    const SystemClock clock = SystemClock();
    return await SettingsStore.open(
      db: AppDatabase.open(),
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
