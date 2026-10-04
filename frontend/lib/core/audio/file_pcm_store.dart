import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'pcm_ring.dart';
import 'pcm_store.dart';
import 'wav_header.dart';

/// A [PcmStore] over a 16-bit mono WAV file: the staging take while it is
/// recorded, then the published take once it has been renamed into place.
///
/// The last `AppConstants.speechPipeline.ringDuration` is served from a
/// [PcmRing]; older audio is read from the file through one read handle,
/// opened on demand so the file can be closed before it is renamed. Between
/// [closeFile] and [rebase] (or [reopen]) file reads wait, so no reader
/// reopens a file while it is being renamed.
final class FilePcmStore implements PcmStore {
  /// A store over [file], whose samples start at [dataOffset] and of which
  /// [length] samples are already written.
  FilePcmStore(
    File file, {
    int length = 0,
    this.dataOffset = WavHeader.dataOffset,
  }) : _file = file,
       _length = length,
       _ring = PcmRing(_ringSamples, origin: length);

  /// Byte offset of the first sample in the file.
  final int dataOffset;

  File _file;
  int _length;
  final PcmRing _ring;
  RandomAccessFile? _handle;
  Completer<void>? _hold;
  bool _closed = false;
  Future<void> _reads = Future<void>.value();

  /// The file the samples are read from.
  File get file => _file;

  @override
  int get length => _length;

  /// Records [samples] the writer has just appended to the file.
  void appended(Int16List samples) {
    _ring.add(samples);
    _length += samples.length;
  }

  @override
  Future<Result<Int16List>> read(int from, int to) {
    if (_closed) {
      return Future<Result<Int16List>>.value(
        const FailureResult<Int16List>(StorageFailure()),
      );
    }
    if (from < 0 || to < from || to > _length) {
      return Future<Result<Int16List>>.value(
        const FailureResult<Int16List>(ValidationFailure()),
      );
    }
    if (_ring.holds(from, to)) {
      return Future<Result<Int16List>>.value(
        Success<Int16List>(_ring.read(from, to)),
      );
    }
    return _readWhenOpen(from, to);
  }

  /// Closes the read handle so the file can be renamed. File reads wait
  /// until [rebase] or [reopen]; reads served by the ring do not.
  Future<void> closeFile() {
    _hold ??= Completer<void>();
    return _serial(_closeHandle);
  }

  /// Reads from [published] from now on: the same samples, renamed into
  /// place, so nothing captured becomes unreadable when a take is published.
  Future<void> rebase(File published) async {
    await _serial(() async {
      await _closeHandle();
      _file = published;
    });
    _releaseHold();
  }

  /// Lets file reads continue on the same file after [closeFile], when it
  /// was not renamed after all.
  void reopen() => _releaseHold();

  /// Closes the store; later reads fail.
  Future<void> close() async {
    _closed = true;
    await _serial(_closeHandle);
    _releaseHold();
  }

  Future<Result<Int16List>> _readWhenOpen(int from, int to) async {
    for (Completer<void>? hold = _hold; hold != null; hold = _hold) {
      await hold.future;
    }
    if (_closed) {
      return const FailureResult<Int16List>(StorageFailure());
    }
    return _serial(() => _readFile(from, to));
  }

  Future<void> _closeHandle() async {
    final RandomAccessFile? handle = _handle;
    _handle = null;
    await handle?.close();
  }

  void _releaseHold() {
    final Completer<void>? hold = _hold;
    _hold = null;
    hold?.complete();
  }

  Future<Result<Int16List>> _readFile(int from, int to) async {
    try {
      final RandomAccessFile handle = _handle ??= await _file.open();
      await handle.setPosition(dataOffset + from * 2);
      final int bytes = (to - from) * 2;
      final Uint8List read = await handle.read(bytes);
      if (read.length != bytes) {
        return const FailureResult<Int16List>(CorruptionFailure());
      }
      final Int16List samples = Int16List(to - from);
      samples.buffer.asUint8List().setRange(0, bytes, read);
      return Success<Int16List>(samples);
    } on Object {
      return const FailureResult<Int16List>(StorageFailure());
    }
  }

  /// Runs [body] after every earlier file operation, so the one read handle
  /// is never positioned by two readers at once.
  Future<T> _serial<T>(Future<T> Function() body) {
    final Future<T> next = _reads.then((_) => body());
    _reads = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}

/// Samples the ring holds: `AppConstants.speechPipeline.ringDuration` of
/// 16 kHz audio.
final int _ringSamples =
    AppConstants.speechPipeline.ringDuration.inMilliseconds *
    AppConstants.audio.sampleRate ~/
    Duration.millisecondsPerSecond;
