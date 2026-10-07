import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/features/processing/data/processing_repository_impl.dart';
import 'package:tapture/features/processing/data/stage_support.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/settings/settings.dart';

import 'fault_injection.dart';
import 'matchers.dart';
import 'processing_fixture.dart';

const String _valid =
    '{"fields":{"serial":{"value":"SN458923","confidence":0.9,"evidence":["photo-1"]}}}';

/// Verifies malformed replies, durable checkpoints, raw evidence and explicit retry.
Future<void> verifyMalformedResponseRecovery(FaultInjector faults) async {
  final ProcessingFixture fixture = await ProcessingFixture.open(
    plateText: 'GRUNDFOS 240V',
  );
  await fixture.addField('serial', required: true);
  final ProcessingJob job = await fixture.job();
  final Photo photo = await fixture.db.select(fixture.db.photos).getSingle();
  final File originalPhoto = File(
    '${fixture.projectFolder}/${photo.relativePath}',
  );
  final Uint8List originalBytes = await originalPhoto.readAsBytes();
  Future<List<ProcessingResult>> storedResults() => (fixture.db.select(
    fixture.db.processingResults,
  )..where(($ProcessingResultsTable row) => row.jobId.equals(job.id))).get();
  List<ProcessingResult> ofKind(List<ProcessingResult> rows, String kind) =>
      rows
          .where(
            (ProcessingResult row) =>
                StageSupport.summaryValue(row.requestSummary, 'kind') == kind,
          )
          .toList();
  faults.fail(Dependency.response, const CorruptionFailure());
  ScriptedExtraction provider() => ScriptedExtraction(<String>[
    faults.check(Dependency.response) == null
        ? _valid
        : '{"fields": still broken',
  ]);
  final ScriptedExtraction badProvider = provider();
  final bad = fixture.worker(
    provider: badProvider,
    ocr: CountingOcr('GRUNDFOS 240V'),
  );
  for (final JobStage stage in <JobStage>[
    JobStage.prepare,
    JobStage.onDevice,
    JobStage.detect,
  ]) {
    await bad.perform(stage, job);
  }
  await expectLater(
    bad.perform(JobStage.online, job),
    throwsA(isA<CorruptionFailure>()),
  );
  expect(badProvider.requests, hasLength(2));
  expect(badProvider.requests.first.repairError, isNull);
  expect(badProvider.requests.last.repairError, isNotNull);
  final List<ProcessingResult> failures = await storedResults();
  final List<ProcessingResult> checkpoints = ofKind(failures, 'attempt');
  final List<ProcessingResult> replies = ofKind(failures, 'online');
  expect(checkpoints, hasLength(2));
  expect(replies, hasLength(2));
  expect(
    replies.every(
      (ProcessingResult row) =>
          !row.parsedOk && row.rawResponse == '{"fields": still broken',
    ),
    isTrue,
  );
  final Set<String?> identities = checkpoints
      .map(
        (ProcessingResult row) =>
            StageSupport.summaryValue(row.requestSummary, 'idempotencyKey'),
      )
      .toSet();
  expect(identities, hasLength(2));
  expect(
    badProvider.requests.map((request) => request.idempotencyKey),
    unorderedEquals(identities),
  );
  expect(
    checkpoints.map(
      (ProcessingResult row) =>
          StageSupport.summaryBool(row.requestSummary, 'repair'),
    ),
    unorderedEquals(<bool>[false, true]),
  );
  for (final ProcessingResult checkpoint in checkpoints) {
    expect(checkpoint.parsedOk, isFalse);
    expect(checkpoint.rawResponse, isEmpty);
    final Map<String, Object?> snapshot =
        StageSupport.json(checkpoint.requestSummary) as Map<String, Object?>;
    expect(snapshot['idempotencyKey'], matches(RegExp(r'^[a-f0-9]{64}$')));
    final ProcessingResult reply = replies.singleWhere(
      (ProcessingResult row) =>
          StageSupport.summaryValue(row.requestSummary, 'idempotencyKey') ==
          snapshot['idempotencyKey'],
    );
    final Map<String, Object?> replySummary =
        StageSupport.json(reply.requestSummary) as Map<String, Object?>;
    for (final String key in <String>[
      'projectRevision',
      'sourceRevision',
      'privacyRevision',
      'requestGeneration',
      'batchKey',
      'repair',
    ]) {
      expect(replySummary[key], snapshot[key], reason: '$key binds the reply');
    }
    expect(snapshot['requestGeneration'], job.requestGeneration);
    expect(snapshot['templateId'], fixture.template.id);
    expect(snapshot['templateVersion'], fixture.template.version);
    expect(snapshot['contextSnapshot'], jsonDecode(fixture.record.contextJson));
    expect(snapshot['schemaSnapshot'], <Map<String, Object?>>[
      <String, Object?>{
        'key': 'serial',
        'type': 'text',
        'required': true,
        'options': <String>[],
      },
    ]);
    expect(
      snapshot['sourceSnapshot'],
      unorderedEquals(<Map<String, Object?>>[
        <String, Object?>{
          'id': 'photo:${photo.id}',
          'kind': 'photo',
          'photoId': photo.id,
          'sha256': photo.sha256,
          'imageIndex': 0,
        },
        <String, Object?>{
          'id': 'ocr:${photo.id}',
          'kind': 'ocr',
          'photoId': photo.id,
          'sha256': photo.sha256,
          'text': 'GRUNDFOS 240V',
        },
      ]),
    );
  }
  expect(originalPhoto.existsSync(), isTrue);
  expect(await originalPhoto.readAsBytes(), originalBytes);
  final ProcessingRepositoryImpl queue = ProcessingRepositoryImpl(
    db: fixture.db,
    clock: fixture.clock,
    deviceId: 'device-a',
    ids: fixture.ids,
    settings: SettingsStore.fake(),
  );
  valueOf(await queue.markStage(job.id, JobStage.detect));
  valueOf(
    await queue.fail(
      job.id,
      'The provider response is malformed.',
      permanent: true,
    ),
  );
  faults.clear();
  valueOf(await queue.retry(job.id));
  final ProcessingJob retried = valueOf(await queue.byId(job.id))!;
  expect(retried.requestGeneration, job.requestGeneration + 1);
  final ScriptedExtraction goodProvider = provider();
  await fixture
      .worker(provider: goodProvider, ocr: CountingOcr('GRUNDFOS 240V'))
      .perform(JobStage.online, retried);
  expect(goodProvider.requests, hasLength(1));
  expect(goodProvider.requests.single.repairError, isNull);
  expect(
    identities,
    isNot(contains(goodProvider.requests.single.idempotencyKey)),
  );
  final List<ProcessingResult> recovered = await storedResults();
  expect(recovered.length, greaterThan(failures.length));
  expect(recovered, containsAll(failures));
  expect(
    ofKind(
      recovered,
      'online',
    ).any((ProcessingResult row) => row.parsedOk && row.rawResponse == _valid),
    isTrue,
  );
  expect(await fixture.db.select(fixture.db.photos).getSingle(), photo);
  expect(await originalPhoto.readAsBytes(), originalBytes);
}
