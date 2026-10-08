import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/encryption.dart';
import 'package:tapture/core/db/tables/projects.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/security/secure_storage.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late Directory directory;
  late Map<SecretKey, String> backing;
  late SecureStorage storage;
  late DatabaseEncryption encryption;
  late UuidV7Service ids;
  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);

  setUp(() {
    directory = Directory.systemTemp.createTempSync('tapture_enc_');
    backing = <SecretKey, String>{};
    storage = SecureStorage.fake(backing: backing);
    encryption = DatabaseEncryption(storage: storage, directory: directory);
    ids = UuidV7Service.sequence(FixedClock(t0));
  });

  tearDown(() {
    if (directory.existsSync()) {
      try {
        directory.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows can keep a handle for a moment after sqlite3.dispose.
      }
    }
  });

  test(
    'a leftover working database never bypasses a missing encryption key',
    () async {
      final AppDatabase plain = AppDatabase.open(directoryPath: directory.path);
      await plain.customSelect('SELECT 1').get();
      await plain.close();
      final File working = File('${directory.path}/tapture.sqlite');
      final List<int> original = working.readAsBytesSync();
      File('${directory.path}/tapture.encryption').writeAsStringSync('enabled');

      await expectLater(
        resolveFileExecutor(directory: directory),
        throwsA(isA<StorageFailure>()),
      );
      expect(working.readAsBytesSync(), original);
      expect(_ok(await encryption.isEnabled()), isTrue);
    },
  );

  test(
    'a crash survivor rejects a wrong key without changing either copy',
    () async {
      final File working = File('${directory.path}/tapture.sqlite');
      final Database raw = sqlite3.open(working.path);
      raw.execute('CREATE TABLE evidence (value TEXT);');
      raw.execute("INSERT INTO evidence VALUES ('kept');");
      raw.close();
      final List<int> plain = await working.readAsBytes();
      _ok(await encryption.enable(onProgress: (double _) {}));
      final File encrypted = File('${directory.path}/tapture.sqlite.enc');
      final List<int> protected = await encrypted.readAsBytes();
      await working.writeAsBytes(plain, flush: true);
      await expectLater(
        resolveFileExecutor(directory: directory, encryptionKey: 'ff' * 32),
        throwsA(isA<StorageFailure>()),
      );
      expect(await working.readAsBytes(), plain);
      expect(await encrypted.readAsBytes(), protected);
      final AppDatabase recovered = AppDatabase.open(
        directoryPath: directory.path,
        encryptionKey: backing[SecretKey.databaseEncryption],
      );
      expect(
        (await recovered.customSelect('SELECT value FROM evidence').getSingle())
            .read<String>('value'),
        'kept',
      );
      await recovered.close();
      expect(await working.exists(), isFalse);
    },
  );

  test(
    'a historical encrypted database opens and upgrades without losing evidence',
    () async {
      const String key =
          'abababababababababababababababababababababababababababababababab';
      final File working = File('${directory.path}/tapture.sqlite');
      final Database raw = sqlite3.open(working.path);
      raw.execute('CREATE TABLE evidence (value TEXT);');
      raw.execute("INSERT INTO evidence VALUES ('legacy evidence');");
      raw.close();
      final File encrypted = File('${directory.path}/tapture.sqlite.enc');
      await encrypted.writeAsBytes(
        _legacyEnvelope(
          await working.readAsBytes(),
          List<int>.filled(32, 0xab),
        ),
        flush: true,
      );
      await working.delete();
      await File(
        '${directory.path}/tapture.encryption',
      ).writeAsString('enabled');
      backing[SecretKey.databaseEncryption] = key;
      final AppDatabase recovered = AppDatabase.open(
        directoryPath: directory.path,
        encryptionKey: key,
      );
      expect(
        (await recovered.customSelect('SELECT value FROM evidence').getSingle())
            .read<String>('value'),
        'legacy evidence',
      );
      await recovered.close();
      expect(
        (await encrypted.readAsBytes()).sublist(0, 8),
        'TAPENC02'.codeUnits,
      );
      expect(await working.exists(), isFalse);
    },
  );

  test(
    'an encrypted file fails without the key and opens with it; counts '
    'survive enable and disable; an interrupted enable is resumable',
    () async {
      final AppDatabase seeded = AppDatabase.open(
        directoryPath: directory.path,
      );
      await seeded.customSelect('SELECT 1').get();
      _ok(
        await upsertProject(
          seeded,
          row: _project('Alpha', 'alpha-1'),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      _ok(
        await upsertProject(
          seeded,
          row: _project('Beta', 'beta-1'),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final Map<String, int> before = await _rowCounts(seeded);
      expect(before['projects'], 2);
      await seeded.close();

      File(
        '${directory.path}/tapture.sqlite.enc.partial',
      ).writeAsBytesSync(List<int>.filled(24, 7));
      File(
        '${directory.path}/tapture.encryption',
      ).writeAsStringSync('enabling');

      final List<double> progress = <double>[];
      _ok(await encryption.enable(onProgress: progress.add));
      expect(progress.first, 0);
      expect(progress.last, 1);
      expect(_ok(await encryption.isEnabled()), isTrue);
      expect(File('${directory.path}/tapture.sqlite').existsSync(), isFalse);
      final File enc = File('${directory.path}/tapture.sqlite.enc');
      expect(enc.existsSync(), isTrue);
      expect(
        File('${directory.path}/tapture.sqlite.bak').existsSync(),
        isFalse,
      );
      expect(enc.readAsBytesSync().sublist(0, 8), 'TAPENC02'.codeUnits);

      final Database raw = sqlite3.open(enc.path);
      try {
        expect(
          () => raw.select('SELECT name FROM sqlite_master'),
          throwsA(isA<SqliteException>()),
        );
      } finally {
        raw.close();
      }

      final String key = _ok(
        await storage.readSecret(SecretKey.databaseEncryption),
      )!;
      final AppDatabase opened = AppDatabase.open(
        directoryPath: directory.path,
        encryptionKey: key,
      );
      await opened.customSelect('SELECT 1').get();
      expect(await _rowCounts(opened), before);
      expect(_ok(await encryption.isEnabled()), isTrue);
      await opened.close();

      expect(
        await encryption.disable(confirmation: 'no'),
        isA<FailureResult<void>>(),
      );
      expect(_ok(await encryption.isEnabled()), isTrue);

      _ok(
        await encryption.disable(confirmation: kDisableEncryptionConfirmation),
      );
      expect(_ok(await encryption.isEnabled()), isFalse);
      expect(
        File('${directory.path}/tapture.sqlite.enc').existsSync(),
        isFalse,
      );
      expect(backing.containsKey(SecretKey.databaseEncryption), isFalse);

      final AppDatabase plain = AppDatabase.open(directoryPath: directory.path);
      addTearDown(plain.close);
      await plain.customSelect('SELECT 1').get();
      expect(await _rowCounts(plain), before);
    },
  );

  test(
    'a fresh install gets a key at launch and its database is ciphertext after close',
    () async {
      final AppDatabase fresh = AppDatabase.open(
        directoryPath: directory.path,
        keyStore: storage,
      );
      await fresh.customSelect('SELECT 1').get();
      _ok(
        await upsertProject(
          fresh,
          row: _project('Alpha', 'alpha-1'),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      await fresh.close();

      expect(backing[SecretKey.databaseEncryption], isNotEmpty);
      expect(File('${directory.path}/tapture.sqlite').existsSync(), isFalse);
      final File enc = File('${directory.path}/tapture.sqlite.enc');
      expect(enc.readAsBytesSync().sublist(0, 8), 'TAPENC02'.codeUnits);

      final AppDatabase reopened = AppDatabase.open(
        directoryPath: directory.path,
        keyStore: storage,
      );
      addTearDown(reopened.close);
      final List<QueryRow> projects = await reopened
          .customSelect('SELECT name FROM projects')
          .get();
      expect(projects.single.read<String>('name'), 'Alpha');
    },
  );

  test(
    'an existing unencrypted database keeps opening and gets no key',
    () async {
      final AppDatabase plain = AppDatabase.open(directoryPath: directory.path);
      await plain.customSelect('SELECT 1').get();
      await plain.close();

      final String? key = await databaseKeyAtLaunch(
        storage: storage,
        directory: directory,
      );
      final AppDatabase reopened = AppDatabase.open(
        directoryPath: directory.path,
        keyStore: storage,
      );
      await reopened.customSelect('SELECT 1').get();
      await reopened.close();

      expect(key, isNull);
      expect(backing.containsKey(SecretKey.databaseEncryption), isFalse);
      expect(
        File('${directory.path}/tapture.sqlite.enc').existsSync(),
        isFalse,
      );
      expect(File('${directory.path}/tapture.sqlite').existsSync(), isTrue);
    },
  );

  test(
    'a key already in secure storage is the one returned at launch',
    () async {
      backing[SecretKey.databaseEncryption] = 'ab' * 32;

      final String? key = await databaseKeyAtLaunch(
        storage: storage,
        directory: directory,
      );

      expect(key, 'ab' * 32);
    },
  );

  test(
    'a lost key is a recoverable failure and does not wipe the file',
    () async {
      final AppDatabase seeded = AppDatabase.open(
        directoryPath: directory.path,
      );
      await seeded.customSelect('SELECT 1').get();
      _ok(
        await upsertProject(
          seeded,
          row: _project('Alpha', 'alpha-1'),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      await seeded.close();

      _ok(await encryption.enable(onProgress: (double _) {}));
      backing.remove(SecretKey.databaseEncryption);

      final Result<void> lost = await encryption.disable(
        confirmation: kDisableEncryptionConfirmation,
      );
      expect(lost, isA<FailureResult<void>>());
      lost.fold((Failure failure) {
        expect(failure, isA<StorageFailure>());
        expect(failure.recoveryAction, isNotEmpty);
      }, (_) => fail('expected a failure'));
      expect(File('${directory.path}/tapture.sqlite.enc').existsSync(), isTrue);
      expect(_ok(await encryption.isEnabled()), isTrue);
    },
  );
}

// Historical TAPENC01 fixture writer, frozen separately from production's
// AES envelope so new writes cannot silently break installed databases.
Uint8List _legacyEnvelope(List<int> plain, List<int> key) {
  final List<int> encryption = Hmac(
    sha256,
    key,
  ).convert(ascii.encode('enc')).bytes;
  final List<int> authentication = Hmac(
    sha256,
    key,
  ).convert(ascii.encode('mac')).bytes;
  final Uint8List nonce = Uint8List.fromList(
    List<int>.generate(16, (int index) => index),
  );
  final Uint8List header = Uint8List(32)
    ..setAll(0, ascii.encode('TAPENC01'))
    ..setAll(8, nonce);
  ByteData.sublistView(header).setUint64(24, plain.length, Endian.big);
  final Uint8List body = Uint8List.fromList(plain);
  for (int offset = 0; offset < body.length; offset += 32) {
    final Uint8List material = Uint8List(24)..setAll(0, nonce);
    ByteData.sublistView(material).setUint64(16, offset ~/ 32, Endian.big);
    final List<int> stream = Hmac(sha256, encryption).convert(material).bytes;
    for (var index = 0; index < 32 && offset + index < body.length; index++) {
      body[offset + index] ^= stream[index];
    }
  }
  final List<int> authenticated = <int>[...header, ...body];
  return Uint8List.fromList(<int>[
    ...authenticated,
    ...Hmac(sha256, authentication).convert(authenticated).bytes,
  ]);
}

ProjectsCompanion _project(String name, String folderName) {
  return ProjectsCompanion(
    name: Value<String>(name),
    client: const Value<String>('Acme'),
    status: const Value<ProjectStatus>(ProjectStatus.active),
    folderName: Value<String>(folderName),
    settings: const Value<String>('{}'),
  );
}

Future<Map<String, int>> _rowCounts(AppDatabase db) async {
  final List<QueryRow> tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .get();
  final Map<String, int> counts = <String, int>{};
  for (final QueryRow table in tables) {
    final String name = table.read<String>('name');
    final QueryRow count = await db
        .customSelect('SELECT COUNT(*) AS n FROM "$name"')
        .getSingle();
    counts[name] = count.read<int>('n');
  }
  return counts;
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
