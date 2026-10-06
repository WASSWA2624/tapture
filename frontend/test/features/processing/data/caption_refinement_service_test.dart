import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/ai/proxy_ai_service.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/captions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/processing/data/caption_refinement_service.dart';
import 'package:tapture/features/processing/data/processing_repository_impl.dart';
import 'package:tapture/features/processing/data/provider_selection.dart';
import 'package:tapture/features/processing/data/stage_support.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/factories.dart';

void main() {
  test(
    'refinement keeps raw text and reuses the stored provider output',
    () async {
      final AppDatabase db = await seededDatabase(records: 1);
      addTearDown(db.close);
      final DateTime now = DateTime.utc(2026, 9, 23, 8);
      final FixedClock clock = FixedClock(now);
      final UuidV7Service ids = UuidV7Service.sequence(clock);
      final RecordRow record = await db.select(db.records).getSingle();
      final Caption caption = _ok(
        await insertCaption(
          db,
          row: CaptionsCompanion(
            ownerType: const Value<CaptionOwnerType>(CaptionOwnerType.record),
            ownerId: Value<String>(record.id),
            textRaw: const Value<String>('Pump SN1234 at 240 V.'),
            inputMode: const Value<CaptionInputMode>(CaptionInputMode.typed),
          ),
          clock: clock,
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final ProcessingRepositoryImpl repository = ProcessingRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
        settings: SettingsStore.fake(),
      );
      final String jobId = _ok(await repository.enqueue(record.id));
      final _RefinementService provider = _RefinementService();
      final CaptionRefinementService service = CaptionRefinementService(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
        selection: ProviderSelection(
          settings: SettingsStore.fake(),
          providers: ProviderRegistry.keyless(proxy: provider),
        ),
      );
      final Project project = await db.select(db.projects).getSingle();
      var budgetChecks = 0;

      final List<String> rejected = await service.refine(
        jobId: jobId,
        project: project,
        captions: <Caption>[caption],
        beforeRequest: () async => budgetChecks++,
      );

      expect(rejected, isEmpty);
      expect(provider.calls, 1);
      expect(budgetChecks, 1);
      final Caption written = await db.select(db.captions).getSingle();
      expect(written.textRaw, 'Pump SN1234 at 240 V.');
      expect(written.textRefined, 'Pump SN1234 operates at 240 V.');
      final List<ProcessingResult> replies = await db
          .select(db.processingResults)
          .get();
      expect(
        replies.where(
          (row) =>
              StageSupport.summaryValue(row.requestSummary, 'kind') ==
              'attempt',
        ),
        hasLength(1),
      );
      final ProcessingResult response = replies.singleWhere(
        (row) => row.parsedOk,
      );
      expect(response.rawResponse, contains('operates'));
      expect(response.parsedOk, isTrue);

      await service.refine(
        jobId: jobId,
        project: project,
        captions: <Caption>[written],
        beforeRequest: () async => budgetChecks++,
      );
      expect(provider.calls, 1);
      expect(budgetChecks, 1);
    },
  );
  test(
    'a human refinement during the call survives with the raw reply saved',
    () async {
      final AppDatabase db = await seededDatabase(records: 1);
      addTearDown(db.close);
      final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 23, 8));
      final UuidV7Service ids = UuidV7Service.sequence(clock);
      final RecordRow record = await db.select(db.records).getSingle();
      final Caption caption = _ok(
        await insertCaption(
          db,
          row: CaptionsCompanion(
            ownerType: const Value<CaptionOwnerType>(CaptionOwnerType.record),
            ownerId: Value<String>(record.id),
            textRaw: const Value<String>('Pump SN1234 at 240 V.'),
            inputMode: const Value<CaptionInputMode>(CaptionInputMode.typed),
          ),
          clock: clock,
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final SettingsStore settings = SettingsStore.fake();
      final ProcessingRepositoryImpl repository = ProcessingRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
        settings: settings,
      );
      final String jobId = _ok(await repository.enqueue(record.id));
      final _RefinementService provider = _RefinementService(
        duringCall: () async {
          _ok(
            await writeCaptionRefined(
              db,
              id: caption.id,
              textRefined: 'Operator reviewed pump SN1234 at 240 V.',
              clock: clock,
              deviceId: 'device-a',
              ids: ids,
            ),
          );
        },
      );
      final CaptionRefinementService service = CaptionRefinementService(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
        selection: ProviderSelection(
          settings: settings,
          providers: ProviderRegistry.keyless(proxy: provider),
        ),
      );
      await expectLater(
        service.refine(
          jobId: jobId,
          project: await db.select(db.projects).getSingle(),
          captions: <Caption>[caption],
          beforeRequest: () async {},
        ),
        throwsA(isA<CancelledFailure>()),
      );
      final Caption current = await db.select(db.captions).getSingle();
      expect(current.textRaw, caption.textRaw);
      expect(current.textRefined, 'Operator reviewed pump SN1234 at 240 V.');
      final ProcessingResult response =
          (await db.select(db.processingResults).get()).singleWhere(
            (row) =>
                StageSupport.summaryValue(row.requestSummary, 'kind') ==
                'online',
          );
      expect(response.rawResponse, contains('operates'));
      expect(response.parsedOk, isFalse);
    },
  );
  test(
    'the proxy plain-text refinement is applied and saved verbatim',
    () async {
      final AppDatabase db = await seededDatabase(records: 1);
      addTearDown(db.close);
      final FixedClock clock = FixedClock(DateTime.utc(2026, 9, 23, 8));
      final UuidV7Service ids = UuidV7Service.sequence(clock);
      final RecordRow record = await db.select(db.records).getSingle();
      final Caption caption = _ok(
        await insertCaption(
          db,
          row: CaptionsCompanion(
            ownerType: const Value<CaptionOwnerType>(CaptionOwnerType.record),
            ownerId: Value<String>(record.id),
            textRaw: const Value<String>('Pump SN1234 at 240 V.'),
            inputMode: const Value<CaptionInputMode>(CaptionInputMode.typed),
          ),
          clock: clock,
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final SettingsStore settings = SettingsStore.fake();
      final String jobId = _ok(
        await ProcessingRepositoryImpl(
          db: db,
          clock: clock,
          deviceId: 'device-a',
          ids: ids,
          settings: settings,
        ).enqueue(record.id),
      );
      const String plain = 'Pump SN1234 operates at 240 V.';
      final ProxyAiService provider = ProxyAiService(
        baseUrl: 'https://org.test',
        send:
            ({
              required String path,
              required Map<String, Object?> json,
            }) async => (
              status: 200,
              body: '{"text":"$plain","model":"economy","provider":"gemini"}',
            ),
      );
      final CaptionRefinementService service = CaptionRefinementService(
        db: db,
        clock: clock,
        deviceId: 'device-a',
        ids: ids,
        selection: ProviderSelection(
          settings: settings,
          providers: ProviderRegistry.keyless(proxy: provider),
        ),
      );
      expect(
        await service.refine(
          jobId: jobId,
          project: await db.select(db.projects).getSingle(),
          captions: <Caption>[caption],
          beforeRequest: () async {},
        ),
        isEmpty,
      );
      final Caption stored = await db.select(db.captions).getSingle();
      expect(stored.textRaw, caption.textRaw);
      expect(stored.textRefined, plain);
      final ProcessingResult result =
          (await db.select(db.processingResults).get()).singleWhere(
            (row) => row.parsedOk,
          );
      expect(result.rawResponse, plain);
    },
  );
}

final class _RefinementService implements AiService {
  _RefinementService({this.duringCall});

  final Future<void> Function()? duringCall;
  var calls = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<Result<RefineTextResult>> refineText(RefineTextRequest request) async {
    calls++;
    expect(request.projectRevision, matches(RegExp(r'^[a-f0-9]{64}$')));
    expect(request.idempotencyKey, matches(RegExp(r'^[a-f0-9]{64}$')));
    expect(request.recordId, isNotEmpty);
    await duringCall?.call();
    return const Success<RefineTextResult>(
      RefineTextResult(
        text: 'Pump SN1234 operates at 240 V.',
        rawResponse: '{"text":"Pump SN1234 operates at 240 V."}',
        provider: 'test-provider',
        model: 'test-model',
        promptVersion: 'caption-1',
      ),
    );
  }

  @override
  Future<Result<ExtractFieldsResult>> extractFields(
    ExtractFieldsRequest request,
  ) async {
    return const FailureResult<ExtractFieldsResult>(ProviderFailure());
  }

  @override
  Future<Result<ReadTextResult>> readText(ReadTextRequest request) async {
    return const FailureResult<ReadTextResult>(ProviderFailure());
  }

  @override
  Future<Result<TranscribeResult>> transcribe(TranscribeRequest request) async {
    return const FailureResult<TranscribeResult>(ProviderFailure());
  }
}

T _ok<T>(Result<T> result) {
  return result.fold(
    (Failure failure) => throw TestFailure(failure.message),
    (T value) => value,
  );
}
