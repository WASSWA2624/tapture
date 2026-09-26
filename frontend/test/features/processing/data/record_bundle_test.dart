import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/features/processing/data/record_bundle.dart';

import '../../../support/factories.dart';

void main() {
  test('a bundle keeps exactly the rows it was built from', () async {
    final AppDatabase db = await seededDatabase(records: 1);
    addTearDown(db.close);
    final RecordRow record = await db.select(db.records).getSingle();
    final Project project = await db.select(db.projects).getSingle();
    final Template template = await db.select(db.templates).getSingle();
    final List<Photo> photos = await db.select(db.photos).get();

    final RecordBundle bundle = RecordBundle(
      record: record,
      project: project,
      template: template,
      fields: const <TemplateField>[],
      rows: const <TemplateRow>[],
      photos: photos,
      captions: const <Caption>[],
      audio: const <Attachment>[],
      existing: const <RecordField>[],
    );

    expect(bundle.record, record);
    expect(bundle.project, project);
    expect(bundle.template, template);
    expect(bundle.photos, photos);
  });
}
