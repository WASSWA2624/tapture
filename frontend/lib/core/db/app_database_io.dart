import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:tapture/core/db/encryption.dart';
import 'package:tapture/core/security/secure_storage.dart';

/// Enables WAL and foreign keys on a new native connection.
void _configureSqliteConnection(Database database) {
  database.execute('PRAGMA journal_mode = WAL;');
  database.execute('PRAGMA foreign_keys = ON;');
}

/// In-memory executor so tests never touch the real file.
QueryExecutor openMemoryExecutor() {
  return NativeDatabase.memory(setup: _configureSqliteConnection);
}

/// Lazy WAL file executor. [directoryPath] overrides the application support
/// directory so a suite can simulate a hot restart without the real file.
/// [encryptionKey] decrypts a ciphertext produced by [DatabaseEncryption];
/// without one, [keyStore] supplies the launch key ([databaseKeyAtLaunch]).
QueryExecutor openFileExecutor({
  String? directoryPath,
  String? encryptionKey,
  SecureStorage? keyStore,
}) {
  return LazyDatabase(() async {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    final Directory directory = directoryPath == null
        ? await getApplicationSupportDirectory()
        : Directory(directoryPath);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    final SecureStorage? store = keyStore;
    return resolveFileExecutor(
      directory: directory,
      encryptionKey:
          encryptionKey ??
          (store == null
              ? null
              : await databaseKeyAtLaunch(
                  storage: store,
                  directory: directory,
                )),
    );
  });
}
