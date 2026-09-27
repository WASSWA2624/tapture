import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';
import 'package:tapture/features/records/domain/record_entry.dart';

import 'factories.dart';

void main() {
  test('a valid project, template, record and photo is one line each', () {
    expect(aProject(name: 'Alpha').name, 'Alpha');
    expect(aTemplate(name: 'Meters').name, 'Meters');
    expect(aRecord(fields: const <String, String>{'serial': 'B-2'}).fields, {
      'serial': 'B-2',
    });
    expect(
      aRecord(context: const <String, String>{'site': 'North'}).context,
      <String, String>{'site': 'North'},
    );
    expect(aRecord().context, isEmpty);
    expect(aPhoto(projectId: 'p-9').projectId, 'p-9');
    expect(aFeedbackEntry(message: 'Slow').message, 'Slow');
    expect(aFeedbackPng, isNotEmpty);
  });

  test('a whole record entry is one line, values and photos included', () {
    final RecordEntry entry = aRecordEntry(
      status: RecordStatus.approved,
      fields: const <String, String>{'model': 'Hoist'},
      photos: 2,
      context: const <String, String>{'site': 'North'},
    );
    expect(entry.status, RecordStatus.approved);
    expect(entry.valueOf('model')?.display, 'Hoist');
    expect(entry.photos, hasLength(2));
    expect(entry.contextLabel, 'North');
    expect(aRecordEntry().valueOf('serial')?.raw, 'A-1');
  });

  test('seededDatabase yields a graph the record DAO can read', () async {
    final sqlite.AppDatabase db = await seededDatabase(records: 3);
    addTearDown(db.close);

    final List<sqlite.RecordRow> all = await db.select(db.records).get();
    expect(all, hasLength(3));
    expect(
      all.map((sqlite.RecordRow row) => row.projectId).toSet(),
      hasLength(1),
    );
    expect(
      all.map((sqlite.RecordRow row) => row.templateId).toSet(),
      hasLength(1),
    );

    final List<sqlite.RecordRow> page = _ok(
      await listRecordsByProjectAndStatus(
        db,
        projectId: all.first.projectId,
        status: 'captured',
        offset: 0,
        limit: 10,
      ),
    );
    expect(page, hasLength(3));
    expect(await db.select(db.photos).get(), hasLength(3));
    expect(await db.select(db.projects).get(), hasLength(1));
    expect(await db.select(db.templates).get(), hasLength(1));
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
