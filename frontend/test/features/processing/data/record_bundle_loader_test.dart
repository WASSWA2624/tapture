import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/features/processing/data/record_bundle.dart';
import 'package:tapture/features/processing/data/record_bundle_loader.dart';

import '../../../support/factories.dart';

void main() {
  test('a record loads with its project, template and photos', () async {
    final AppDatabase db = await seededDatabase(records: 2);
    addTearDown(db.close);
    final RecordRow record = (await db.select(db.records).get()).first;

    final RecordBundle bundle = await RecordBundleLoader(
      db: db,
    ).load(record.id);

    expect(bundle.record.id, record.id);
    expect(bundle.project.id, record.projectId);
    expect(bundle.template.id, record.templateId);
    expect(bundle.photos.map((Photo photo) => photo.recordId), <String?>[
      record.id,
    ]);
    expect(bundle.fields, isEmpty);
    expect(bundle.rows, isEmpty);
    expect(bundle.captions, isEmpty);
    expect(bundle.audio, isEmpty);
    expect(bundle.existing, isEmpty);
  });

  test('a record that is gone is a storage failure', () async {
    final AppDatabase db = await seededDatabase();
    addTearDown(db.close);

    await expectLater(
      RecordBundleLoader(db: db).load('missing'),
      throwsA(isA<StorageFailure>()),
    );
  });

  test('a record whose template is gone is a validation failure', () async {
    final AppDatabase db = await seededDatabase(records: 1);
    addTearDown(db.close);
    final RecordRow record = await db.select(db.records).getSingle();
    await (db.update(db.records)
          ..where(($RecordsTable table) => table.id.equals(record.id)))
        .write(const RecordsCompanion(templateId: Value<String>('gone')));

    await expectLater(
      RecordBundleLoader(db: db).load(record.id),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
