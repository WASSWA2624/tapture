import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/security/authenticated_file_cipher.dart';

void main() {
  const AuthenticatedFileCipher cipher = AuthenticatedFileCipher(
    magic: 'TAPTEST2',
    purpose: 'fixture',
  );
  final Uint8List key = Uint8List.fromList(
    List<int>.generate(32, (int i) => i),
  );

  test(
    'a Node AES-256 ECB counter fixture opens independently of the sealing implementation',
    () {
      // Generated using Node's maintained crypto AES-256-ECB over CTR blocks.
      final Uint8List header = Uint8List(32)
        ..setAll(0, ascii.encode('TAPTEST2'))
        ..setAll(8, List<int>.generate(16, (int i) => i));
      ByteData.sublistView(header).setUint64(24, 20, Endian.big);
      final Uint8List fixture = Uint8List.fromList(<int>[
        ...header,
        ..._hex('f05cb8d67800ab7a4c827ac11a97b2dcc3975fef'),
        ..._hex(
          '6146c585c0ad566eb2d4923f462f9f15dd0c62279bdd4004d851fc152c87b984',
        ),
      ]);
      expect(utf8.decode(cipher.open(fixture, key)), 'independent AES test');
    },
  );

  test(
    'cooperative bytes match native counter chunks and reject tampering',
    () async {
      final Uint8List plain = Uint8List(
        AppConstants.hashing.chunkBytes * 2 + 19,
      )..fillRange(0, AppConstants.hashing.chunkBytes * 2 + 19, 41);
      final Uint8List sealed = await cipher.sealAsync(plain, key);
      expect(cipher.open(sealed, key), plain);
      expect(await cipher.openAsync(cipher.seal(plain, key), key), plain);
      final Uint8List changed = Uint8List.fromList(sealed)..[32] ^= 1;
      await expectLater(cipher.openAsync(changed, key), throwsFormatException);
      final CancellationToken cancel = CancellationToken()..cancel();
      await expectLater(
        cipher.sealAsync(plain, key, cancel: cancel),
        throwsA(isA<CancelledFailure>()),
      );
      expect(cancel.debugListenerCount, 0);
    },
  );

  test(
    'two-word lengths preserve empty envelopes and reject malformed bounds',
    () async {
      final Uint8List empty = await cipher.sealAsync(Uint8List(0), key);
      expect(empty.sublist(24, 32), orderedEquals(List<int>.filled(8, 0)));
      expect(cipher.open(empty, key), isEmpty);
      expect(await cipher.openAsync(empty, key), isEmpty);

      final Uint8List original = cipher.seal(Uint8List(20), key);
      final Matcher invalidLength = throwsA(
        isA<FormatException>().having(
          (FormatException error) => error.message,
          'message',
          'length',
        ),
      );
      for (final ({int high, int low}) declared in <({int high, int low})>[
        (high: 0, low: 0xffffffff),
        (high: 1, low: 20),
        (high: 15, low: 0xffffffef),
        (high: 15, low: 0xfffffff0),
        (high: 15, low: 0xfffffff1),
        (high: 16, low: 20),
        (high: 0x40000000, low: 20),
        (high: 0xffffffff, low: 0xffffffff),
      ]) {
        final Uint8List changed = Uint8List.fromList(original);
        final ByteData header = ByteData.sublistView(changed);
        header.setUint32(24, declared.high, Endian.big);
        header.setUint32(28, declared.low, Endian.big);
        final Uint8List retained = Uint8List.fromList(changed);
        expect(() => cipher.open(changed, key), invalidLength);
        await expectLater(cipher.openAsync(changed, key), invalidLength);
        expect(changed, orderedEquals(retained));
      }
    },
  );

  test('byte and bounded file APIs agree across an unaligned final chunk', () {
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture-cipher-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final Uint8List plain = Uint8List.fromList(
      List<int>.generate(
        AppConstants.hashing.chunkBytes * 2 + 19,
        (int i) => i & 255,
      ),
    );
    final File source = File('${directory.path}/source')
      ..writeAsBytesSync(plain);
    final File sealed = File('${directory.path}/sealed');
    final File opened = File('${directory.path}/opened');
    final List<double> progress = <double>[];
    cipher.sealFile(source, sealed, key, onProgress: progress.add);
    expect(cipher.open(sealed.readAsBytesSync(), key), plain);
    expect(progress.first, 0);
    expect(progress.last, 1);
    cipher.openFile(sealed, opened, key);
    expect(opened.readAsBytesSync(), plain);
    final File bytesSealed = File('${directory.path}/bytes')
      ..writeAsBytesSync(cipher.seal(plain, key));
    cipher.openFile(bytesSealed, File('${directory.path}/from-bytes'), key);
    expect(File('${directory.path}/from-bytes').readAsBytesSync(), plain);
    cipher.verifyFile(sealed, key);
  });

  test(
    'wrong keys and modified header body or tag fail before plaintext exists',
    () {
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture-cipher-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final Uint8List original = cipher.seal(
        Uint8List.fromList(utf8.encode('private project evidence')),
        key,
      );
      final File source = File('${directory.path}/sealed');
      final File target = File('${directory.path}/opened');
      final Uint8List wrong = Uint8List.fromList(key)..[0] ^= 1;
      source.writeAsBytesSync(original);
      expect(
        () => cipher.openFile(source, target, wrong),
        throwsFormatException,
      );
      expect(target.existsSync(), isFalse);
      expect(() => cipher.verifyFile(source, wrong), throwsFormatException);
      for (final int position in <int>[8, 24, 32, original.length - 1]) {
        final Uint8List changed = Uint8List.fromList(original)..[position] ^= 1;
        source.writeAsBytesSync(changed);
        expect(
          () => cipher.openFile(source, target, key),
          throwsFormatException,
        );
        expect(target.existsSync(), isFalse);
      }
    },
  );

  test('existing targets and identical paths stay intact on refusal', () {
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture-cipher-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final File source = File('${directory.path}/source')
      ..writeAsBytesSync(cipher.seal(Uint8List.fromList(<int>[1, 2, 3]), key));
    final File target = File('${directory.path}/target')
      ..writeAsStringSync('retained');
    final List<int> before = source.readAsBytesSync();
    expect(
      () => cipher.openFile(source, target, key),
      throwsA(isA<FileSystemException>()),
    );
    expect(target.readAsStringSync(), 'retained');
    expect(
      () => cipher.sealFile(source, source, key),
      throwsA(isA<FileSystemException>()),
    );
    expect(source.readAsBytesSync(), before);
  });

  test(
    'a target appearing after preflight is never overwritten or removed',
    () {
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture-cipher-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final File plain = File('${directory.path}/plain')
        ..writeAsStringSync('source evidence');
      final File sealed = File('${directory.path}/sealed')
        ..writeAsBytesSync(cipher.seal(plain.readAsBytesSync(), key));
      for (final bool opening in <bool>[false, true]) {
        final File target = File('${directory.path}/target-$opening');
        void claimTarget(double progress) {
          if (progress == 0) {
            target.writeAsStringSync('retained concurrent output');
          }
        }

        expect(
          () => opening
              ? cipher.openFile(sealed, target, key, onProgress: claimTarget)
              : cipher.sealFile(plain, target, key, onProgress: claimTarget),
          throwsA(isA<FileSystemException>()),
        );
        expect(target.readAsStringSync(), 'retained concurrent output');
        expect(plain.readAsStringSync(), 'source evidence');
      }
    },
  );

  test(
    'cancellation removes the unpublished output and preserves the source',
    () {
      final Directory directory = Directory.systemTemp.createTempSync(
        'tapture-cipher-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final File source = File('${directory.path}/source')
        ..writeAsBytesSync(
          List<int>.filled(AppConstants.hashing.chunkBytes * 2, 7),
        );
      final File target = File('${directory.path}/target');
      var checks = 0;
      expect(
        () => cipher.sealFile(
          source,
          target,
          key,
          check: () {
            if (++checks == 3) {
              throw const CancelledFailure();
            }
          },
        ),
        throwsA(isA<CancelledFailure>()),
      );
      expect(target.existsSync(), isFalse);
      expect(source.lengthSync(), AppConstants.hashing.chunkBytes * 2);
    },
  );
}

List<int> _hex(String hex) => <int>[
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
];
