import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/audio/audio_capture_service.dart';
import 'package:tapture/core/audio/audio_recovery_service.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/storage_guard.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/lifecycle/leave_guard.dart';
import 'package:tapture/core/lifecycle/lifecycle_observer.dart';
import 'package:tapture/core/logging/logger.dart';
import 'package:tapture/core/speech/speech.dart';

const int _gib = 1024 * 1024 * 1024;

/// A desktop with room for every bundled model.
const SpeechDeviceProfile testDesktopDevice = SpeechDeviceProfile(
  runtime: SpeechRuntimeFacts(
    available: true,
    abiVersion: 1,
    is64Bit: true,
    totalMemoryBytes: 16 * _gib,
    availableMemoryBytes: 8 * _gib,
    logicalCores: 8,
  ),
  platform: TargetPlatform.windows,
  isWeb: false,
  charging: true,
);

/// Every bundled model, present.
Map<String, SpeechModelStatus> testInstalledModels() =>
    <String, SpeechModelStatus>{
      for (final SpeechModelEntry entry in <SpeechModelEntry>[
        SpeechModelCatalogue.tiny,
        SpeechModelCatalogue.base,
        SpeechModelCatalogue.vad,
      ])
        entry.id: SpeechModelStatus(entry: entry, present: true),
    };

/// A [TranscriptSink] that records every write and every finish, and can
/// hold writes until a test lets them land.
final class HeldTranscriptSink implements TranscriptSink {
  /// Utterances stored, in order.
  final List<FinishedUtterance> stored = <FinishedUtterance>[];

  /// Outcomes passed to [finish], in order.
  final List<TranscriptOutcome> outcomes = <TranscriptOutcome>[];

  /// Every call, in order: `append` or `finish`.
  final List<String> calls = <String>[];

  /// While set, each write waits for it.
  Completer<void>? hold;

  /// Writes started and not yet finished.
  int inFlight = 0;

  @override
  Future<Result<void>> appendUtterance(FinishedUtterance utterance) async {
    calls.add('append');
    inFlight++;
    try {
      final Completer<void>? waiting = hold;
      if (waiting != null) {
        await waiting.future;
      }
      stored.add(utterance);
      return const Success<void>(null);
    } finally {
      inFlight--;
    }
  }

  @override
  Future<Result<void>> finish(TranscriptOutcome outcome) async {
    calls.add('finish');
    outcomes.add(outcome);
    return const Success<void>(null);
  }

  /// The stored segments' words, in order.
  List<String> get words => <String>[
    for (final FinishedUtterance utterance in stored)
      for (final TranscriptSegment segment in utterance.segments)
        for (final TranscriptWord word in segment.words) word.text,
  ];

  /// The stored segments, in order.
  List<TranscriptSegment> get segments => <TranscriptSegment>[
    for (final FinishedUtterance utterance in stored) ...utterance.segments,
  ];
}

/// A live transcription service over [capture] and a speech host over
/// [engine], with a fake lifecycle, leave guard and logger a test drives
/// and reads.
final class LiveTranscriptionRig {
  /// A rig whose host serves [quality] from [models] (every bundled model
  /// by default) on [device], with [store] or a fake store.
  LiveTranscriptionRig({
    required this.capture,
    required this.engine,
    StorageGuard? storageGuard,
    StorageRoot? storageRoot,
    FileReader? reader,
    AudioRecoveryService? recovery,
    Duration? sessionLimit,
    SpeechQuality quality = SpeechQuality.fast,
    SpeechDeviceProfile device = testDesktopDevice,
    SpeechDeviceProbe? probe,
    SpeechModelStore? store,
    Map<String, SpeechModelStatus>? models,
    StorageGuard Function(LifecycleObserver lifecycle)? guard,
  }) {
    host = SpeechEngineHost(
      engine: engine,
      store: store ?? SpeechModelStore.fake(models ?? testInstalledModels()),
      probe: probe ?? SpeechDeviceProbe.fake(device),
      quality: () => quality,
      lifecycle: lifecycle.states,
      memoryPressure: lifecycle.memoryPressure,
      // The model stays loaded for the whole test.
      delay: (Duration _) => Completer<void>().future,
      logger: logger,
    );
    service = LiveTranscriptionService(
      capture: capture,
      host: host,
      lifecycle: lifecycle,
      leaveGuard: leaveGuard,
      storageGuard:
          storageGuard ??
          guard?.call(lifecycle) ??
          StorageGuard.fake(
            storageRoot:
                storageRoot ?? StorageRoot.fake(documentsDirectory: _scratch),
            freeBytes: _plenty,
          ),
      recovery: recovery,
      storageRoot: storageRoot,
      reader: reader,
      sessionLimit: sessionLimit,
      logger: logger,
    );
  }

  /// A folder of the rig's own, removed by [dispose].
  final Directory _scratch = Directory.systemTemp.createTempSync(
    'tapture_live_',
  );

  /// The capture the service starts.
  final AudioCaptureService capture;

  /// The engine under the host.
  final SpeechEngine engine;

  /// The lifecycle a test drives with `handle`.
  final LifecycleObserver lifecycle = LifecycleObserver.fake();

  /// The leave guard, held while a long-form session is unsaved.
  final LeaveGuard leaveGuard = LeaveGuard.fake();

  /// Everything logged, for the no-text check.
  final Logger logger = Logger();

  /// The speech host.
  late final SpeechEngineHost host;

  /// The service under test.
  late final LiveTranscriptionService service;

  /// Everything a session reported, from its start.
  final List<LiveTranscriptionEvent> events = <LiveTranscriptionEvent>[];

  /// Starts [request] and records its events, failing the test when the
  /// start fails.
  Future<LiveTranscriptionSession> start(
    LiveTranscriptionRequest request,
  ) async {
    final Result<LiveTranscriptionSession> started = await service.start(
      request,
    );
    if (started case FailureResult<LiveTranscriptionSession>(:final failure)) {
      fail('the session did not start: $failure');
    }
    final LiveTranscriptionSession session =
        (started as Success<LiveTranscriptionSession>).value;
    session.events.listen(events.add);
    return session;
  }

  /// The phases reported, in order, without repeats.
  List<LiveTranscriptionPhase> get phases {
    final List<LiveTranscriptionPhase> seen = <LiveTranscriptionPhase>[];
    for (final LiveTranscriptionEvent event in events) {
      if (event is TranscriptionStateChanged &&
          (seen.isEmpty || seen.last != event.phase)) {
        seen.add(event.phase);
      }
    }
    return seen;
  }

  /// The warnings reported, in order.
  List<TranscriptionWarningKind> get warnings => <TranscriptionWarningKind>[
    for (final LiveTranscriptionEvent event in events)
      if (event is TranscriptionWarning) event.kind,
  ];

  /// Every finalized word reported, in order.
  List<String> get words => <String>[
    for (final LiveTranscriptionEvent event in events)
      if (event is SegmentFinalized)
        for (final TranscriptWord word in event.segment.words) word.text,
  ];

  /// Releases the service, the host and the engine, then checks that every
  /// session and lease is gone.
  Future<void> dispose() async {
    await service.dispose();
    expect(debugLiveTranscriptionSessions, 0, reason: 'sessions left');
    expect(host.activeLeases, 0, reason: 'leases left');
    expect(leaveGuard.isHeld, isFalse, reason: 'leave guard held');
    await host.dispose();
    await engine.dispose();
    lifecycle.dispose();
    if (_scratch.existsSync()) {
      _scratch.deleteSync(recursive: true);
    }
  }
}

/// [samples] in chunks of [chunk], each followed by event-loop turns so
/// the pipeline keeps up, through [push].
Future<void> feedSamples(
  Int16List samples,
  void Function(Int16List chunk) push, {
  int chunk = 1600,
  int pumps = 20,
}) async {
  for (int at = 0; at < samples.length; at += chunk) {
    final int end = at + chunk < samples.length ? at + chunk : samples.length;
    push(Int16List.sublistView(samples, at, end));
    await pumpEventQueue(times: pumps);
  }
}

/// Free space that never runs low.
int _plenty() => 1 << 40;
