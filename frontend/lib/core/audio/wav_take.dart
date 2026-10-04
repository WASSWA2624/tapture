import 'dart:io';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';

/// Bounded RIFF header inspection of a WAV take; audio samples are always
/// streamed. A take's length fields may still be zero after a process
/// kill, and [read] can measure it from the bytes on disk instead.
final class WavTake {
  /// A take whose [header] ends at [dataOffset] and which holds
  /// [dataLength] bytes of samples at [byteRate] bytes a second.
  const WavTake({
    required this.header,
    required this.dataOffset,
    required this.dataLength,
    required this.byteRate,
    this.consistent = false,
  });

  /// The header bytes up to the first sample.
  final Uint8List header;

  /// Byte offset of the first sample.
  final int dataOffset;

  /// Bytes of whole sample frames.
  final int dataLength;

  /// Bytes per second of audio.
  final int byteRate;

  /// Whether the header's two length fields match the file exactly, so it
  /// can be published as it stands.
  final bool consistent;

  /// Length of the audio, from its bytes rather than wall time.
  Duration get duration =>
      AppConstants.microsecond *
      (dataLength * Duration.microsecondsPerSecond ~/ byteRate);

  /// Reads [file]'s header. With [interrupted], the samples are measured
  /// from the file size whatever the header says. Null when the file is not
  /// a PCM WAV take holding at least one frame.
  static Future<WavTake?> read(File file, {bool interrupted = false}) async {
    final RandomAccessFile handle = await file.open();
    try {
      final int length = await handle.length();
      // A recorder header is small; malformed chunks must not trigger a
      // recording-sized allocation or an unbounded scan on the UI isolate.
      const int headerLimit = 64 * 1024;
      final Uint8List bytes = await handle.read(
        length < headerLimit ? length : headerLimit,
      );
      if (bytes.length < 12 ||
          !_tag(bytes, 0, 'RIFF') ||
          !_tag(bytes, 8, 'WAVE')) {
        return null;
      }
      final ByteData numbers = ByteData.sublistView(bytes);
      final int riffSize = numbers.getUint32(4, Endian.little);
      int offset = 12;
      int byteRate = 0;
      int blockAlign = 0;
      while (offset + 8 <= bytes.length) {
        final int size = numbers.getUint32(offset + 4, Endian.little);
        if (_tag(bytes, offset, 'fmt ')) {
          if (size < 16 || offset + 24 > bytes.length) return null;
          final int encoding = numbers.getUint16(offset + 8, Endian.little);
          if (encoding != 1 && encoding != 3 && encoding != 0xfffe) return null;
          byteRate = numbers.getUint32(offset + 16, Endian.little);
          blockAlign = numbers.getUint16(offset + 20, Endian.little);
        } else if (_tag(bytes, offset, 'data')) {
          if (byteRate <= 0 || blockAlign <= 0) return null;
          final int dataOffset = offset + 8;
          final int available = length - dataOffset;
          final int samples = interrupted || size == 0 || size > available
              ? available
              : size;
          final int dataLength = samples - samples % blockAlign;
          if (dataLength <= 0 || dataOffset + dataLength - 8 > 0xffffffff) {
            return null;
          }
          return WavTake(
            header: Uint8List.sublistView(bytes, 0, dataOffset),
            dataOffset: dataOffset,
            dataLength: dataLength,
            byteRate: byteRate,
            consistent:
                size == available &&
                size == dataLength &&
                riffSize == length - 8,
          );
        }
        offset += 8 + size + size % 2;
      }
      return null;
    } finally {
      await handle.close();
    }
  }

  /// [original]'s samples behind a header whose lengths match them: a
  /// playable derivative. [original] itself is only read.
  Stream<List<int>> repairedBytes(File original) async* {
    final Uint8List repaired = Uint8List.fromList(header);
    final ByteData lengths = ByteData.sublistView(repaired);
    lengths.setUint32(4, dataOffset + dataLength - 8, Endian.little);
    lengths.setUint32(dataOffset - 4, dataLength, Endian.little);
    yield repaired;
    yield* original.openRead(dataOffset, dataOffset + dataLength);
  }

  static bool _tag(Uint8List bytes, int offset, String tag) {
    for (int index = 0; index < tag.length; index++) {
      if (bytes[offset + index] != tag.codeUnitAt(index)) return false;
    }
    return true;
  }
}
