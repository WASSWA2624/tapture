import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart' hide ContextPreset;
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
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

  test('empty project loads empty state and writes no rows', () async {
    final ContextState state = _ok(await repo.load('proj-1'));
    expect(state.isEmpty, isTrue);
    expect(await db.select(db.context).get(), isEmpty);
    expect(await db.select(db.contextState).get(), isEmpty);
    _ok(await repo.saveHierarchy('proj-1', const <ContextLevel>[]));
    expect(await db.select(db.context).get(), isEmpty);
    expect(await db.select(db.contextState).get(), isEmpty);
  });

  test('two fields can share one level and both values survive', () async {
    _ok(
      await repo.saveHierarchy('proj-1', const <ContextLevel>[
        ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
        ContextLevel(fieldKey: 'ward', order: 0, label: 'Ward'),
        ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
      ]),
    );
    _ok(
      await repo.setLevelValue(
        projectId: 'proj-1',
        fieldKey: 'district',
        value: 'North',
        clearBelow: false,
      ),
    );
    _ok(
      await repo.setLevelValue(
        projectId: 'proj-1',
        fieldKey: 'ward',
        value: 'A',
        clearBelow: false,
      ),
    );
    final ContextState state = _ok(await repo.load('proj-1'));
    expect(state.levels, hasLength(3));
    expect(state.values['district'], 'North');
    expect(state.values['ward'], 'A');
  });

  test('hierarchy and values survive a simulated restart', () async {
    _ok(
      await repo.saveHierarchy('proj-1', const <ContextLevel>[
        ContextLevel(fieldKey: 'district', order: 0, label: 'District'),
        ContextLevel(fieldKey: 'facility', order: 1, label: 'Facility'),
        ContextLevel(fieldKey: 'dept', order: 2, label: 'Department'),
      ]),
    );
    _ok(
      await repo.setLevelValue(
        projectId: 'proj-1',
        fieldKey: 'district',
        value: 'Kampala',
      ),
    );
    _ok(
      await repo.setLevelValue(
        projectId: 'proj-1',
        fieldKey: 'facility',
        value: 'Kasubi HC IV',
      ),
    );
    _ok(
      await repo.setLevelValue(
        projectId: 'proj-1',
        fieldKey: 'dept',
        value: 'Theatre',
      ),
    );
    final ContextRepositoryImpl restarted = ContextRepositoryImpl(
      db: db,
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: ids,
    );
    final ContextState state = _ok(await restarted.load('proj-1'));
    expect(state.values['district'], 'Kampala');
    expect(state.values['facility'], 'Kasubi HC IV');
    expect(state.values['dept'], 'Theatre');
    expect(state.levels, hasLength(3));
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
