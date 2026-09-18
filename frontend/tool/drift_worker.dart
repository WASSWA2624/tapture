import 'package:drift/wasm.dart';

/// Compiled to `web/drift_worker.js` for [WasmDatabase.open].
void main() {
  WasmDatabase.workerMainForOpen(
    setupAllDatabases: (database) {
      database.execute('PRAGMA foreign_keys = ON;');
    },
  );
}
