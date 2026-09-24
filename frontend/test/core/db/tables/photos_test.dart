import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late AppDatabase db;
  late UuidV7Service ids;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);

  setUp(() {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
  });

  tearDown(() async {
    await db.close();
  });

  test('the same hash in one project is refused by the unique index', () async {
    _ok(
      await upsertPhoto(
        db,
        row: _photo(projectId: 'p1', sha256: 'abc', recordId: 'r1'),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );

    final Result<Photo> duplicate = await upsertPhoto(
      db,
      row: _photo(projectId: 'p1', sha256: 'abc', recordId: 'r2'),
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: ids,
    );
    late StorageFailure failure;
    duplicate.fold((Failure value) {
      failure = value as StorageFailure;
    }, (_) => fail('expected a uniqueness failure'));
    expect(failure.message, contains('already exists'));
    expect(failure.recoveryAction, isNotEmpty);

    _ok(
      await upsertPhoto(
        db,
        row: _photo(projectId: 'p2', sha256: 'abc'),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
  });

  test('an unfiled capture stores a null recordId', () async {
    final Photo unfiled = _ok(
      await upsertPhoto(
        db,
        row: _photo(projectId: 'p1', sha256: 'unfiled'),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    expect(unfiled.recordId, isNull);
    expect(unfiled.gpsLat, isNull);
    expect(unfiled.gpsLon, isNull);
  });

  test('version 6 creates the photos table with merge columns', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_photos_',
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

    expect(
      await _columns(upgraded, 'photos'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'project_id',
        'record_id',
        'capture_session_id',
        'original_filename',
        'stored_filename',
        'relative_path',
        'photo_type',
        'sort_order',
        'width',
        'height',
        'file_size',
        'mime_type',
        'sha256',
        'captured_at',
        'gps_lat',
        'gps_lon',
        'derived_from',
        'rotation_degrees',
      ]),
    );
  });
}

PhotosCompanion _photo({
  required String projectId,
  required String sha256,
  String? recordId,
}) {
  return PhotosCompanion(
    projectId: Value<String>(projectId),
    recordId: Value<String?>(recordId),
    captureSessionId: const Value<String>('session-1'),
    originalFilename: const Value<String>('IMG_001.jpg'),
    storedFilename: const Value<String>('img-001.jpg'),
    relativePath: Value<String>('photos/_unfiled/$sha256.jpg'),
    photoType: const Value<String>('front'),
    sortOrder: const Value<int>(0),
    width: const Value<int>(1600),
    height: const Value<int>(1200),
    fileSize: const Value<int>(2048),
    mimeType: const Value<String>('image/jpeg'),
    sha256: Value<String>(sha256),
    capturedAt: Value<DateTime>(DateTime.utc(2026, 9, 17, 8)),
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
