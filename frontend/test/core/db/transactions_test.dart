import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    await db.customStatement(
      'CREATE TABLE tx_probe (id TEXT PRIMARY KEY, n INTEGER NOT NULL)',
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('a throw mid-transaction leaves no partial rows', () async {
    final Result<void> result = await runInTransaction(db, () async {
      await db.customStatement("INSERT INTO tx_probe VALUES ('a', 1)");
      throw StateError('boom');
    });
    expect(
      result.fold((Failure failure) => failure, (_) => null),
      isA<StorageFailure>(),
    );
    expect(await _count(db), 0);
  });

  test('a nested throw rolls back the outer write too', () async {
    final Result<void> result = await runInTransaction(db, () async {
      await db.customStatement("INSERT INTO tx_probe VALUES ('a', 1)");
      await runInTransaction(db, () async {
        await db.customStatement("INSERT INTO tx_probe VALUES ('b', 2)");
        throw StateError('nested');
      });
    });
    expect(
      result.fold((Failure failure) => failure, (_) => null),
      isA<StorageFailure>(),
    );
    expect(await _count(db), 0);
  });

  test('a nested call that succeeds commits with the outer write', () async {
    final Result<void> result = await runInTransaction(db, () async {
      await db.customStatement("INSERT INTO tx_probe VALUES ('a', 1)");
      final Result<void> inner = await runInTransaction(db, () async {
        await db.customStatement("INSERT INTO tx_probe VALUES ('b', 2)");
      });
      inner.fold((Failure failure) => throw failure, (_) {});
    });
    expect(result.fold((_) => false, (_) => true), isTrue);
    expect(await _count(db), 2);
  });
}

Future<int> _count(AppDatabase db) async {
  final QueryRow row = await db
      .customSelect('SELECT COUNT(*) AS c FROM tx_probe')
      .getSingle();
  return row.read<int>('c');
}
