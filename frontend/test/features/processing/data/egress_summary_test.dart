import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/data/processing_stage_worker.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/processing_fixture.dart';

void main() {
  /// A record the plate cannot complete, so online work would be sent.
  Future<({ProcessingFixture fixture, ProcessingJob job})> record() async {
    final ProcessingFixture fixture = await ProcessingFixture.open(
      plateText: 'GRUNDFOS 240V',
    );
    await fixture.addPhoto(1, plateText: 'AT-0042 MOTOR 7');
    await fixture.addField('serial', required: true);
    return (fixture: fixture, job: await fixture.job());
  }

  Future<({int imageCount, int payloadBytes})> summarise(
    ProcessingFixture fixture,
    ProcessingJob job, {
    SettingsStore? settings,
  }) async {
    final ProcessingStageWorker worker = fixture.worker(
      provider: ScriptedExtraction(<String>['{}'], transcript: 'unused'),
      settings: settings,
    );
    await worker.perform(JobStage.prepare, job);
    await worker.perform(JobStage.onDevice, job);
    return worker.egressSummary(job);
  }

  /// The bytes of the compressed copies an online call sends: each copy
  /// the reading copy (`<copy>.ocr.jpg`) was made from.
  int sentBytes(ProcessingFixture fixture) {
    const String suffix = '.ocr.jpg';
    return fixture.documents
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith(suffix))
        .map(
          (File file) =>
              File(file.path.substring(0, file.path.length - suffix.length)),
        )
        .fold(0, (int sum, File file) => sum + file.lengthSync());
  }

  test('the summary counts every compressed image and the text', () async {
    final seeded = await record();

    final ({int imageCount, int payloadBytes}) summary = await summarise(
      seeded.fixture,
      seeded.job,
    );

    expect(summary.imageCount, 2);
    expect(summary.payloadBytes, greaterThan(sentBytes(seeded.fixture)));
  });

  test('a record the device completes sends nothing', () async {
    final ProcessingFixture fixture = await ProcessingFixture.open();
    await fixture.addField('notes');

    expect(await summarise(fixture, await fixture.job()), (
      imageCount: 0,
      payloadBytes: 0,
    ));
  });

  test('offline by choice sends nothing', () async {
    final seeded = await record();

    expect(
      await summarise(
        seeded.fixture,
        seeded.job,
        settings: SettingsStore.fake(
          stored: <String, Object?>{SettingKeys.offlineByChoice.name: true},
        ),
      ),
      (imageCount: 0, payloadBytes: 0),
    );
  });

  test('a project that keeps images on the device sends text only', () async {
    final seeded = await record();
    final ({int imageCount, int payloadBytes}) withImages = await summarise(
      seeded.fixture,
      seeded.job,
    );
    await seeded.fixture.setProjectSettings('{"doNotSendImages":true}');

    final ({int imageCount, int payloadBytes}) textOnly = await summarise(
      seeded.fixture,
      seeded.job,
    );

    expect(textOnly.imageCount, 0);
    expect(textOnly.payloadBytes, greaterThan(0));
    expect(
      withImages.payloadBytes - textOnly.payloadBytes,
      sentBytes(seeded.fixture),
    );
  });

  test('a voice note counts as audio until its transcript is stored', () async {
    final seeded = await record();
    final ({int imageCount, int payloadBytes}) silent = await summarise(
      seeded.fixture,
      seeded.job,
    );
    final Attachment audio = await seeded.fixture.addAudio(0, bytes: 5000);

    final ({int imageCount, int payloadBytes}) spoken = await summarise(
      seeded.fixture,
      seeded.job,
    );
    expect(spoken.payloadBytes - silent.payloadBytes, 5000);

    expect(
      await seeded.fixture.responses.save(
        jobId: seeded.job.id,
        requestSummary:
            '{"kind":"transcript","attachmentId":"${audio.id}",'
            '"provider":"backend","model":"default"}',
        rawResponse: 'pump hums',
        parsedOk: true,
      ),
      isA<Success<ProcessingResult>>(),
    );
    final ({int imageCount, int payloadBytes}) transcribed = await summarise(
      seeded.fixture,
      seeded.job,
    );
    expect(transcribed.payloadBytes - silent.payloadBytes, 'pump hums'.length);
  });
}
