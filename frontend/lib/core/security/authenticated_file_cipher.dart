import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart' show Aes;
import 'package:crypto/crypto.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';

import 'authenticated_hmac.dart';

/// Bounded AES-256-CTR encryption with an authenticated header and ciphertext.
/// Every file has independent encryption/authentication keys and a random nonce.
final class AuthenticatedFileCipher {
  /// [magic] identifies the caller's versioned format. [purpose] separates keys
  /// when one master key is used for more than one kind of protected artifact.
  const AuthenticatedFileCipher({required this.magic, required this.purpose});

  /// Eight ASCII bytes naming the versioned envelope.
  final String magic;

  /// Stable domain used to derive independent encryption and MAC keys.
  final String purpose;

  static const int _nonceLength = 16;
  static const int _headerLength = 32;
  static const int _tagLength = 32;

  /// Envelope size without allocating or encrypting the content.
  static int sealedLength(int plainLength) =>
      _headerLength + plainLength + _tagLength;

  /// Encrypts bounded browser content; neither input nor key is changed.
  Uint8List seal(Uint8List plain, Uint8List key) {
    final Uint8List header = _header(plain.length);
    final ({Aes aes, Uint8List mac}) cipher = _cipher(key, header);
    final Uint8List sealed = Uint8List(sealedLength(plain.length))
      ..setAll(0, header)
      ..setAll(_headerLength, plain);
    final Uint8List body = Uint8List.sublistView(
      sealed,
      _headerLength,
      _headerLength + plain.length,
    );
    cipher.aes.processData(body, 0, body.length);
    final int tagOffset = _headerLength + plain.length;
    final Uint8List authenticated = Uint8List.sublistView(sealed, 0, tagOffset);
    sealed.setAll(
      tagOffset,
      Hmac(sha256, cipher.mac).convert(authenticated).bytes,
    );
    return sealed;
  }

  /// Verifies every authenticated byte before returning any plaintext.
  Uint8List open(Uint8List sealed, Uint8List key) {
    if (sealed.length < _headerLength + _tagLength) {
      throw const FormatException('short');
    }
    final Uint8List header = sealed.sublist(0, _headerLength);
    final int length = _length(header);
    if (sealed.length != _headerLength + length + _tagLength) {
      throw const FormatException('length');
    }
    final ({Aes aes, Uint8List mac}) cipher = _cipher(key, header);
    final Uint8List authenticated = Uint8List.sublistView(
      sealed,
      0,
      sealed.length - _tagLength,
    );
    final Uint8List tag = Uint8List.sublistView(
      sealed,
      sealed.length - _tagLength,
    );
    if (!_same(tag, Hmac(sha256, cipher.mac).convert(authenticated).bytes)) {
      throw const FormatException('authentication');
    }
    final Uint8List body = sealed.sublist(
      _headerLength,
      sealed.length - _tagLength,
    );
    cipher.aes.processData(body, 0, body.length);
    return body;
  }

  /// Preserves the native counter format while yielding between aligned chunks.
  /// Browser HMAC runs through WebCrypto rather than blocking the event loop.
  Future<Uint8List> sealAsync(
    Uint8List plain,
    Uint8List key, {
    CancellationToken? cancel,
  }) async {
    _check(cancel);
    final Uint8List header = _header(plain.length);
    final ({Aes aes, Uint8List mac}) cipher = _cipher(key, header);
    final Uint8List sealed = Uint8List(sealedLength(plain.length))
      ..setAll(0, header)
      ..setAll(_headerLength, plain);
    final int tagOffset = _headerLength + plain.length;
    await _transform(
      cipher.aes,
      Uint8List.sublistView(sealed, _headerLength, tagOffset),
      cancel,
    );
    final Uint8List tag = await authenticatedHmac(
      cipher.mac,
      Uint8List.sublistView(sealed, 0, tagOffset),
      cancel: cancel,
    );
    _check(cancel);
    sealed.setAll(tagOffset, tag);
    return sealed;
  }

  /// Authenticates before copying ciphertext or decrypting. Reauthentication of
  /// the owned snapshot prevents mutation of a caller's buffer during an await.
  Future<Uint8List> openAsync(
    Uint8List sealed,
    Uint8List key, {
    CancellationToken? cancel,
  }) async {
    _check(cancel);
    if (sealed.length < _headerLength + _tagLength) {
      throw const FormatException('short');
    }
    final Uint8List header = sealed.sublist(0, _headerLength);
    final int length = _length(header);
    final int tagOffset = _headerLength + length;
    if (sealed.length != tagOffset + _tagLength) {
      throw const FormatException('length');
    }
    final ({Aes aes, Uint8List mac}) cipher = _cipher(key, header);
    final Uint8List expected = sealed.sublist(tagOffset);
    final Uint8List actual = await authenticatedHmac(
      cipher.mac,
      Uint8List.sublistView(sealed, 0, tagOffset),
      cancel: cancel,
    );
    _check(cancel);
    if (!_same(expected, actual)) {
      throw const FormatException('authentication');
    }
    final Uint8List snapshot = sealed.sublist(0, tagOffset);
    final Uint8List snapshotMac = await authenticatedHmac(
      cipher.mac,
      snapshot,
      cancel: cancel,
    );
    _check(cancel);
    if (!_same(expected, snapshotMac)) {
      throw const FormatException('authentication');
    }
    final Uint8List body = Uint8List.sublistView(snapshot, _headerLength);
    await _transform(cipher.aes, body, cancel);
    return body;
  }

  Future<void> _transform(
    Aes cipher,
    Uint8List bytes,
    CancellationToken? cancel,
  ) async {
    // Intermediate chunks are block-aligned so the maintained AES counter
    // advances identically to one synchronous call, including the last tail.
    final int chunkBytes = AppConstants.hashing.chunkBytes & ~15;
    for (int offset = 0; offset < bytes.length; offset += chunkBytes) {
      await Future<void>.delayed(Duration.zero);
      _check(cancel);
      final int end = min(offset + chunkBytes, bytes.length);
      final Uint8List chunk = Uint8List.sublistView(bytes, offset, end);
      cipher.processData(chunk, 0, chunk.length);
    }
    _check(cancel);
  }

  void _check(CancellationToken? cancel) {
    if (cancel?.isCancelled ?? false) {
      throw const CancelledFailure();
    }
  }

  /// Seals [source] off the UI isolate. Failure removes only [target].
  void sealFile(
    File source,
    File target,
    Uint8List key, {
    void Function()? check,
    void Function(double)? onProgress,
  }) {
    _validateTarget(source, target);
    onProgress?.call(0);
    final RandomAccessFile input = source.openSync();
    RandomAccessFile? output;
    var created = false;
    try {
      final Uint8List header = _header(input.lengthSync());
      final ({Aes aes, Uint8List mac}) cipher = _cipher(key, header);
      final _DigestSink digest = _DigestSink();
      final ByteConversionSink mac = Hmac(
        sha256,
        cipher.mac,
      ).startChunkedConversion(digest);
      check?.call();
      target.createSync(exclusive: true);
      created = true;
      output = target.openSync(mode: FileMode.write);
      output.writeFromSync(header);
      mac.add(header);
      final Uint8List buffer = Uint8List(AppConstants.hashing.chunkBytes & ~15);
      var remaining = _length(header);
      while (remaining > 0) {
        check?.call();
        final int count = _readChunk(
          input,
          buffer,
          min(buffer.length, remaining),
        );
        final Uint8List bytes = Uint8List.sublistView(buffer, 0, count);
        cipher.aes.processData(bytes, 0, count);
        mac.add(bytes);
        output.writeFromSync(bytes);
        remaining -= count;
        onProgress?.call(
          (_length(header) - remaining) / max(1, _length(header)),
        );
      }
      mac.close();
      output.writeFromSync(digest.value.bytes);
      output.flushSync();
      onProgress?.call(1);
    } on Object {
      output?.closeSync();
      output = null;
      if (created && target.existsSync()) {
        target.deleteSync();
      }
      rethrow;
    } finally {
      input.closeSync();
      output?.closeSync();
    }
  }

  /// Authenticates [source] completely before creating [target]. A second MAC
  /// during decryption detects an in-place source change between the two passes.
  void openFile(
    File source,
    File target,
    Uint8List key, {
    void Function()? check,
    void Function(double)? onProgress,
  }) {
    _validateTarget(source, target);
    onProgress?.call(0);
    final RandomAccessFile input = source.openSync();
    RandomAccessFile? output;
    var created = false;
    try {
      final ({
        Uint8List header,
        int length,
        Uint8List tag,
        Aes aes,
        Uint8List mac,
      })
      verified = _authenticate(
        input,
        key,
        check: check,
        onProgress: (double progress) => onProgress?.call(progress / 2),
      );
      final Uint8List header = verified.header;
      final int length = verified.length;
      final Uint8List tag = verified.tag;
      final ({Aes aes, Uint8List mac}) cipher = (
        aes: verified.aes,
        mac: verified.mac,
      );
      final Uint8List buffer = Uint8List(AppConstants.hashing.chunkBytes & ~15);
      var remaining = length;
      check?.call();
      input.setPositionSync(_headerLength);
      target.createSync(exclusive: true);
      created = true;
      output = target.openSync(mode: FileMode.write);
      final _DigestSink replay = _DigestSink();
      final ByteConversionSink replayMac = Hmac(
        sha256,
        cipher.mac,
      ).startChunkedConversion(replay)..add(header);
      remaining = length;
      while (remaining > 0) {
        check?.call();
        final int count = _readChunk(
          input,
          buffer,
          min(buffer.length, remaining),
        );
        final Uint8List bytes = Uint8List.sublistView(buffer, 0, count);
        replayMac.add(bytes);
        cipher.aes.processData(bytes, 0, count);
        output.writeFromSync(bytes);
        remaining -= count;
        onProgress?.call(0.5 + (length - remaining) / max(1, length) / 2);
      }
      replayMac.close();
      if (!_same(tag, replay.value.bytes)) {
        throw const FormatException('changed source');
      }
      output.flushSync();
      onProgress?.call(1);
    } on Object {
      output?.closeSync();
      output = null;
      if (created && target.existsSync()) {
        target.deleteSync();
      }
      rethrow;
    } finally {
      input.closeSync();
      output?.closeSync();
    }
  }

  /// Verifies the complete protected source without creating plaintext.
  void verifyFile(
    File source,
    Uint8List key, {
    void Function()? check,
    void Function(double)? onProgress,
  }) {
    onProgress?.call(0);
    final RandomAccessFile input = source.openSync();
    try {
      _authenticate(input, key, check: check, onProgress: onProgress);
      onProgress?.call(1);
    } finally {
      input.closeSync();
    }
  }

  ({Uint8List header, int length, Uint8List tag, Aes aes, Uint8List mac})
  _authenticate(
    RandomAccessFile input,
    Uint8List key, {
    void Function()? check,
    void Function(double)? onProgress,
  }) {
    final Uint8List header = input.readSync(_headerLength);
    final int length = _length(header);
    if (input.lengthSync() != _headerLength + length + _tagLength) {
      throw const FormatException('length');
    }
    final ({Aes aes, Uint8List mac}) cipher = _cipher(key, header);
    final Uint8List buffer = Uint8List(AppConstants.hashing.chunkBytes & ~15);
    final _DigestSink authentication = _DigestSink();
    final ByteConversionSink verify = Hmac(
      sha256,
      cipher.mac,
    ).startChunkedConversion(authentication)..add(header);
    var remaining = length;
    while (remaining > 0) {
      check?.call();
      final int count = _readChunk(
        input,
        buffer,
        min(buffer.length, remaining),
      );
      verify.add(Uint8List.sublistView(buffer, 0, count));
      remaining -= count;
      onProgress?.call((length - remaining) / max(1, length));
    }
    verify.close();
    final Uint8List tag = input.readSync(_tagLength);
    if (!_same(tag, authentication.value.bytes)) {
      throw const FormatException('authentication');
    }
    return (
      header: header,
      length: length,
      tag: tag,
      aes: cipher.aes,
      mac: cipher.mac,
    );
  }

  void _validateTarget(File source, File target) {
    final String sourcePath = source.absolute.path;
    final String targetPath = target.absolute.path;
    if ((Platform.isWindows
            ? sourcePath.toLowerCase() == targetPath.toLowerCase()
            : sourcePath == targetPath) ||
        target.existsSync()) {
      throw const FileSystemException('Encryption needs a fresh target path.');
    }
  }

  int _readChunk(RandomAccessFile input, Uint8List buffer, int wanted) {
    var count = 0;
    while (count < wanted) {
      final int received = input.readIntoSync(buffer, count, wanted);
      if (received == 0) {
        throw const FormatException('truncated');
      }
      count += received;
    }
    return count;
  }

  Uint8List _header(int length) {
    if (magic.codeUnits.length != 8 || length < 0 || length > 16 * 0xffffffff) {
      throw const FormatException('format');
    }
    final Random random = Random.secure();
    final Uint8List bytes = Uint8List(_headerLength)
      ..setAll(0, ascii.encode(magic));
    bytes.setAll(8, <int>[
      for (var i = 0; i < _nonceLength; i++) random.nextInt(256),
    ]);
    ByteData.sublistView(bytes).setUint64(24, length, Endian.big);
    return bytes;
  }

  int _length(Uint8List header) {
    if (header.length != _headerLength ||
        !_same(header.sublist(0, 8), ascii.encode(magic))) {
      throw const FormatException('magic');
    }
    final int length = ByteData.sublistView(header).getUint64(24, Endian.big);
    // The maintained AES-CTR implementation uses a 32-bit block counter.
    if (length > 16 * 0xffffffff) {
      throw const FormatException('length');
    }
    return length;
  }

  ({Aes aes, Uint8List mac}) _cipher(Uint8List key, Uint8List header) {
    if (key.length != 32) {
      throw const FormatException('key length');
    }
    final List<int> domain = <int>[...utf8.encode(purpose), 0, ...header];
    final Uint8List encryption = Uint8List.fromList(
      Hmac(
        sha256,
        key,
      ).convert(<int>[...ascii.encode('encryption'), 0, ...domain]).bytes,
    );
    final Uint8List mac = Uint8List.fromList(
      Hmac(
        sha256,
        key,
      ).convert(<int>[...ascii.encode('authentication'), 0, ...domain]).bytes,
    );
    // The random nonce is incorporated into the AES key, so fixed CTR counter
    // 1 cannot repeat for two files sealed with the same master key.
    return (aes: Aes(encryption, mac, 32, encrypt: true), mac: mac);
  }

  bool _same(List<int> left, List<int> right) {
    if (left.length != right.length) {
      return false;
    }
    var difference = 0;
    for (var i = 0; i < left.length; i++) {
      difference |= left[i] ^ right[i];
    }
    return difference == 0;
  }
}

final class _DigestSink implements Sink<Digest> {
  late Digest value;
  @override
  void add(Digest digest) => value = digest;
  @override
  void close() {}
}
