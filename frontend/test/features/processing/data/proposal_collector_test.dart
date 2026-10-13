import 'dart:convert';
import 'dart:ui';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ocr_block.dart';
import 'package:tapture/core/ai/ocr_result.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/data/ocr_cache.dart';
import 'package:tapture/features/processing/data/processing_evidence.dart';
import 'package:tapture/features/processing/data/processing_snapshot.dart';
import 'package:tapture/features/processing/data/proposal_collector.dart';
import 'package:tapture/features/processing/data/record_bundle_loader.dart';
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
    return ProposalCollector(
      cache: cache(),
      responses: fixture.responses,
      currentRevision: (job, bundle) async => 'test-project',
    );
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
    final bundle = await fixture.bundle();
    final sources = await ProcessingEvidence(
      cache: cache(),
    ).catalogue(bundle, const <ProcessingResult>[]);
    final Object? document = jsonDecode(raw);
    if (document is Map && document['fields'] is Map) {
      for (final Object? field in (document['fields']! as Map).values) {
        if (field is! Map || field['evidence'] is! List) continue;
        field['evidence'] = <Object?>[
          for (final Object? reference in field['evidence']! as List)
            if (reference is String && !sources.containsKey(reference))
              sources.values
                      .where(
                        (source) =>
                            source['text'] is String &&
                            (source['text']! as String).contains(reference),
                      )
                      .firstOrNull?['id'] ??
                  reference
            else
              reference,
        ];
      }
    }
    expect(
      await fixture.responses.save(
        jobId: job.id,
        requestSummary: jsonEncode(<String, Object?>{
          'kind': 'online',
          'provider': 'backend',
          'model': 'default',
          'promptVersion': 'v3',
          'projectRevision': 'test-project',
          'sourceRevision': await ProcessingSnapshot.sourceRevision(
            bundle,
            privacyRevision: '',
          ),
          'privacyRevision': '',
          'requestGeneration': job.requestGeneration,
          'sources': sources.values.toList(),
        }),
        rawResponse: jsonEncode(document),
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

  test(
    'protected identity patterns stay local and cached hostile keys are rejected',
    () async {
      await fixture.db
          .update(fixture.db.templateFields)
          .write(
            const TemplateFieldsCompanion(
              inputMode: Value<String>('MANUAL_ONLY'),
            ),
          );
      await plate('SN458923 model CR-10');
      await respond(
        '{"fields":{"serial":{"value":"SN458923","confidence":0.99,'
        '"evidence":["SN458923"]},"model":{"value":"CR-10",'
        '"confidence":0.99,"evidence":["CR-10"]}}}',
      );
      final ProposalSelection selection = await collector().collect(
        job,
        await fixture.bundle(),
      );
      expect(selection.proposals, isEmpty);
      expect(
        selection.rejections,
        containsAll(<String>[
          'serial is protected from extraction.',
          'model is protected from extraction.',
        ]),
      );
      expect(
        (await fixture.responses.forJob(
          job.id,
        )).getOrThrow().single.rawResponse,
        contains('SN458923'),
      );
    },
  );

  test('a stored response fills the rest from retained text', () async {
    await plate('SN458923 model CR-10');
    await respond(
      '{"fields":{"serial":{"value":"SN458923","confidence":0.99,'
      '"evidence":["SN458923"]},"model":{"value":"CR-10",'
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
    expect(
      model.evidence.map((e) => e.snippet).join('\n'),
      contains('model CR-10'),
    );
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
          'No evidence supports serial.',
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

  test('a fabricated source ID never becomes a proposal', () async {
    await plate('CR-10');
    await respond(
      '{"fields":{"model":{"value":"CR-10","confidence":0.99,"evidence":["photo:invented"]}}}',
    );
    final ProposalSelection selection = await collector().collect(
      job,
      await fixture.bundle(),
    );
    expect(selection.proposals, isEmpty);
    expect(selection.rejections, contains('No evidence supports model.'));
  });

  test('a supported source that was not sent cannot become evidence', () async {
    await plate('CR-10');
    final Photo photo = await fixture.db.select(fixture.db.photos).getSingle();
    await fixture.responses.save(
      jobId: job.id,
      requestSummary: '{"kind":"online","sources":[]}',
      rawResponse:
          '{"fields":{"model":{"value":"CR-10","confidence":0.99,"evidence":["ocr:${photo.id}"]}}}',
      parsedOk: true,
    );
    expect(
      (await collector().collect(job, await fixture.bundle())).proposals,
      isEmpty,
    );
  });

  test('conflicting supported values are unresolved for review', () async {
    await plate('SN458923 SN000001');
    final Photo photo = await fixture.db.select(fixture.db.photos).getSingle();
    await respond(
      '{"fields":{"serial":{"value":"SN000001","confidence":0.99,"evidence":["photo:${photo.id}"]}}}',
    );
    final ProposalSelection selection = await collector().collect(
      job,
      await fixture.bundle(),
    );
    expect(
      selection.proposals.where(
        (ProposedValue value) => value.fieldKey == 'serial',
      ),
      isEmpty,
    );
    expect(
      selection.rejections.join(' '),
      contains('Conflicting values for serial'),
    );
  });

  test(
    'photo parameters map optional typed fields with their true source',
    () async {
      await fixture.addField('frequency', type: 'decimal', unit: 'Hz');
      await fixture.addField('capacity', type: 'decimal', unit: 'L');
      await fixture.addField('working', type: 'boolean');
      await plate(
        'Model: CR-10\nFrequency: 50 Hz\nCapacity: 1000 mL\nWorking: Yes',
      );
      final ProposalSelection selection = await collector().collect(
        job,
        await fixture.bundle(),
      );
      final Map<String, ProposedValue> values = <String, ProposedValue>{
        for (final ProposedValue proposal in selection.proposals)
          proposal.fieldKey: proposal,
      };
      expect(values['model']!.value, 'CR-10');
      expect(values['frequency']!.value, '50 Hz');
      expect(values['capacity']!.value, '1000 mL');
      expect(values['working']!.value, 'Yes');
      expect(
        values.values.every((value) => value.provenance.model == 'test'),
        isTrue,
      );
      expect(
        values.values.every((value) => value.evidence.single.photoId != null),
        isTrue,
      );
      expect(selection.rejections, isEmpty);
    },
  );

  test(
    'different photos with conflicting parameter values require human review',
    () async {
      await fixture.addField('frequency', type: 'decimal', unit: 'Hz');
      await plate('Frequency: 50 Hz');
      final Photo second = await fixture.addPhoto(
        1,
        plateText: 'Frequency: 60 Hz',
      );
      await cache().put(
        contentHash: second.sha256,
        perceptualHash: '',
        result: const OcrResult(text: 'Frequency: 60 Hz', blocks: <OcrBlock>[]),
      );
      final ProposalSelection selection = await collector().collect(
        job,
        await fixture.bundle(),
      );
      expect(
        selection.proposals.where((value) => value.fieldKey == 'frequency'),
        isEmpty,
      );
      expect(
        selection.rejections.join(' '),
        contains('Conflicting values for frequency'),
      );
    },
  );

  test('a selected field never consumes unselected parameter values', () async {
    await fixture.addField('description');
    await plate('Description: observed Model: CR-10');
    final bundle = await RecordBundleLoader(
      db: fixture.db,
    ).load(fixture.record.id, fieldKeys: const <String>['description']);
    final ProposalSelection selection = await collector().collect(job, bundle);
    expect(selection.proposals.single.fieldKey, 'description');
    expect(selection.proposals.single.value, 'observed');
  });

  test(
    'equivalent unit values from AI and OCR agree without losing evidence',
    () async {
      await fixture.addField('capacity', type: 'decimal', unit: 'L');
      await plate('Capacity: 13000 mL');
      final Photo photo = await fixture.db
          .select(fixture.db.photos)
          .getSingle();
      // Text fields can carry supported units from an online provider; typed
      // numeric fields return their canonical amount against the selected unit.
      await respond(
        '{"fields":{"capacity":{"value":13,"confidence":0.99,'
        '"evidence":["photo:${photo.id}"]}}}',
      );
      final ProposalSelection selection = await collector().collect(
        job,
        await fixture.bundle(),
      );
      expect(selection.proposals.single.value, '13');
      expect(selection.proposals.single.confidence, 0.99);
      expect(selection.proposals.single.provenance.source, 'extraction');
      expect(selection.proposals.single.evidence, hasLength(2));
      expect(selection.rejections, isEmpty);
    },
  );

  test(
    'grounded AI values still must satisfy their field types and ranges',
    () async {
      await fixture.addField('count', type: 'number', validation: '{"min":0}');
      await fixture.addField('inspection_date', type: 'date');
      await plate('Count: -1\nInspection date: 2026-02-31');
      final Photo photo = await fixture.db
          .select(fixture.db.photos)
          .getSingle();
      await respond(
        '{"fields":{"count":{"value":-1,"confidence":0.99,'
        '"evidence":["photo:${photo.id}"]},"inspection_date":{"value":"2026-02-31",'
        '"confidence":0.99,"evidence":["photo:${photo.id}"]}}}',
      );
      final ProposalSelection selection = await collector().collect(
        job,
        await fixture.bundle(),
      );
      expect(selection.proposals, isEmpty);
      expect(
        selection.rejections.join(' '),
        contains('proposed value for count'),
      );
      expect(
        selection.rejections.join(' '),
        contains('proposed value for inspection_date'),
      );
    },
  );

  test(
    'unlabelled values shared by identity patterns require a mapping decision',
    () async {
      await fixture.addField('identity_a', pattern: r'^[A-Z0-9]+$');
      await fixture.addField('identity_b', pattern: r'^[A-Z0-9]+$');
      await fixture.setIdentityFields(<String>['identity_a', 'identity_b']);
      await plate('AB123');
      final ProposalSelection selection = await collector().collect(
        job,
        await fixture.bundle(),
      );
      expect(selection.proposals, isEmpty);
      expect(
        selection.rejections.join(' '),
        contains('identity_a has no unique field'),
      );
      expect(
        selection.rejections.join(' '),
        contains('identity_b has no unique field'),
      );
    },
  );

  test(
    'a labelled identity never supplies an unrelated identity fallback',
    () async {
      await fixture.addField('identity_a', pattern: r'^[A-Z0-9]+$');
      await fixture.addField('identity_b', pattern: r'^[A-Z0-9]+$');
      await fixture.setIdentityFields(<String>['identity_a', 'identity_b']);
      await plate('Identity a: AB123');
      final ProposalSelection selection = await collector().collect(
        job,
        await fixture.bundle(),
      );
      expect(selection.proposals.single.fieldKey, 'identity_a');
      expect(selection.proposals.single.value, 'AB123');
    },
  );

  test(
    'a collector without verifiable current request context ignores online values',
    () async {
      await plate('CR-10');
      final Photo photo = await fixture.db
          .select(fixture.db.photos)
          .getSingle();
      await respond(
        '{"fields":{"model":{"value":"CR-10","confidence":0.99,'
        '"evidence":["photo:${photo.id}"]}}}',
      );
      final unverified = ProposalCollector(
        cache: cache(),
        responses: fixture.responses,
      );
      expect(
        (await unverified.collect(job, await fixture.bundle())).proposals,
        isEmpty,
      );
    },
  );

  test('equivalent measured units across photos retain both sources', () async {
    await fixture.addField('capacity', type: 'decimal', unit: 'L');
    await plate('Capacity: 13000 mL');
    final Photo second = await fixture.addPhoto(
      1,
      plateText: 'Capacity: 13.0 L',
    );
    await cache().put(
      contentHash: second.sha256,
      perceptualHash: '',
      result: const OcrResult(text: 'Capacity: 13.0 L', blocks: <OcrBlock>[]),
    );
    final ProposalSelection selection = await collector().collect(
      job,
      await fixture.bundle(),
    );
    expect(selection.proposals.single.value, '13000 mL');
    expect(
      selection.proposals.single.evidence.map((e) => e.photoId).toSet(),
      hasLength(2),
    );
    expect(selection.rejections, isEmpty);
  });

  test(
    'equal confidence duplicate mappings retain both photo regions',
    () async {
      await fixture.addField('capacity', type: 'decimal', unit: 'L');
      await plate('Capacity: 13000 mL');
      final Photo second = await fixture.addPhoto(
        1,
        plateText: 'Capacity: 13 L',
      );
      await cache().put(
        contentHash: second.sha256,
        perceptualHash: '',
        result: const OcrResult(
          text: 'Capacity: 13 L',
          blocks: <OcrBlock>[
            OcrBlock(
              text: 'Capacity: 13 L',
              bounds: Rect.fromLTWH(10, 60, 200, 30),
              confidence: 0.88,
            ),
          ],
        ),
      );
      final ProposalSelection selection = await collector().collect(
        job,
        await fixture.bundle(),
      );
      expect(selection.proposals.single.value, '13000 mL');
      expect(selection.proposals.single.evidence, hasLength(2));
      expect(selection.rejections, isEmpty);
    },
  );

  test('different measured values across photos remain unresolved', () async {
    await fixture.addField('capacity', type: 'decimal', unit: 'L');
    await plate('Capacity: 13000 mL');
    final Photo second = await fixture.addPhoto(1, plateText: 'Capacity: 14 L');
    await cache().put(
      contentHash: second.sha256,
      perceptualHash: '',
      result: const OcrResult(text: 'Capacity: 14 L', blocks: <OcrBlock>[]),
    );
    final ProposalSelection selection = await collector().collect(
      job,
      await fixture.bundle(),
    );
    expect(selection.proposals, isEmpty);
    expect(
      selection.rejections.join(' '),
      contains('Conflicting values for capacity'),
    );
  });
}
