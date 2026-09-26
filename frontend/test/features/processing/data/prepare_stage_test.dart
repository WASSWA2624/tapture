import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/features/processing/data/processing_stage_worker.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';

import '../../../support/processing_fixture.dart';

void main() {
  List<File> preparedFiles(ProcessingFixture fixture) {
    return fixture.documents
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith('.ocr.jpg'))
        .toList();
  }

  test(
    'each photo gets a prepared copy and the original is untouched',
    () async {
      final ProcessingFixture fixture = await ProcessingFixture.open();
      await fixture.addPhoto(1, plateText: 'AT-0042 MOTOR 7');
      final List<Photo> photos = await fixture.db
          .select(fixture.db.photos)
          .get();
      final Map<String, Digest> before = <String, Digest>{
        for (final Photo photo in photos)
          photo.id: sha256.convert(
            File(
              '${fixture.projectFolder}/${photo.relativePath}',
            ).readAsBytesSync(),
          ),
      };
      final ProcessingStageWorker worker = fixture.worker();

      await worker.perform(
        JobStage.prepare,
        ProcessingJob(id: 'job-1', recordId: fixture.record.id),
      );

      for (final Photo photo in photos) {
        final Uint8List after = File(
          '${fixture.projectFolder}/${photo.relativePath}',
        ).readAsBytesSync();
        expect(sha256.convert(after), before[photo.id], reason: photo.id);
      }
      final List<File> prepared = preparedFiles(fixture);
      expect(prepared, hasLength(2));
      expect(img.decodeJpg(prepared.first.readAsBytesSync()), isNotNull);
    },
  );

  test('a prepared copy already there is not written again', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    final ProcessingStageWorker worker = fixture.worker();
    final ProcessingJob job = ProcessingJob(
      id: 'job-1',
      recordId: fixture.record.id,
    );
    await worker.perform(JobStage.prepare, job);
    final File prepared = preparedFiles(fixture).single;
    prepared.writeAsBytesSync(<int>[1, 2, 3]);

    await worker.perform(JobStage.prepare, job);

    expect(prepared.readAsBytesSync(), <int>[1, 2, 3]);
  });

  test('a photo that is not an image fails the stage', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    final Photo photo = await fixture.db.select(fixture.db.photos).getSingle();
    File(
      '${fixture.projectFolder}/${photo.relativePath}',
    ).writeAsBytesSync(<int>[0, 1, 2, 3]);

    await expectLater(
      fixture.worker().perform(
        JobStage.prepare,
        ProcessingJob(id: 'job-1', recordId: fixture.record.id),
      ),
      throwsA(isA<Failure>()),
    );
  });
}
