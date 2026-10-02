import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as ml;
import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'ocr_block.dart';
import 'ocr_result.dart';

part 'ocr_glyph_reader.dart';

/// On-device recognition. No network call is made.
abstract interface class OcrService {
  /// Reads [imagePath] without touching the network.
  ///
  /// [cancel] stops the read: the desktop reader's isolate is torn down, and
  /// the platform reader is closed and its answer dropped. Either way the
  /// call throws a [CancelledFailure].
  Future<OcrResult> recognise(String imagePath, {CancellationToken? cancel});

  /// The on-device reader.
  factory OcrService() = _OnDeviceOcr;
}

final class _OnDeviceOcr implements OcrService {
  const _OnDeviceOcr();

  @override
  Future<OcrResult> recognise(
    String imagePath, {
    CancellationToken? cancel,
  }) async {
    if (cancel?.isCancelled ?? false) {
      throw const CancelledFailure();
    }
    final File file = File(imagePath);
    if (!await file.exists()) {
      throw ValidationFailure(
        localizedMessage: Copy.messages.failureThatPhotoIsNotOnThisDevice,
        localizedRecovery:
            Copy.messages.failureCaptureThePhotoAgainThenTryAgain,
      );
    }
    // ML Kit decodes and reads natively from the path; this isolate only
    // waits on the platform channel. Calling the channel from a runner
    // isolate would not move that native work, so cancel closes the reader.
    if (Platform.isAndroid || Platform.isIOS) {
      return recogniseNativeOcr(imagePath, cancel);
    }
    final Result<Map<String, Object?>> result = await runIsolate(
      _recognisePath,
      imagePath,
      cancel: cancel,
    );
    return result.fold((Failure failure) {
      throw failure;
    }, _decodePayload);
  }
}

/// Native platform boundary, exposed for channel-level lifecycle regression.
@visibleForTesting
Future<OcrResult> recogniseNativeOcr(
  String imagePath,
  CancellationToken? cancel,
) async {
  final ml.TextRecognizer recognizer = ml.TextRecognizer(
    script: ml.TextRecognitionScript.latin,
  );
  try {
    final Future<ml.RecognizedText> work = recognizer.processImage(
      ml.InputImage.fromFilePath(imagePath),
    );
    final ml.RecognizedText? recognised = cancel == null
        ? await work
        : await cancel.race<ml.RecognizedText?>(work, onCancel: () => null);
    if (recognised == null) {
      throw const CancelledFailure();
    }
    return OcrResult(
      text: recognised.text,
      engine: AppConstants.processing.ocrEngineMlKit,
      blocks: <OcrBlock>[
        for (final ml.TextBlock block in recognised.blocks)
          for (final ml.TextLine line in block.lines)
            OcrBlock(
              text: line.text,
              bounds: line.boundingBox,
              confidence: _lineConfidence(line),
            ),
      ],
    );
  } on CancelledFailure {
    rethrow;
  } on Object {
    throw ValidationFailure(
      localizedMessage: Copy.messages.failureThatPhotoCouldNotBeReadOn,
      localizedRecovery: Copy.messages.failureUseAnotherPhotoOrEnterTheValue,
    );
  } finally {
    await recognizer.close();
  }
}

double _lineConfidence(ml.TextLine line) {
  final List<double> scores = <double>[
    if (line.confidence case final double score) score,
    for (final ml.TextElement element in line.elements)
      if (element.confidence case final double score) score,
  ];
  if (scores.isEmpty) {
    return 0;
  }
  return scores.reduce((double left, double right) => left + right) /
      scores.length;
}

Future<Map<String, Object?>> _recognisePath(String path) async {
  final File file = File(path);
  if (!file.existsSync()) {
    return <String, Object?>{'error': 'missing'};
  }
  final Uint8List bytes = await file.readAsBytes();
  IsolateRunner.reportProgress(_decodeShare);
  final img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return <String, Object?>{'error': 'unreadable'};
  }
  IsolateRunner.reportProgress(_readShare);
  final Map<String, Object?> read = _read(decoded);
  IsolateRunner.reportProgress(1);
  return read;
}

/// Share of a desktop read done once the file is loaded, then decoded.
const double _decodeShare = 0.2;
const double _readShare = 0.5;

OcrResult _decodePayload(Map<String, Object?> payload) {
  final Object? error = payload['error'];
  if (error == 'missing') {
    throw ValidationFailure(
      localizedMessage: Copy.messages.failureThatPhotoIsNotOnThisDevice,
      localizedRecovery: Copy.messages.failureCaptureThePhotoAgainThenTryAgain,
    );
  }
  if (error == 'unreadable') {
    throw ValidationFailure(
      localizedMessage: Copy.messages.failureThatPhotoCouldNotBeReadAs,
      localizedRecovery: Copy.messages.failureCaptureThePhotoAgainThenTryAgain,
    );
  }
  final String text = payload['text'] as String? ?? '';
  final Object? rawBlocks = payload['blocks'];
  final List<OcrBlock> blocks = <OcrBlock>[];
  if (rawBlocks is List<Object?>) {
    for (final Object? raw in rawBlocks) {
      if (raw is! List<Object?> || raw.length < 6) {
        continue;
      }
      blocks.add(
        OcrBlock(
          text: raw[0]! as String,
          bounds: Rect.fromLTRB(
            (raw[1]! as num).toDouble(),
            (raw[2]! as num).toDouble(),
            (raw[3]! as num).toDouble(),
            (raw[4]! as num).toDouble(),
          ),
          confidence: (raw[5]! as num).toDouble(),
        ),
      );
    }
  }
  return OcrResult(
    text: text,
    blocks: blocks,
    engine: AppConstants.processing.ocrEngineDesktop,
  );
}
