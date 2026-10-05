import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/ai/platform_recogniser_policy.dart';
import 'package:tapture/core/ai/stt_service.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/core/speech/routed_stt_service.dart';
import 'package:tapture/core/speech/speech.dart';

import '../domain/setting_key.dart';
import '../domain/setting_keys.dart';
import '../settings.dart' show SettingsStore;
import 'offline_switch.dart';
import 'speech_models_view.dart';

// The notifiers are private so this file declares providers only (FE-STR-06).
// ignore_for_file: library_private_types_in_public_api

/// The stored speech quality's wire name (`auto`, `fast` or `accurate`),
/// re-read from the settings store on every change rather than held as a
/// second copy (FE-STATE-06). Kept alive: `main` derives core's
/// `speechQualityProvider` from it, which the speech host reads at every
/// model load (FE-STATE-09).
final NotifierProvider<_QualitySetting, String> speechQualitySettingProvider =
    NotifierProvider<_QualitySetting, String>(_QualitySetting.new);

/// Whether the platform's own recogniser would serve dictation here and
/// keep speech on the device (FE-SEC-04), as the router decides at a listen.
final FutureProvider<bool> speechPlatformOnDeviceProvider =
    FutureProvider.autoDispose<bool>((Ref ref) async {
      final SttService? platform = ref.watch(platformRecogniserProvider);
      if (platform == null) {
        return false;
      }
      return PlatformRecogniserPolicy.platform().keepsSpeechOnDevice();
    });

/// The speech models, read each time the Language screen opens, with the
/// operator's verify, import and remove. A failed read shows at once
/// (FE-STATE-11).
final AsyncNotifierProvider<_Models, SpeechModelsView> speechModelsProvider =
    AsyncNotifierProvider.autoDispose<_Models, SpeechModelsView>(
      _Models.new,
      retry: (int _, Object _) => null,
    );

class _QualitySetting extends Notifier<String> {
  StreamSubscription<SettingKey<Object?>>? _changes;

  @override
  String build() {
    final SettingsStore store = ref.watch(offlineStoreProvider);
    unawaited(_changes?.cancel());
    _changes = store.changes().listen((SettingKey<Object?> key) {
      if (key.name == SettingKeys.speechQuality.name) {
        state = store.read(SettingKeys.speechQuality);
      }
    });
    ref.onDispose(() {
      unawaited(_changes?.cancel());
      _changes = null;
    });
    return store.read(SettingKeys.speechQuality);
  }

  /// Persists [quality]; the state follows once the write has committed.
  Future<void> set(SpeechQuality quality) async {
    final SettingsStore store = ref.read(offlineStoreProvider);
    await store.write(SettingKeys.speechQuality, quality.name);
    if (ref.mounted) {
      state = store.read(SettingKeys.speechQuality);
    }
  }
}

class _Models extends AsyncNotifier<SpeechModelsView> {
  /// The picker's file type for a whisper model.
  static const List<String> _extensions = <String>['bin'];
  static const String _mimeType = 'application/octet-stream';

  @override
  Future<SpeechModelsView> build() async {
    final SpeechModelStore store = ref.watch(speechModelStoreProvider);
    final SpeechDeviceProbe probe = ref.watch(speechDeviceProbeProvider);
    final List<SpeechModelStatus> models = await _inventory(store);
    final SpeechDeviceProfile device = await probe.read();
    return (
      models: models,
      device: device,
      canImport: store.canImport,
      verified: const <String>{},
      working: null,
      importing: false,
    );
  }

  /// Checks [entry]'s file in full: size, header and SHA-256. A failed
  /// check marks it damaged; readiness then looks again.
  Future<Result<void>> verify(SpeechModelEntry entry) async {
    final SpeechModelsView? view = _idle();
    if (view == null) {
      return const FailureResult<void>(CancelledFailure());
    }
    _show(view, working: entry.id);
    final SpeechModelStore store = ref.read(speechModelStoreProvider);
    final SpeechReadinessNotifier readiness = ref.read(
      speechReadinessProvider.notifier,
    );
    final Result<SpeechModelSource> located = await store.locate(entry);
    final Result<void> checked = switch (located) {
      Success<SpeechModelSource>(:final SpeechModelSource value) =>
        await store.verify(value),
      FailureResult<SpeechModelSource>(:final Failure failure) =>
        FailureResult<void>(failure),
    };
    await _settle(
      store,
      readiness,
      view.verified,
      passed: checked is Success<void> ? entry.id : null,
      failed: checked is Success<void> ? null : entry.id,
    );
    return checked;
  }

  /// Asks for a model file and imports it when it is exactly a catalogue
  /// model. A [CancelledFailure] when the operator closes the picker.
  Future<Result<SpeechModelEntry>> importModel() async {
    final SpeechModelsView? view = _idle();
    if (view == null || !view.canImport) {
      return const FailureResult<SpeechModelEntry>(CancelledFailure());
    }
    _show(view, importing: true);
    final SpeechModelStore store = ref.read(speechModelStoreProvider);
    final SpeechReadinessNotifier readiness = ref.read(
      speechReadinessProvider.notifier,
    );
    final Result<PickedDocument> picked = await ref
        .read(documentPickerProvider)
        .pick(
          extensions: _extensions,
          mimeType: _mimeType,
          maxBytes: _importMaxBytes,
        );
    if (!ref.mounted) {
      if (picked case Success<PickedDocument>(:final PickedDocument value)) {
        await discardPickedCopy(value);
      }
      return const FailureResult<SpeechModelEntry>(CancelledFailure());
    }
    switch (picked) {
      case FailureResult<PickedDocument>(:final Failure failure):
        _show(view);
        return FailureResult<SpeechModelEntry>(failure);
      case Success<PickedDocument>(:final PickedDocument value):
        // The store checks the bytes and discards the picked copy.
        final Result<SpeechModelEntry> imported = await store.import(value);
        await _settle(
          store,
          readiness,
          view.verified,
          passed: switch (imported) {
            Success<SpeechModelEntry>(:final SpeechModelEntry value) =>
              value.id,
            FailureResult<SpeechModelEntry>() => null,
          },
        );
        return imported;
    }
  }

  /// Removes the imported copy of [entry]; readiness then looks again.
  Future<Result<void>> remove(SpeechModelEntry entry) async {
    final SpeechModelsView? view = _idle();
    if (view == null) {
      return const FailureResult<void>(CancelledFailure());
    }
    _show(view, working: entry.id);
    final SpeechModelStore store = ref.read(speechModelStoreProvider);
    final SpeechReadinessNotifier readiness = ref.read(
      speechReadinessProvider.notifier,
    );
    final Result<void> removed = await store.remove(entry);
    await _settle(store, readiness, view.verified, failed: entry.id);
    return removed;
  }

  /// The shown view when no other work is in flight, else null.
  SpeechModelsView? _idle() {
    final SpeechModelsView? view = state.value;
    if (view == null || view.working != null || view.importing) {
      return null;
    }
    return view;
  }

  void _show(
    SpeechModelsView view, {
    List<SpeechModelStatus>? models,
    Set<String>? verified,
    String? working,
    bool importing = false,
  }) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncData<SpeechModelsView>((
      models: models ?? view.models,
      device: view.device,
      canImport: view.canImport,
      verified: verified ?? view.verified,
      working: working,
      importing: importing,
    ));
  }

  /// Reads the models again after a change, records which passed a check
  /// this session, and has readiness look again, even when the screen has
  /// closed meanwhile, so dictation never trusts a removed or damaged model.
  Future<void> _settle(
    SpeechModelStore store,
    SpeechReadinessNotifier readiness,
    Set<String> verified, {
    String? passed,
    String? failed,
  }) async {
    final Result<List<SpeechModelStatus>> read = await store.inventory();
    final SpeechModelsView? view = ref.mounted ? state.value : null;
    if (view == null) {
      await readiness.refresh();
      return;
    }
    _show(
      view,
      models: switch (read) {
        Success<List<SpeechModelStatus>>(
          :final List<SpeechModelStatus> value,
        ) =>
          value,
        FailureResult<List<SpeechModelStatus>>() => view.models,
      },
      verified: <String>{
        for (final String id in verified)
          if (id != failed) id,
        ?passed,
      },
    );
    await readiness.refresh();
  }

  static Future<List<SpeechModelStatus>> _inventory(
    SpeechModelStore store,
  ) async {
    final Result<List<SpeechModelStatus>> read = await store.inventory();
    return switch (read) {
      Success<List<SpeechModelStatus>>(:final List<SpeechModelStatus> value) =>
        value,
      FailureResult<List<SpeechModelStatus>>(:final Failure failure) =>
        throw failure,
    };
  }

  /// The largest file the app accepts by import, so a browser refuses
  /// anything bigger before reading it.
  static int get _importMaxBytes => SpeechModelCatalogue.all
      .where((SpeechModelEntry entry) => entry.asset == null)
      .fold<int>(0, (int most, SpeechModelEntry entry) {
        return math.max(most, entry.bytes);
      });
}
