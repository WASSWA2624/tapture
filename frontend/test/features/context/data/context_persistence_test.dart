import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart' show AppDatabase;
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/context/data/context_persistence.dart';
import 'package:tapture/features/context/data/context_repository_impl.dart';
import 'package:tapture/features/context/domain/context_state.dart';

import '../../../support/matchers.dart';

void main() {
  const String projectId = 'proj-1';
  late MemoryContextPersistence persistence;

  Future<void> remember(String value, {String fieldKey = 'facility'}) {
    return persistence.rememberRecent(
      projectId: projectId,
      fieldKey: fieldKey,
      value: value,
    );
  }

  Future<List<String>> recents({String fieldKey = 'facility'}) {
    return persistence.recents(projectId: projectId, fieldKey: fieldKey);
  }

  setUp(() {
    persistence = MemoryContextPersistence();
  });

  test('a field nobody has set has no recents', () async {
    expect(await recents(), isEmpty);
  });

  test('recents come back newest first', () async {
    await remember('Kasubi HC IV');
    await remember('Mulago');
    await remember('Kawempe');
    expect(await recents(), <String>['Kawempe', 'Mulago', 'Kasubi HC IV']);
  });

  test('a value set again moves to the front without a duplicate', () async {
    await remember('Kasubi HC IV');
    await remember('Mulago');
    await remember('Kasubi HC IV');
    expect(await recents(), <String>['Kasubi HC IV', 'Mulago']);
  });

  test('surrounding whitespace is trimmed before the value is kept', () async {
    await remember('  Kasubi HC IV ');
    await remember('Kasubi HC IV');
    expect(await recents(), <String>['Kasubi HC IV']);
  });

  test('an empty or blank value is never remembered', () async {
    await remember('');
    await remember('   ');
    expect(await recents(), isEmpty);
  });

  test('recents stop at AppConstants.context.recentCap, dropping the oldest', () async {
    final int cap = AppConstants.context.recentCap;
    for (int i = 0; i <= cap; i++) {
      await remember('Facility $i');
    }
    final List<String> kept = await recents();
    expect(kept, hasLength(cap));
    expect(kept.first, 'Facility $cap');
    expect(kept, isNot(contains('Facility 0')));
    expect(kept.last, 'Facility 1');
  });

  test('recents are kept per project and per field', () async {
    await remember('Kasubi HC IV');
    await remember('Theatre', fieldKey: 'dept');
    await persistence.rememberRecent(
      projectId: 'proj-2',
      fieldKey: 'facility',
      value: 'Mulago',
    );
    expect(await recents(), <String>['Kasubi HC IV']);
    expect(await recents(fieldKey: 'dept'), <String>['Theatre']);
    expect(
      await persistence.recents(projectId: 'proj-2', fieldKey: 'facility'),
      <String>['Mulago'],
    );
  });

  test('the list handed out is a copy the caller cannot corrupt', () async {
    await remember('Kasubi HC IV');
    final List<String> handed = await recents();
    handed.add('Mulago');
    expect(await recents(), <String>['Kasubi HC IV']);
  });

  test('recents survive a repository restart over the same persistence', () async {
    final AppDatabase db = AppDatabase.memory();
    addTearDown(db.close);
    final DateTime t0 = DateTime.utc(2026, 9, 22, 8);
    final IdService ids = UuidV7Service.sequence(FixedClock(t0));
    ContextRepositoryImpl open() {
      return ContextRepositoryImpl(
        db: db,
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
        persistence: persistence,
      );
    }

    final ContextRepositoryImpl first = open();
    valueOf(
      await first.saveHierarchy(projectId, const <ContextLevel>[
        ContextLevel(fieldKey: 'facility', order: 0, label: 'Facility'),
      ]),
    );
    valueOf(
      await first.setLevelValue(
        projectId: projectId,
        fieldKey: 'facility',
        value: 'Kasubi HC IV',
      ),
    );

    final ContextRepositoryImpl reopened = open();
    expect(
      valueOf(
        await reopened.recentValues(projectId: projectId, fieldKey: 'facility'),
      ),
      <String>['Kasubi HC IV'],
    );
    expect(valueOf(await reopened.load(projectId)).values['facility'], 'Kasubi HC IV');
  });
}
