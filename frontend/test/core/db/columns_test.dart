import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import 'probe_database.dart';

void main() {
  late ProbeDatabase db;
  late UuidV7Service ids;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);
  final DateTime t1 = t0.add(const Duration(seconds: 2));

  setUp(() {
    db = ProbeDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
  });

  tearDown(() async {
    await db.close();
  });

  test('repeated writes through the base DAO bump rev and updatedAt', () async {
    final ProbeDao first = ProbeDao(
      db,
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: ids,
    );
    final ProbeRow created = _ok(
      await first.upsert(const ProbeRowsCompanion(label: Value<String>('one'))),
    );

    expect(created.rev, 1);
    expect(created.updatedAt.isAtSameMomentAs(t0), isTrue);
    expect(created.createdAt.isAtSameMomentAs(t0), isTrue);
    expect(created.updatedByDevice, 'device-a');
    expect(created.id, isNotEmpty);

    final ProbeDao second = ProbeDao(
      db,
      clock: FixedClock(t1),
      deviceId: 'device-b',
      ids: ids,
    );
    final ProbeRow updated = _ok(
      await second.upsert(
        ProbeRowsCompanion(
          id: Value<String>(created.id),
          label: const Value<String>('two'),
        ),
      ),
    );

    expect(updated.id, created.id);
    expect(updated.createdAt, created.createdAt);
    expect(updated.rev, 2);
    expect(updated.updatedAt.isAfter(created.updatedAt), isTrue);
    expect(updated.updatedByDevice, 'device-b');
    expect(updated.label, 'two');
  });

  test('a write that skips the helper leaves rev unchanged', () async {
    final ProbeDao dao = ProbeDao(
      db,
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: ids,
    );
    final ProbeRow created = _ok(
      await dao.upsert(const ProbeRowsCompanion(label: Value<String>('one'))),
    );

    await (db.update(db.probeRows)
          ..where(($ProbeRowsTable tbl) => tbl.id.equals(created.id)))
        .write(const ProbeRowsCompanion(label: Value<String>('skipped')));

    final ProbeRow after = _ok(await dao.getById(created.id))!;
    expect(after.label, 'skipped');
    expect(after.rev, created.rev);
    expect(after.updatedAt, created.updatedAt);
  });

  test('no table declares merge columns by hand', () {
    final Directory lib = Directory('lib');
    final List<String> offenders = <String>[];
    final RegExp declared = RegExp(
      r'(?:TextColumn get id|DateTimeColumn get createdAt|'
      r'DateTimeColumn get updatedAt|TextColumn get updatedByDevice|'
      r'IntColumn get rev)\s*=>',
    );
    for (final File file
        in lib
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (File file) =>
                  file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'),
            )) {
      final String path = file.path.replaceAll(r'\', '/');
      if (path.endsWith('lib/core/db/columns.dart')) {
        continue;
      }
      if (declared.hasMatch(file.readAsStringSync())) {
        offenders.add(path);
      }
    }
    expect(offenders, isEmpty);
  });
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final failure) => throw TestFailure(failure.message),
  };
}
