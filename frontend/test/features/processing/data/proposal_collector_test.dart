import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ocr_block.dart';
import 'package:tapture/core/ai/ocr_result.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/data/ocr_cache.dart';
import 'package:tapture/features/processing/data/proposal_collector.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/processing/domain/proposal_application.dart';

import '../../../support/processing_fixture.dart';

void main() {
  late ProcessingFixture fixture;
  late ProcessingJob job;

  setUp(() async {
    fixture = await ProcessingFixture.open();
    job = await fixture.job();
    await fixture.addField('serial', pattern: r'SN\d{6}', required: true);
    await fixture.addField('model');
    await fixture.setIdentityFields(<String>['serial']);
  });

  OcrCache cache() {
    return OcrCache(
      db: fixture.db,
      clock: fixture.clock,
      deviceId: 'device-a',
      ids: fixture.ids,
    );
  }

  ProposalCollector collector() {
    return ProposalCollector(cache: cache(), responses: fixture.responses);
  }

  Future<void> plate(String line) async {
    expect(
      await cache().put(
        contentHash: 'sha-0',
        perceptualHash: '',
        result: OcrResult(
          text: 'GRUNDFOS\n$line',
          blocks: <OcrBlock>[
            const OcrBlock(
              text: 'GRUNDFOS',
              bounds: Rect.fromLTWH(10, 10, 200, 30),
              confidence: 0.9,
            ),
            OcrBlock(
              text: line,
              bounds: const Rect.fromLTWH(10, 60, 200, 30),
              confidence: 0.88,
            ),
          ],
          engine: 'test',
        ),
      ),
      isA<Success<void>>(),
    );
  }

  Future<void> respond(String raw, {bool parsedOk = true}) async {
    expect(
      await fixture.responses.save(
        jobId: job.id,
        requestSummary:
            '{"kind":"online","provider":"backend","model":"default",'
            '"promptVersion":"v3"}',
        rawResponse: raw,
        parsedOk: parsedOk,
      ),
      isA<Success<ProcessingResult>>(),
    );
  }

  test('a plate identifier becomes a proposal with its region', () async {
    await plate('SN458923');

    final ProposalSelection selection = await collector().collect(
      job,
      await fixture.bundle(),
    );

    final ProposedValue serial = selection.proposals.single;
    expect(serial.fieldKey, 'serial');
    expect(serial.value, 'SN458923');
    expect(serial.confidence, 0.88);
    expect(serial.provenance.source, 'ocr');
    expect(serial.provenance.provider, 'on-device');
    final Photo photo = await fixture.db.select(fixture.db.photos).getSingle();
    expect(serial.evidence.single.photoId, photo.id);
    expect(serial.evidence.single.regionJson, isNotNull);
    expect(serial.evidence.single.snippet, 'SN458923');
  });

  test('a stored response fills the rest and the plate wins a tie', () async {
    await plate('SN458923');
    await respond(
      '{"fields":{"serial":{"value":"SN000001","confidence":0.99,'
      '"evidence":["SN000001"]},"model":{"value":"CR-10",'
      '"confidence":0.8,"evidence":["model CR-10"]}}}',
    );

    final ProposalSelection selection = await collector().collect(
      job,
      await fixture.bundle(),
    );

    expect(
      <String, String?>{
        for (final ProposedValue value in selection.proposals)
          value.fieldKey: value.value,
      },
      <String, String?>{'serial': 'SN458923', 'model': 'CR-10'},
    );
    final ProposedValue model = selection.proposals.last;
    expect(model.provenance.source, 'extraction');
    expect(model.provenance.provider, 'backend');
    expect(model.provenance.promptVersion, 'v3');
    expect(model.evidence.single.snippet, 'model CR-10');
  });

  test(
    'an unsupported or malformed value is dropped with the reason',
    () async {
      await respond(
        '{"fields":{"serial":{"value":"12345","confidence":0.9,'
        '"evidence":["12345"]},"model":{"value":"CR-10",'
        '"confidence":0.9,"evidence":[]}}}',
      );

      final ProposalSelection selection = await collector().collect(
        job,
        await fixture.bundle(),
      );

      expect(selection.proposals, isEmpty);
      expect(
        selection.rejections,
        containsAll(<String>[
          'serial does not match its identifier pattern.',
          'No evidence supports model.',
        ]),
      );
    },
  );

  test('a response that did not parse is not used', () async {
    await respond(
      '{"fields":{"model":{"value":"CR-10","confidence":0.9,'
      '"evidence":["CR-10"]}}}',
      parsedOk: false,
    );

    expect(
      (await collector().collect(job, await fixture.bundle())).proposals,
      isEmpty,
    );
  });
}
