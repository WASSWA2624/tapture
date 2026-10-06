import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/speech/finished_utterance.dart';
import 'package:tapture/core/speech/transcript_segment.dart';
import 'package:tapture/features/processing/data/job_writes.dart';
import 'package:tapture/features/processing/data/online_budget.dart';
import 'package:tapture/features/processing/data/online_transcripts.dart';
import 'package:tapture/features/processing/data/stage_settings.dart';
import 'package:tapture/features/processing/data/stage_support.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/settings/settings.dart';
import 'package:tapture/features/transcripts/transcripts.dart';

import '../../../support/processing_fixture.dart';

void main() {
  late ProcessingFixture fixture;
  late ProcessingJob job;
  late TranscriptRepositoryImpl store;

  setUp(() async {
    fixture = await ProcessingFixture.open();
    job = await fixture.job();
    store = TranscriptRepositoryImpl(
      db: fixture.db,
      clock: fixture.clock,
      deviceId: 'device-a',
      ids: fixture.ids,
    );
  });

  /// An on-device transcript of [audio] reading [text], left live, or
  /// completed or interrupted as [end] says.
  Future<String> heard(
    Attachment audio,
    String text, {
    TranscriptStatus end = TranscriptStatus.complete,
  }) async {
    final String id = _ok(
      await store.begin((
        projectId: fixture.project.id,
        ownerKind: TranscriptOwnerKind.capture,
        ownerId: null,
        attachmentId: audio.id,
        audioPath:
            'projects/${fixture.project.folderName}/${audio.relativePath}',
        title: '',
        languageTag: 'en',
        modelId: 'tiny-q5_1',
        startedAt: fixture.clock.nowUtc(),
      )),
    ).id;
    _ok(
      await store.appendUtterance(
        id,
        FinishedUtterance(
          utteranceId: 1,
          fromSample: 0,
          toSample: 16000,
          segments: <TranscriptSegment>[
            TranscriptSegment(
              id: 1,
              utteranceId: 1,
              startSample: 0,
              endSample: 16000,
              text: text,
              languageTag: 'en',
              modelId: 'tiny-q5_1',
              confidence: 0.9,
            ),
          ],
        ),
      ),
    );
    switch (end) {
      case TranscriptStatus.complete:
        _ok(
          await store.complete(
            id,
            duration: const Duration(seconds: 1),
            languageTag: 'en',
            modelId: 'tiny-q5_1',
          ),
        );
      case TranscriptStatus.interrupted:
        _ok(await store.markInterrupted(id));
      case TranscriptStatus.live:
        break;
    }
    return id;
  }

  Future<List<ProcessingResult>> stored() async =>
      (await fixture.db.select(fixture.db.processingResults).get())
          .where(
            (row) =>
                StageSupport.summaryValue(row.requestSummary, 'kind') ==
                'transcript',
          )
          .toList();

  OnlineTranscripts transcripts(AiService provider, {SettingsStore? settings}) {
    final StageSettings stage = fixture.stageSettings(
      settings: settings,
      provider: provider,
    );
    return OnlineTranscripts(
      storageRoot: fixture.storageRoot,
      responses: fixture.responses,
      settings: stage,
      budget: OnlineBudget(
        db: fixture.db,
        clock: fixture.clock,
        settings: stage,
        writes: JobWrites(db: fixture.db),
      ),
      deviceTranscripts: store,
    );
  }

  test('a record without voice notes asks for nothing', () async {
    final ScriptedExtraction provider = ScriptedExtraction(
      const <String>[],
      transcript: 'hello',
    );

    expect(
      await transcripts(provider).forJob(job, await fixture.bundle()),
      isEmpty,
    );
    expect(provider.transcriptions, isEmpty);
  });

  test('each clip is transcribed once, then read back', () async {
    final Attachment first = await fixture.addAudio(0);
    await fixture.addAudio(1);
    final ScriptedExtraction provider = ScriptedExtraction(
      const <String>[],
      transcript: 'pump hums at night',
    );

    final List<String> heard = await transcripts(
      provider,
      settings: SettingsStore.fake(
        stored: <String, Object?>{SettingKeys.voiceLanguage.name: 'sw'},
      ),
    ).forJob(job, await fixture.bundle());

    expect(heard, <String>['pump hums at night', 'pump hums at night']);
    expect(provider.transcriptions, hasLength(2));
    expect(provider.transcriptions.first.languageCode, 'sw');
    expect(
      provider.transcriptions.first.clipPath,
      endsWith(first.relativePath),
    );
    final List<ProcessingResult> all = await fixture.db
        .select(fixture.db.processingResults)
        .get();
    final List<ProcessingResult> stored = all
        .where(
          (row) =>
              StageSupport.summaryValue(row.requestSummary, 'kind') ==
              'transcript',
        )
        .toList();
    expect(
      all.where(
        (row) =>
            StageSupport.summaryValue(row.requestSummary, 'kind') == 'attempt',
      ),
      hasLength(2),
    );
    expect(stored, hasLength(2));
    expect(stored.first.requestSummary, contains('"kind":"transcript"'));
    expect(stored.first.requestSummary, contains(first.id));

    final ScriptedExtraction again = ScriptedExtraction(
      const <String>[],
      transcript: 'different',
    );
    expect(
      await transcripts(
        again,
        settings: SettingsStore.fake(
          stored: <String, Object?>{SettingKeys.voiceLanguage.name: 'sw'},
        ),
      ).forJob(job, await fixture.bundle()),
      <String>['pump hums at night', 'pump hums at night'],
    );
    expect(again.transcriptions, isEmpty);
  });

  test('with no provider that can transcribe, no transcript is made', () async {
    await fixture.addAudio(0);

    expect(
      await transcripts(
        const AiService.unavailable(),
      ).forJob(job, await fixture.bundle()),
      isEmpty,
    );
  });

  test('the daily cap applies to transcription', () async {
    await fixture.addAudio(0);
    await fixture.setProjectSettings('{"dailyRequestCap":0}');
    final ScriptedExtraction provider = ScriptedExtraction(
      const <String>[],
      transcript: 'hello',
    );

    await expectLater(
      transcripts(provider).forJob(job, await fixture.bundle()),
      throwsA(isA<CancelledFailure>()),
    );
    expect(provider.transcriptions, isEmpty);
  });

  group('the on-device transcript comes first', () {
    test('a complete one is used as it reads, with no provider call and '
        'no charge against the cap', () async {
      final Attachment audio = await fixture.addAudio(0);
      final String id = await heard(audio, 'valve two is leaking');
      _ok(await store.saveEdit(id, 'Valve 2 is leaking.'));
      // A cap of zero would stop any online request.
      await fixture.setProjectSettings('{"dailyRequestCap":0}');
      final ScriptedExtraction provider = ScriptedExtraction(
        const <String>[],
        transcript: 'online words',
      );

      final List<String> used = await transcripts(
        provider,
      ).forJob(job, await fixture.bundle());

      expect(used, <String>['Valve 2 is leaking.']);
      expect(provider.transcriptions, isEmpty);
      final List<ProcessingResult> rows = await stored();
      expect(rows, hasLength(1));
      expect(rows.single.requestSummary, contains('"source":"device"'));
      expect(rows.single.requestSummary, contains('"kind":"transcript"'));
      expect(rows.single.requestSummary, contains(audio.id));
      expect(rows.single.requestSummary, contains(id));
      expect(rows.single.rawResponse, 'Valve 2 is leaking.');

      // Read again, its use is not recorded twice.
      expect(
        await transcripts(provider).forJob(job, await fixture.bundle()),
        <String>['Valve 2 is leaking.'],
      );
      expect(await stored(), hasLength(1));
      expect(provider.transcriptions, isEmpty);
    });

    test('it is used even when no provider can transcribe', () async {
      final Attachment first = await fixture.addAudio(0);
      await fixture.addAudio(1);
      await heard(first, 'gate is open');

      expect(
        await transcripts(
          const AiService.unavailable(),
        ).forJob(job, await fixture.bundle()),
        <String>['gate is open'],
      );
    });

    test('only clips without one go online', () async {
      final Attachment first = await fixture.addAudio(0);
      final Attachment second = await fixture.addAudio(1);
      await heard(first, 'gate is open');
      final ScriptedExtraction provider = ScriptedExtraction(
        const <String>[],
        transcript: 'pump hums at night',
      );

      final List<String> used = await transcripts(
        provider,
      ).forJob(job, await fixture.bundle());

      expect(used, <String>['gate is open', 'pump hums at night']);
      expect(provider.transcriptions, hasLength(1));
      expect(
        provider.transcriptions.single.clipPath,
        endsWith(second.relativePath),
      );
    });

    for (final TranscriptStatus status in <TranscriptStatus>[
      TranscriptStatus.live,
      TranscriptStatus.interrupted,
    ]) {
      test('a transcript left ${status.name} is not used', () async {
        final Attachment audio = await fixture.addAudio(0);
        await heard(audio, 'half heard', end: status);
        final ScriptedExtraction provider = ScriptedExtraction(
          const <String>[],
          transcript: 'pump hums at night',
        );

        expect(
          await transcripts(provider).forJob(job, await fixture.bundle()),
          <String>['pump hums at night'],
        );
        expect(provider.transcriptions, hasLength(1));
        final List<ProcessingResult> rows = await stored();
        expect(rows, hasLength(1));
        expect(rows.single.requestSummary, isNot(contains('"source"')));
      });
    }

    test('once discarded, its recorded use is not read back', () async {
      final Attachment audio = await fixture.addAudio(0);
      final String id = await heard(audio, 'gate is open');
      final ScriptedExtraction provider = ScriptedExtraction(
        const <String>[],
        transcript: 'pump hums at night',
      );
      expect(
        await transcripts(provider).forJob(job, await fixture.bundle()),
        <String>['gate is open'],
      );

      _ok(await store.discard(id));

      expect(
        await transcripts(provider).forJob(job, await fixture.bundle()),
        <String>['pump hums at night'],
      );
      expect(provider.transcriptions, hasLength(1));
    });

    test('a store that cannot be read stops the stage rather than sending '
        'the audio', () async {
      await fixture.addAudio(0);
      await fixture.db.customStatement('DROP TABLE transcript_segments');
      await fixture.db.customStatement('DROP TABLE transcripts');
      final ScriptedExtraction provider = ScriptedExtraction(
        const <String>[],
        transcript: 'pump hums at night',
      );

      await expectLater(
        () async => transcripts(provider).forJob(job, await fixture.bundle()),
        throwsA(isA<StorageFailure>()),
      );
      expect(provider.transcriptions, isEmpty);
    });
  });
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
