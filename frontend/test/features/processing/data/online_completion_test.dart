import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/record_fields.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/data/ocr_cache.dart';
import 'package:tapture/features/processing/data/online_completion.dart';
import 'package:tapture/features/processing/data/processing_snapshot.dart';
import 'package:tapture/features/processing/data/proposal_collector.dart';
import 'package:tapture/features/processing/data/record_bundle_loader.dart';
import 'package:tapture/features/processing/domain/confidence.dart';
import 'package:tapture/features/processing/domain/online_skip_rule.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';

import '../../../support/processing_fixture.dart';

void main() {
  late ProcessingFixture fixture;
  late ProcessingJob job;

  setUp(() async {
    fixture = await ProcessingFixture.open();
    job = await fixture.job();
    await fixture.addField('serial', required: true, order: 0);
    await fixture.addField('model', order: 1);
    await fixture.addField('rating', required: true, order: 2);
    await fixture.addField('notes', order: 3);
  });

  OnlineCompletion completion() {
    return OnlineCompletion(
      collector: ProposalCollector(
        cache: OcrCache(
          db: fixture.db,
          clock: fixture.clock,
          deviceId: 'device-a',
          ids: fixture.ids,
        ),
        responses: fixture.responses,
        currentRevision: (_, _) async => 'test-project',
      ),
      settings: fixture.stageSettings(),
    );
  }

  Future<void> stored(
    String key,
    String raw, {
    double? confidence,
    String source = 'extraction',
  }) async {
    expect(
      await insertRecordField(
        fixture.db,
        row: RecordFieldsCompanion(
          recordId: Value<String>(fixture.record.id),
          fieldKey: Value<String>(key),
          valueRaw: Value<String>(raw),
          confidence: Value<double?>(confidence),
          source: Value<String>(source),
        ),
        clock: fixture.clock,
        deviceId: 'device-a',
        ids: fixture.ids,
      ),
      isA<Success<RecordField>>(),
    );
  }

  test(
    'current grounded proposals replace old raw confidence for skipping',
    () async {
      final Photo photo = await fixture.db
          .select(fixture.db.photos)
          .getSingle();
      await stored('serial', 'SN1', confidence: 0.2);
      await stored('model', 'CR-10', source: 'manual');
      expect(
        await fixture.responses.save(
          jobId: job.id,
          requestSummary: jsonEncode(<String, Object?>{
            'kind': 'online',
            'projectRevision': 'test-project',
            'sourceRevision': await ProcessingSnapshot.sourceRevision(
              await fixture.bundle(),
              privacyRevision: '',
            ),
            'privacyRevision': '',
            'requestGeneration': job.requestGeneration,
            'sources': <Map<String, String>>[
              <String, String>{'id': 'photo:${photo.id}'},
            ],
          }),
          rawResponse:
              '{"fields":{"serial":{"value":"SN2","confidence":0.99,'
              '"evidence":["photo:${photo.id}"]},"rating":{"value":"240 V",'
              '"confidence":0.95,"evidence":["photo:${photo.id}"]}}}',
          parsedOk: true,
        ),
        isA<Success<ProcessingResult>>(),
      );

      final List<SkipField> fields = await completion().forOnline(
        job,
        await fixture.bundle(),
      );

      expect(fields, <SkipField>[
        (requiredField: true, value: 'SN2', band: ConfidenceBand.high),
        (requiredField: true, value: '240 V', band: ConfidenceBand.high),
        (requiredField: false, value: null, band: null),
      ]);
      final RecordField raw =
          (await fixture.db.select(fixture.db.recordFields).get()).firstWhere(
            (RecordField field) => field.fieldKey == 'serial',
          );
      expect(raw.valueRaw, 'SN1');
    },
  );

  test(
    'old high-confidence OCR does not skip an explicit field reanalysis',
    () async {
      await stored('serial', 'OLD123', source: 'ocr', confidence: 0.99);
      final ProcessingJob scoped = job.copyWith(fieldKeys: <String>['serial']);
      final List<SkipField> fields = await completion().forOnline(
        scoped,
        await RecordBundleLoader(
          db: fixture.db,
        ).load(fixture.record.id, fieldKeys: scoped.fieldKeys),
      );
      expect(fields, <SkipField>[
        (requiredField: true, value: null, band: null),
      ]);
      expect(OnlineSkipRule.reason(fields), isNull);
    },
  );

  test(
    'an old extraction value needs grounded evidence before skipping AI',
    () async {
      await stored('serial', 'OLD123', confidence: 0.99);
      final List<SkipField> fields = await completion().forOnline(
        job,
        await fixture.bundle(),
      );
      expect(fields.first.value, isNull);
      expect(fields.first.band, isNull);
      expect(OnlineSkipRule.reason(fields), isNull);
    },
  );

  test('a record with nothing yet reads as empty', () async {
    final List<SkipField> fields = await completion().forOnline(
      job,
      await fixture.bundle(),
    );

    expect(fields.map((SkipField f) => f.value), everyElement(isNull));
    expect(fields.map((SkipField f) => f.requiredField), <bool>[
      true,
      false,
      true,
      false,
    ]);
    expect(OnlineSkipRule.reason(fields), isNull);
  });

  test(
    'missing required source-protected fields do not request online extraction',
    () async {
      await fixture.db
          .update(fixture.db.templateFields)
          .write(
            const TemplateFieldsCompanion(inputMode: Value<String>('AUTO')),
          );
      final List<SkipField> fields = await completion().forOnline(
        job,
        await fixture.bundle(),
      );
      expect(fields, isEmpty);
      expect(OnlineSkipRule.reason(fields), contains('No eligible fields'));
    },
  );
}
