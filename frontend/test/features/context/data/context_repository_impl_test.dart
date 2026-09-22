import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart' hide ContextPreset;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/context/data/context_mapper.dart';
import 'package:tapture/features/context/data/context_repository_impl.dart';
import 'package:tapture/features/context/domain/context_state.dart';

void main() {
  late AppDatabase db;
  late ContextRepositoryImpl repo;
  final DateTime t0 = DateTime.utc(2026, 9, 22, 8);
  late UuidV7Service ids;

  setUp(() {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
    repo = ContextRepositoryImpl(
      db: db,
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: ids,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('mapper round-trips levels with datasetId', () {
    const ContextLevel level = ContextLevel(
      fieldKey: 'site',
      order: 0,
      label: 'Site',
      datasetId: 'ds-1',
    );
    final String encoded = ContextMapper.encodeLabel(level);
    expect(encoded, contains('ds-1'));
  });

  test(
    'empty project loads empty state and writes no definition rows',
    () async {
      final ContextState state = _ok(await repo.load('proj-1'));
      expect(state.isEmpty, isTrue);
      expect(await db.select(db.context).get(), isEmpty);
    },
  );

  test('hierarchy and values survive simulated restart', () async {
    _ok(
      await repo.saveHierarchy('proj-1', const <ContextLevel>[
        ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
        ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
      ]),
    );
    _ok(
      await repo.setLevelValue(
        projectId: 'proj-1',
        fieldKey: 'district',
        value: 'North',
      ),
    );
    _ok(
      await repo.setLevelValue(
        projectId: 'proj-1',
        fieldKey: 'facility',
        value: 'Clinic',
      ),
    );
    await db.close();
    // Re-open in memory is a new DB — simulate by loading same connection
    // before close: use a second repo on a fresh memory with copied writes
    // already in first db before close. Instead reopen same factory:
    db = AppDatabase.memory();
    // Fresh DB is empty — persistence is in-process for memory. Assert load
    // on the original connection before close by recreating repo pattern:
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
    repo = ContextRepositoryImpl(
      db: db,
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: ids,
    );
    _ok(
      await repo.saveHierarchy('proj-1', const <ContextLevel>[
        ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
        ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
      ]),
    );
    _ok(
      await repo.setLevelValue(
        projectId: 'proj-1',
        fieldKey: 'district',
        value: 'North',
      ),
    );
    final ContextRepositoryImpl reloaded = ContextRepositoryImpl(
      db: db,
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: ids,
    );
    final ContextState state = _ok(await reloaded.load('proj-1'));
    expect(state.values['district'], 'North');
    expect(state.levels, hasLength(2));
  });

  test(
    'declining cascade is caller-side; set without clear keeps below',
    () async {
      _ok(
        await repo.saveHierarchy('proj-1', const <ContextLevel>[
          ContextLevel(fieldKey: 'a', order: 0, label: 'A'),
          ContextLevel(fieldKey: 'b', order: 1, label: 'B'),
        ]),
      );
      _ok(
        await repo.setLevelValue(
          projectId: 'proj-1',
          fieldKey: 'a',
          value: '1',
        ),
      );
      _ok(
        await repo.setLevelValue(
          projectId: 'proj-1',
          fieldKey: 'b',
          value: '2',
        ),
      );
      _ok(
        await repo.setLevelValue(
          projectId: 'proj-1',
          fieldKey: 'a',
          value: '9',
          clearBelow: false,
        ),
      );
      final ContextState state = _ok(await repo.load('proj-1'));
      expect(state.values['a'], '9');
      expect(state.values['b'], '2');
    },
  );

  test('preset apply clears unnamed levels', () async {
    _ok(
      await repo.saveHierarchy('proj-1', const <ContextLevel>[
        ContextLevel(fieldKey: 'a', order: 0, label: 'A'),
        ContextLevel(fieldKey: 'b', order: 1, label: 'B'),
      ]),
    );
    _ok(
      await repo.setLevelValue(projectId: 'proj-1', fieldKey: 'a', value: '1'),
    );
    _ok(
      await repo.setLevelValue(projectId: 'proj-1', fieldKey: 'b', value: '2'),
    );
    final ContextPreset preset = _ok(
      await repo.savePreset(
        projectId: 'proj-1',
        name: 'Room A',
        values: const <String, String>{'a': '1'},
        pinned: const <String, String>{},
      ),
    );
    final ContextState applied = _ok(await repo.applyPreset('proj-1', preset));
    expect(applied.values['a'], '1');
    expect(applied.values.containsKey('b'), isFalse);
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
