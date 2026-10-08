part of 'authenticated_file_cipher.dart';

/// Retains the envelope's original little-endian 32-bit counter sequence.
/// A generic CTR mode uses a different counter layout and cannot open old files.
final class _AuthenticatedFileCounter {
  _AuthenticatedFileCounter(Uint8List key)
    : _engine = AESEngine()..init(true, KeyParameter(key));

  static const int _blockBytes = 16;
  final AESEngine _engine;
  final Uint8List _counter = Uint8List(_blockBytes);
  final Uint8List _mask = Uint8List(_blockBytes);
  int _nonce = 1;

  void processData(Uint8List bytes, int start, int length) {
    RangeError.checkValidRange(start, start + length, bytes.length);
    final int end = start + length;
    for (int offset = start; offset < end; offset += _blockBytes) {
      _counter[0] = _nonce & 0xff;
      _counter[1] = (_nonce >> 8) & 0xff;
      _counter[2] = (_nonce >> 16) & 0xff;
      _counter[3] = (_nonce >> 24) & 0xff;
      _engine.processBlock(_counter, 0, _mask, 0);
      final int count = min(_blockBytes, end - offset);
      for (int index = 0; index < count; index++) {
        bytes[offset + index] ^= _mask[index];
      }
      _nonce = (_nonce + 1) & 0xffffffff;
    }
  }
}
