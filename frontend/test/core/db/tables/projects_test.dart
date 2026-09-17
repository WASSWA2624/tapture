import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/projects.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late AppDatabase db;
  late UuidV7Service ids;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);
  final DateTime t1 = t0.add(const Duration(seconds: 2));
  final DateTime t2 = t0.add(const Duration(seconds: 4));

  setUp(() {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
  });

  tearDown(() async {
    await db.close();
  });

  test('create, paged list by status and update', () async {
    final Project first = _ok(
      await upsertProject(
        db,
        row: _project(name: 'Alpha', folderName: 'alpha-1'),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    _ok(
      await upsertProject(
        db,
        row: _project(name: 'Beta', folderName: 'beta-1'),
        clock: FixedClock(t1),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    _ok(
      await upsertProject(
        db,
        row: _project(name: 'Gamma', folderName: 'gamma-1'),
        clock: FixedClock(t2),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    _ok(
      await upsertProject(
        db,
        row: _project(
          name: 'Old',
          folderName: 'old-1',
          status: ProjectStatus.archived,
        ),
        clock: FixedClock(t2),
        deviceId: 'device-a',
        ids: ids,
      ),
    );

    final List<Project> page = _ok(
      await listProjectsByStatus(
        db,
        status: ProjectStatus.active,
        offset: 0,
        limit: 2,
      ),
    );
    expect(page.map((Project row) => row.name).toList(), <String>[
      'Gamma',
      'Beta',
    ]);
    final List<Project> rest = _ok(
      await listProjectsByStatus(
        db,
        status: ProjectStatus.active,
        offset: 2,
        limit: 2,
      ),
    );
    expect(rest.map((Project row) => row.name).toList(), <String>['Alpha']);

    final Project renamed = _ok(
      await upsertProject(
        db,
        row: ProjectsCompanion(
          id: Value<String>(first.id),
          name: const Value<String>('Alpha renamed'),
        ),
        clock: FixedClock(t2),
        deviceId: 'device-b',
        ids: ids,
      ),
    );
    expect(renamed.name, 'Alpha renamed');
    expect(renamed.folderName, 'alpha-1');
    expect(renamed.rev, 2);
  });

  test('the status list is served by projects_by_status', () async {
    _ok(
      await upsertProject(
        db,
        row: _project(name: 'Alpha', folderName: 'alpha-1'),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    final List<QueryRow> plan = await db
        .customSelect(
          'EXPLAIN QUERY PLAN SELECT * FROM projects '
          "WHERE status = 'active' ORDER BY updated_at DESC",
        )
        .get();
    final String details = plan
        .map((QueryRow row) => row.read<String>('detail'))
        .join('; ');
    expect(details, contains('projects_by_status'));
  });

  test('malformed settings JSON is refused and never stored', () async {
    final Result<Project> invalid = await upsertProject(
      db,
      row: _project(name: 'Bad', folderName: 'bad-1', settings: '{'),
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: ids,
    );
    expect(
      invalid.fold((Failure failure) => failure, (_) => null),
      isA<StorageFailure>(),
    );

    final Result<Project> notObject = await upsertProject(
      db,
      row: _project(name: 'List', folderName: 'list-1', settings: '[]'),
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: ids,
    );
    expect(
      notObject.fold((Failure failure) => failure, (_) => null),
      isA<StorageFailure>(),
    );

    final List<Project> rows = await db.select(db.projects).get();
    expect(rows, isEmpty);
  });

  test('version 3 creates the projects table with merge columns', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_projects_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    final File seed = File('${directory.path}/tapture.sqlite');
    _seedVersion1(seed);

    final AppDatabase upgraded = AppDatabase.open(
      directoryPath: directory.path,
    );
    addTearDown(upgraded.close);
    await upgraded.customSelect('SELECT 1').get();

    final Set<String> columns = await _columns(upgraded, 'projects');
    expect(
      columns,
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'name',
        'client',
        'status',
        'started_at',
        'completed_at',
        'folder_name',
        'settings',
      ]),
    );
  });
}

ProjectsCompanion _project({
  required String name,
  required String folderName,
  ProjectStatus status = ProjectStatus.active,
  String settings = '{}',
}) {
  return ProjectsCompanion(
    name: Value<String>(name),
    client: const Value<String>('Acme'),
    status: Value<ProjectStatus>(status),
    folderName: Value<String>(folderName),
    settings: Value<String>(settings),
  );
}

void _seedVersion1(File file) {
  file.parent.createSync(recursive: true);
  final Database database = sqlite3.open(file.path);
  database.execute('PRAGMA user_version = 1');
  database.dispose();
}

Future<Set<String>> _columns(AppDatabase db, String table) async {
  final List<QueryRow> info = await db
      .customSelect('PRAGMA table_info("$table")')
      .get();
  return <String>{for (final QueryRow row in info) row.read<String>('name')};
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
