import 'dart:io';
import 'dart:typed_data';

/// The canonical 44-byte header of a 16-bit PCM WAV file, and the patch
/// that brings its two length fields up to date while a take grows.
abstract final class WavHeader {
  /// Byte offset of the first sample after the canonical header.
  static const int dataOffset = 44;

  /// Bits per sample of every take the app writes.
  static const int bitsPerSample = 16;

  /// Offset of the RIFF chunk size.
  static const int _riffSizeOffset = 4;

  /// Offset of the data chunk size.
  static const int _dataSizeOffset = 40;

  /// The header of a PCM file at [sampleRate] Hz with [channels] channels
  /// and [dataLength] bytes of samples. A take still being written passes
  /// zero, and both length fields stay zero, which a reader takes to mean
  /// "up to the end of the file" until [patchLengths] fills them in.
  static Uint8List bytes(
    int sampleRate,
    int channels, {
    required int dataLength,
  }) {
    final int blockAlign = channels * bitsPerSample ~/ 8;
    final Uint8List header = Uint8List(dataOffset);
    final ByteData fields = ByteData.sublistView(header);
    header.setRange(0, 4, 'RIFF'.codeUnits);
    fields.setUint32(
      _riffSizeOffset,
      dataLength == 0 ? 0 : _riffSize(dataLength),
      Endian.little,
    );
    header.setRange(8, 12, 'WAVE'.codeUnits);
    header.setRange(12, 16, 'fmt '.codeUnits);
    fields.setUint32(16, 16, Endian.little);
    fields.setUint16(20, 1, Endian.little);
    fields.setUint16(22, channels, Endian.little);
    fields.setUint32(24, sampleRate, Endian.little);
    fields.setUint32(28, sampleRate * blockAlign, Endian.little);
    fields.setUint16(32, blockAlign, Endian.little);
    fields.setUint16(34, bitsPerSample, Endian.little);
    header.setRange(36, 40, 'data'.codeUnits);
    fields.setUint32(_dataSizeOffset, dataLength, Endian.little);
    return header;
  }

  /// Writes the RIFF and data sizes for [dataLength] bytes of samples into
  /// the open take [file], then returns its position to the end of the
  /// samples so appends continue there. Does not flush.
  static Future<void> patchLengths(
    RandomAccessFile file,
    int dataLength,
  ) async {
    final Uint8List field = Uint8List(4);
    final ByteData value = ByteData.sublistView(field);
    value.setUint32(0, _riffSize(dataLength), Endian.little);
    await file.setPosition(_riffSizeOffset);
    await file.writeFrom(field);
    value.setUint32(0, dataLength, Endian.little);
    await file.setPosition(_dataSizeOffset);
    await file.writeFrom(field);
    await file.setPosition(dataOffset + dataLength);
  }

  static int _riffSize(int dataLength) => dataOffset - 8 + dataLength;
}
