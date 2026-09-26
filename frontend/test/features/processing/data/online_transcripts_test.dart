import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ai_service.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/features/processing/data/job_writes.dart';
import 'package:tapture/features/processing/data/online_budget.dart';
import 'package:tapture/features/processing/data/online_transcripts.dart';
import 'package:tapture/features/processing/data/stage_settings.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/processing_fixture.dart';

void main() {
  late ProcessingFixture fixture;
  late ProcessingJob job;

  setUp(() async {
    fixture = await ProcessingFixture.open();
    job = await fixture.job();
  });

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
    final List<ProcessingResult> stored = await fixture.db
        .select(fixture.db.processingResults)
        .get();
    expect(stored, hasLength(2));
    expect(stored.first.requestSummary, contains('"kind":"transcript"'));
    expect(stored.first.requestSummary, contains(first.id));

    final ScriptedExtraction again = ScriptedExtraction(
      const <String>[],
      transcript: 'different',
    );
    expect(
      await transcripts(again).forJob(job, await fixture.bundle()),
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
}
