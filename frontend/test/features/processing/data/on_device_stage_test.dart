import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/features/processing/data/processing_stage_worker.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';

import '../../../support/processing_fixture.dart';

void main() {
  test('a plate is read on the device and its text cached', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open(
      plateText: 'SN458923',
    );
    final ProcessingStageWorker worker = fixture.worker();
    final ProcessingJob job = ProcessingJob(
      id: 'job-1',
      recordId: fixture.record.id,
    );

    await worker.perform(JobStage.prepare, job);
    await worker.perform(JobStage.onDevice, job);

    final OcrCacheEntry cached = await fixture.db
        .select(fixture.db.ocrCacheEntries)
        .getSingle();
    expect(cached.recognisedText, 'SN458923');
    expect(cached.contentHash, 'sha-0');
    expect(cached.perceptualHash, isNotEmpty);
  });

  test('reprocessing reuses stored text and reads nothing', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    final ProcessingJob job = ProcessingJob(
      id: 'job-1',
      recordId: fixture.record.id,
    );
    final CountingOcr first = CountingOcr('SN458923');
    await fixture.worker(ocr: first).perform(JobStage.prepare, job);
    await fixture.worker(ocr: first).perform(JobStage.onDevice, job);
    expect(first.reads, 1);

    final CountingOcr again = CountingOcr('different');
    await fixture.worker(ocr: again).perform(JobStage.onDevice, job);
    expect(again.reads, 0);
  });

  test('a second copy of the same photo is a perceptual hit', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open(photos: 2);
    final CountingOcr reader = CountingOcr('SN458923');
    final ProcessingStageWorker worker = fixture.worker(ocr: reader);
    final ProcessingJob job = ProcessingJob(
      id: 'job-1',
      recordId: fixture.record.id,
    );

    await worker.perform(JobStage.prepare, job);
    await worker.perform(JobStage.onDevice, job);

    // Two photos, different content hashes, one picture: one read.
    expect(reader.reads, 1);
  });

  test('a different photo is read on its own', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    await fixture.addPhoto(1, plateText: 'AT-0042 MOTOR 7');
    final CountingOcr reader = CountingOcr('text');
    final ProcessingStageWorker worker = fixture.worker(ocr: reader);
    final ProcessingJob job = ProcessingJob(
      id: 'job-1',
      recordId: fixture.record.id,
    );

    await worker.perform(JobStage.prepare, job);
    await worker.perform(JobStage.onDevice, job);

    expect(reader.reads, 2);
  });
}
