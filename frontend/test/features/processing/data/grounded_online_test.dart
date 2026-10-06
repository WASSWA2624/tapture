import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/ai_usage.dart';
import 'package:tapture/core/ai/proxy_ai_service.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/attachment_owners.dart';
import 'package:tapture/core/db/tables/captions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/processing/data/processing_findings.dart';
import 'package:tapture/features/processing/data/processing_stage_worker.dart';
import 'package:tapture/features/processing/data/processing_usage.dart';
import 'package:tapture/features/processing/data/stage_support.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/processing_fixture.dart';

const String _reply =
    '{"fields":{"serial":{"value":"SN458923",'
    '"confidence":0.9,"evidence":["photo:photo-1"]}}}';

void main() {
  late ProcessingFixture fixture;
  late ProcessingJob job;
  late String reply;
  setUp(() async {
    fixture = await ProcessingFixture.open(plateText: 'GRUNDFOS');
    await fixture.addField('serial', required: true);
    job = await fixture.job();
    final Photo photo = await fixture.db.select(fixture.db.photos).getSingle();
    reply = _reply.replaceAll('photo:photo-1', 'photo:${photo.id}');
  });

  Future<void> prepare(ProcessingStageWorker worker) async {
    for (final JobStage stage in <JobStage>[
      JobStage.prepare,
      JobStage.onDevice,
      JobStage.detect,
    ]) {
      await worker.perform(stage, job);
    }
  }

  Future<Caption> caption(String photoId, String text) async =>
      (await insertCaption(
        fixture.db,
        row: CaptionsCompanion(
          ownerType: const Value<CaptionOwnerType>(CaptionOwnerType.photo),
          ownerId: Value<String>(photoId),
          textRaw: Value<String>(text),
          inputMode: const Value<CaptionInputMode>(CaptionInputMode.typed),
        ),
        clock: fixture.clock,
        deviceId: 'device-a',
        ids: fixture.ids,
      )).getOrThrow();

  test(
    'real proxy malformed output is saved before one bounded repair',
    () async {
      final List<Map<String, Object?>> calls = <Map<String, Object?>>[];
      final ProxyAiService service = ProxyAiService(
        baseUrl: 'https://organisation.test',
        readBytes: (String _) async => Success<Uint8List>(Uint8List(1)),
        send:
            ({required String path, required Map<String, Object?> json}) async {
              calls.add(json);
              return (
                status: 200,
                body: jsonEncode(<String, Object?>{
                  'text': calls.length == 1 ? 'unfinished {' : reply,
                  'provider': 'gemini',
                  'model': 'default',
                  'usage': <String, Object?>{
                    'totalTokens': 12,
                    'reservedCost': 0.002,
                    'currency': 'configured',
                  },
                }),
              );
            },
      );
      final ProcessingStageWorker worker = fixture.worker(
        provider: service,
        ocr: CountingOcr('GRUNDFOS'),
      );
      await prepare(worker);
      await worker.perform(JobStage.online, job);
      expect(calls, hasLength(2));
      final Map<String, Object?> repairEnvelope =
          jsonDecode(
                utf8.decode(base64Decode(calls.last['payload']! as String)),
              )
              as Map<String, Object?>;
      expect(
        (repairEnvelope['data']! as Map<String, Object?>)['repairError'],
        isNotNull,
      );
      expect(calls.first['processing'], isNot(calls.last['processing']));
      final List<ProcessingResult> replies =
          (await fixture.db.select(fixture.db.processingResults).get())
              .where(
                (row) =>
                    StageSupport.summaryValue(row.requestSummary, 'kind') ==
                    'online',
              )
              .toList();
      expect(replies.map((row) => row.rawResponse), <String>[
        'unfinished {',
        reply,
      ]);
      expect(replies.first.parsedOk, isFalse);
      expect(replies.last.parsedOk, isTrue);
      await worker.perform(JobStage.online, job.copyWith(requestGeneration: 1));
      expect(calls, hasLength(2));
      final usage = (await ProcessingUsage(
        db: fixture.db,
        settings: SettingsStore.fake(),
      ).on(fixture.clock.nowUtc())).getOrThrow();
      expect(usage.requests, 2);
      expect(usage.totalTokens, 24);
    },
  );

  test(
    'the envelope preserves caption-photo and audio-photo relationships',
    () async {
      final Photo second = await fixture.addPhoto(1, plateText: 'PUMP');
      final Caption note = await caption(second.id, 'Room 3 pump');
      final Attachment audio = await fixture.addAudio(0);
      await fixture.db
          .into(fixture.db.attachmentOwners)
          .insert(
            AttachmentOwnersCompanion(
              id: Value<String>(fixture.ids.newId()),
              attachmentId: Value<String>(audio.id),
              ownerType: const Value<AttachmentOwnerType>(
                AttachmentOwnerType.photo,
              ),
              ownerId: Value<String>(second.id),
              sortOrder: const Value<int>(0),
              createdAt: Value<DateTime>(fixture.clock.nowUtc()),
              updatedAt: Value<DateTime>(fixture.clock.nowUtc()),
              updatedByDevice: const Value<String>('device-a'),
              rev: const Value<int>(1),
            ),
          );
      final ScriptedExtraction service = ScriptedExtraction(<String>[
        reply,
      ], transcript: 'Room 3 pump');
      final ProcessingStageWorker worker = fixture.worker(
        provider: service,
        ocr: CountingOcr('GRUNDFOS'),
      );
      await prepare(worker);
      await worker.perform(JobStage.online, job);
      final ExtractFieldsRequest sent = service.requests.single;
      expect(
        sent.sources.singleWhere(
          (source) => source['id'] == 'caption:${note.id}',
        )['photoId'],
        second.id,
      );
      expect(
        sent.sources.singleWhere(
          (source) => source['id'] == 'audio:${audio.id}',
        )['photoIds'],
        <String>[second.id],
      );
      expect(sent.recordId, fixture.record.id);
      expect(sent.projectRevision, matches(RegExp(r'^[a-f0-9]{64}$')));
      expect(sent.idempotencyKey, matches(RegExp(r'^[a-f0-9]{64}$')));
    },
  );

  test(
    'unchanged successful extraction is reused across explicit requeue generations',
    () async {
      final ScriptedExtraction service = ScriptedExtraction(<String>[reply]);
      final ProcessingStageWorker worker = fixture.worker(
        provider: service,
        ocr: CountingOcr('GRUNDFOS'),
      );
      await prepare(worker);
      await worker.perform(JobStage.online, job);
      final ScriptedExtraction retry = ScriptedExtraction(<String>[reply]);
      await fixture
          .worker(provider: retry, ocr: CountingOcr('GRUNDFOS'))
          .perform(JobStage.online, job.copyWith(requestGeneration: 1));
      expect(retry.requests, isEmpty);
      final List<ProcessingResult> rows = await fixture.db
          .select(fixture.db.processingResults)
          .get();
      expect(
        rows.where(
          (row) =>
              StageSupport.summaryValue(row.requestSummary, 'kind') == 'cache',
        ),
        hasLength(1),
      );
    },
  );

  test(
    'changed caption, schema and approved limit each require a new request',
    () async {
      final ScriptedExtraction service = ScriptedExtraction(<String>[reply]);
      final SettingsStore settings = SettingsStore.fake();
      final ProcessingStageWorker worker = fixture.worker(
        provider: service,
        settings: settings,
        ocr: CountingOcr('GRUNDFOS'),
      );
      await prepare(worker);
      await worker.perform(JobStage.online, job);
      final Photo photo = await fixture.db
          .select(fixture.db.photos)
          .getSingle();
      await caption(photo.id, 'Room 3');
      await worker.perform(JobStage.online, job);
      await fixture.addField('model', required: true);
      await worker.perform(JobStage.online, job);
      final ProcessingStageWorker costChanged = fixture.worker(
        provider: service,
        settings: SettingsStore.fake(
          stored: <String, Object?>{SettingKeys.aiRequestMaxCost.name: 2.0},
        ),
        ocr: CountingOcr('GRUNDFOS'),
      );
      await costChanged.perform(JobStage.online, job);
      expect(service.requests, hasLength(4));
      expect(
        service.requests.map((request) => request.idempotencyKey).toSet(),
        hasLength(4),
      );
    },
  );

  test(
    'cancellation keeps the reply and stops repair and subsequent media batches',
    () async {
      for (var index = 1; index < 7; index++) {
        await fixture.addPhoto(index, plateText: 'PUMP');
      }
      final CancellationToken token = CancellationToken();
      final _ObservedService service = _ObservedService(() async {
        token.cancel();
      }, raw: 'malformed');
      final ProcessingStageWorker worker = fixture.worker(
        provider: service,
        ocr: CountingOcr('GRUNDFOS'),
      );
      await prepare(worker);
      await expectLater(
        worker.perform(JobStage.online, job, token),
        throwsA(isA<CancelledFailure>()),
      );
      expect(service.requests, hasLength(1));
      expect(service.requests.single.cancellationToken, same(token));
      final List<ProcessingResult> rows = await fixture.db
          .select(fixture.db.processingResults)
          .get();
      expect(
        rows.where((row) => row.rawResponse == 'malformed').single.parsedOk,
        isFalse,
      );
    },
  );

  test(
    'an edit during the provider call keeps raw evidence without applying stale fields',
    () async {
      final _ObservedService service = _ObservedService(
        () => fixture.setContext('{"room":"New room"}'),
        raw: reply,
      );
      final ProcessingStageWorker worker = fixture.worker(
        provider: service,
        ocr: CountingOcr('GRUNDFOS'),
      );
      await prepare(worker);
      await expectLater(
        worker.perform(JobStage.online, job),
        throwsA(isA<CancelledFailure>()),
      );
      final List<ProcessingResult> rows = await fixture.db
          .select(fixture.db.processingResults)
          .get();
      expect(
        rows.where((row) => row.rawResponse == reply).single.parsedOk,
        isFalse,
      );
      await worker.perform(JobStage.validate, job);
      expect(await fixture.db.select(fixture.db.recordFields).get(), isEmpty);
      expect((await fixture.storedRecord()).status, 'needsReview');
    },
  );

  test(
    'attempt and result usage count once and cache replays add no spend',
    () async {
      final _ObservedService service = _ObservedService(
        () async {},
        raw: reply,
      );
      final ProcessingStageWorker worker = fixture.worker(
        provider: service,
        ocr: CountingOcr('GRUNDFOS'),
      );
      await prepare(worker);
      await worker.perform(JobStage.online, job);
      await worker.perform(JobStage.online, job.copyWith(requestGeneration: 1));
      final usage = (await ProcessingUsage(
        db: fixture.db,
        settings: SettingsStore.fake(),
      ).on(fixture.clock.nowUtc())).getOrThrow();
      expect(usage.requests, 1);
      expect(usage.totalTokens, 12);
      expect(usage.reservedCosts, <String, double>{'configured': 0.002});
    },
  );

  test(
    'crash resume uses its reserved identity even when the daily cap is full',
    () async {
      final SettingsStore settings = SettingsStore.fake(
        stored: <String, Object?>{SettingKeys.aiDailyRequestCap.name: 1},
      );
      final _ObservedService interrupted = _ObservedService(() async {
        throw const NetworkFailure();
      }, raw: reply);
      final ProcessingStageWorker worker = fixture.worker(
        provider: interrupted,
        settings: settings,
        ocr: CountingOcr('GRUNDFOS'),
      );
      await prepare(worker);
      await expectLater(
        worker.perform(JobStage.online, job),
        throwsA(isA<NetworkFailure>()),
      );
      final _ObservedService resumed = _ObservedService(
        () async {},
        raw: reply,
      );
      await fixture
          .worker(
            provider: resumed,
            settings: settings,
            ocr: CountingOcr('GRUNDFOS'),
          )
          .perform(JobStage.online, job);
      expect(
        resumed.requests.single.idempotencyKey,
        interrupted.requests.single.idempotencyKey,
      );
      final usage = (await ProcessingUsage(
        db: fixture.db,
        settings: settings,
      ).on(fixture.clock.nowUtc())).getOrThrow();
      expect(usage.requests, 1);
    },
  );

  test(
    'transcription and refinement persist identities and usage before extraction',
    () async {
      final Photo photo = await fixture.db
          .select(fixture.db.photos)
          .getSingle();
      final Caption note = await caption(photo.id, 'Pump 240 V.');
      await fixture.addAudio(0);
      final SettingsStore settings = SettingsStore.fake(
        stored: <String, Object?>{SettingKeys.aiRefineCaptions.name: true},
      );
      final _ObservedService service = _ObservedService(
        () async {},
        raw: reply,
        duringAuxiliary: () async {
          final List<ProcessingResult> checkpoints = await fixture.db
              .select(fixture.db.processingResults)
              .get();
          expect(
            StageSupport.summaryValue(checkpoints.last.requestSummary, 'kind'),
            'attempt',
          );
        },
      );
      final ProcessingStageWorker worker = fixture.worker(
        provider: service,
        settings: settings,
        ocr: CountingOcr('GRUNDFOS'),
      );
      await prepare(worker);
      await worker.perform(JobStage.online, job);
      expect(service.transcribed, hasLength(1));
      expect(service.refined, hasLength(1));
      expect(service.transcribed.single.recordId, fixture.record.id);
      expect(
        service.refined.single.idempotencyKey,
        matches(RegExp(r'^[a-f0-9]{64}$')),
      );
      expect(
        (await fixture.db.select(fixture.db.captions).getSingle()).textRaw,
        note.textRaw,
      );
      await worker.perform(JobStage.online, job.copyWith(requestGeneration: 1));
      final usage = (await ProcessingUsage(
        db: fixture.db,
        settings: settings,
      ).on(fixture.clock.nowUtc())).getOrThrow();
      expect(usage.requests, 3);
      expect(usage.totalTokens, 36);
      expect(usage.reservedCosts['configured'], closeTo(0.006, 0.000001));
      expect(service.transcribed, hasLength(1));
      expect(service.refined, hasLength(1));
      final ProcessingStageWorker languageChanged = fixture.worker(
        provider: service,
        settings: SettingsStore.fake(
          stored: <String, Object?>{
            SettingKeys.aiRefineCaptions.name: true,
            SettingKeys.voiceLanguage.name: 'sw',
          },
        ),
        ocr: CountingOcr('GRUNDFOS'),
      );
      await languageChanged.perform(
        JobStage.online,
        job.copyWith(requestGeneration: 1),
      );
      expect(service.transcribed, hasLength(2));
      expect(
        service.transcribed.last.idempotencyKey,
        isNot(service.transcribed.first.idempotencyKey),
      );
    },
  );

  for (final bool refine in <bool>[false, true]) {
    test(
      '${refine ? 'refinement' : 'transcription'} crash resume retains one potentially charged identity',
      () async {
        if (refine) {
          final Photo photo = await fixture.db
              .select(fixture.db.photos)
              .getSingle();
          await caption(photo.id, 'Pump 240 V.');
        } else {
          await fixture.addAudio(0);
        }
        final SettingsStore settings = SettingsStore.fake(
          stored: <String, Object?>{SettingKeys.aiRefineCaptions.name: refine},
        );
        final _ObservedService failing = _ObservedService(
          () async {},
          raw: reply,
          auxiliaryFailure: const NetworkFailure(),
        );
        final ProcessingStageWorker worker = fixture.worker(
          provider: failing,
          settings: settings,
          ocr: CountingOcr('GRUNDFOS'),
        );
        await prepare(worker);
        await expectLater(
          worker.perform(JobStage.online, job),
          throwsA(isA<NetworkFailure>()),
        );
        final ProcessingFindings findings = ProcessingFindings(db: fixture.db);
        expect(
          (await findings.requiresRetryApproval(job.id)).getOrThrow(),
          isTrue,
        );
        final _ObservedService resumed = _ObservedService(
          () async {},
          raw: reply,
        );
        await fixture
            .worker(
              provider: resumed,
              settings: settings,
              ocr: CountingOcr('GRUNDFOS'),
            )
            .perform(JobStage.online, job);
        final String initialIdentity = refine
            ? failing.refined.single.idempotencyKey
            : failing.transcribed.single.idempotencyKey;
        final String resumedIdentity = refine
            ? resumed.refined.single.idempotencyKey
            : resumed.transcribed.single.idempotencyKey;
        expect(resumedIdentity, initialIdentity);
        expect(
          (await findings.requiresRetryApproval(job.id)).getOrThrow(),
          isFalse,
        );
        final rows = await fixture.db
            .select(fixture.db.processingResults)
            .get();
        expect(
          rows.where(
            (row) =>
                StageSupport.summaryValue(row.requestSummary, 'kind') ==
                    'attempt' &&
                StageSupport.summaryValue(
                      row.requestSummary,
                      'idempotencyKey',
                    ) ==
                    initialIdentity,
          ),
          hasLength(1),
        );
      },
    );
  }
}

final class _ObservedService implements AiService {
  _ObservedService(
    this.duringRequest, {
    this.raw = _reply,
    this.duringAuxiliary,
    this.auxiliaryFailure,
  });
  final Future<void> Function() duringRequest;
  final String raw;
  final Future<void> Function()? duringAuxiliary;
  final Failure? auxiliaryFailure;
  final List<ExtractFieldsRequest> requests = <ExtractFieldsRequest>[];
  final List<TranscribeRequest> transcribed = <TranscribeRequest>[];
  final List<RefineTextRequest> refined = <RefineTextRequest>[];
  @override
  bool get isAvailable => true;
  @override
  Future<Result<ExtractFieldsResult>> extractFields(
    ExtractFieldsRequest request,
  ) async {
    requests.add(request);
    await duringRequest();
    return Success<ExtractFieldsResult>(
      ExtractFieldsResult(
        fields: const <String, String?>{},
        rawResponse: raw,
        provider: 'gemini',
        model: 'economy',
        billingKind: 'managed',
        usage: const AiUsage(
          reservedCost: 0.002,
          currency: 'configured',
          totalTokens: 12,
        ),
      ),
    );
  }

  @override
  Future<Result<ReadTextResult>> readText(ReadTextRequest request) =>
      const AiService.unavailable().readText(request);
  @override
  Future<Result<RefineTextResult>> refineText(RefineTextRequest request) async {
    refined.add(request);
    await duringAuxiliary?.call();
    if (auxiliaryFailure case final Failure failure) {
      return FailureResult<RefineTextResult>(failure);
    }
    return Success<RefineTextResult>(
      RefineTextResult(
        text: request.raw,
        provider: 'gemini',
        model: 'economy',
        billingKind: 'managed',
        usage: const AiUsage(
          reservedCost: 0.002,
          currency: 'configured',
          totalTokens: 12,
        ),
      ),
    );
  }

  @override
  Future<Result<TranscribeResult>> transcribe(TranscribeRequest request) async {
    transcribed.add(request);
    await duringAuxiliary?.call();
    if (auxiliaryFailure case final Failure failure) {
      return FailureResult<TranscribeResult>(failure);
    }
    return const Success<TranscribeResult>(
      TranscribeResult(
        text: 'Pump 240 V.',
        provider: 'gemini',
        model: 'economy',
        billingKind: 'managed',
        usage: AiUsage(
          reservedCost: 0.002,
          currency: 'configured',
          totalTokens: 12,
        ),
      ),
    );
  }
}
