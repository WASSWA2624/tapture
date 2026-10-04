part of 'whisper_library.dart';

/// An open whisper model, local to the isolate that opened it.
///
/// One call at a time: a second call while one runs on the same model, from
/// any isolate, is refused with [WhisperStatus.busy]. A model nobody closes is
/// closed when it is garbage collected; [close] detaches that finalizer first,
/// so the native close runs exactly once.
final class WhisperModel implements Finalizable {
  WhisperModel._(this._library, this._handle, this.facts, int externalSize) {
    _library._bindings.contextFinalizer.attach(
      this,
      _handle,
      detach: this,
      externalSize: externalSize,
    );
  }

  /// Takes ownership of [handle], whose model is [externalSize] bytes; the
  /// handle is closed when its facts cannot be read.
  factory WhisperModel._adopt(
    WhisperLibrary library,
    Pointer<Void> handle,
    int externalSize,
  ) {
    final WhisperModelFacts facts;
    try {
      facts = using((Arena arena) {
        final Pointer<Void> native = NativeTypes.allocate(
          arena,
          NativeTypes.modelFacts,
        );
        _check(library._bindings.contextFacts(handle, native));
        return NativeTypes.readModelFacts(native);
      });
    } on WhisperNativeException {
      library._bindings.contextClose(handle);
      rethrow;
    }
    return WhisperModel._(library, handle, facts, externalSize);
  }

  final WhisperLibrary _library;
  final Pointer<Void> _handle;
  bool _closed = false;

  /// The loaded model's hyperparameters.
  final WhisperModelFacts facts;

  /// Whether [close] has run.
  bool get isClosed => _closed;

  /// Transcribes [pcm], 16 kHz mono float samples, and copies the whole
  /// result out of native memory.
  ///
  /// [initialPrompt] and [promptPieces] condition the decoder. With [abort],
  /// the call stops once the cell holds a value of at least [jobId] (which
  /// must then be above 0) and reports [WhisperStatus.aborted], never an
  /// empty success. Throws [WhisperNativeException] for every refusal, with
  /// whisper's own code on [WhisperStatus.inference].
  WhisperTranscript transcribe(
    Float32List pcm,
    WhisperDecodeOptions options, {
    String? initialPrompt,
    Int32List? promptPieces,
    WhisperCell? abort,
    int jobId = 0,
  }) {
    final WhisperBindings bindings = _library._bindings;
    final Pointer<Void> handle = _open();
    final Pointer<Int32> cell = abort?._open() ?? nullptr;
    if (pcm.isEmpty) {
      throw const WhisperNativeException(WhisperStatus.invalidArgument);
    }
    if (pcm.length > WhisperLibrary.maxSamples) {
      throw const WhisperNativeException(WhisperStatus.audioTooLong);
    }
    final Pointer<Float> samples = bindings.contextPcmBuffer(
      handle,
      pcm.length,
    );
    if (samples == nullptr) {
      throw const WhisperNativeException(WhisperStatus.busy);
    }
    samples.asTypedList(pcm.length).setAll(0, pcm);
    return using((Arena arena) {
      final Pointer<Void> native = NativeTypes.allocate(
        arena,
        NativeTypes.transcribeOptions,
      );
      NativeTypes.writeTranscribeOptions(native, options);
      final Int32List pieces = promptPieces ?? Int32List(0);
      final Pointer<Int32> prompt = pieces.isEmpty
          ? nullptr
          : arena<Int32>(pieces.length);
      if (pieces.isNotEmpty) {
        prompt.asTypedList(pieces.length).setAll(0, pieces);
      }
      final Pointer<Pointer<Void>> out = arena<Pointer<Void>>();
      final int status = bindings.transcribe(
        handle,
        samples,
        pcm.length,
        native,
        initialPrompt == null || initialPrompt.isEmpty
            ? nullptr
            : initialPrompt.toNativeUtf8(allocator: arena),
        prompt,
        pieces.length,
        cell,
        jobId,
        out,
      );
      _check(status, whisperCode: bindings.lastWhisperCode(handle));
      final Pointer<Void> result = out.value;
      try {
        final Pointer<Int32> count = arena<Int32>();
        final Pointer<Void> segments = bindings.resultSegments(result, count);
        final int segmentCount = count.value;
        final Pointer<Void> resultPieces = bindings.resultPieces(result, count);
        final int pieceCount = count.value;
        final Pointer<Uint8> text = bindings.resultText(result, count);
        return NativeTypes.readTranscript(
          segments: segments,
          segmentCount: segmentCount,
          pieces: resultPieces,
          pieceCount: pieceCount,
          text: text,
          textLength: count.value,
          language: bindings.resultLanguage(result).toDartString(),
          wallMs: bindings.resultWallMs(result),
        );
      } finally {
        bindings.resultFree(result);
      }
    });
  }

  /// Closes the model; later calls throw a [StateError]. Closing twice does
  /// nothing. A close during a call in another isolate takes effect when that
  /// call returns.
  void close() {
    if (_closed) {
      return;
    }
    _closed = true;
    _library._bindings.contextFinalizer.detach(this);
    _library._bindings.contextClose(_handle);
  }

  Pointer<Void> _open() {
    if (_closed) {
      throw StateError('the whisper model is closed');
    }
    return _handle;
  }
}
