import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/device/app_version.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/lifecycle/lifecycle_observer.dart';
import 'package:tapture/core/logging/logger.dart';
import 'package:tapture/core/time/clock.dart';

import 'speech_availability.dart';
import 'speech_decode_request.dart';
import 'speech_decode_result.dart';
import 'speech_device_probe.dart';
import 'speech_device_profile.dart';
import 'speech_engine.dart';
import 'speech_engine_lease.dart';
import 'speech_failures.dart';
import 'speech_load_report.dart';
import 'speech_model_catalogue.dart';
import 'speech_model_entry.dart';
import 'speech_model_selector.dart';
import 'speech_model_source.dart';
import 'speech_model_status.dart';
import 'speech_model_store.dart';
import 'speech_preferences.dart';
import 'speech_quality.dart';
import 'speech_selection.dart';
import 'speech_vad_handle.dart';
import 'speech_vad_result.dart';
import 'speech_verdict.dart';

const String _logTag = 'speech';

/// The crash-loop marker's key in the host's store.
const String _markerKey = 'load-attempt';

/// The single owner of loading and releasing the speech model (spec
/// §30.4.2): sessions ask it for a lease and never touch the engine's load.
///
/// One load serves every lease, and the model is never swapped while a lease
/// is held. After the last lease is released the model stays loaded through
/// a grace period (`idleRelease` on a phone on battery, `idleReleaseExtended`
/// on a desktop or while charging), so a quick second session starts warm.
/// With no lease held, going to the background or memory pressure releases
/// it at once. A failed load of a larger model falls back to the fast one
/// once; a damaged extracted copy on Android is extracted again once; and a
/// load that killed the process [AppConstants.speechEngine]'s
/// `maxLoadAttempts` times marks that model suspect until the app version
/// changes.
final class SpeechEngineHost {
  /// Hosts [engine] over the models in [store], sized to what [probe] reads
  /// and the operator's [quality]. [lifecycle] and [memoryPressure] release
  /// an unused model. [attempts] keeps the crash-loop marker; without it no
  /// marker is kept. [delay] waits out the idle grace period (the test seam
  /// for time), [clock] stamps the marker and [logger] defaults to
  /// [Logger.current].
  SpeechEngineHost({
    required this._engine,
    required this._store,
    required this._probe,
    required this._quality,
    required Stream<AppLifecycleState> lifecycle,
    required Stream<void> memoryPressure,
    this._attempts,
    this._clock = const SystemClock(),
    Future<void> Function(Duration)? delay,
    this._logger,
  }) : _delay = delay ?? Future<void>.delayed {
    _subscriptions = <StreamSubscription<void>>[
      lifecycle.listen(_onLifecycle),
      memoryPressure.listen((void _) {
        unawaited(_releaseUnused('memory pressure'));
      }),
    ];
    _started = _readMarker();
  }

  final SpeechEngine _engine;
  final SpeechModelStore _store;
  final SpeechDeviceProbe _probe;
  final SpeechQuality Function() _quality;
  final BlobStore? _attempts;
  final Clock _clock;
  final Future<void> Function(Duration) _delay;
  final Logger? _logger;
  final StreamController<void> _changes = StreamController<void>.broadcast();
  late final List<StreamSubscription<void>> _subscriptions;
  late final Future<void> _started;

  /// Models whose load killed the process `maxLoadAttempts` times.
  final Set<String> _suspects = <String>{};

  /// Loads that did not finish before the process ended, per model.
  final Map<String, int> _crashes = <String, int>{};

  /// Larger models that failed to load this session; never retried.
  final Set<String> _failed = <String>{};

  /// Android models already extracted again this session.
  final Set<String> _reextracted = <String>{};

  Future<void> _tail = Future<void>.value();
  SpeechSelection? _loaded;
  SpeechDeviceProfile? _device;
  String? _lastVerdict;
  bool _engineMissing = false;
  bool _disposed = false;
  int _leases = 0;
  int _nextLeaseId = 0;
  int _idleGeneration = 0;

  Logger get _log => _logger ?? Logger.current;

  /// Leases handed out and not yet released.
  int get activeLeases => _leases;

  /// An event whenever availability may have changed: a model loaded,
  /// released, failed or was marked damaged. A broadcast stream.
  Stream<void> get changes => _changes.stream;

  /// The verdict and selection for [languageTag] now, from the device, the
  /// installed models and the quality. Never loads a model.
  Future<SpeechAvailability> availability({required String languageTag}) async {
    await _started;
    if (_disposed) {
      return SpeechAvailability(
        verdict: SpeechVerdict.engineMissing,
        failure: speechEngineStopped(),
        reason: 'host disposed',
      );
    }
    return _choose(languageTag);
  }

  /// A lease on the model selected for [languageTag], loading it first when
  /// no other lease holds one. While leases are held the loaded model is
  /// kept, whatever a new selection would pick.
  Future<Result<SpeechEngineLease>> acquire({
    required String languageTag,
    CancellationToken? cancel,
  }) => _serial(() => _acquire(languageTag, cancel));

  /// Loads the model selected for [languageTag] ahead of a session, so the
  /// first partial is not held up by loading. Best effort: a failure is
  /// logged and the next [acquire] decides again.
  Future<void> warmUp({required String languageTag}) async {
    await _serial(() async {
      await _started;
      if (_disposed) {
        return;
      }
      final SpeechAvailability chosen = await _choose(languageTag);
      final SpeechSelection? wanted = chosen.selection;
      if (chosen.ready && wanted != null) {
        await _ensureLoaded(wanted, languageTag, null);
      }
    });
    _scheduleIdle();
  }

  /// Stops listening and releases an unused model. Leases still held keep
  /// working until the engine itself is disposed.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _idleGeneration++;
    for (final StreamSubscription<void> subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _tail;
    if (_leases == 0 && _engine.loaded != null) {
      _loaded = null;
      await _engine.unload();
    }
    await _changes.close();
  }

  Future<Result<SpeechEngineLease>> _acquire(
    String languageTag,
    CancellationToken? cancel,
  ) async {
    await _started;
    if (_disposed) {
      return FailureResult<SpeechEngineLease>(speechEngineStopped());
    }
    if (cancel?.isCancelled ?? false) {
      return FailureResult<SpeechEngineLease>(speechCancelled());
    }
    // A lease wanted again cancels a pending idle release.
    _idleGeneration++;
    final SpeechAvailability chosen = await _choose(languageTag);
    final SpeechSelection? wanted = chosen.selection;
    if (!chosen.ready || wanted == null) {
      _scheduleIdle();
      return FailureResult<SpeechEngineLease>(
        chosen.failure ?? speechUnavailable(),
      );
    }
    final Result<SpeechSelection> loaded = await _ensureLoaded(
      wanted,
      languageTag,
      cancel,
    );
    final SpeechSelection selection;
    switch (loaded) {
      case FailureResult<SpeechSelection>(:final Failure failure):
        _scheduleIdle();
        return FailureResult<SpeechEngineLease>(failure);
      case Success<SpeechSelection>(value: final SpeechSelection value):
        selection = value;
    }
    final Result<SpeechVadHandle> opened = await _openVad(selection, cancel);
    switch (opened) {
      case FailureResult<SpeechVadHandle>(:final Failure failure):
        _scheduleIdle();
        return FailureResult<SpeechEngineLease>(failure);
      case Success<SpeechVadHandle>(value: final SpeechVadHandle vad):
        _leases++;
        return Success<SpeechEngineLease>(
          _HostLease(
            SpeechEngineLease.over(
              _engine,
              selection,
              leaseId: ++_nextLeaseId,
              vad: vad,
            ),
            _onReleased,
          ),
        );
    }
  }

  /// The verdict now, logged when it differs from the last one.
  Future<SpeechAvailability> _choose(String languageTag) async {
    final SpeechAvailability chosen;
    if (_engineMissing) {
      chosen = SpeechAvailability(
        verdict: SpeechVerdict.engineMissing,
        failure: speechUnavailable(),
        reason: 'the fast model failed to load this session',
      );
    } else {
      final SpeechDeviceProfile device = await _probe.read();
      _device = device;
      final Result<List<SpeechModelStatus>> inventory = await _store
          .inventory();
      chosen = switch (inventory) {
        FailureResult<List<SpeechModelStatus>>(:final Failure failure) =>
          SpeechAvailability(
            verdict: SpeechVerdict.modelMissing,
            failure: failure,
            reason: 'models could not be listed',
          ),
        Success<List<SpeechModelStatus>>(
          value: final List<SpeechModelStatus> statuses,
        ) =>
          SpeechModelSelector.choose(
            device: device,
            quality: _quality(),
            inventory: statuses,
            languageTag: languageTag,
            suspectModelIds: <String>{..._suspects, ..._failed},
          ),
      };
    }
    _logVerdict(chosen);
    return chosen;
  }

  void _logVerdict(SpeechAvailability chosen) {
    final SpeechSelection? selection = chosen.selection;
    final String verdict = chosen.verdict.name;
    final String summary = selection == null
        ? verdict
        : '$verdict ${selection.model.id} with ${selection.threads} threads';
    if (summary == _lastVerdict) {
      return;
    }
    _lastVerdict = summary;
    final String reason = chosen.reason;
    final Logger logger = _log;
    logger.info(_logTag, 'verdict $summary: $reason');
  }

  /// The model [wanted] names, or the one already loaded when leases hold it
  /// or it is the same model, falling back once to the fast model.
  Future<Result<SpeechSelection>> _ensureLoaded(
    SpeechSelection wanted,
    String languageTag,
    CancellationToken? cancel,
  ) async {
    final SpeechSelection? current = _loaded;
    final SpeechLoadReport? report = _engine.loaded;
    if (current != null &&
        report != null &&
        report.model.id == current.model.id &&
        (_leases > 0 || current.model.id == wanted.model.id)) {
      return Success<SpeechSelection>(current.forLanguage(wanted.language));
    }
    Result<SpeechSelection> loaded = await _load(wanted, cancel);
    final bool fast = wanted.model.id == SpeechModelCatalogue.tiny.id;
    if (loaded case FailureResult<SpeechSelection>(
      :final Failure failure,
    ) when failure is! CancelledFailure && !fast) {
      final SpeechAvailability retry = await _choose(languageTag);
      final SpeechSelection? smaller = retry.selection;
      if (retry.ready &&
          smaller != null &&
          smaller.model.id != wanted.model.id) {
        final Logger logger = _log;
        logger.warn(_logTag, 'falling back to ${smaller.model.id}');
        loaded = await _load(smaller, cancel);
      }
    } else if (loaded is Success<SpeechSelection> &&
        !fast &&
        (_device?.isWeb ?? false)) {
      // A browser may report threads yet run the single-thread worker when
      // its thread pool cannot start; the engine knows only after loading.
      // Re-read and, when that changes the choice, load what fits.
      final SpeechAvailability again = await _choose(languageTag);
      final SpeechSelection? fits = again.selection;
      if (again.ready && fits != null && fits.model.id != wanted.model.id) {
        final Logger logger = _log;
        logger.info(_logTag, 'browser runs single thread: ${fits.model.id}');
        loaded = await _load(fits, cancel);
      }
    }
    return loaded;
  }

  /// One load of [selection]'s model, with the crash-loop marker around it,
  /// one re-extraction of a damaged Android copy, and the bookkeeping of
  /// what a failure means for this session.
  Future<Result<SpeechSelection>> _load(
    SpeechSelection selection,
    CancellationToken? cancel,
  ) async {
    final SpeechModelEntry entry = selection.model;
    final Logger logger = _log;
    ({Result<SpeechLoadReport> outcome, bool loading}) attempt =
        await _locateAndLoad(
          () => _store.locate(entry, cancel: cancel),
          selection,
          cancel,
        );
    if (attempt.outcome case FailureResult<SpeechLoadReport>(
      failure: CorruptionFailure(),
    ) when _isExtractedCopy(entry) && _reextracted.add(entry.id)) {
      logger.warn(_logTag, 'model ${entry.id} damaged; extracting again');
      attempt = await _locateAndLoad(
        () => _store.reextract(entry),
        selection,
        cancel,
      );
    }
    switch (attempt.outcome) {
      case Success<SpeechLoadReport>():
        _loaded = selection;
        _crashes.remove(entry.id);
        logger.info(_logTag, 'selection ${entry.id}: ${selection.reason}');
        _notify();
        return Success<SpeechSelection>(selection);
      case FailureResult<SpeechLoadReport>(:final Failure failure):
        _loaded = null;
        if (failure is CancelledFailure) {
          return FailureResult<SpeechSelection>(failure);
        }
        logger.warn(
          _logTag,
          'load of ${entry.id} failed: ${failure.runtimeType}',
        );
        if (failure is CorruptionFailure) {
          _store.markDamaged(entry.id);
          _notify();
          return FailureResult<SpeechSelection>(speechModelDamaged());
        }
        if (attempt.loading && failure is ProviderFailure) {
          // The engine could not load it: a larger model is not tried again
          // this session, and without the fast one there is no engine.
          if (entry.id == SpeechModelCatalogue.tiny.id) {
            _engineMissing = true;
          } else {
            _failed.add(entry.id);
          }
          _notify();
        }
        return FailureResult<SpeechSelection>(failure);
    }
  }

  /// Finds the model through [locate] and loads it, with the crash-loop
  /// marker written before the load and removed once it returns. `loading`
  /// says whether the engine was asked, rather than the store failing to
  /// find the file.
  Future<({Result<SpeechLoadReport> outcome, bool loading})> _locateAndLoad(
    Future<Result<SpeechModelSource>> Function() locate,
    SpeechSelection selection,
    CancellationToken? cancel,
  ) async {
    final SpeechModelSource source;
    switch (await locate()) {
      case FailureResult<SpeechModelSource>(:final Failure failure):
        return (
          outcome: FailureResult<SpeechLoadReport>(failure),
          loading: false,
        );
      case Success<SpeechModelSource>(value: final SpeechModelSource found):
        source = found;
    }
    await _writeMarker(selection.model.id);
    final Result<SpeechLoadReport> loaded = await _engine.load(
      source,
      threads: selection.threads,
      cancel: cancel,
    );
    // Any load that returned did not kill the process.
    await _clearMarker();
    return (outcome: loaded, loading: true);
  }

  /// Opens the lease's own voice detector.
  Future<Result<SpeechVadHandle>> _openVad(
    SpeechSelection selection,
    CancellationToken? cancel,
  ) async {
    final SpeechModelSource source;
    switch (await _store.locate(selection.vad, cancel: cancel)) {
      case FailureResult<SpeechModelSource>(:final Failure failure):
        return FailureResult<SpeechVadHandle>(failure);
      case Success<SpeechModelSource>(value: final SpeechModelSource found):
        source = found;
    }
    final Result<SpeechVadHandle> opened = await _engine.openVad(source);
    switch (opened) {
      case FailureResult<SpeechVadHandle>(:final Failure failure):
        final Logger logger = _log;
        logger.warn(_logTag, 'voice detector failed: ${failure.runtimeType}');
        if (failure is CorruptionFailure) {
          _store.markDamaged(selection.vad.id);
          _notify();
        }
        return opened;
      case Success<SpeechVadHandle>(value: final SpeechVadHandle vad):
        if (cancel?.isCancelled ?? false) {
          await _engine.closeVad(vad);
          return FailureResult<SpeechVadHandle>(speechCancelled());
        }
        return opened;
    }
  }

  /// Whether [entry] is read from a copy extracted out of the Android
  /// package, which a re-extraction can repair.
  bool _isExtractedCopy(SpeechModelEntry entry) {
    final SpeechDeviceProfile? device = _device;
    return device != null &&
        !device.isWeb &&
        device.platform == TargetPlatform.android &&
        entry.asset != null;
  }

  void _onReleased() {
    _leases--;
    if (_leases == 0) {
      _scheduleIdle();
    }
  }

  /// Releases the model after the idle grace period, unless a lease is
  /// taken first.
  void _scheduleIdle() {
    if (_disposed || _leases > 0 || _engine.loaded == null) {
      return;
    }
    final int generation = ++_idleGeneration;
    final SpeechDeviceProfile? device = _device;
    final Duration grace = device != null && device.isMobile && !device.charging
        ? AppConstants.speechEngine.idleRelease
        : AppConstants.speechEngine.idleReleaseExtended;
    unawaited(
      _delay(grace).then((void _) {
        if (generation == _idleGeneration) {
          return _releaseUnused('after idle');
        }
      }),
    );
  }

  void _onLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        unawaited(_releaseUnused('in the background'));
      case AppLifecycleState.inactive ||
          AppLifecycleState.resumed ||
          AppLifecycleState.detached:
        break;
    }
  }

  /// Unloads the model now when no lease holds it.
  Future<void> _releaseUnused(String why) {
    if (_disposed || _leases > 0) {
      return Future<void>.value();
    }
    return _serial(() async {
      if (_disposed || _leases > 0) {
        return;
      }
      _idleGeneration++;
      if (_engine.loaded == null && _loaded == null) {
        return;
      }
      _loaded = null;
      await _engine.unload();
      final Logger logger = _log;
      logger.info(_logTag, 'model released $why');
      _notify();
    });
  }

  /// Reads the crash-loop marker a previous process left: a load that never
  /// returned. It is counted once and removed; the count travels with the
  /// next marker for the same model.
  Future<void> _readMarker() async {
    final BlobStore? store = _attempts;
    if (store == null) {
      return;
    }
    final Uint8List? bytes = (await store.read(
      _markerKey,
    )).fold((Failure _) => null, (Uint8List? found) => found);
    if (bytes == null) {
      return;
    }
    await store.remove(_markerKey);
    final ({String model, String version, int attempts})? marker = _decode(
      bytes,
    );
    if (marker == null || marker.version != appVersionName) {
      return;
    }
    final int attempts = marker.attempts + 1;
    _crashes[marker.model] = attempts;
    final String model = marker.model;
    final Logger logger = _log;
    logger.warn(_logTag, 'model $model load ended the app ($attempts times)');
    if (attempts >= AppConstants.speechEngine.maxLoadAttempts) {
      _suspects.add(model);
    }
  }

  static ({String model, String version, int attempts})? _decode(
    Uint8List bytes,
  ) {
    try {
      final Object? decoded = jsonDecode(utf8.decode(bytes));
      if (decoded case <String, Object?>{
        'modelId': final String model,
        'appVersion': final String version,
        'attempts': final int attempts,
      }) {
        return (model: model, version: version, attempts: attempts);
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  Future<void> _writeMarker(String modelId) async {
    final BlobStore? store = _attempts;
    if (store == null) {
      return;
    }
    final Result<void> written = await store.write(
      _markerKey,
      utf8.encode(
        jsonEncode(<String, Object>{
          'modelId': modelId,
          'appVersion': appVersionName,
          'attempts': _crashes[modelId] ?? 0,
          'startedAtMs': _clock.nowUtc().millisecondsSinceEpoch,
        }),
      ),
    );
    if (written case FailureResult<void>(:final Failure failure)) {
      final Logger logger = _log;
      logger.warn(_logTag, 'load marker not written', error: failure);
    }
  }

  Future<void> _clearMarker() async {
    await _attempts?.remove(_markerKey);
  }

  void _notify() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  /// Runs [action] after every earlier load, acquire and release.
  Future<T> _serial<T>(Future<T> Function() action) {
    final Future<T> run = _tail.then((void _) => action());
    _tail = run.then<void>((T _) {}, onError: (Object _) {});
    return run;
  }
}

/// The app's speech host over the app's engine, model store and device
/// probe, released with the provider. `main` overrides it to keep the
/// crash-loop marker and the production logger.
final Provider<SpeechEngineHost> speechEngineHostProvider =
    Provider<SpeechEngineHost>((Ref ref) {
      final LifecycleObserver lifecycle = ref.watch(lifecycleObserverProvider);
      final SpeechEngineHost host = SpeechEngineHost(
        engine: ref.watch(speechEngineProvider),
        store: ref.watch(speechModelStoreProvider),
        probe: ref.watch(speechDeviceProbeProvider),
        quality: () => ref.read(speechQualityProvider),
        lifecycle: lifecycle.states,
        memoryPressure: lifecycle.memoryPressure,
      );
      ref.onDispose(() => unawaited(host.dispose()));
      return host;
    });

/// A lease that tells the host when it is released.
final class _HostLease implements SpeechEngineLease {
  _HostLease(this._lease, this._onReleased);

  final SpeechEngineLease _lease;
  final void Function() _onReleased;
  Future<void>? _released;

  @override
  SpeechSelection get selection => _lease.selection;

  @override
  String get modelId => _lease.modelId;

  @override
  int get vadFrameSamples => _lease.vadFrameSamples;

  @override
  Future<Result<SpeechDecodeResult>> decode(
    SpeechDecodeRequest request, {
    CancellationToken? cancel,
  }) => _lease.decode(request, cancel: cancel);

  @override
  Future<Result<SpeechVadResult>> detectSpeech(
    Float32List samples, {
    bool resetState = false,
    CancellationToken? cancel,
  }) => _lease.detectSpeech(samples, resetState: resetState, cancel: cancel);

  @override
  void abort() => _lease.abort();

  @override
  Future<void> release() =>
      _released ??= _lease.release().whenComplete(_onReleased);
}
