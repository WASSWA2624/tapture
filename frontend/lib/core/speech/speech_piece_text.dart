import 'dart:convert';

import 'speech_piece.dart';

/// Turns whisper's raw piece bytes into readable pieces, on device and in a
/// browser alike.
///
/// whisper splits text on byte-pair boundaries, so one code point (an
/// accented letter, a non-Latin character) can arrive across two or more
/// pieces. Decoding each alone would leave replacement characters.
abstract final class SpeechPieceText {
  /// Merges consecutive [raw] pieces until their bytes end on a whole UTF-8
  /// code point. A merged piece keeps the first piece's start, the last
  /// piece's end and the mean of their probabilities. Bytes still incomplete
  /// at the end are decoded leniently rather than dropped.
  static List<SpeechPiece> group(
    List<
      ({List<int> bytes, int startSample, int endSample, double probability})
    >
    raw,
  ) {
    final List<SpeechPiece> pieces = <SpeechPiece>[];
    final List<int> pending = <int>[];
    int start = 0;
    int end = 0;
    double probabilitySum = 0;
    int merged = 0;
    for (final ({
          List<int> bytes,
          int startSample,
          int endSample,
          double probability,
        })
        piece
        in raw) {
      if (merged == 0) {
        start = piece.startSample;
      }
      pending.addAll(piece.bytes);
      end = piece.endSample;
      probabilitySum += piece.probability;
      merged++;
      if (_endsOnCodePoint(pending)) {
        pieces.add(_piece(pending, start, end, probabilitySum / merged));
        pending.clear();
        probabilitySum = 0;
        merged = 0;
      }
    }
    if (merged > 0) {
      pieces.add(_piece(pending, start, end, probabilitySum / merged));
    }
    return pieces;
  }

  static SpeechPiece _piece(
    List<int> bytes,
    int start,
    int end,
    double probability,
  ) {
    return SpeechPiece(
      startSample: start,
      endSample: end,
      text: utf8.decode(bytes, allowMalformed: true),
      probability: probability,
    );
  }

  /// Whether [bytes] ends after the last byte of a code point: its final
  /// lead byte has all the continuation bytes it announces.
  static bool _endsOnCodePoint(List<int> bytes) {
    int continuation = 0;
    for (int index = bytes.length - 1; index >= 0; index--) {
      final int byte = bytes[index] & 0xFF;
      if (byte & 0xC0 == 0x80) {
        continuation++;
        if (continuation > 3) {
          return true;
        }
        continue;
      }
      final int expected = switch (byte) {
        < 0x80 => 0,
        >= 0xF0 => 3,
        >= 0xE0 => 2,
        >= 0xC0 => 1,
        _ => 0,
      };
      return continuation >= expected;
    }
    return true;
  }
}
