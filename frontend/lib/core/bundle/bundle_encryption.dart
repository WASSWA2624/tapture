import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/security/authenticated_file_cipher.dart';

import 'bundle_password_key.dart';
import 'bundle_pbkdf2.dart';

/// Password encryption for project bundles. A random salt derives a key with
/// PBKDF2-HMAC-SHA256; authenticated AES-256 encryption stores no secret.
final class BundleEncryption {
  static const String _magic = 'TAPBND03';
  static const String _legacyMagic = 'TAPBND02';
  static const int _headerLength = 28;
  static const AuthenticatedFileCipher _cipher = AuthenticatedFileCipher(
    magic: 'TAPBND03',
    purpose: 'project bundle',
  );
  static const AuthenticatedFileCipher _legacyCipher = AuthenticatedFileCipher(
    magic: 'TAPBND02',
    purpose: 'project bundle',
  );

  /// Ciphertext size for relay preflight, including both authenticated headers.
  static int sealedLength(int plainLength) =>
      _headerLength + AuthenticatedFileCipher.sealedLength(plainLength);

  /// Whether a picked file needs a password before inspection.
  static bool isSealed(List<int> bytes) =>
      _hasMagic(bytes, _magic) || _hasMagic(bytes, _legacyMagic);

  /// Encrypts bounded bytes on a worker. UI callers use [sealAsync].
  Uint8List seal(Uint8List plain, String password) {
    final Uint8List header = _header();
    return _join(header, _cipher.seal(plain, _key(password, _parse(header))));
  }

  /// Authenticates all content before returning any decrypted bytes.
  Uint8List open(Uint8List sealed, String password) {
    try {
      final _PasswordHeader header = _parse(sealed);
      _requireBody(sealed.length, header);
      return header.cipher.open(
        Uint8List.sublistView(sealed, header.length),
        _key(password, header),
      );
    } on Object {
      throw _wrongPassword;
    }
  }

  /// Derives the password key off-thread or through asynchronous WebCrypto.
  Future<Uint8List> sealAsync(
    Uint8List plain,
    String password, {
    CancellationToken? cancel,
  }) async {
    if (!kIsWeb) {
      return (await runIsolate<(Uint8List, String), Uint8List>(_sealBytes, (
        plain,
        password,
      ), cancel: cancel)).getOrThrow();
    }
    final Uint8List header = _header();
    final _PasswordHeader parsed = _parse(header);
    final Uint8List key = await bundlePasswordKey(
      password,
      parsed.salt,
      parsed.iterations,
      cancel: cancel,
    );
    if (cancel?.isCancelled ?? false) {
      throw const CancelledFailure();
    }
    return _join(header, await _cipher.sealAsync(plain, key, cancel: cancel));
  }

  /// Authenticates before returning plaintext, including legacy v2 packages.
  Future<Uint8List> openAsync(
    Uint8List sealed,
    String password, {
    CancellationToken? cancel,
  }) async {
    if (!kIsWeb) {
      return (await runIsolate<(Uint8List, String), Uint8List>(_openBytes, (
        sealed,
        password,
      ), cancel: cancel)).getOrThrow();
    }
    try {
      final _PasswordHeader header = _parse(sealed);
      _requireBody(sealed.length, header);
      final Uint8List key = await bundlePasswordKey(
        password,
        header.salt,
        header.iterations,
        cancel: cancel,
      );
      if (cancel?.isCancelled ?? false) {
        throw const CancelledFailure();
      }
      return await header.cipher.openAsync(
        Uint8List.sublistView(sealed, header.length),
        key,
        cancel: cancel,
      );
    } on CancelledFailure {
      rethrow;
    } on Object {
      throw _wrongPassword;
    }
  }

  /// Seals a native ZIP in bounded chunks. Call on a worker isolate.
  void sealFile(
    File source,
    File target,
    String password, {
    void Function()? check,
  }) {
    final Uint8List header = _header();
    final File cipher = File('${target.path}.cipher');
    if (target.existsSync() ||
        cipher.existsSync() ||
        source.absolute.path.toLowerCase() ==
            target.absolute.path.toLowerCase()) {
      throw const FileSystemException('Encryption needs fresh target paths.');
    }
    var created = false;
    try {
      check?.call();
      _cipher.sealFile(
        source,
        cipher,
        _key(password, _parse(header), check: check),
        check: check,
      );
      final RandomAccessFile input = cipher.openSync();
      try {
        final RandomAccessFile output = target.openSync(mode: FileMode.write);
        created = true;
        try {
          output.writeFromSync(header);
          _copy(input, output, check: check);
        } finally {
          output.closeSync();
        }
      } finally {
        input.closeSync();
      }
    } on Object {
      if (created && target.existsSync()) {
        target.deleteSync();
      }
      rethrow;
    } finally {
      if (cipher.existsSync()) {
        cipher.deleteSync();
      }
    }
  }

  /// Verifies a native bundle before creating plaintext. Neither a wrong
  /// password nor a modified file leaves [target] behind.
  void openFile(
    File source,
    File target,
    String password, {
    void Function()? check,
  }) {
    final File cipher = File('${target.path}.cipher');
    if (target.existsSync() ||
        cipher.existsSync() ||
        source.absolute.path.toLowerCase() ==
            target.absolute.path.toLowerCase()) {
      throw const FileSystemException('Encryption needs fresh target paths.');
    }
    try {
      final RandomAccessFile input = source.openSync();
      try {
        final _PasswordHeader header = _parse(input.readSync(_headerLength));
        _requireBody(input.lengthSync(), header);
        check?.call();
        // Reject an untrusted work factor before copying or deriving any key.
        final Uint8List key = _key(password, header, check: check);
        input.setPositionSync(header.length);
        final RandomAccessFile output = cipher.openSync(mode: FileMode.write);
        try {
          _copy(input, output, check: check);
        } finally {
          output.closeSync();
        }
        header.cipher.openFile(cipher, target, key, check: check);
      } finally {
        input.closeSync();
      }
    } on FormatException {
      throw _wrongPassword;
    } finally {
      if (cipher.existsSync()) {
        cipher.deleteSync();
      }
    }
  }

  void _copy(
    RandomAccessFile input,
    RandomAccessFile output, {
    void Function()? check,
  }) {
    final Uint8List buffer = Uint8List(AppConstants.hashing.chunkBytes);
    while (true) {
      check?.call();
      final int count = input.readIntoSync(buffer);
      if (count == 0) {
        break;
      }
      output.writeFromSync(buffer, 0, count);
    }
    output.flushSync();
  }

  Uint8List _header() {
    final Random random = Random.secure();
    final Uint8List header = Uint8List(_headerLength)
      ..setAll(0, ascii.encode(_magic))
      ..setAll(8, <int>[for (var i = 0; i < 16; i++) random.nextInt(256)]);
    ByteData.sublistView(
      header,
    ).setUint32(24, AppConstants.bundleSeal.iterations, Endian.big);
    return header;
  }

  Uint8List _key(
    String password,
    _PasswordHeader header, {
    void Function()? check,
  }) => bundlePbkdf2(password, header.salt, header.iterations, check: check);

  Uint8List _join(Uint8List header, Uint8List cipher) =>
      Uint8List(header.length + cipher.length)
        ..setAll(0, header)
        ..setAll(header.length, cipher);

  void _requireBody(int length, _PasswordHeader header) {
    if (length < header.length + AuthenticatedFileCipher.sealedLength(0)) {
      throw const FormatException('truncated');
    }
  }

  _PasswordHeader _parse(Uint8List bytes) {
    final bool legacy = _hasMagic(bytes, _legacyMagic);
    final int length = legacy ? 24 : _headerLength;
    if (bytes.length < length || (!legacy && !_hasMagic(bytes, _magic))) {
      throw const FormatException('header');
    }
    final int iterations = legacy
        ? 1000
        : ByteData.sublistView(bytes).getUint32(24, Endian.big);
    if (!legacy &&
        (iterations < AppConstants.bundleSeal.iterations ||
            iterations > AppConstants.bundleSeal.maxIterations)) {
      throw const FormatException('work factor');
    }
    return (
      length: length,
      salt: Uint8List.sublistView(bytes, 8, 24),
      iterations: iterations,
      cipher: legacy ? _legacyCipher : _cipher,
    );
  }

  static bool _hasMagic(List<int> bytes, String magic) {
    if (bytes.length < magic.length) {
      return false;
    }
    for (int index = 0; index < magic.length; index++) {
      if (bytes[index] != magic.codeUnitAt(index)) {
        return false;
      }
    }
    return true;
  }

  static final ValidationFailure _wrongPassword = ValidationFailure(
    localizedMessage: Copy.messages.failureThatPasswordDidNotOpenTheBundle,
    localizedRecovery:
        Copy.messages.failureTryThePasswordAgainNothingWasExtracted,
  );
}

typedef _PasswordHeader = ({
  int length,
  Uint8List salt,
  int iterations,
  AuthenticatedFileCipher cipher,
});

Uint8List _sealBytes((Uint8List, String) input) =>
    BundleEncryption().seal(input.$1, input.$2);

Uint8List _openBytes((Uint8List, String) input) =>
    BundleEncryption().open(input.$1, input.$2);
