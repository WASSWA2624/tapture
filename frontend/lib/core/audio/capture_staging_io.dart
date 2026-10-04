import 'dart:io';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/storage_root.dart';

import 'audio_recording.dart';
import 'capture_staging.dart';
import 'file_pcm_store.dart';
import 'pcm_store.dart';
import 'staged_take.dart';
import 'wav_header.dart';

/// Opens `<root>/<relativePath>.recording` beside its target, refusing a
/// take whose staging file or target already exists, and writes a header
/// whose lengths are zero until the first checkpoint.
Future<Result<CaptureStaging>> openCaptureStaging({
  required StorageRoot root,
  required FileWriter writer,
  required String relativePath,
}) async {
  try {
    final String path = stagedTakePath(relativePath);
    final Result<Directory> resolved = await root.resolve();
    if (resolved case FailureResult<Directory>(:final Failure failure)) {
      return FailureResult<CaptureStaging>(failure);
    }
    final Directory folder = (resolved as Success<Directory>).value;
    final File target = File('${folder.path}/$path');
    final File staging = File('${target.path}$stagedTakeSuffix');
    if (await staging.exists() || await target.exists()) {
      return FailureResult<CaptureStaging>(
        ValidationFailure(localizedMessage: Copy.messages.audioStartFailed),
      );
    }
    await staging.parent.create(recursive: true);
    final RandomAccessFile handle = await staging.open(mode: FileMode.write);
    try {
      await handle.writeFrom(
        WavHeader.bytes(
          AppConstants.audio.sampleRate,
          AppConstants.audio.channels,
          dataLength: 0,
        ),
      );
      await handle.flush();
    } on Object {
      await handle.close();
      rethrow;
    }
    return Success<CaptureStaging>(
      _FileCaptureStaging(
        writer: writer,
        path: path,
        staging: staging,
        target: target,
        handle: handle,
      ),
    );
  } on Failure catch (failure) {
    return FailureResult<CaptureStaging>(failure);
  } on Object {
    return FailureResult<CaptureStaging>(_writeFailure(relativePath));
  }
}

/// The staging WAV: one write handle, appends applied in order, and the
/// header patched and flushed every `AppConstants.speechSession
/// .wavFlushInterval` of audio and at every checkpoint.
final class _FileCaptureStaging implements CaptureStaging {
  _FileCaptureStaging({
    required this._writer,
    required this._path,
    required this._staging,
    required this._target,
    required RandomAccessFile this._handle,
  }) : _store = FilePcmStore(_staging);

  final FileWriter _writer;
  final String _path;
  final File _staging;
  final File _target;
  final FilePcmStore _store;
  RandomAccessFile? _handle;
  int _samples = 0;
  int _sinceFlush = 0;
  Future<void> _tail = Future<void>.value();

  @override
  PcmStore get store => _store;

  @override
  Future<Result<void>> append(Int16List samples) => _serial(() async {
    final RandomAccessFile handle = _open();
    await handle.writeFrom(
      samples.buffer.asUint8List(samples.offsetInBytes, samples.lengthInBytes),
    );
    _samples += samples.length;
    _store.appended(samples);
    _sinceFlush += samples.length;
    if (_sinceFlush >= _flushSamples) {
      await _patch(handle);
    }
  });

  @override
  Future<Result<void>> checkpoint() => _serial(() async {
    final RandomAccessFile? handle = _handle;
    if (handle != null) {
      await _patch(handle);
    }
  });

  @override
  Future<Result<AudioRecording?>> publish() async {
    final Result<void> closed = await _serial(_close);
    if (closed case FailureResult<void>(:final Failure failure)) {
      _store.reopen();
      return FailureResult<AudioRecording?>(failure);
    }
    final Result<AudioRecording> published = await publishStagedTake(
      writer: _writer,
      staging: _staging,
      relativePath: _path,
      fallback: stagedTakeDuration(_samples),
    );
    if (published is Success<AudioRecording>) {
      await _store.rebase(_target);
    } else {
      // The take stays where it is, and so do its reads.
      _store.reopen();
    }
    return published.map((AudioRecording recording) => recording);
  }

  @override
  Future<Result<String?>> abandon() async {
    final Result<void> closed = await _serial(_close);
    _store.reopen();
    return closed.map((_) => '$_path$stagedTakeSuffix');
  }

  @override
  Future<void> discardIfEmpty() async {
    await _serial(_close);
    if (_samples == 0) {
      await discardUnpublishedFile(_staging);
    }
  }

  @override
  Future<void> release() async {
    await _serial(_close);
    await _store.close();
  }

  RandomAccessFile _open() {
    final RandomAccessFile? handle = _handle;
    if (handle == null) {
      throw StateError('The staged take is closed.');
    }
    return handle;
  }

  /// Patches the header, flushes, and closes both the write handle and the
  /// store's read handle, so the take can be renamed.
  Future<void> _close() async {
    final RandomAccessFile? handle = _handle;
    if (handle != null) {
      _handle = null;
      try {
        await _patch(handle);
      } finally {
        await handle.close();
      }
    }
    await _store.closeFile();
  }

  Future<void> _patch(RandomAccessFile handle) async {
    await WavHeader.patchLengths(handle, _samples * 2);
    await handle.flush();
    _sinceFlush = 0;
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

/// Samples between two header patches.
final int _flushSamples =
    AppConstants.speechSession.wavFlushInterval.inMilliseconds *
    AppConstants.audio.sampleRate ~/
    Duration.millisecondsPerSecond;

StorageFailure _writeFailure(String path) {
  return StorageFailure(
    localizedMessage: Copy.messages.failureTaptureCouldNotWriteToValue(path),
    localizedRecovery: Copy.messages.failureFreeUpSpaceOrExportAProject,
  );
}
