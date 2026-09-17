import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/captions.dart';
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

  test(
    'applying one caption to thirty photos writes thirty independent rows and leaves textRaw unchanged',
    () async {
      const String raw = 'North elevation, looking east.';
      final List<String> photoIds = <String>[];
      for (int index = 0; index < 30; index++) {
        photoIds.add(
          _ok(
            await upsertPhoto(
              db,
              row: PhotosCompanion(
                projectId: const Value<String>('p1'),
                captureSessionId: const Value<String>('session-1'),
                originalFilename: Value<String>('IMG_$index.jpg'),
                storedFilename: Value<String>('img-$index.jpg'),
                relativePath: Value<String>('photos/_unfiled/$index.jpg'),
                photoType: const Value<String>('front'),
                sortOrder: Value<int>(index),
                width: const Value<int>(1600),
                height: const Value<int>(1200),
                fileSize: const Value<int>(2048),
                mimeType: const Value<String>('image/jpeg'),
                sha256: Value<String>('hash-$index'),
                capturedAt: Value<DateTime>(t0),
              ),
              clock: FixedClock(t0),
              deviceId: 'device-a',
              ids: ids,
            ),
          ).id,
        );
      }

      final List<Caption> rows = _ok(
        await applyCaptionToPhotos(
          db,
          photoIds: photoIds,
          text: raw,
          inputMode: CaptionInputMode.typed,
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(rows, hasLength(30));
      expect(rows.map((Caption row) => row.ownerId).toSet(), photoIds.toSet());
      expect(rows.every((Caption row) => row.textRaw == raw), isTrue);
      expect(
        rows.every((Caption row) => row.ownerType == CaptionOwnerType.photo),
        isTrue,
      );

      final Caption refined = _ok(
        await writeCaptionRefined(
          db,
          id: rows.first.id,
          textRefined: 'North elevation.',
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(refined.textRaw, raw);
      expect(refined.textRefined, 'North elevation.');

      final Caption untouched = await (db.select(
        db.captions,
      )..where(($CaptionsTable tbl) => tbl.id.equals(rows[1].id))).getSingle();
      expect(untouched.textRaw, raw);
      expect(untouched.textRefined, isNull);

      final Result<Caption> secondRaw = await insertCaption(
        db,
        row: CaptionsCompanion(
          id: Value<String>(rows.first.id),
          textRaw: const Value<String>('changed'),
        ),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      );
      expect(
        secondRaw.fold((Failure failure) => failure, (_) => null),
        isA<StorageFailure>(),
      );
      expect(
        (await (db.select(db.captions)
                  ..where(($CaptionsTable tbl) => tbl.id.equals(rows.first.id)))
                .getSingle())
            .textRaw,
        raw,
      );
    },
  );

  test('version 6 creates the captions table with merge columns', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_captions_',
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
      await _columns(upgraded, 'captions'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'owner_type',
        'owner_id',
        'text_raw',
        'text_refined',
        'input_mode',
        'refined_at',
      ]),
    );
  });
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
