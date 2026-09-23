import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart'
    as ml;
import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'ocr_block.dart';
import 'ocr_result.dart';

/// On-device recognition. No network call is made.
abstract interface class OcrService {
  /// Reads [imagePath] off the UI thread.
  Future<OcrResult> recognise(String imagePath);

  /// The on-device reader.
  factory OcrService() = _OnDeviceOcr;

  /// Paints [text] as a high-contrast plate the on-device reader can read.
  static Uint8List paintPlate(String text) => _paintPlate(text);
}

final class _OnDeviceOcr implements OcrService {
  const _OnDeviceOcr();

  @override
  Future<OcrResult> recognise(String imagePath) async {
    final File file = File(imagePath);
    if (!await file.exists()) {
      throw const ValidationFailure(
        message: 'That photo is not on this device.',
        recoveryAction: 'Capture the photo again, then try again.',
      );
    }
    if (Platform.isAndroid || Platform.isIOS) {
      return _recogniseNative(imagePath);
    }
    final Result<Map<String, Object?>> result = await runIsolate(
      _recognisePath,
      imagePath,
    );
    return result.fold((Failure failure) {
      throw failure;
    }, _decodePayload);
  }
}

Future<OcrResult> _recogniseNative(String imagePath) async {
  final ml.TextRecognizer recognizer = ml.TextRecognizer(
    script: ml.TextRecognitionScript.latin,
  );
  try {
    final ml.RecognizedText recognised = await recognizer.processImage(
      ml.InputImage.fromFilePath(imagePath),
    );
    return OcrResult(
      text: recognised.text,
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
  } on Object {
    throw const ValidationFailure(
      message: 'That photo could not be read on this device.',
      recoveryAction: 'Use another photo or enter the value by hand.',
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
  final img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return <String, Object?>{'error': 'unreadable'};
  }
  return _read(decoded);
}

OcrResult _decodePayload(Map<String, Object?> payload) {
  final Object? error = payload['error'];
  if (error == 'missing') {
    throw const ValidationFailure(
      message: 'That photo is not on this device.',
      recoveryAction: 'Capture the photo again, then try again.',
    );
  }
  if (error == 'unreadable') {
    throw const ValidationFailure(
      message: 'That photo could not be read as an image.',
      recoveryAction: 'Capture the photo again, then try again.',
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
  return OcrResult(text: text, blocks: blocks);
}

Map<String, Object?> _read(img.Image source) {
  final List<_Glyph> glyphs = _segment(source);
  if (glyphs.isEmpty) {
    return <String, Object?>{'text': '', 'blocks': <Object?>[]};
  }
  final StringBuffer line = StringBuffer();
  final List<Object?> blocks = <Object?>[];
  for (final _Glyph glyph in glyphs) {
    final ({String char, double confidence}) match = _match(glyph.rows);
    if (match.char.isEmpty) {
      continue;
    }
    line.write(match.char);
    blocks.add(<Object?>[
      match.char,
      glyph.left,
      glyph.top,
      glyph.right,
      glyph.bottom,
      match.confidence,
    ]);
  }
  return <String, Object?>{'text': line.toString(), 'blocks': blocks};
}

class _Glyph {
  _Glyph({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.rows,
  });

  final int left;
  final int top;
  final int right;
  final int bottom;
  final List<String> rows;
}

List<_Glyph> _segment(img.Image source) {
  final int width = source.width;
  final int height = source.height;
  final List<bool> columnInk = List<bool>.filled(width, false);
  var top = height;
  var bottom = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (_dark(source.getPixel(x, y))) {
        columnInk[x] = true;
        if (y < top) {
          top = y;
        }
        if (y > bottom) {
          bottom = y;
        }
      }
    }
  }
  if (top > bottom) {
    return const <_Glyph>[];
  }
  final List<_Glyph> glyphs = <_Glyph>[];
  var x = 0;
  while (x < width) {
    while (x < width && !columnInk[x]) {
      x++;
    }
    if (x >= width) {
      break;
    }
    final int start = x;
    while (x < width && columnInk[x]) {
      x++;
    }
    glyphs.add(_sample(source, start, x - 1, top, bottom));
  }
  return glyphs;
}

_Glyph _sample(img.Image source, int left, int right, int top, int bottom) {
  final List<String> rows = <String>[];
  final int glyphWidth = right - left + 1;
  final int glyphHeight = bottom - top + 1;
  for (var row = 0; row < 7; row++) {
    final StringBuffer bits = StringBuffer();
    final int y0 = top + (row * glyphHeight) ~/ 7;
    final int y1 = top + ((row + 1) * glyphHeight) ~/ 7;
    final int yEnd = y1 <= y0 ? y0 + 1 : y1;
    for (var col = 0; col < 5; col++) {
      final int x0 = left + (col * glyphWidth) ~/ 5;
      final int x1 = left + ((col + 1) * glyphWidth) ~/ 5;
      final int xEnd = x1 <= x0 ? x0 + 1 : x1;
      var ink = 0;
      var seen = 0;
      for (var y = y0; y < yEnd && y <= bottom; y++) {
        for (var x = x0; x < xEnd && x <= right; x++) {
          seen++;
          if (_dark(source.getPixel(x, y))) {
            ink++;
          }
        }
      }
      bits.write(seen > 0 && ink * 2 >= seen ? '1' : '0');
    }
    rows.add(bits.toString());
  }
  return _Glyph(left: left, top: top, right: right, bottom: bottom, rows: rows);
}

({String char, double confidence}) _match(List<String> rows) {
  var best = '';
  var bestDistance = 36;
  for (final MapEntry<String, List<String>> entry in _font.entries) {
    var distance = 0;
    for (var i = 0; i < 7; i++) {
      for (var bit = 0; bit < 5; bit++) {
        if (rows[i][bit] != entry.value[i][bit]) {
          distance++;
        }
      }
    }
    if (distance < bestDistance) {
      bestDistance = distance;
      best = entry.key;
    }
  }
  if (bestDistance > 8) {
    return (char: '', confidence: 0);
  }
  return (char: best, confidence: 1 - (bestDistance / 35));
}

bool _dark(img.Pixel pixel) => img.getLuminance(pixel) < 160;

Uint8List _paintPlate(String text) {
  const int scale = 8;
  const int gap = 8;
  final int width = text.isEmpty ? scale : text.length * (5 * scale + gap);
  const int height = 7 * scale + gap * 2;
  final img.Image plate = img.Image(width: width, height: height);
  img.fill(plate, color: img.ColorRgb8(255, 255, 255));
  var cursor = gap ~/ 2;
  for (final int rune in text.runes) {
    final String char = String.fromCharCode(rune);
    final List<String>? rows = _font[char];
    if (rows == null) {
      cursor += 5 * scale + gap;
      continue;
    }
    for (var row = 0; row < 7; row++) {
      for (var col = 0; col < 5; col++) {
        if (rows[row][col] != '1') {
          continue;
        }
        img.fillRect(
          plate,
          x1: cursor + col * scale,
          y1: gap + row * scale,
          x2: cursor + (col + 1) * scale - 1,
          y2: gap + (row + 1) * scale - 1,
          color: img.ColorRgb8(0, 0, 0),
        );
      }
    }
    cursor += 5 * scale + gap;
  }
  return Uint8List.fromList(img.encodePng(plate));
}

const Map<String, List<String>> _font = <String, List<String>>{
  '0': <String>['01110', '10001', '10001', '10001', '10001', '10001', '01110'],
  '1': <String>['00100', '01100', '00100', '00100', '00100', '00100', '01110'],
  '2': <String>['01110', '10001', '00001', '00010', '00100', '01000', '11111'],
  '3': <String>['01110', '10001', '00001', '00110', '00001', '10001', '01110'],
  '4': <String>['00010', '00110', '01010', '10010', '11111', '00010', '00010'],
  '5': <String>['11111', '10000', '11110', '00001', '00001', '10001', '01110'],
  '6': <String>['01110', '10000', '11110', '10001', '10001', '10001', '01110'],
  '7': <String>['11111', '00001', '00010', '00100', '01000', '01000', '01000'],
  '8': <String>['01110', '10001', '10001', '01110', '10001', '10001', '01110'],
  '9': <String>['01110', '10001', '10001', '01111', '00001', '00001', '01110'],
  'A': <String>['01110', '10001', '10001', '11111', '10001', '10001', '10001'],
  'B': <String>['11110', '10001', '10001', '11110', '10001', '10001', '11110'],
  'C': <String>['01110', '10001', '10000', '10000', '10000', '10001', '01110'],
  'D': <String>['11110', '10001', '10001', '10001', '10001', '10001', '11110'],
  'E': <String>['11111', '10000', '10000', '11110', '10000', '10000', '11111'],
  'F': <String>['11111', '10000', '10000', '11110', '10000', '10000', '10000'],
  'G': <String>['01110', '10001', '10000', '10111', '10001', '10001', '01110'],
  'H': <String>['10001', '10001', '10001', '11111', '10001', '10001', '10001'],
  'I': <String>['01110', '00100', '00100', '00100', '00100', '00100', '01110'],
  'J': <String>['00111', '00010', '00010', '00010', '10010', '10010', '01100'],
  'K': <String>['10001', '10010', '10100', '11000', '10100', '10010', '10001'],
  'L': <String>['10000', '10000', '10000', '10000', '10000', '10000', '11111'],
  'M': <String>['10001', '11011', '10101', '10101', '10001', '10001', '10001'],
  'N': <String>['10001', '11001', '10101', '10011', '10001', '10001', '10001'],
  'O': <String>['01110', '10001', '10001', '10001', '10001', '10001', '01110'],
  'P': <String>['11110', '10001', '10001', '11110', '10000', '10000', '10000'],
  'Q': <String>['01110', '10001', '10001', '10001', '10101', '10010', '01101'],
  'R': <String>['11110', '10001', '10001', '11110', '10100', '10010', '10001'],
  'S': <String>['01111', '10000', '10000', '01110', '00001', '00001', '11110'],
  'T': <String>['11111', '00100', '00100', '00100', '00100', '00100', '00100'],
  'U': <String>['10001', '10001', '10001', '10001', '10001', '10001', '01110'],
  'V': <String>['10001', '10001', '10001', '10001', '10001', '01010', '00100'],
  'W': <String>['10001', '10001', '10001', '10101', '10101', '10101', '01010'],
  'X': <String>['10001', '10001', '01010', '00100', '01010', '10001', '10001'],
  'Y': <String>['10001', '10001', '01010', '00100', '00100', '00100', '00100'],
  'Z': <String>['11111', '00001', '00010', '00100', '01000', '10000', '11111'],
  '-': <String>['00000', '00000', '00000', '11111', '00000', '00000', '00000'],
};
