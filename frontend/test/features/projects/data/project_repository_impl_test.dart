import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/projects/data/project_repository_impl.dart';
import 'package:tapture/features/projects/domain/project_repository.dart';

import '../../../support/factories.dart';
import '../project_repository_contract.dart';

void main() {
  late AppDatabase db;
  late ProjectRepositoryImpl repo;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);
  final FixedClock clock = FixedClock(t0);

  setUp(() {
    db = AppDatabase.memory();
    repo = ProjectRepositoryImpl(
      db: db,
      clock: clock,
      deviceId: 'device-test',
      ids: UuidV7Service.sequence(clock),
    );
  });

  tearDown(() async {
    await db.close();
  });

  runProjectRepositoryContract(() => repo);

  test('watchList returns counts and last-worked from one query', () async {
    final IdService ids = UuidV7Service.sequence(clock);
    _ok(await repo.create(aProject()));
    _ok(
      await upsertRecord(
        db,
        row: RecordsCompanion(
          projectId: const Value<String>('project-1'),
          templateId: const Value<String>('template-1'),
          status: const Value<String>('captured'),
          processingMode: const Value<String>('manual'),
          contextJson: const Value<String>('{}'),
          identityHash: const Value<String>('hash-captured'),
          source: const Value<String>('capture'),
          capturedAt: Value<DateTime>(t0),
          capturedBy: const Value<String>('Ada'),
        ),
        clock: FixedClock(t0.add(const Duration(hours: 2))),
        deviceId: 'device-test',
        ids: ids,
      ),
    );
    _ok(
      await upsertRecord(
        db,
        row: RecordsCompanion(
          projectId: const Value<String>('project-1'),
          templateId: const Value<String>('template-1'),
          status: const Value<String>('approved'),
          processingMode: const Value<String>('manual'),
          contextJson: const Value<String>('{}'),
          identityHash: const Value<String>('hash-approved'),
          source: const Value<String>('capture'),
          capturedAt: Value<DateTime>(t0),
          capturedBy: const Value<String>('Ada'),
        ),
        clock: clock,
        deviceId: 'device-test',
        ids: ids,
      ),
    );
    final ProjectListRow row = (await repo.watchList().first).single;
    expect(row.recordCount, 2);
    expect(row.unprocessedCount, 1);
    expect(row.lastWorkedAt.toUtc(), t0.add(const Duration(hours: 2)));
  });

  test('presentation under projects imports no core/db', () {
    final Directory presentation = Directory(
      'lib/features/projects/presentation',
    );
    expect(presentation.existsSync(), isTrue);
    for (final FileSystemEntity entity in presentation.listSync(
      recursive: true,
    )) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      expect(
        entity.readAsStringSync(),
        isNot(contains('core/db')),
        reason: entity.path,
      );
    }
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
