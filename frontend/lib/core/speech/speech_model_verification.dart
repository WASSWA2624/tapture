import 'dart:io';
import 'dart:typed_data';

import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/hash/hashing_service.dart';

import 'speech_failures.dart';
import 'speech_model_entry.dart';
import 'speech_model_header.dart';

/// Checks that the file at [path] is exactly [entry]: its size, then its
/// 48-byte header, then its SHA-256, streamed by [HashingService.sha256OfFile]
/// off the UI isolate (spec §30.4.2). Used for an import and for the
/// settings "Verify" action; a load does only [precheckSpeechModelFile],
/// because the native shim hashes the file itself.
///
/// A missing or unreadable file is `speechModelMissing`; a wrong size, a
/// foreign or mismatched header, a truncated file or another hash is
/// `speechModelDamaged` (a [CorruptionFailure]). [cancel] gives a
/// [CancelledFailure]; [onProgress] follows the hash and ends at 1.0.
Future<Result<void>> verifySpeechModelFile(
  String path,
  SpeechModelEntry entry, {
  CancellationToken? cancel,
  void Function(double)? onProgress,
}) async {
  final Result<void> prechecked = await precheckSpeechModelFile(path, entry);
  if (prechecked is FailureResult<void>) {
    return prechecked;
  }
  if (cancel?.isCancelled ?? false) {
    return const FailureResult<void>(CancelledFailure());
  }
  final Result<String> hashed = await HashingService.sha256OfFile(
    File(path),
    cancel: cancel,
    onProgress: onProgress,
  );
  switch (hashed) {
    case FailureResult<String>(failure: final CancelledFailure failure):
      return FailureResult<void>(failure);
    case FailureResult<String>():
      return FailureResult<void>(speechModelDamaged());
    case Success<String>(:final String value):
      return value == entry.sha256
          ? const Success<void>(null)
          : FailureResult<void>(speechModelDamaged());
  }
}

/// The cheap part of [verifySpeechModelFile]: the size, then the header,
/// without hashing. The native engine runs it before every load.
///
/// A whisper header is compared on the vocabulary, audio state and layers,
/// text layers, mel bands and `ftype % 1000`
/// ([SpeechModelHeader.mismatchesWith]); a VAD header on its magic only. The
/// context lengths, head counts and text state are fixed by those for every
/// published whisper model, so they add no protection here: the SHA-256
/// that follows, and the shape the shim reports after loading, cover them.
Future<Result<void>> precheckSpeechModelFile(
  String path,
  SpeechModelEntry entry,
) async {
  final File file = File(path);
  final int length;
  final Uint8List first;
  try {
    if (!await file.exists()) {
      return FailureResult<void>(speechModelMissing());
    }
    length = await file.length();
    if (length != entry.bytes) {
      return FailureResult<void>(speechModelDamaged());
    }
    final RandomAccessFile handle = await file.open();
    try {
      first = await handle.read(SpeechModelHeader.length);
    } finally {
      await handle.close();
    }
  } on FileSystemException {
    return FailureResult<void>(speechModelMissing());
  }
  final SpeechModelHeader? header = SpeechModelHeader.parse(first);
  if (header == null || header.mismatchesWith(entry).isNotEmpty) {
    return FailureResult<void>(speechModelDamaged());
  }
  return const Success<void>(null);
}
