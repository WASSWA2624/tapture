import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/attachments.dart';
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
    'a document stores pageCount and an audio clip stores durationMs',
    () async {
      final Attachment document = _ok(
        await upsertAttachment(
          db,
          row: const AttachmentsCompanion(
            projectId: Value<String>('p1'),
            relativePath: Value<String>('documents/spec.pdf'),
            mimeType: Value<String>('application/pdf'),
            fileSize: Value<int>(4096),
            sha256: Value<String>('pdf-hash'),
            kind: Value<AttachmentKind>(AttachmentKind.document),
            pageCount: Value<int>(12),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(document.kind, AttachmentKind.document);
      expect(document.pageCount, 12);
      expect(document.durationMs, isNull);

      final Attachment audio = _ok(
        await upsertAttachment(
          db,
          row: const AttachmentsCompanion(
            projectId: Value<String>('p1'),
            relativePath: Value<String>('audio/walkthrough.m4a'),
            mimeType: Value<String>('audio/mp4'),
            fileSize: Value<int>(8192),
            sha256: Value<String>('audio-hash'),
            kind: Value<AttachmentKind>(AttachmentKind.audio),
            durationMs: Value<int>(90 * 1000),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(audio.kind, AttachmentKind.audio);
      expect(audio.durationMs, 90 * 1000);
      expect(audio.pageCount, isNull);
    },
  );

  test('version 6 creates the attachments table with merge columns', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_attachments_',
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
      await _columns(upgraded, 'attachments'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'project_id',
        'relative_path',
        'mime_type',
        'file_size',
        'sha256',
        'kind',
        'duration_ms',
        'page_count',
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
