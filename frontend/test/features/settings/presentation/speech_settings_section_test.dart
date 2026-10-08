import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/ai/stt_service.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/copy/l10n/app_localizations.g.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/speech/routed_stt_service.dart';
import 'package:tapture/core/speech/speech.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/features/settings/data/settings_store.dart';
import 'package:tapture/features/settings/domain/setting_keys.dart';
import 'package:tapture/features/settings/presentation/offline_switch.dart';
import 'package:tapture/features/settings/presentation/speech_settings_providers.dart';
import 'package:tapture/features/settings/presentation/speech_settings_section.dart';
import 'package:tapture/main.dart' show speechQualityOverride;

import '../../../support/a11y_matchers.dart';
import '../../../support/fakes/fake_speech_engine.dart';
import '../../../support/fakes/fake_stt_service.dart';
import '../../../support/live_transcription_rig.dart';
import '../../../support/screen_matrix.dart';

const SpeechModelEntry _tiny = SpeechModelCatalogue.tiny;
const SpeechModelEntry _base = SpeechModelCatalogue.base;
const SpeechModelEntry _small = SpeechModelCatalogue.small;
const SpeechModelEntry _vad = SpeechModelCatalogue.vad;

/// Free memory that holds the fast model and not the balanced one.
final SpeechDeviceProfile _tightDevice = SpeechDeviceProfile(
  runtime: SpeechRuntimeFacts(
    available: true,
    abiVersion: 1,
    is64Bit: true,
    totalMemoryBytes: testDesktopDevice.runtime.totalMemoryBytes,
    availableMemoryBytes: _base.memoryEstimateBytes,
    logicalCores: 8,
  ),
  platform: TargetPlatform.windows,
  isWeb: false,
  charging: true,
);

void main() {
  late FakeSpeechEngine engine;
  late StreamController<AppLifecycleState> lifecycle;
  late StreamController<void> pressure;

  setUp(() {
    engine = FakeSpeechEngine();
    lifecycle = StreamController<AppLifecycleState>.broadcast();
    pressure = StreamController<void>.broadcast();
  });

  tearDown(() async {
    await engine.dispose();
    await lifecycle.close();
    await pressure.close();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    SpeechModelStore? store,
    SpeechDeviceProfile device = testDesktopDevice,
    SettingsStore? settings,
    DocumentPicker picker = const DocumentPicker.fake(),
    SttService? platform,
    bool expanded = true,
    ScreenMatrix cell = const ScreenMatrix(
      Size(393, 852),
      1,
      Brightness.light,
      false,
    ),
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = cell.size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = cell.textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final ProviderContainer container = ProviderContainer(
      retry: (int _, Object _) => null,
      overrides: <Override>[
        offlineStoreProvider.overrideWithValue(
          settings ?? SettingsStore.fake(),
        ),
        // main's own binding: core reads the quality the settings store holds.
        speechQualityOverride(),
        speechModelStoreProvider.overrideWithValue(
          store ?? SpeechModelStore.fake(testInstalledModels()),
        ),
        speechDeviceProbeProvider.overrideWithValue(
          SpeechDeviceProbe.fake(device),
        ),
        documentPickerProvider.overrideWithValue(picker),
        platformRecogniserProvider.overrideWithValue(platform),
        speechEngineHostProvider.overrideWith((Ref ref) {
          final SpeechEngineHost host = SpeechEngineHost(
            engine: engine,
            store: ref.watch(speechModelStoreProvider),
            probe: ref.watch(speechDeviceProbeProvider),
            quality: () => ref.read(speechQualityProvider),
            lifecycle: lifecycle.stream,
            memoryPressure: pressure.stream,
            delay: (Duration _) => Completer<void>().future,
          );
          ref.onDispose(() => unawaited(host.dispose()));
          return host;
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(brightness: cell.brightness, outdoor: cell.outdoor),
          home: const Scaffold(
            body: SingleChildScrollView(child: SpeechSettingsSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (expanded) {
      final LocalizedCopy copy = Copy.of(
        tester.element(find.byType(SpeechSettingsSection)),
      );
      await tester.ensureVisible(find.text(copy.settingsSpeechModels));
      await tester.pumpAndSettle();
      await _tap(tester, find.text(copy.settingsSpeechModels));
      await tester.pumpAndSettle();
    }
    return container;
  }

  Finder row(SpeechModelEntry entry) =>
      find.byKey(ValueKey<String>('speech-model-${entry.id}'));

  Finder inRow(SpeechModelEntry entry, String text) =>
      find.descendant(of: row(entry), matching: find.textContaining(text));

  String detail(SpeechModelEntry entry, String origin, String state) =>
      Copy.settingsSpeechModelSummary(state, Copy.fileSize(entry.bytes));

  testWidgets('inventory starts closed with engine health visible', (
    WidgetTester tester,
  ) async {
    await pump(tester, expanded: false);
    expect(row(_tiny), findsNothing);
    expect(find.text(Copy.settingsSpeechImport), findsNothing);
    expect(
      find.text(
        Copy.settingsSpeechEngineWhisper(Copy.settingsSpeechModelBalanced),
      ),
      findsOneWidget,
    );
    await _tap(tester, find.text(Copy.settingsSpeechModels));
    await tester.pumpAndSettle();
    expect(row(_tiny), findsOneWidget);
    tester.view.physicalSize = const Size(800, 600);
    await tester.pumpAndSettle();
    expect(row(_tiny), findsOneWidget);
    await _tap(tester, find.text(Copy.settingsSpeechModels));
    await tester.pumpAndSettle();
    expect(row(_tiny), findsNothing);
  });

  testWidgets(
    'a compact model row keeps origin in details and Verify works with the keyboard',
    (WidgetTester tester) async {
      await pump(tester);
      expect(find.text(Copy.settingsSpeechModelBundled), findsNothing);
      final Finder details = find.byKey(
        ValueKey<String>('speech-model-details-${_tiny.id}'),
      );
      await _tap(
        tester,
        find.descendant(
          of: details,
          matching: find.text(Copy.settingsSpeechModelDetails),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(Copy.settingsSpeechModelBundled), findsOneWidget);
      final Finder menu = find.byKey(
        ValueKey<String>('speech-model-menu-${_tiny.id}'),
      );
      await _tap(tester, menu);
      await tester.pumpAndSettle();
      expect(menu, meetsTapTarget());
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        find.text(Copy.settingsSpeechVerified(Copy.settingsSpeechModelFast)),
        findsOneWidget,
      );
      expect(inRow(_tiny, Copy.settingsSpeechModelVerified), findsOneWidget);
    },
  );

  for (final bool damaged in <bool>[false, true]) {
    testWidgets(
      'required model recovery remains visible when closed: damaged=$damaged',
      (WidgetTester tester) async {
        await pump(
          tester,
          expanded: false,
          store: SpeechModelStore.fake(<String, SpeechModelStatus>{
            ...testInstalledModels(),
            _tiny.id: SpeechModelStatus(
              entry: _tiny,
              present: damaged,
              damaged: damaged,
            ),
          }),
        );
        expect(row(_tiny), findsNothing);
        expect(
          find.text(
            damaged ? Copy.speechModelDamaged : Copy.speechModelMissing,
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            damaged
                ? Copy.speechModelDamagedRecovery
                : Copy.speechModelMissingRecovery,
          ),
          findsOneWidget,
        );
        expect(find.text(Copy.settingsSpeechImport), findsOneWidget);
      },
    );
  }

  testWidgets('an optional damaged model stays in the closed inventory', (
    WidgetTester tester,
  ) async {
    await pump(
      tester,
      expanded: false,
      store: SpeechModelStore.fake(<String, SpeechModelStatus>{
        ...testInstalledModels(),
        _small.id: const SpeechModelStatus(
          entry: _small,
          present: true,
          imported: true,
          damaged: true,
        ),
      }),
    );
    expect(find.text(Copy.speechModelDamaged), findsNothing);
    expect(find.text(Copy.speechModelDamagedRecovery), findsNothing);
    expect(row(_small), findsNothing);
  });

  testWidgets('collapsing during removal keeps the operation and result', (
    WidgetTester tester,
  ) async {
    final _HeldRemoveStore store = _HeldRemoveStore(
      SpeechModelStore.fake(<String, SpeechModelStatus>{
        ...testInstalledModels(),
        _base.id: const SpeechModelStatus(
          entry: _base,
          present: true,
          imported: true,
        ),
      }),
    );
    final ProviderContainer container = await pump(tester, store: store);
    await _modelAction(tester, _base, 'remove');
    await tester.pumpAndSettle();
    await _tap(
      tester,
      find.descendant(
        of: find.byType(AppDialog),
        matching: find.text(Copy.settingsSpeechRemove),
      ),
    );
    await tester.pump();
    await _tap(tester, find.text(Copy.settingsSpeechModels));
    await tester.pump();
    expect(row(_base), findsNothing);
    expect(find.text(Copy.busy), findsOneWidget);
    store.release.complete();
    await tester.pumpAndSettle();
    expect(find.text(Copy.busy), findsNothing);
    expect(
      container.read(speechReadinessProvider).selection!.model.id,
      _tiny.id,
    );
    await _tap(tester, find.text(Copy.settingsSpeechModels));
    await tester.pumpAndSettle();
    expect(
      inRow(
        _base,
        detail(
          _base,
          Copy.settingsSpeechModelBundled,
          Copy.settingsSpeechModelMissing,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('collapsing during verification keeps its durable result', (
    WidgetTester tester,
  ) async {
    final Completer<void> gate = Completer<void>();
    final _HeldRemoveStore store = _HeldRemoveStore(
      SpeechModelStore.fake(testInstalledModels()),
      verifyGate: gate,
    );
    final ProviderContainer container = await pump(tester, store: store);
    await _modelAction(tester, _tiny, 'verify');
    await tester.pump();
    await _tap(tester, find.text(Copy.settingsSpeechModels));
    await tester.pump();
    expect(row(_tiny), findsNothing);
    expect(find.text(Copy.busy), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(
      container.read(speechModelsProvider).requireValue.verified,
      contains(_tiny.id),
    );
    expect(find.text(Copy.busy), findsNothing);
  });

  testWidgets('collapsing while the picker is open preserves cancellation', (
    WidgetTester tester,
  ) async {
    final _HeldPicker picker = _HeldPicker();
    final ProviderContainer container = await pump(tester, picker: picker);
    await _tap(
      tester,
      find.byKey(const ValueKey<String>('speech-model-import')),
    );
    await tester.pump();
    await _tap(tester, find.text(Copy.settingsSpeechModels));
    await tester.pump();
    expect(find.text(Copy.busy), findsOneWidget);
    picker.result.complete(
      const FailureResult<PickedDocument>(CancelledFailure()),
    );
    await tester.pumpAndSettle();
    expect(
      container.read(speechModelsProvider).requireValue.importing,
      isFalse,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(picker.calls, 1);
  });

  group('engine line', () {
    testWidgets('names the on-device model in use, with the offline badge', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(find.text(Copy.settingsSpeechSection), findsOneWidget);
      expect(find.text(Copy.speechOfflineBadge), findsOneWidget);
      expect(
        find.text(
          Copy.settingsSpeechEngineWhisper(Copy.settingsSpeechModelBalanced),
        ),
        findsOneWidget,
      );
      expect(find.text(Copy.settingsSpeechEngineNone), findsNothing);
    });

    testWidgets(
      'names the platform recogniser where it keeps speech on device',
      (WidgetTester tester) async {
        await pump(
          tester,
          store: SpeechModelStore.fake(const <String, SpeechModelStatus>{}),
          platform: FakeSttService(),
        );

        expect(find.text(Copy.settingsSpeechEnginePlatform), findsOneWidget);
        expect(find.text(Copy.speechOfflineBadge), findsOneWidget);
        // Why the app's own model is not used is still said.
        expect(find.text(Copy.speechModelMissing), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets('says voice input is unavailable with no engine at all', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        store: SpeechModelStore.fake(const <String, SpeechModelStatus>{}),
        platform: FakeSttService(),
      );

      // A recogniser that cannot prove it stays on device is not offered.
      expect(find.text(Copy.settingsSpeechEnginePlatform), findsNothing);
      expect(find.text(Copy.settingsSpeechEngineNone), findsOneWidget);
      expect(find.text(Copy.speechModelMissing), findsOneWidget);
    });
  });

  group('quality', () {
    testWidgets('is Automatic by default', (WidgetTester tester) async {
      final ProviderContainer container = await pump(tester);

      expect(find.text(Copy.settingsSpeechQuality), findsOneWidget);
      expect(find.text(Copy.settingsSpeechQualityEffect), findsOneWidget);
      expect(find.text(Copy.settingsSpeechQualityAuto), findsOneWidget);
      expect(find.text(Copy.settingsSpeechQualityFast), findsNothing);
      expect(find.text(Copy.settingsSpeechQualityAccurate), findsNothing);
      expect(container.read(speechQualitySettingProvider), 'auto');
      expect(container.read(speechQualityProvider), SpeechQuality.auto);
    });

    testWidgets('writing it stores it and refreshes readiness', (
      WidgetTester tester,
    ) async {
      final SettingsStore settings = SettingsStore.fake();
      final ProviderContainer container = await pump(
        tester,
        settings: settings,
      );
      expect(
        container.read(speechReadinessProvider).selection!.model.id,
        _base.id,
      );
      expect(inRow(_base, Copy.settingsSpeechModelInUse), findsOneWidget);

      await tester.ensureVisible(find.text(Copy.settingsSpeechQualityAuto));
      await tester.pumpAndSettle();
      await _tap(tester, find.text(Copy.settingsSpeechQualityAuto));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Fast');
      await tester.pumpAndSettle();
      await _tap(tester, find.text(Copy.settingsSpeechQualityFast));
      await tester.pumpAndSettle();

      expect(settings.read(SettingKeys.speechQuality), 'fast');
      expect(container.read(speechQualityProvider), SpeechQuality.fast);
      expect(
        container.read(speechReadinessProvider).selection!.model.id,
        _tiny.id,
      );
      expect(
        find.text(
          Copy.settingsSpeechEngineWhisper(Copy.settingsSpeechModelFast),
        ),
        findsOneWidget,
      );
      expect(inRow(_tiny, Copy.settingsSpeechModelInUse), findsOneWidget);
      expect(inRow(_base, Copy.settingsSpeechModelInUse), findsNothing);
    });
  });

  testWidgets(
    'failed quality writes preserve the selected engine and report recovery',
    (WidgetTester tester) async {
      final SettingsStore settings = SettingsStore.fake(failWrites: true);
      final ProviderContainer container = await pump(
        tester,
        settings: settings,
        expanded: false,
      );
      final String originalModel = container
          .read(speechReadinessProvider)
          .selection!
          .model
          .id;
      await _tap(tester, find.text(Copy.settingsSpeechQualityAuto));
      await tester.pumpAndSettle();
      await _tap(tester, find.text(Copy.settingsSpeechQualityFast));
      await tester.pumpAndSettle();
      expect(settings.read(SettingKeys.speechQuality), 'auto');
      expect(container.read(speechQualityProvider), SpeechQuality.auto);
      expect(
        container.read(speechReadinessProvider).selection!.model.id,
        originalModel,
      );
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(Copy.settingsSpeechQualityAuto), findsOneWidget);
    },
  );

  group('model rows', () {
    testWidgets('summarize state and size, and mark the models in use', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        store: SpeechModelStore.fake(<String, SpeechModelStatus>{
          ...testInstalledModels(),
          _small.id: const SpeechModelStatus(
            entry: _small,
            present: true,
            imported: true,
            damaged: true,
          ),
        }),
      );

      expect(
        inRow(
          _tiny,
          detail(
            _tiny,
            Copy.settingsSpeechModelBundled,
            Copy.settingsSpeechModelPresent,
          ),
        ),
        findsOneWidget,
      );
      expect(
        inRow(
          _small,
          detail(
            _small,
            Copy.settingsSpeechModelImported,
            Copy.settingsSpeechModelDamaged,
          ),
        ),
        findsOneWidget,
      );
      expect(inRow(_vad, Copy.settingsSpeechModelVad), findsOneWidget);
      expect(inRow(_base, Copy.settingsSpeechModelInUse), findsOneWidget);
      expect(inRow(_vad, Copy.settingsSpeechModelInUse), findsOneWidget);
      expect(inRow(_tiny, Copy.settingsSpeechModelInUse), findsNothing);
      expect(find.text(Copy.settingsSpeechTooLarge), findsNothing);
      expect(inRow(_small, Copy.settingsSpeechModelImported), findsNothing);
      await _tap(tester, inRow(_small, Copy.settingsSpeechModelDetails));
      await tester.pumpAndSettle();
      expect(inRow(_small, Copy.settingsSpeechModelImported), findsOneWidget);
    });

    testWidgets('a model missing here reads as missing, import only', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      expect(
        inRow(
          _small,
          detail(
            _small,
            Copy.settingsSpeechModelImportOnly,
            Copy.settingsSpeechModelMissing,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey<String>('speech-model-verify-${_small.id}')),
        findsNothing,
      );
    });

    testWidgets('warn when a model is too large for this device', (
      WidgetTester tester,
    ) async {
      await pump(tester, device: _tightDevice);

      expect(inRow(_base, Copy.settingsSpeechTooLarge), findsOneWidget);
      expect(inRow(_small, Copy.settingsSpeechTooLarge), findsOneWidget);
      expect(inRow(_tiny, Copy.settingsSpeechTooLarge), findsNothing);
      // The selector steps down to the model that fits.
      expect(inRow(_tiny, Copy.settingsSpeechModelInUse), findsOneWidget);
    });

    testWidgets('Verify reports success and marks the model checked', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await _modelAction(tester, _tiny, 'verify');
      await tester.pumpAndSettle();

      expect(
        find.text(Copy.settingsSpeechVerified(Copy.settingsSpeechModelFast)),
        findsOneWidget,
      );
      expect(
        inRow(
          _tiny,
          detail(
            _tiny,
            Copy.settingsSpeechModelBundled,
            Copy.settingsSpeechModelVerified,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Verify reports a mismatch', (WidgetTester tester) async {
      await pump(
        tester,
        store: SpeechModelStore.fake(<String, SpeechModelStatus>{
          ...testInstalledModels(),
          _tiny.id: const SpeechModelStatus(
            entry: _tiny,
            present: true,
            damaged: true,
          ),
        }),
      );

      await _modelAction(tester, _tiny, 'verify');
      await tester.pumpAndSettle();

      expect(
        find.text(
          Copy.settingsSpeechVerifyMismatch(Copy.settingsSpeechModelFast),
        ),
        findsOneWidget,
      );
      expect(
        find.text(Copy.settingsSpeechVerified(Copy.settingsSpeechModelFast)),
        findsNothing,
      );
      expect(
        inRow(
          _tiny,
          detail(
            _tiny,
            Copy.settingsSpeechModelBundled,
            Copy.settingsSpeechModelDamaged,
          ),
        ),
        findsOneWidget,
      );
    });
  });

  group('import', () {
    final Finder importButton = find.byKey(
      const ValueKey<String>('speech-model-import'),
    );

    PickedDocument picked(int bytes) =>
        PickedFile(File('picked/ggml-small-q5_1.bin'), 'model.bin', bytes);

    testWidgets('reports success and lists the model as imported', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        picker: DocumentPicker.fake(document: picked(_small.bytes)),
      );

      await _tap(tester, importButton);
      await tester.pumpAndSettle();

      expect(
        find.text(
          Copy.settingsSpeechImported(Copy.settingsSpeechModelAccurate),
        ),
        findsOneWidget,
      );
      expect(
        inRow(
          _small,
          detail(
            _small,
            Copy.settingsSpeechModelImported,
            Copy.settingsSpeechModelVerified,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('refuses a file that is not a known model in plain copy', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        picker: DocumentPicker.fake(document: picked(_small.bytes - 1)),
      );

      await _tap(tester, importButton);
      await tester.pumpAndSettle();

      expect(find.text(Copy.speechImportUnknown), findsOneWidget);
      expect(
        inRow(
          _small,
          detail(
            _small,
            Copy.settingsSpeechModelImportOnly,
            Copy.settingsSpeechModelMissing,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('is silent when the picker is cancelled', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      await _tap(tester, importButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      final AppButton button = tester.widget<AppButton>(importButton);
      expect(button.busy, isFalse);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('is hidden where the platform cannot import', (
      WidgetTester tester,
    ) async {
      await pump(tester, store: const SpeechModelStore.empty());

      expect(importButton, findsNothing);
      expect(find.text(Copy.settingsSpeechImport), findsNothing);
    });
  });

  testWidgets('removing an imported model asks first, then removes it', (
    WidgetTester tester,
  ) async {
    await pump(
      tester,
      store: SpeechModelStore.fake(<String, SpeechModelStatus>{
        ...testInstalledModels(),
        _small.id: const SpeechModelStatus(
          entry: _small,
          present: true,
          imported: true,
        ),
      }),
    );
    // Bundled models offer verification without removal.
    final AppOverflowMenu bundled = tester.widget<AppOverflowMenu>(
      find.byKey(ValueKey<String>('speech-model-menu-${_tiny.id}')),
    );
    expect(bundled.items.map((AppOverflowAction item) => item.label), <String>[
      Copy.settingsSpeechVerify,
    ]);

    await _modelAction(tester, _small, 'remove');
    await tester.pumpAndSettle();
    expect(
      find.text(
        Copy.settingsSpeechRemoveTitle(Copy.settingsSpeechModelAccurate),
      ),
      findsOneWidget,
    );
    expect(find.text(Copy.settingsSpeechRemoveMessage), findsOneWidget);

    await _tap(
      tester,
      find.descendant(
        of: find.byType(AppDialog),
        matching: find.text(Copy.settingsSpeechRemove),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(Copy.settingsSpeechRemoved(Copy.settingsSpeechModelAccurate)),
      findsOneWidget,
    );
    expect(
      inRow(
        _small,
        detail(
          _small,
          Copy.settingsSpeechModelImportOnly,
          Copy.settingsSpeechModelMissing,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey<String>('speech-model-remove-${_small.id}')),
      findsNothing,
    );
  });

  testWidgets('leaving mid-removal still has readiness look again', (
    WidgetTester tester,
  ) async {
    final _HeldRemoveStore store = _HeldRemoveStore(
      SpeechModelStore.fake(<String, SpeechModelStatus>{
        ...testInstalledModels(),
        _base.id: const SpeechModelStatus(
          entry: _base,
          present: true,
          imported: true,
        ),
      }),
    );
    final ProviderContainer container = await pump(tester, store: store);
    expect(
      container.read(speechReadinessProvider).selection!.model.id,
      _base.id,
    );

    await _modelAction(tester, _base, 'remove');
    await tester.pumpAndSettle();
    await _tap(
      tester,
      find.descendant(
        of: find.byType(AppDialog),
        matching: find.text(Copy.settingsSpeechRemove),
      ),
    );
    await tester.pump();

    // The operator leaves while the file is still being removed.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold()),
      ),
    );
    await tester.pumpAndSettle();
    store.release.complete();
    await tester.pumpAndSettle();

    expect(
      container.read(speechReadinessProvider).selection!.model.id,
      _tiny.id,
    );
  });

  testWidgets(
    'cancelled and failed removal preserve an imported model and its recovery action',
    (WidgetTester tester) async {
      final SpeechModelStore store = _HeldRemoveStore(
        SpeechModelStore.fake(<String, SpeechModelStatus>{
          ...testInstalledModels(),
          _small.id: const SpeechModelStatus(
            entry: _small,
            present: true,
            imported: true,
          ),
        }),
        removeFailure: const StorageFailure(
          message: 'The fixture removal failed.',
        ),
      );
      await pump(tester, store: store);
      await _modelAction(tester, _small, 'remove');
      await tester.pumpAndSettle();
      await tester.tap(find.text(Copy.cancel));
      await tester.pumpAndSettle();
      expect(inRow(_small, Copy.settingsSpeechModelPresent), findsOneWidget);
      await _modelAction(tester, _small, 'remove');
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppDialog),
          matching: find.text(Copy.settingsSpeechRemove),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('The fixture removal failed.'), findsOneWidget);
      expect(inRow(_small, Copy.settingsSpeechModelPresent), findsOneWidget);
      await _tap(
        tester,
        find.byKey(ValueKey<String>('speech-model-menu-${_small.id}')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey<String>('speech-model-remove-${_small.id}')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'failed import preserves installed models and keeps Import available',
    (WidgetTester tester) async {
      await pump(
        tester,
        store: SpeechModelStore.fake(
          testInstalledModels(),
          importFailure: const StorageFailure(
            message: 'The fixture import failed.',
          ),
        ),
        picker: DocumentPicker.fake(
          document: PickedFile(
            File('picked/ggml-small-q5_1.bin'),
            'model.bin',
            _small.bytes,
          ),
        ),
      );
      await _tap(
        tester,
        find.byKey(const ValueKey<String>('speech-model-import')),
      );
      await tester.pumpAndSettle();
      expect(find.text('The fixture import failed.'), findsOneWidget);
      expect(inRow(_base, Copy.settingsSpeechModelInUse), findsOneWidget);
      expect(
        tester
            .widget<AppButton>(
              find.byKey(const ValueKey<String>('speech-model-import')),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  for (final ScreenMatrix cell in ScreenMatrix.cells) {
    for (final Locale locale in <Locale>[
      const Locale('en'),
      const Locale('en', 'XA'),
    ]) {
      testWidgets(
        'mixed speech-model states and action menus fit ${cell.description} $locale',
        (WidgetTester tester) async {
          await pump(
            tester,
            cell: cell,
            locale: locale,
            device: _tightDevice,
            store: SpeechModelStore.fake(<String, SpeechModelStatus>{
              _vad.id: const SpeechModelStatus(entry: _vad, present: true),
              _tiny.id: const SpeechModelStatus(entry: _tiny, present: true),
              _base.id: const SpeechModelStatus(
                entry: _base,
                present: true,
                damaged: true,
              ),
              _small.id: const SpeechModelStatus(
                entry: _small,
                present: true,
                imported: true,
              ),
            }),
          );
          final LocalizedCopy copy = Copy.of(
            tester.element(find.byType(SpeechSettingsSection)),
          );
          expect(inRow(_tiny, copy.settingsSpeechModelInUse), findsOneWidget);
          expect(inRow(_base, copy.settingsSpeechModelDamaged), findsOneWidget);
          expect(inRow(_small, copy.settingsSpeechTooLarge), findsOneWidget);
          final Finder menu = find.byKey(
            ValueKey<String>('speech-model-menu-${_small.id}'),
          );
          await _tap(tester, menu);
          await tester.pumpAndSettle();
          final Finder verify = find.byKey(
            ValueKey<String>('speech-model-verify-${_small.id}'),
          );
          final Finder remove = find.byKey(
            ValueKey<String>('speech-model-remove-${_small.id}'),
          );
          expect(verify, meetsTapTarget());
          expect(remove, meetsTapTarget());
          expect(verify, hasSemanticLabel(copy.settingsSpeechVerify));
          expect(remove, hasSemanticLabel(copy.settingsSpeechRemove));
          expect(tester.takeException(), isNull);
        },
        variant: TargetPlatformVariant.all(),
      );
    }
  }
}

Future<void> _modelAction(
  WidgetTester tester,
  SpeechModelEntry entry,
  String action,
) async {
  await _tap(
    tester,
    find.byKey(ValueKey<String>('speech-model-menu-${entry.id}')),
  );
  await tester.pumpAndSettle();
  await _tap(
    tester,
    find.byKey(ValueKey<String>('speech-model-$action-${entry.id}')),
  );
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
}

/// A store whose removal waits until [release] completes.
final class _HeldRemoveStore implements SpeechModelStore {
  _HeldRemoveStore(this._inner, {this.verifyGate, this.removeFailure});

  final SpeechModelStore _inner;
  final Completer<void>? verifyGate;
  final Failure? removeFailure;

  /// Completes to let the held removal land.
  final Completer<void> release = Completer<void>();

  @override
  bool get canImport => _inner.canImport;

  @override
  Future<Result<List<SpeechModelStatus>>> inventory() => _inner.inventory();

  @override
  Future<Result<SpeechModelSource>> locate(
    SpeechModelEntry entry, {
    CancellationToken? cancel,
  }) => _inner.locate(entry, cancel: cancel);

  @override
  Future<Result<SpeechModelSource>> reextract(SpeechModelEntry entry) =>
      _inner.reextract(entry);

  @override
  Future<Result<void>> verify(
    SpeechModelSource source, {
    CancellationToken? cancel,
    void Function(double)? onProgress,
  }) async {
    await verifyGate?.future;
    return _inner.verify(source, cancel: cancel, onProgress: onProgress);
  }

  @override
  Future<Result<SpeechModelEntry>> import(
    PickedDocument picked, {
    CancellationToken? cancel,
    void Function(double)? onProgress,
  }) => _inner.import(picked, cancel: cancel, onProgress: onProgress);

  @override
  Future<Result<void>> remove(SpeechModelEntry entry) async {
    if (removeFailure case final Failure failure) {
      return FailureResult<void>(failure);
    }
    await release.future;
    return _inner.remove(entry);
  }

  @override
  void markDamaged(String modelId) => _inner.markDamaged(modelId);
}

final class _HeldPicker implements DocumentPicker {
  final Completer<Result<PickedDocument>> result =
      Completer<Result<PickedDocument>>();
  int calls = 0;
  @override
  bool get canPick => true;
  @override
  Future<Result<PickedDocument>> pick({
    required List<String> extensions,
    required String mimeType,
    int? maxBytes,
  }) {
    calls += 1;
    return result.future;
  }
}
