import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';

/// Seals a bundle with a password. The password and the derived key are
/// not stored. A wrong password fails before any plaintext is returned.
///
/// The seal is PBKDF2-HMAC-SHA256 and an HMAC-SHA256 keystream, then an
/// HMAC over the ciphertext. The salt and nonce sit in the header.
final class BundleEncryption {
  /// Encrypts [plain]. The header carries the salt, never the password.
  Uint8List seal(Uint8List plain, String password) {
    final Random random = Random.secure();
    final Uint8List salt = _random(random, 16);
    final Uint8List nonce = _random(random, 16);
    final ({Uint8List stream, Uint8List mac}) keys = _keys(password, salt);
    final Uint8List cipher = _xor(
      plain,
      _keystream(keys.stream, nonce, plain.length),
    );
    final Uint8List tag = _mac(keys.mac, cipher);
    final BytesBuilder out = BytesBuilder();
    out.add(_magic);
    out.add(salt);
    out.add(nonce);
    out.add(tag);
    out.add(cipher);
    return out.toBytes();
  }

  /// Decrypts [sealed]. A wrong password throws [ValidationFailure] and
  /// returns nothing.
  Uint8List open(Uint8List sealed, String password) {
    if (sealed.length < _header || !_starts(sealed)) {
      throw const ValidationFailure(
        message: 'That bundle could not be opened.',
        recoveryAction: 'Choose the bundle file again.',
      );
    }
    final Uint8List salt = sealed.sublist(4, 20);
    final Uint8List nonce = sealed.sublist(20, 36);
    final Uint8List tag = sealed.sublist(36, 68);
    final Uint8List cipher = sealed.sublist(_header);
    final ({Uint8List stream, Uint8List mac}) keys = _keys(password, salt);
    final Uint8List expected = _mac(keys.mac, cipher);
    if (!_same(tag, expected)) {
      throw const ValidationFailure(
        message: 'That password did not open the bundle.',
        recoveryAction: 'Try the password again. Nothing was extracted.',
      );
    }
    return _xor(cipher, _keystream(keys.stream, nonce, cipher.length));
  }

  static const List<int> _magic = <int>[84, 65, 80, 84];
  static const int _header = 68;

  ({Uint8List stream, Uint8List mac}) _keys(String password, Uint8List salt) {
    final Uint8List material = _pbkdf2(
      utf8.encode(password),
      salt,
      AppConstants.bundleSeal.iterations,
      64,
    );
    return (stream: material.sublist(0, 32), mac: material.sublist(32));
  }

  Uint8List _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int length,
  ) {
    final Hmac hmac = Hmac(sha256, password);
    final BytesBuilder out = BytesBuilder();
    final int blocks = (length + 31) ~/ 32;
    for (var block = 1; block <= blocks; block++) {
      List<int> u = hmac.convert(<int>[
        ...salt,
        block >> 24,
        (block >> 16) & 255,
        (block >> 8) & 255,
        block & 255,
      ]).bytes;
      final List<int> mixed = List<int>.of(u);
      for (var round = 1; round < iterations; round++) {
        u = hmac.convert(u).bytes;
        for (var i = 0; i < mixed.length; i++) {
          mixed[i] ^= u[i];
        }
      }
      out.add(mixed);
    }
    return Uint8List.fromList(out.toBytes().sublist(0, length));
  }

  Uint8List _keystream(Uint8List key, Uint8List nonce, int length) {
    final Hmac hmac = Hmac(sha256, key);
    final BytesBuilder out = BytesBuilder();
    var counter = 0;
    while (out.length < length) {
      out.add(
        hmac.convert(<int>[
          ...nonce,
          counter >> 24,
          (counter >> 16) & 255,
          (counter >> 8) & 255,
          counter & 255,
        ]).bytes,
      );
      counter += 1;
    }
    return Uint8List.fromList(out.toBytes().sublist(0, length));
  }

  Uint8List _mac(Uint8List key, Uint8List cipher) {
    return Uint8List.fromList(Hmac(sha256, key).convert(cipher).bytes);
  }

  Uint8List _xor(Uint8List left, Uint8List right) {
    final Uint8List out = Uint8List(left.length);
    for (var i = 0; i < left.length; i++) {
      out[i] = left[i] ^ right[i];
    }
    return out;
  }

  Uint8List _random(Random random, int length) {
    return Uint8List.fromList(<int>[
      for (var i = 0; i < length; i++) random.nextInt(256),
    ]);
  }

  bool _starts(Uint8List bytes) {
    for (var i = 0; i < _magic.length; i++) {
      if (bytes[i] != _magic[i]) {
        return false;
      }
    }
    return true;
  }

  bool _same(Uint8List left, Uint8List right) {
    if (left.length != right.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < left.length; i++) {
      diff |= left[i] ^ right[i];
    }
    return diff == 0;
  }
}
