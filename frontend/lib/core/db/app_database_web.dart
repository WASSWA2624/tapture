import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

/// Served from `web/sqlite3.wasm`.
const String _sqlite3Asset = 'sqlite3.wasm';

/// Served from `web/drift_worker.js`.
const String _workerAsset = 'drift_worker.js';

/// Process-wide name when [openFileExecutor] is not given a directory.
const String _databaseName = 'tapture';

/// Turns on foreign keys for every wasm connection.
void _configure(CommonDatabase database) {
  database.execute('PRAGMA foreign_keys = ON;');
}

/// In-memory wasm database so web tests never touch IndexedDB.
QueryExecutor openMemoryExecutor() {
  return LazyDatabase(() async {
    final CommonSqlite3 sqlite3 = await WasmSqlite3.loadFromUrl(
      Uri.parse(_sqlite3Asset),
    );
    sqlite3.registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true);
    return WasmDatabase.inMemory(sqlite3, setup: _configure);
  });
}

/// Persistent wasm database. [directoryPath] becomes the IndexedDB/OPFS name
/// when set. [encryptionKey] is native-only (task 064) and unused here.
QueryExecutor openFileExecutor({String? directoryPath, String? encryptionKey}) {
  return LazyDatabase(() async {
    final WasmDatabaseResult opened = await WasmDatabase.open(
      databaseName: _databaseNameFor(directoryPath),
      sqlite3Uri: Uri.parse(_sqlite3Asset),
      driftWorkerUri: Uri.parse(_workerAsset),
      localSetup: encryptionKey == null ? _configure : _configure,
    );
    return opened.resolvedExecutor;
  });
}

String _databaseNameFor(String? directoryPath) {
  if (directoryPath == null || directoryPath.isEmpty) {
    return _databaseName;
  }
  return directoryPath.replaceAll(RegExp('[^A-Za-z0-9._-]'), '_');
}
