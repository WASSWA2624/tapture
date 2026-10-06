part of 'live_transcription_service.dart';

/// A published take opened for reading, with how to let it go.
typedef _OpenedTake = ({
  PcmStore store,
  int length,
  Future<void> Function() close,
});

/// One run of `transcribeRemaining`: each gap, then the tail, decoded from
/// the stored audio and appended to the transcript in order, with segment
/// ids continuing from the last stored one.
///
/// Each range runs the live pipeline from the range's first sample over a
/// view of the take that ends with the range, so every time stays on the
/// take's timeline. A gap decoded to its end is closed with an empty
/// utterance over the whole range, so silence inside it stops counting as
/// a gap. The first range that cannot be finished ends the run: later ids
/// would no longer follow on.
final class _RemainingTranscription {
  _RemainingTranscription({
    required this._service,
    required this._audioPath,
    required List<(int, int)> gaps,
    required this._fromSample,
    required this._nextSegmentId,
    required this._languageTag,
    required this._sink,
    required this._emit,
  }) : _gaps = List<(int, int)>.of(gaps)
         ..sort(((int, int) a, (int, int) b) => a.$1.compareTo(b.$1));

  final _LiveTranscriptionService _service;
  final String _audioPath;
  final List<(int, int)> _gaps;
  final int _fromSample;
  final int _nextSegmentId;
  final String _languageTag;
  final TranscriptSink _sink;
  final void Function(LiveTranscriptionEvent event) _emit;
  SpeechPipeline? _running;
  bool _cancelled = false;

  Logger get _log => _service._logger;

  /// Stops the run: the decode in flight is abandoned and the transcript
  /// is finished as it stands.
  void cancel() {
    _cancelled = true;
    unawaited(_running?.abort());
  }

  Future<void> run() async {
    _emit(
      const TranscriptionStateChanged(phase: LiveTranscriptionPhase.draining),
    );
    final Result<_OpenedTake> opened = await _open();
    final _OpenedTake take;
    switch (opened) {
      case FailureResult<_OpenedTake>(:final Failure failure):
        _log.warn(_tag, 'take unreadable (${failure.runtimeType})');
        // The transcript is restored to how it stood; its length is not
        // known, so it keeps the one it had.
        await _finish(
          complete: false,
          length: null,
          covered: _fromSample,
          modelId: null,
        );
        _failWith(failure);
        return;
      case Success<_OpenedTake>(:final _OpenedTake value):
        take = value;
    }
    final Result<SpeechEngineLease> acquired = await _service._host.acquire(
      languageTag: _languageTag,
    );
    final SpeechEngineLease lease;
    switch (acquired) {
      case FailureResult<SpeechEngineLease>(:final Failure failure):
        _log.warn(_tag, 'engine unavailable (${failure.runtimeType})');
        await take.close();
        await _finish(
          complete: false,
          length: take.length,
          covered: _fromSample,
          modelId: null,
        );
        _failWith(failure);
        return;
      case Success<SpeechEngineLease>(:final SpeechEngineLease value):
        lease = value;
    }
    final int length = take.length;
    int nextId = _nextSegmentId;
    int covered = math.min(_fromSample, length);
    bool whole = true;
    try {
      for (final (int from, int to) in _gaps) {
        final int start = math.max(0, from);
        final int end = math.min(to, length);
        if (end <= start) {
          continue;
        }
        if (_cancelled) {
          whole = false;
          break;
        }
        final ({bool whole, int covered, int nextId}) gap = await _range(
          take.store,
          lease,
          from: start,
          to: end,
          nextId: nextId,
        );
        nextId = gap.nextId;
        if (!gap.whole) {
          whole = false;
          break;
        }
        final Result<void> closed = await _sink.appendUtterance(
          FinishedUtterance(
            utteranceId: 0,
            fromSample: start,
            toSample: end,
            segments: const <TranscriptSegment>[],
          ),
        );
        if (closed case FailureResult<void>(:final Failure failure)) {
          _log.warn(_tag, 'gap not closed (${failure.runtimeType})');
          whole = false;
          break;
        }
      }
      if (whole && !_cancelled && covered < length) {
        final ({bool whole, int covered, int nextId}) tail = await _range(
          take.store,
          lease,
          from: covered,
          to: length,
          nextId: nextId,
        );
        covered = math.max(covered, tail.covered);
        whole = tail.whole;
      }
    } finally {
      await lease.release();
      await take.close();
    }
    final bool complete = whole && !_cancelled && covered >= length;
    await _finish(
      complete: complete,
      length: length,
      covered: covered,
      modelId: lease.modelId,
    );
    _log.info(
      _tag,
      'remaining transcription ended: '
      '${nextId - _nextSegmentId} segments, '
      '${complete ? 'complete' : 'incomplete'}',
    );
    _emit(
      TranscriptionStateChanged(
        phase: _cancelled
            ? LiveTranscriptionPhase.cancelled
            : LiveTranscriptionPhase.completed,
      ),
    );
  }

  /// Decodes samples [from] to [to] of [store] with segment ids from
  /// [nextId]: whether the range was accounted for to its end and stored,
  /// how far it was, and the next free segment id.
  Future<({bool whole, int covered, int nextId})> _range(
    PcmStore store,
    SpeechEngineLease lease, {
    required int from,
    required int to,
    required int nextId,
  }) async {
    int next = nextId;
    final SpeechPipeline pipeline = _running = _service._pipelineFor(
      _EndedPcmStore(store, length: to),
      languageTag: _languageTag,
      interims: false,
      dictation: false,
      sink: _sink,
      nextSegmentId: nextId,
      startSample: from,
      emit: (LiveTranscriptionEvent event) {
        if (event is SegmentFinalized) {
          next = math.max(next, event.segment.id + 1);
        }
        _emit(event);
      },
    );
    if (_cancelled) {
      await pipeline.abort();
    }
    pipeline
      ..attachLease(lease)
      ..audioAvailable(to);
    await pipeline.finish(drain: true);
    _running = null;
    final int covered = pipeline.coveredToSample;
    return (
      whole: !_cancelled && covered >= to && pipeline.unsaved.isEmpty,
      covered: covered,
      nextId: next,
    );
  }

  /// Finishes the sink over [length] samples of take, or without a length
  /// when the take could not be read.
  Future<void> _finish({
    required bool complete,
    required int? length,
    required int covered,
    required String? modelId,
  }) async {
    final Result<void> finished = await _sink.finish(
      TranscriptOutcome(
        complete: complete,
        captured: length == null
            ? null
            : _LiveTranscriptionService._durationOf(length),
        coveredToSample: covered,
        languageTag: _languageTag,
        modelId: modelId,
      ),
    );
    if (finished case FailureResult<void>(:final Failure failure)) {
      _log.warn(_tag, 'sink finish failed (${failure.runtimeType})');
    }
  }

  void _failWith(Failure failure) {
    _emit(TranscriptionFailed(failure: failure));
    _emit(
      const TranscriptionStateChanged(phase: LiveTranscriptionPhase.failed),
    );
  }

  /// The published take at the run's path: read in place from the file
  /// where files are reachable, otherwise loaded whole through the reader
  /// (a browser take is at most `webMaxSessionDuration` long).
  Future<Result<_OpenedTake>> _open() async {
    try {
      final String path = stagedTakePath(_audioPath);
      final StorageRoot? root = _service._storageRoot;
      if (!kIsWeb && root != null) {
        final Result<Directory> resolved = await root.resolve();
        switch (resolved) {
          case FailureResult<Directory>(:final Failure failure):
            return FailureResult<_OpenedTake>(failure);
          case Success<Directory>(:final Directory value):
            final File file = File('${value.path}/$path');
            if (!await file.exists()) {
              return FailureResult<_OpenedTake>(FileReader.unreadable(path));
            }
            final WavTake? wav = await WavTake.read(file);
            if (wav == null) {
              return const FailureResult<_OpenedTake>(CorruptionFailure());
            }
            final int samples = wav.dataLength ~/ _bytesPerSample;
            final FilePcmStore store = FilePcmStore(
              file,
              length: samples,
              dataOffset: wav.dataOffset,
            );
            return Success<_OpenedTake>((
              store: store,
              length: samples,
              close: store.close,
            ));
        }
      }
      final FileReader? reader = _service._reader;
      if (reader == null) {
        return FailureResult<_OpenedTake>(speechUnavailable());
      }
      final Result<Uint8List> bytes = await reader.read(path);
      switch (bytes) {
        case FailureResult<Uint8List>(:final Failure failure):
          return FailureResult<_OpenedTake>(failure);
        case Success<Uint8List>(:final Uint8List value):
          final Int16List? samples = _wavSamples(value);
          if (samples == null) {
            return const FailureResult<_OpenedTake>(CorruptionFailure());
          }
          final MemoryPcmStore store = MemoryPcmStore(
            maxSamples: math.max(1, samples.length),
          )..append(samples);
          return Success<_OpenedTake>((
            store: store,
            length: samples.length,
            close: () async => store.close(),
          ));
      }
    } on Failure catch (failure) {
      return FailureResult<_OpenedTake>(failure);
    }
  }

  /// The 16-bit samples of the WAV in [bytes], or null when it holds no
  /// `data` chunk.
  static Int16List? _wavSamples(Uint8List bytes) {
    final ByteData data = ByteData.sublistView(bytes);
    int at = _riffHeaderBytes;
    while (at + _chunkHeaderBytes <= bytes.length) {
      final int size = data.getUint32(at + _chunkSizeOffset, Endian.little);
      final int body = at + _chunkHeaderBytes;
      if (bytes[at] == _d &&
          bytes[at + 1] == _a &&
          bytes[at + 2] == _t &&
          bytes[at + 3] == _a) {
        final int end = math.min(bytes.length, body + size);
        final int count = (end - body) ~/ _bytesPerSample;
        final Int16List samples = Int16List(count);
        for (int index = 0; index < count; index++) {
          samples[index] = data.getInt16(
            body + index * _bytesPerSample,
            Endian.little,
          );
        }
        return samples;
      }
      at = body + size + size % _bytesPerSample;
    }
    return null;
  }
}

/// A take read only up to sample [length], so a range's drain ends there.
final class _EndedPcmStore implements PcmStore {
  _EndedPcmStore(this._inner, {required this.length});

  final PcmStore _inner;

  @override
  final int length;

  @override
  Future<Result<Int16List>> read(int from, int to) {
    if (to > length) {
      return Future<Result<Int16List>>.value(
        const FailureResult<Int16List>(ValidationFailure()),
      );
    }
    return _inner.read(from, to);
  }
}

/// Bytes per 16-bit mono sample.
const int _bytesPerSample = 2;

/// The `RIFF` id, size and `WAVE` form before the first chunk.
const int _riffHeaderBytes = 12;

/// A chunk's id and size before its body.
const int _chunkHeaderBytes = 8;

/// Where a RIFF chunk header holds the chunk's size.
const int _chunkSizeOffset = 4;

/// The letters of the `data` chunk id.
const int _d = 0x64;
const int _a = 0x61;
const int _t = 0x74;
