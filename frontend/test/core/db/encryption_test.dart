import 'dart:io';

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
      expect(enc.readAsBytesSync().sublist(0, 8), 'TAPENC01'.codeUnits);

      final Database raw = sqlite3.open(enc.path);
      try {
        expect(
          () => raw.select('SELECT name FROM sqlite_master'),
          throwsA(isA<SqliteException>()),
        );
      } finally {
        raw.dispose();
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
