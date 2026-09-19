import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/projects/data/project_repository_impl.dart';

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
