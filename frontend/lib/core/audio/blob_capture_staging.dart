import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/file_writer.dart';

import 'audio_recording.dart';
import 'capture_staging.dart';
import 'pcm_ring.dart';
import 'pcm_store.dart';
import 'staged_take.dart';
import 'wav_header.dart';

/// A take staged in a [BlobStore], for a browser, which has no file to
/// append to.
///
/// Every `AppConstants.speechSession.webChunkDuration` of samples becomes
/// one key, `<path>.recording/<seq>` with a six-digit sequence, and
/// `<path>.recording/manifest` names the format and how far the take has
/// got. The chunk being filled is kept in memory until it is full or a
/// [checkpoint] flushes it, so a closed tab loses at most one chunk.
///
/// [publish] streams a WAV header and the chunks through the [FileWriter]
/// to `<path>`; the chunks stay readable until [release], which alone
/// removes them, and only after a publish. [abandon] keeps every chunk, and
/// [recover] assembles them after a reload. Every call is applied in order.
final class BlobCaptureStaging implements CaptureStaging {
  BlobCaptureStaging._({
    required this._store,
    required this._writer,
    required this._path,
    required this._maxSamples,
  }) : _prefix = '$_path$stagedTakeSuffix',
       _pending = Int16List(_chunkSamples) {
    _reader = _BlobPcmStore(this);
  }

  /// Opens staging for a take published at [relativePath] through
  /// [writer], keeping its chunks in [store]. A take whose staging or
  /// target already exists is refused. [maxDuration] caps the take, at
  /// `AppConstants.speechSession.webMaxSessionDuration` when null, because
  /// publishing holds the whole take in memory.
  static Future<Result<BlobCaptureStaging>> open({
    required BlobStore store,
    required FileWriter writer,
    required String relativePath,
    Duration? maxDuration,
  }) async {
    try {
      final String path = stagedTakePath(relativePath);
      final BlobCaptureStaging staging = BlobCaptureStaging._(
        store: store,
        writer: writer,
        path: path,
        maxSamples:
            (maxDuration ?? AppConstants.speechSession.webMaxSessionDuration)
                .inMicroseconds *
            AppConstants.audio.sampleRate ~/
            Duration.microsecondsPerSecond,
      );
      for (final String key in <String>[staging._manifestKey, path]) {
        final Uint8List? existing = (await store.read(key)).getOrThrow();
        if (existing != null) {
          return FailureResult<BlobCaptureStaging>(
            ValidationFailure(localizedMessage: Copy.messages.audioStartFailed),
          );
        }
      }
      await staging._writeManifest(chunks: 0, samples: 0);
      return Success<BlobCaptureStaging>(staging);
    } on Failure catch (failure) {
      return FailureResult<BlobCaptureStaging>(failure);
    } on Object {
      return FailureResult<BlobCaptureStaging>(_writeFailure(relativePath));
    }
  }

  /// Publishes the take staged for [relativePath] in [store] after a
  /// reload, through [writer]. A take already published is measured and
  /// hashed, never rewritten. Otherwise the chunks the manifest names are
  /// assembled behind a header that matches them, and kept (rule 1). Null
  /// when nothing was staged or no audio was captured.
  static Future<Result<AudioRecording?>> recover({
    required BlobStore store,
    required FileWriter writer,
    required String relativePath,
  }) async {
    try {
      final String path = stagedTakePath(relativePath);
      final Uint8List? published = (await store.read(path)).getOrThrow();
      if (published != null) {
        return Success<AudioRecording?>(_publishedTake(path, published));
      }
      final String prefix = '$path$stagedTakeSuffix';
      final Uint8List? manifest = (await store.read(
        _manifestKeyOf(prefix),
      )).getOrThrow();
      if (manifest == null) {
        return const Success<AudioRecording?>(null);
      }
      final int listed = _listedChunks(manifest);
      final List<int> lengths = <int>[];
      for (int seq = 0; ; seq++) {
        final Uint8List? chunk = (await store.read(
          _chunkKeyOf(prefix, seq),
        )).getOrThrow();
        if (chunk == null) {
          if (seq < listed) throw const CorruptionFailure();
          break;
        }
        if (chunk.length.isOdd) throw const CorruptionFailure();
        lengths.add(chunk.length);
        // Every chunk but the last is full; a short one ends the take.
        if (chunk.length < _chunkSamples * 2) break;
      }
      final int dataBytes = lengths.fold(0, (int sum, int n) => sum + n);
      if (dataBytes == 0) {
        return const Success<AudioRecording?>(null);
      }
      final Result<WrittenFile> written = await writer.write(
        _takeBytes(store, prefix, lengths),
        path,
      );
      return written.map((WrittenFile file) {
        return _recording(file, dataBytes ~/ 2);
      });
    } on Failure catch (failure) {
      return FailureResult<AudioRecording?>(failure);
    } on Object catch (error) {
      return FailureResult<AudioRecording?>(Failure.from(error));
    }
  }

  final BlobStore _store;
  final FileWriter _writer;
  final String _path;
  final String _prefix;
  final int _maxSamples;
  late final _BlobPcmStore _reader;

  /// The chunk being filled; its first [_pendingLength] samples are live.
  final Int16List _pending;
  int _pendingLength = 0;

  /// Whether the pending samples differ from what the store holds for
  /// chunk [_seq].
  bool _dirty = false;

  /// Whether chunk [_seq] has been written while still partial.
  bool _partialWritten = false;

  /// Full chunks written; the pending chunk is number [_seq].
  int _seq = 0;

  /// The highest chunk number ever written, removed by [release].
  int _highestKey = -1;

  /// Samples appended, counted from the start of the take.
  int _length = 0;

  Failure? _failure;
  bool _closed = false;
  bool _published = false;
  bool _released = false;
  Future<void> _tail = Future<void>.value();

  String get _manifestKey => _manifestKeyOf(_prefix);

  @override
  PcmStore get store => _reader;

  @override
  Future<Result<void>> append(Int16List samples) => _serial(() async {
    final Failure? failed = _failure;
    if (failed != null) throw failed;
    if (_closed) throw StateError('The staged take is closed.');
    if (_length + samples.length > _maxSamples) {
      // A full take stays full: a shorter append later would leave a gap.
      final Failure fullFailure = StorageFailure(
        localizedMessage: Copy.messages.audioTakeLimitReached,
        localizedRecovery: Copy.messages.audioTakeLimitReachedRecovery,
      );
      _failure = fullFailure;
      throw fullFailure;
    }
    try {
      await _keep(samples);
    } on Object catch (error) {
      _failure = error is Failure ? error : _writeFailure(_path);
      // A chunk may have been written whole before a later write failed;
      // the next flush puts back exactly what the take holds.
      _dirty = _pendingLength > 0;
      rethrow;
    }
  });

  @override
  Future<Result<void>> checkpoint() => _serial(_flush);

  @override
  Future<Result<AudioRecording?>> publish() async {
    final Result<void> closed = await _serial(_close);
    if (closed case FailureResult<void>(:final Failure failure)) {
      return FailureResult<AudioRecording?>(failure);
    }
    final List<int> lengths = <int>[
      for (int seq = 0; seq < _seq; seq++) _chunkSamples * 2,
      if (_partialWritten) _pendingLength * 2,
    ];
    final Result<WrittenFile> written = await _writer.write(
      _takeBytes(_store, _prefix, lengths),
      _path,
    );
    if (written is Success<WrittenFile>) {
      _published = true;
    }
    return written.map((WrittenFile file) => _recording(file, _length));
  }

  @override
  Future<Result<String?>> abandon() async {
    final Result<void> closed = await _serial(_close);
    return closed.map((_) => _prefix);
  }

  @override
  Future<void> discardIfEmpty() async {
    await _serial(_close);
    if (_length == 0 && _highestKey < 0) {
      await _store.remove(_manifestKey);
    }
  }

  @override
  Future<void> release() async {
    if (_released) {
      return;
    }
    _released = true;
    await _serial(_close);
    _reader.close();
    if (!_published) {
      // An unpublished take is the only copy: its chunks stay for recovery.
      return;
    }
    for (int seq = 0; seq <= _highestKey; seq++) {
      await _store.remove(_chunkKeyOf(_prefix, seq));
    }
    await _store.remove(_manifestKey);
  }

  /// Adds [samples] to the pending chunk, writing every chunk they fill.
  /// Nothing is committed unless every write succeeds, so a failed append
  /// leaves the take as it was.
  Future<void> _keep(Int16List samples) async {
    var seq = _seq;
    var pendingLength = _pendingLength;
    var offset = 0;
    while (samples.length - offset >= _chunkSamples - pendingLength) {
      final int take = _chunkSamples - pendingLength;
      final Int16List full = Int16List(_chunkSamples)
        ..setRange(0, pendingLength, _pending)
        ..setRange(pendingLength, _chunkSamples, samples, offset);
      await _writeChunk(seq, full);
      offset += take;
      pendingLength = 0;
      seq++;
    }
    final bool advanced = seq != _seq;
    if (advanced) {
      await _writeManifest(chunks: seq, samples: seq * _chunkSamples);
      _seq = seq;
      _partialWritten = false;
    }
    final int rest = samples.length - offset;
    _pending.setRange(pendingLength, pendingLength + rest, samples, offset);
    _pendingLength = pendingLength + rest;
    _dirty = _pendingLength > 0;
    _length += samples.length;
    _reader.appended(samples);
  }

  /// Writes the pending chunk and the manifest when either is behind.
  Future<void> _flush() async {
    if (!_dirty) {
      return;
    }
    await _writeChunk(_seq, Int16List.sublistView(_pending, 0, _pendingLength));
    _partialWritten = true;
    _dirty = false;
    await _writeManifest(chunks: _seq + 1, samples: _length);
  }

  /// Refuses further appends and flushes what is pending. Safe to repeat:
  /// a flush that failed is tried again.
  Future<void> _close() async {
    _closed = true;
    await _flush();
  }

  Future<void> _writeChunk(int seq, Int16List samples) async {
    final Uint8List bytes = Uint8List.sublistView(samples);
    (await _store.write(_chunkKeyOf(_prefix, seq), bytes)).getOrThrow();
    _highestKey = math.max(_highestKey, seq);
  }

  /// Records that [chunks] keys hold the take's first [samples] samples.
  Future<void> _writeManifest({
    required int chunks,
    required int samples,
  }) async {
    final Map<String, int> manifest = <String, int>{
      'v': _manifestVersion,
      'rate': AppConstants.audio.sampleRate,
      'ch': AppConstants.audio.channels,
      'chunks': chunks,
      'samples': samples,
    };
    final Uint8List bytes = utf8.encode(jsonEncode(manifest));
    (await _store.write(_manifestKey, bytes)).getOrThrow();
  }

  /// Samples `[from, to)` from the pending chunk and the stored chunks.
  /// The pending part is copied before any await, because an append may
  /// refill the pending chunk meanwhile; stored chunks never change.
  Future<Int16List> _read(int from, int to) async {
    final Int16List out = Int16List(to - from);
    final int stored = math.min(to, _seq * _chunkSamples);
    if (to > stored) {
      final int start = _seq * _chunkSamples;
      final int first = math.max(from, start);
      out.setRange(first - from, to - from, _pending, first - start);
    }
    var index = from;
    while (index < stored) {
      final int seq = index ~/ _chunkSamples;
      final int start = seq * _chunkSamples;
      final int end = math.min(stored, start + _chunkSamples);
      final Int16List chunk = await _reader.chunk(seq);
      out.setRange(index - from, end - from, chunk, index - start);
      index = end;
    }
    return out;
  }

  /// Runs [body] after every earlier call, as a [Result].
  Future<Result<void>> _serial(Future<void> Function() body) {
    final Future<Result<void>> next = _tail.then((_) async {
      try {
        await body();
        return const Success<void>(null);
      } on Failure catch (failure) {
        return FailureResult<void>(failure);
      } on Object {
        return FailureResult<void>(_writeFailure(_path));
      }
    });
    _tail = next.then<void>((_) {});
    return next;
  }
}

/// The [PcmStore] of a [BlobCaptureStaging]: the last
/// `AppConstants.speechPipeline.ringDuration` from memory, older audio from
/// the stored chunks, one chunk cached for sequential readers.
final class _BlobPcmStore implements PcmStore {
  _BlobPcmStore(this._staging) : _ring = PcmRing(_ringSamples);

  final BlobCaptureStaging _staging;
  final PcmRing _ring;
  int? _cachedSeq;
  Int16List? _cached;
  bool _closed = false;

  @override
  int get length => _ring.length;

  void appended(Int16List samples) => _ring.add(samples);

  @override
  Future<Result<Int16List>> read(int from, int to) async {
    if (_closed) {
      return const FailureResult<Int16List>(StorageFailure());
    }
    if (from < 0 || to < from || to > length) {
      return const FailureResult<Int16List>(ValidationFailure());
    }
    if (_ring.holds(from, to)) {
      return Success<Int16List>(_ring.read(from, to));
    }
    try {
      return Success<Int16List>(await _staging._read(from, to));
    } on Failure catch (failure) {
      return FailureResult<Int16List>(failure);
    } on Object {
      return const FailureResult<Int16List>(StorageFailure());
    }
  }

  /// The full stored chunk [seq].
  Future<Int16List> chunk(int seq) async {
    final Int16List? cached = _cached;
    if (cached != null && _cachedSeq == seq) {
      return cached;
    }
    final Uint8List? bytes = (await _staging._store.read(
      _chunkKeyOf(_staging._prefix, seq),
    )).getOrThrow();
    if (_closed) throw const StorageFailure();
    if (bytes == null || bytes.length != _chunkSamples * 2) {
      throw const CorruptionFailure();
    }
    final Int16List samples = _samplesOf(bytes);
    _cachedSeq = seq;
    _cached = samples;
    return samples;
  }

  void close() {
    _closed = true;
    _cached = null;
    _cachedSeq = null;
  }
}

/// Version of the manifest's shape; a new shape gets a new number.
const int _manifestVersion = 1;

/// Samples in one stored chunk.
final int _chunkSamples =
    AppConstants.speechSession.webChunkDuration.inMilliseconds *
    AppConstants.audio.sampleRate ~/
    Duration.millisecondsPerSecond;

/// Samples served from memory.
final int _ringSamples =
    AppConstants.speechPipeline.ringDuration.inMilliseconds *
    AppConstants.audio.sampleRate ~/
    Duration.millisecondsPerSecond;

String _manifestKeyOf(String prefix) => '$prefix/manifest';

String _chunkKeyOf(String prefix, int seq) {
  return '$prefix/${seq.toString().padLeft(6, '0')}';
}

/// How many chunks [manifest] says were written, after checking it
/// describes a 16 kHz mono take this version understands.
int _listedChunks(Uint8List manifest) {
  final Object? decoded = jsonDecode(utf8.decode(manifest));
  if (decoded is! Map<String, Object?> ||
      decoded['v'] != _manifestVersion ||
      decoded['rate'] != AppConstants.audio.sampleRate ||
      decoded['ch'] != AppConstants.audio.channels) {
    throw const CorruptionFailure();
  }
  final Object? chunks = decoded['chunks'];
  if (chunks is! int || chunks < 0) throw const CorruptionFailure();
  return chunks;
}

/// The canonical header for [dataBytes] of samples, with both lengths
/// filled in as a finished device take has them, then the chunks of
/// [lengths] bytes each, read one at a time.
Stream<List<int>> _takeBytes(
  BlobStore store,
  String prefix,
  List<int> lengths,
) async* {
  final int dataBytes = lengths.fold(0, (int sum, int n) => sum + n);
  final Uint8List header = WavHeader.bytes(
    AppConstants.audio.sampleRate,
    AppConstants.audio.channels,
    dataLength: dataBytes,
  );
  ByteData.sublistView(
    header,
  ).setUint32(4, WavHeader.dataOffset - 8 + dataBytes, Endian.little);
  yield header;
  for (int seq = 0; seq < lengths.length; seq++) {
    final Uint8List? chunk = (await store.read(
      _chunkKeyOf(prefix, seq),
    )).getOrThrow();
    if (chunk == null || chunk.length != lengths[seq]) {
      throw const CorruptionFailure();
    }
    yield chunk;
  }
}

/// The metadata of a take already published as [bytes] at [path].
AudioRecording _publishedTake(String path, Uint8List bytes) {
  final int dataBytes = math.max(0, bytes.length - WavHeader.dataOffset);
  return AudioRecording(
    relativePath: path,
    sha256: sha256.convert(bytes).toString(),
    byteLength: bytes.length,
    duration: stagedTakeDuration(dataBytes ~/ 2),
    mimeType: stagedTakeMimeType,
  );
}

AudioRecording _recording(WrittenFile file, int samples) {
  return AudioRecording(
    relativePath: file.relativePath,
    sha256: file.sha256,
    byteLength: file.byteLength,
    duration: stagedTakeDuration(samples),
    mimeType: stagedTakeMimeType,
  );
}

/// [bytes] of little-endian samples, copied so their alignment never
/// matters.
Int16List _samplesOf(Uint8List bytes) {
  final Int16List samples = Int16List(bytes.length ~/ 2);
  samples.buffer.asUint8List().setRange(0, samples.length * 2, bytes);
  return samples;
}

StorageFailure _writeFailure(String path) {
  return StorageFailure(
    localizedMessage: Copy.messages.failureTaptureCouldNotWriteToValue(path),
    localizedRecovery: Copy.messages.failureFreeUpSpaceOrExportAProject,
  );
}
