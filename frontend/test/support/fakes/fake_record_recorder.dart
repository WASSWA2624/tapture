import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:record/record.dart' as record;

/// A hand-written stand-in for the recorder plugin in stream mode
/// (FE-TEST-03).
///
/// Like the plugin it hands out a broadcast stream that drops bytes while
/// nothing listens, delivers platform events as separate event-loop tasks,
/// and closes the stream when stopped. A test scripts refused rates, start
/// errors, a reported format, the first chunks, stream errors, an early
/// end, a native pause, and a whole WAV file streamed in chunks.
final class FakeRecordRecorder implements record.AudioRecorder {
  /// A recorder that refuses [refusedRates], throws [startError] from
  /// `startStream`, reports [reportedConfig] to the format callback while
  /// starting, and emits [firstChunks] on the event-loop turn after
  /// `startStream` resolves.
  FakeRecordRecorder({
    this.permission = true,
    this.refusedRates = const <int>{},
    this.startError,
    this.reportedConfig,
    this.firstChunks = const <Uint8List>[],
  });

  /// What `hasPermission` answers.
  bool permission;

  /// Sample rates `startStream` refuses the way Media Foundation does.
  final Set<int> refusedRates;

  /// Thrown by the next `startStream`, when set.
  Object? startError;

  /// Passed to the format callback while a stream starts, when set.
  record.RecordConfig? reportedConfig;

  /// Emitted on the event-loop turn after the first `startStream`.
  final List<Uint8List> firstChunks;

  /// Every configuration `startStream` was called with, refused or not.
  final List<record.RecordConfig> requested = <record.RecordConfig>[];

  final StreamController<record.RecordState> _states =
      StreamController<record.RecordState>.broadcast();
  StreamController<Uint8List>? _stream;
  void Function(record.RecordConfig)? _onConfig;
  bool _firstSent = false;

  /// Calls to `stop`.
  int stops = 0;

  /// Calls to `pause`.
  int pauses = 0;

  /// Calls to `resume`.
  int resumes = 0;

  /// Calls to `dispose`.
  int disposes = 0;

  /// Streams opened successfully.
  int streams = 0;

  /// Whether a stream is open.
  bool get streaming => _stream != null;

  @override
  Future<bool> hasPermission({bool request = true}) async => permission;

  @override
  Stream<record.RecordState> onStateChanged() => _states.stream;

  @override
  Future<void> setOnConfigChanged(
    void Function(record.RecordConfig config)? callback,
  ) async {
    _onConfig = callback;
  }

  @override
  Future<Stream<Uint8List>> startStream(record.RecordConfig config) async {
    requested.add(config);
    final Object? error = startError;
    if (error != null) {
      startError = null;
      throw error;
    }
    if (refusedRates.contains(config.sampleRate)) {
      throw _PlatformError(
        'MF_E_INVALIDMEDIATYPE: ${config.sampleRate} Hz is not supported',
      );
    }
    final record.RecordConfig? reported = reportedConfig;
    if (reported != null) {
      _onConfig?.call(reported);
    }
    final StreamController<Uint8List> controller =
        StreamController<Uint8List>.broadcast();
    _stream = controller;
    streams++;
    if (!_firstSent) {
      _firstSent = true;
      for (final Uint8List chunk in firstChunks) {
        Timer.run(() {
          if (!controller.isClosed) {
            controller.add(chunk);
          }
        });
      }
    }
    _states.add(record.RecordState.record);
    return controller.stream;
  }

  /// Delivers [bytes] as one platform chunk.
  void emit(Uint8List bytes) => _stream?.add(bytes);

  /// Streams the samples of [wav] (after its 44-byte header) in chunks of
  /// [chunkBytes], one event-loop turn apart.
  Future<void> streamWav(File wav, {int chunkBytes = 3200}) async {
    final Uint8List bytes = await wav.readAsBytes();
    for (int offset = 44; offset < bytes.length; offset += chunkBytes) {
      final int end = offset + chunkBytes < bytes.length
          ? offset + chunkBytes
          : bytes.length;
      emit(Uint8List.fromList(bytes.sublist(offset, end)));
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Fails the open stream with [error].
  void fail(Object error) => _stream?.addError(error);

  /// Ends the open stream without a stop, as an unplugged device does.
  Future<void> end() async {
    final StreamController<Uint8List>? stream = _stream;
    _stream = null;
    await stream?.close();
  }

  /// Pauses natively, as audio focus loss does.
  void interrupt() => _states.add(record.RecordState.pause);

  @override
  Future<String?> stop() async {
    stops++;
    final StreamController<Uint8List>? stream = _stream;
    _stream = null;
    await stream?.close();
    if (!_states.isClosed) {
      _states.add(record.RecordState.stop);
    }
    return null;
  }

  @override
  Future<void> pause() async {
    pauses++;
    _states.add(record.RecordState.pause);
  }

  @override
  Future<void> resume() async {
    resumes++;
    _states.add(record.RecordState.record);
  }

  @override
  Future<void> dispose() async {
    disposes++;
    final StreamController<Uint8List>? stream = _stream;
    _stream = null;
    await stream?.close();
    await _states.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// What a platform channel error looks like to the adapter: only its text.
final class _PlatformError implements Exception {
  const _PlatformError(this.message);

  final String message;

  @override
  String toString() => 'PlatformException(record, $message)';
}
