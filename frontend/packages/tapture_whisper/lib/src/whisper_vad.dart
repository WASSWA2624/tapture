part of 'whisper_library.dart';

/// An open Silero voice-activity detector, local to the isolate that opened
/// it.
///
/// [feed] streams audio: it scores whole windows of [windowSamples] samples
/// and keeps the remainder for the next feed, so its speech state carries
/// across feeds. [segments] cuts one whole buffer into speech spans.
final class WhisperVad implements Finalizable {
  WhisperVad._(
    this._library,
    this._handle,
    this.windowSamples,
    int externalSize,
  ) {
    _library._bindings.vadFinalizer.attach(
      this,
      _handle,
      detach: this,
      externalSize: externalSize,
    );
  }

  factory WhisperVad._adopt(
    WhisperLibrary library,
    Pointer<Void> handle,
    int externalSize,
  ) => WhisperVad._(
    library,
    handle,
    library._bindings.vadWindowSamples(handle),
    externalSize,
  );

  final WhisperLibrary _library;
  final Pointer<Void> _handle;
  bool _closed = false;

  /// Samples scored together; one probability per window.
  final int windowSamples;

  /// Whether [close] has run.
  bool get isClosed => _closed;

  /// Adds [pcm], 16 kHz mono float samples, to the stream and returns one
  /// speech probability per window completed by it.
  Float32List feed(Float32List pcm) {
    final WhisperBindings bindings = _library._bindings;
    final Pointer<Void> handle = _open();
    if (pcm.length > WhisperLibrary.maxSamples) {
      throw const WhisperNativeException(WhisperStatus.audioTooLong);
    }
    Pointer<Float> samples = nullptr;
    if (pcm.isNotEmpty) {
      samples = bindings.vadPcmBuffer(handle, pcm.length);
      if (samples == nullptr) {
        throw const WhisperNativeException(WhisperStatus.busy);
      }
      samples.asTypedList(pcm.length).setAll(0, pcm);
    }
    return using((Arena arena) {
      final Pointer<Int32> count = arena<Int32>();
      _check(bindings.vadFeed(handle, samples, pcm.length, count));
      final Pointer<Float> probabilities = bindings.vadProbs(handle, count);
      return count.value == 0
          ? Float32List(0)
          : Float32List.fromList(probabilities.asTypedList(count.value));
    });
  }

  /// Samples fed but not yet scored, fewer than [windowSamples].
  int get pendingSamples => _library._bindings.vadPendingSamples(_open());

  /// Forgets the stream's speech state and its pending samples.
  void reset() => _library._bindings.vadReset(_open());

  /// Cuts the whole of [pcm] into speech spans. The stream's state and
  /// pending samples are reset first.
  List<WhisperSpeechSpan> segments(Float32List pcm, WhisperVadOptions options) {
    final WhisperBindings bindings = _library._bindings;
    final Pointer<Void> handle = _open();
    if (pcm.length > WhisperLibrary.maxSamples) {
      throw const WhisperNativeException(WhisperStatus.audioTooLong);
    }
    Pointer<Float> samples = nullptr;
    if (pcm.isNotEmpty) {
      samples = bindings.vadPcmBuffer(handle, pcm.length);
      if (samples == nullptr) {
        throw const WhisperNativeException(WhisperStatus.busy);
      }
      samples.asTypedList(pcm.length).setAll(0, pcm);
    }
    return using((Arena arena) {
      final Pointer<Void> native = NativeTypes.allocate(
        arena,
        NativeTypes.vadOptions,
      );
      NativeTypes.writeVadOptions(native, options);
      final Pointer<Pointer<Void>> out = arena<Pointer<Void>>();
      _check(bindings.vadSegments(handle, samples, pcm.length, native, out));
      final Pointer<Void> spans = out.value;
      try {
        final Pointer<Int32> count = arena<Int32>();
        final Pointer<Void> data = bindings.spansData(spans, count);
        return NativeTypes.readSpans(data, count.value);
      } finally {
        bindings.spansFree(spans);
      }
    });
  }

  /// Closes the detector; later calls throw a [StateError]. Closing twice
  /// does nothing.
  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    _library._bindings.vadFinalizer.detach(this);
    _library._bindings.vadClose(_handle);
  }

  Pointer<Void> _open() {
    if (_closed) {
      throw StateError('the VAD is closed');
    }
    return _handle;
  }
}
