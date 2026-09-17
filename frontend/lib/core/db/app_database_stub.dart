import 'package:drift/drift.dart';

/// Web stand-in: native SQLite is not compiled into the web binary.
QueryExecutor openMemoryExecutor() {
  throw UnsupportedError('AppDatabase.memory is not available on web');
}

/// Web stand-in: the on-disk database is a later native-only path.
QueryExecutor openFileExecutor({String? directoryPath, String? encryptionKey}) {
  throw UnsupportedError(
    'AppDatabase.open is not available on web'
    '${directoryPath == null ? '' : ': $directoryPath'}'
    '${encryptionKey == null ? '' : ' (encrypted)'}',
  );
}
