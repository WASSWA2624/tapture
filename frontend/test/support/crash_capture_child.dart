import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// A real interrupted SQLite writer. The parent kills this process only after
/// its transaction holds the database lock. Committed capture evidence is never
/// touched; the uncommitted mutation must roll back when the process dies.
Future<void> main(List<String> args) async {
  final Database database = sqlite3.open(args.single);
  try {
    database.execute('BEGIN IMMEDIATE');
    database.execute(
      'UPDATE capture_sessions SET payload_json = ?, rev = rev + 1',
      <Object?>['{}'],
    );
    stdout.writeln('TAPTURE_CAPTURE_TRANSACTION_OPEN');
    await stdout.flush();
    await stdin.transform(utf8.decoder).transform(const LineSplitter()).first;
    database.execute('ROLLBACK');
  } finally {
    database.close();
  }
}
