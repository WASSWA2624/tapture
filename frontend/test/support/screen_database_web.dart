import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';
import 'package:tapture/core/db/app_database.dart';

Future<WasmSqlite3>? _sqlite;

/// Shares only the real WASM runtime within this test iframe. Each fixture
/// opens its own SQLite in-memory connection and closes it independently.
AppDatabase createScreenDatabase() {
  return AppDatabase(
    LazyDatabase(() async {
      final WasmSqlite3 sqlite = await (_sqlite ??= _loadSqlite());
      return WasmDatabase.inMemory(
        sqlite,
        setup: (CommonDatabase database) {
          database.execute('PRAGMA foreign_keys = ON;');
        },
      );
    }),
  );
}

Future<WasmSqlite3> _loadSqlite() async {
  final WasmSqlite3 sqlite = await WasmSqlite3.loadFromUrl(
    Uri.parse('sqlite3.wasm'),
  );
  sqlite.registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true);
  return sqlite;
}
