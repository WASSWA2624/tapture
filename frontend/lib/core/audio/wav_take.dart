part of 'audio_recorder_plugin.dart';

Future<AudioRecording?> _readPublishedTake((String, String) paths) async {
  final File published = File(paths.$1);
  final _WavTake? take = await _WavTake.read(published);
  if (take == null) throw const FormatException('Invalid WAV take.');
  final Digest hash = await sha256.bind(published.openRead()).first;
  return AudioRecording(
    relativePath: paths.$2,
    sha256: hash.toString(),
    byteLength: await published.length(),
    duration: take.duration,
    mimeType: 'audio/wav',
  );
}

/// Bounded RIFF header inspection; audio samples are always streamed. Record
/// writes PCM WAV, whose length fields may remain zero after a process kill.
final class _WavTake {
  const _WavTake({
    required this.header,
    required this.dataOffset,
    required this.dataLength,
    required this.byteRate,
  });

  final Uint8List header;
  final int dataOffset;
  final int dataLength;
  final int byteRate;

  Duration get duration =>
      AppConstants.microsecond *
      (dataLength * Duration.microsecondsPerSecond ~/ byteRate);

  static Future<_WavTake?> read(File file, {bool interrupted = false}) async {
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
          return _WavTake(
            header: Uint8List.sublistView(bytes, 0, dataOffset),
            dataOffset: dataOffset,
            dataLength: dataLength,
            byteRate: byteRate,
          );
        }
        offset += 8 + size + size % 2;
      }
      return null;
    } finally {
      await handle.close();
    }
  }

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
