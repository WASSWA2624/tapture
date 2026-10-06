import 'dart:math' as math;

import 'package:tapture/core/constants/app_constants.dart';

import 'speech_availability.dart';
import 'speech_decode_profile.dart';
import 'speech_device_profile.dart';
import 'speech_failures.dart';
import 'speech_languages.dart';
import 'speech_model_catalogue.dart';
import 'speech_model_entry.dart';
import 'speech_model_status.dart';
import 'speech_quality.dart';
import 'speech_runtime_facts.dart';
import 'speech_selection.dart';
import 'speech_unavailable_reason.dart';
import 'speech_verdict.dart';

/// The C ABI version this app's engines speak (`TW_ABI_VERSION`).
const int _abiVersion = 1;

/// Bytes in one gibibyte: a browser reports its memory in whole gibibytes.
const int _gibibyte = 1024 * 1024 * 1024;

/// The fewest logical processors that can run the engine at all.
const int _minLogicalCores = 2;

/// The fewest threads a native device decodes with.
const int _minThreads = 2;

/// Logical processors from which a phone without a performance-core count
/// is given the mobile maximum.
const int _mobileManyCores = 8;

/// Picks the whisper model, threads and decode profiles for one device, one
/// quality and one language: a pure function of what it is given, applying
/// the rules of spec §30.4.2 in order. Every number is an
/// `AppConstants.speechEngine` field.
abstract final class SpeechModelSelector {
  /// The verdict for [device] at [quality] in [languageTag], given what the
  /// device holds ([inventory]) and the models whose loads killed the
  /// process ([suspectModelIds]).
  ///
  /// The rules, in order: an engine that is absent, unopenable or of
  /// another ABI is `engineMissing`; a processor, word size, memory or core
  /// count that cannot run it is `unsupportedDevice`; a language whisper
  /// does not know is `languageUnsupported`; an absent or damaged voice
  /// detector or fast model is `modelMissing`. Otherwise the quality, the
  /// device class and power pick a target model, which steps down past any
  /// model that is absent, damaged, suspect or does not fit in the memory
  /// free now; when not even the fast model fits, the verdict is
  /// `lowMemory`.
  static SpeechAvailability choose({
    required SpeechDeviceProfile device,
    required SpeechQuality quality,
    required List<SpeechModelStatus> inventory,
    required String languageTag,
    Set<String> suspectModelIds = const <String>{},
  }) {
    final SpeechRuntimeFacts runtime = device.runtime;
    final SpeechAvailability? refused =
        _engineRefusal(runtime) ?? _deviceRefusal(device);
    if (refused != null) {
      return refused;
    }
    final String? language = whisperLanguageFor(languageTag);
    if (language == null) {
      return SpeechAvailability(
        verdict: SpeechVerdict.languageUnsupported,
        failure: speechLanguageUnsupported(),
        reason: 'no whisper language for the voice language',
      );
    }
    final Map<String, SpeechModelStatus> held = <String, SpeechModelStatus>{
      for (final SpeechModelStatus status in inventory) status.entry.id: status,
    };
    bool usable(SpeechModelEntry entry) {
      final SpeechModelStatus? status = held[entry.id];
      return status != null &&
          status.present &&
          !status.damaged &&
          (!device.isWeb || entry.webAllowed);
    }

    for (final SpeechModelEntry required in <SpeechModelEntry>[
      SpeechModelCatalogue.vad,
      SpeechModelCatalogue.tiny,
    ]) {
      if (!usable(required)) {
        final bool damaged = held[required.id]?.damaged ?? false;
        return SpeechAvailability(
          verdict: SpeechVerdict.modelMissing,
          failure: damaged ? speechModelDamaged() : speechModelMissing(),
          reason: '${required.id} ${damaged ? 'damaged' : 'absent'}',
        );
      }
    }
    final bool powerOk = _powerOk(device);
    final ({SpeechModelEntry model, String why}) target = _target(
      device,
      quality,
      powerOk: powerOk,
      smallUsable: usable(SpeechModelCatalogue.small),
    );
    final List<String> steps = <String>[];
    SpeechModelEntry? chosen;
    for (final SpeechModelEntry candidate in _ladderFrom(target.model)) {
      if (!usable(candidate)) {
        steps.add('${candidate.id} unavailable');
      } else if (suspectModelIds.contains(candidate.id)) {
        steps.add('${candidate.id} suspect');
      } else if (!fits(candidate, device)) {
        steps.add('${candidate.id} does not fit');
      } else {
        chosen = candidate;
        break;
      }
    }
    if (chosen == null) {
      return SpeechAvailability(
        verdict: SpeechVerdict.lowMemory,
        failure: speechLowMemory(),
        reason: steps.join(', '),
      );
    }
    final int threads = _threads(device, powerOk: powerOk);
    final ({
      SpeechDecodeProfile interim,
      SpeechDecodeProfile committed,
      SpeechDecodeProfile? dictation,
    })
    profiles = _profiles(device, threads);
    final String reason = <String>[
      '${quality.name} on ${_deviceClass(device)}: ${target.why}',
      ...steps,
      '$threads threads',
    ].join('; ');
    return SpeechAvailability(
      verdict: SpeechVerdict.ready,
      selection: SpeechSelection(
        model: chosen,
        vad: SpeechModelCatalogue.vad,
        threads: threads,
        language: language,
        interim: profiles.interim,
        committed: profiles.committed,
        dictationCommitted: profiles.dictation,
        reason: reason,
      ),
      reason: reason,
    );
  }

  /// Whether [entry] fits in the memory [device] has free now, with
  /// `memoryHeadroomPercent` headroom. Unknown free memory fits.
  static bool fits(SpeechModelEntry entry, SpeechDeviceProfile device) {
    final int? available = device.runtime.availableMemoryBytes;
    if (available == null) {
      return true;
    }
    final int needed =
        entry.memoryEstimateBytes *
        AppConstants.speechEngine.memoryHeadroomPercent ~/
        100;
    return needed <= available;
  }

  /// Rule 1: no usable engine library.
  static SpeechAvailability? _engineRefusal(SpeechRuntimeFacts runtime) {
    if (!runtime.available) {
      final SpeechUnavailableReason? reason = runtime.unavailableReason;
      switch (reason) {
        case SpeechUnavailableReason.cpu ||
            SpeechUnavailableReason.engineNotBuilt ||
            SpeechUnavailableReason.simd:
          return null;
        case SpeechUnavailableReason.platform ||
            SpeechUnavailableReason.library ||
            SpeechUnavailableReason.abi ||
            null:
          return SpeechAvailability(
            verdict: SpeechVerdict.engineMissing,
            failure: speechUnavailable(),
            reason: 'engine ${reason?.name ?? 'unavailable'}',
          );
      }
    }
    if (runtime.abiVersion != _abiVersion) {
      return SpeechAvailability(
        verdict: SpeechVerdict.engineMissing,
        failure: speechUnavailable(),
        reason: 'engine abi ${runtime.abiVersion}',
      );
    }
    return null;
  }

  /// Rule 2: an engine this device cannot run.
  static SpeechAvailability? _deviceRefusal(SpeechDeviceProfile device) {
    final SpeechRuntimeFacts runtime = device.runtime;
    final int? total = runtime.totalMemoryBytes;
    final int minimum = device.isWeb
        ? AppConstants.speechEngine.webMinDeviceMemoryGiB * _gibibyte
        : AppConstants.speechEngine.minTotalMemoryBytes;
    final String? why = switch (runtime) {
      SpeechRuntimeFacts(available: false, :final unavailableReason?) =>
        'processor ${unavailableReason.name}',
      _ when !device.isWeb && !runtime.is64Bit => '32-bit',
      _ when total != null && total < minimum => 'memory',
      _ when runtime.logicalCores < _minLogicalCores => 'cores',
      _ => null,
    };
    if (why == null) {
      return null;
    }
    return SpeechAvailability(
      verdict: SpeechVerdict.unsupportedDevice,
      failure: speechDeviceUnsupported(),
      reason: 'device $why',
    );
  }

  /// `charging || (!saver && (percent unknown || percent ≥ 30))`.
  static bool _powerOk(SpeechDeviceProfile device) {
    if (device.charging) {
      return true;
    }
    final int? percent = device.batteryPercent;
    return !device.batterySaver &&
        (percent == null ||
            percent >= AppConstants.speechEngine.lowBatteryPercent);
  }

  /// Rule 5: the model the quality and the device class aim for.
  static ({SpeechModelEntry model, String why}) _target(
    SpeechDeviceProfile device,
    SpeechQuality quality, {
    required bool powerOk,
    required bool smallUsable,
  }) {
    const SpeechModelEntry tiny = SpeechModelCatalogue.tiny;
    const SpeechModelEntry base = SpeechModelCatalogue.base;
    final SpeechRuntimeFacts runtime = device.runtime;
    final int? total = runtime.totalMemoryBytes;
    final int cores = runtime.performanceCores ?? runtime.logicalCores ~/ 2;
    // A desktop that cannot say its memory is not held back for it.
    bool memoryAtLeast(int bytes) => total == null || total >= bytes;
    final bool webBase =
        runtime.webThreads &&
        total != null &&
        total >= AppConstants.speechEngine.webBaseDeviceMemoryGiB * _gibibyte;
    if (quality == SpeechQuality.fast) {
      return (model: tiny, why: 'fast asked');
    }
    if (device.isWeb) {
      return webBase
          ? (model: base, why: 'threads and memory allow base')
          : (model: tiny, why: 'browser threads or memory short of base');
    }
    if (device.isMobile) {
      if (quality == SpeechQuality.auto) {
        return (model: tiny, why: 'tiny until device evidence');
      }
      return fits(base, device) && powerOk
          ? (model: base, why: 'base fits and power allows')
          : (model: tiny, why: 'base does not fit or power is low');
    }
    if (quality == SpeechQuality.accurate) {
      return smallUsable &&
              memoryAtLeast(AppConstants.speechEngine.accurateMemoryBytes) &&
              cores >= AppConstants.speechEngine.accurateCores &&
              powerOk
          ? (model: SpeechModelCatalogue.small, why: 'small imported and fits')
          : (model: base, why: 'small not imported or short of it');
    }
    return memoryAtLeast(AppConstants.speechEngine.balancedMemoryBytes) &&
            cores >= AppConstants.speechEngine.balancedCores &&
            powerOk
        ? (model: base, why: 'memory, cores and power allow base')
        : (model: tiny, why: 'memory, cores or power short of base');
  }

  /// [target] and every smaller model, largest first.
  static List<SpeechModelEntry> _ladderFrom(SpeechModelEntry target) {
    const List<SpeechModelEntry> ladder = <SpeechModelEntry>[
      SpeechModelCatalogue.small,
      SpeechModelCatalogue.base,
      SpeechModelCatalogue.tiny,
    ];
    final int start = ladder.indexWhere(
      (SpeechModelEntry entry) => entry.id == target.id,
    );
    return ladder.sublist(start < 0 ? ladder.length - 1 : start);
  }

  /// Rule 7: threads follow physical cores, never every logical processor,
  /// which runs two to three times slower on a hyper-threaded processor.
  static int _threads(SpeechDeviceProfile device, {required bool powerOk}) {
    final SpeechRuntimeFacts runtime = device.runtime;
    final int logical = runtime.logicalCores;
    if (device.isWeb) {
      return runtime.webThreads
          ? (logical - 1).clamp(1, AppConstants.speechEngine.webMaxThreads)
          : 1;
    }
    final int mobileMax = AppConstants.speechEngine.mobileMaxThreads;
    final int threads = device.isMobile
        ? (runtime.performanceCores ??
                  (logical >= _mobileManyCores ? mobileMax : logical ~/ 2))
              .clamp(_minThreads, mobileMax)
        : (logical ~/ 2).clamp(
            _minThreads,
            AppConstants.speechEngine.desktopMaxThreads,
          );
    return !powerOk || device.batterySaver
        ? math.min(threads, AppConstants.speechEngine.saverThreads)
        : threads;
  }

  /// Rule 8: the interim, committed and phone-dictation profiles.
  static ({
    SpeechDecodeProfile interim,
    SpeechDecodeProfile committed,
    SpeechDecodeProfile? dictation,
  })
  _profiles(SpeechDeviceProfile device, int threads) {
    final SpeechDecodeProfile shared = SpeechDecodeProfile(
      threads: threads,
      noSpeechThreshold: AppConstants.speechEngine.noSpeechThreshold,
      logprobThreshold: AppConstants.speechEngine.logprobThreshold,
      entropyThreshold: AppConstants.speechEngine.entropyThreshold,
    );
    // Greedy with temperature fallback: a second candidate changed no word
    // on this machine's measurements and only added compute. The length
    // bound stops a looping fallback round well short of whisper's own.
    final SpeechDecodeProfile committed = shared.copyWith(
      temperatureStep: AppConstants.speechEngine.temperatureStep,
      piecesPerSecond: AppConstants.speechEngine.committedPiecesPerSecond,
      minPieces: AppConstants.speechEngine.committedMinPieces,
      audioContextPad: AppConstants.speechEngine.committedAudioContextPad,
      minAudioContext: AppConstants.speechEngine.committedMinAudioContext,
    );
    return (
      interim: shared.copyWith(
        singleSegment: true,
        timestamps: false,
        maxPieces: AppConstants.speechEngine.interimMaxPieces,
        audioContextPad: AppConstants.speechEngine.interimAudioContextPad,
      ),
      committed: committed,
      dictation: device.isMobile
          ? committed.copyWith(
              audioContextPad:
                  AppConstants.speechEngine.mobileDictationCommittedPad,
              minAudioContext: 0,
            )
          : null,
    );
  }

  static String _deviceClass(SpeechDeviceProfile device) =>
      device.isWeb ? 'web' : (device.isMobile ? 'mobile' : 'desktop');
}
