import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

/// File name written under the application support directory.
const String _databaseFileName = 'tapture.sqlite';

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
QueryExecutor openFileExecutor({String? directoryPath}) {
  return LazyDatabase(() async {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    final Directory directory = directoryPath == null
        ? await getApplicationSupportDirectory()
        : Directory(directoryPath);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    final File file = File('${directory.path}/$_databaseFileName');
    return NativeDatabase.createInBackground(
      file,
      setup: _configureSqliteConnection,
    );
  });
}
