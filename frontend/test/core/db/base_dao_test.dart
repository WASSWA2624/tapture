import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/common.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import 'probe_database.dart';

void main() {
  late ProbeDatabase db;
  late ProbeDao dao;
  late UuidV7Service ids;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);

  setUp(() {
    db = ProbeDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
    dao = ProbeDao(db, clock: FixedClock(t0), deviceId: 'device-a', ids: ids);
  });

  tearDown(() async {
    await db.close();
  });

  test('watch emits the row after an upsert', () async {
    final Future<List<ProbeRow>> next = dao.watchAll().firstWhere(
      (List<ProbeRow> rows) => rows.isNotEmpty,
    );
    _ok(
      await dao.upsert(
        const ProbeRowsCompanion(
          id: Value<String>('w1'),
          label: Value<String>('watched'),
        ),
      ),
    );
    final List<ProbeRow> rows = await next;
    expect(rows, hasLength(1));
    expect(rows.single.label, 'watched');
  });

  test('getById returns the row or null', () async {
    _ok(
      await dao.upsert(
        const ProbeRowsCompanion(
          id: Value<String>('g1'),
          label: Value<String>('got'),
        ),
      ),
    );
    final ProbeRow? found = _ok(await dao.getById('g1'));
    expect(found?.label, 'got');
    expect(_ok(await dao.getById('missing')), isNull);
  });

  test('upsert inserts then updates', () async {
    final ProbeRow created = _ok(
      await dao.upsert(
        const ProbeRowsCompanion(
          id: Value<String>('u1'),
          label: Value<String>('first'),
        ),
      ),
    );
    expect(created.rev, 1);
    final ProbeRow updated = _ok(
      await dao.upsert(
        const ProbeRowsCompanion(
          id: Value<String>('u1'),
          label: Value<String>('second'),
        ),
      ),
    );
    expect(updated.label, 'second');
    expect(updated.rev, 2);
  });

  test('page returns a limited slice', () async {
    for (int index = 0; index < 3; index++) {
      _ok(
        await dao.upsert(
          ProbeRowsCompanion(
            id: Value<String>('p$index'),
            label: Value<String>('label-$index'),
          ),
        ),
      );
    }
    final List<ProbeRow> first = _ok(await dao.page(offset: 0, limit: 2));
    final List<ProbeRow> rest = _ok(await dao.page(offset: 2, limit: 2));
    expect(first, hasLength(2));
    expect(rest, hasLength(1));
    expect(
      <String>{...first.map((ProbeRow row) => row.id), rest.single.id},
      <String>{'p0', 'p1', 'p2'},
    );
  });

  test('a uniqueness violation maps to StorageFailure', () async {
    _ok(
      await dao.upsert(
        const ProbeRowsCompanion(
          id: Value<String>('a'),
          label: Value<String>('same'),
        ),
      ),
    );
    final Result<ProbeRow> result = await dao.upsert(
      const ProbeRowsCompanion(
        id: Value<String>('b'),
        label: Value<String>('same'),
      ),
    );
    late StorageFailure failure;
    result.fold((Failure value) {
      failure = value as StorageFailure;
    }, (_) => fail('expected a uniqueness failure'));
    expect(failure.message, contains('already exists'));
    expect(failure.recoveryAction, isNotEmpty);
  });

  test('a busy timeout maps to StorageFailure', () {
    final StorageFailure failure = storageFailureFrom(
      SqliteException(SqlError.SQLITE_BUSY, 'database is locked'),
    );
    expect(failure.message, contains('busy'));
    expect(failure.recoveryAction, isNotEmpty);
  });

  test('a generic sqlite error maps to StorageFailure', () {
    final StorageFailure failure = storageFailureFrom(
      SqliteException(SqlError.SQLITE_IOERR, 'disk I/O error'),
    );
    expect(failure.message, contains('could not complete'));
    expect(failure.recoveryAction, isNotEmpty);
  });

  test('softDelete keeps the row', () async {
    _ok(
      await dao.upsert(
        const ProbeRowsCompanion(
          id: Value<String>('s1'),
          label: Value<String>('stay'),
        ),
      ),
    );
    _ok(await dao.softDelete('s1', reason: 'test'));
    expect(_ok(await dao.getById('s1'))?.label, 'stay');
  });
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
