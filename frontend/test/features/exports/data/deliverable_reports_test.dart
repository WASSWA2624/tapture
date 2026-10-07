import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/export/export_record.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/pdf/pdf_engine.dart';
import 'package:tapture/core/export/pdf/transcript_report.dart';
import 'package:tapture/core/export/value_formatter.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/exports/data/deliverable_reports.dart';
import 'package:tapture/features/exports/data/export_pdf.dart';
import 'package:tapture/features/meetings/data/meeting_repository_impl.dart';
import 'package:tapture/features/meetings/domain/domain.dart';
import 'package:tapture/features/transcripts/domain/domain.dart';

import '../../../support/factories.dart';
import '../../../support/fakes/fake_quality_repository.dart';
import '../../transcripts/fakes/fake_transcript_repository.dart';

void main() {
  final ExportRequest request = ExportRequest(
    projectId: 'project-1',
    formats: const <ExportFormat>{ExportFormat.pdf},
    scope: (
      kind: ExportScopeKind.approved,
      context: null,
      from: null,
      to: null,
      filter: null,
    ),
    columns: (raw: false, refined: true, confidence: false, evidence: false),
    extras: (
      dictionary: false,
      photoIndex: false,
      photoMode: 'filename',
      pdfPhotos: 'thumbnail',
      delimiter: ',',
    ),
    records: <ExportRecord>[anExportRecord()],
  );

  DeliverableReportInputs inputsWith(List<TranscriptContent> transcripts) => (
    projectName: 'Field',
    cover: const <String>[],
    checklists: const <DeliverableChecklist>[],
    meetings: const <DeliverableMeeting>[],
    transcripts: transcripts,
    variance: null,
    actionRegister: const <List<String>>[],
  );

  test('records and a summary are named, and a meeting keeps its title', () {
    final Map<String, PdfDocument> documents = DeliverableReports.documents(
      request,
      inputsWith(const <TranscriptContent>[]),
      exportPdfEngine(),
    );

    expect(documents.keys, containsAll(<String>['records.pdf', 'summary.pdf']));
    expect(documents['records.pdf']!.project, 'Field');
    expect(documents.keys, isNot(contains('transcripts.pdf')));
  });

  test('the transcripts report prints raw text as heard and the edit beside '
      'it', () {
    final Map<String, PdfDocument> documents = DeliverableReports.documents(
      request,
      inputsWith(const <TranscriptContent>[
        (
          title: 'Pump room',
          raw: 'the seal is leaking',
          edited: 'The seal is leaking.',
        ),
        (title: 'Gate', raw: 'hinges rusted', edited: null),
      ]),
      exportPdfEngine(),
    );

    final PdfDocument report = documents['transcripts.pdf']!;
    expect(report.title, 'Transcripts');
    expect(report.project, 'Field');
    expect(
      <String, List<String>>{
        for (final PdfSection section in report.sections)
          section.heading: section.lines,
      },
      <String, List<String>>{
        'Pump room (as heard)': <String>['the seal is leaking'],
        'Pump room (edited)': <String>['The seal is leaking.'],
        'Gate (as heard)': <String>['hinges rusted'],
      },
    );
  });

  test('load reads finished transcripts of the exported records, raw and '
      'edited, and leaves a live one out', () async {
    final AppDatabase db = AppDatabase.memory();
    addTearDown(db.close);
    final FixedClock clock = FixedClock(DateTime.utc(2026, 10, 4));
    final FakeTranscriptRepository transcripts = FakeTranscriptRepository();
    addTearDown(transcripts.dispose);
    final ExportRecord record = anExportRecord();
    transcripts.recordAttachments['audio-1'] = <String>{record.id};
    transcripts.recordAttachments['audio-2'] = <String>{record.id};
    TranscriptSummary summary(
      String id,
      TranscriptStatus status, {
      String title = '',
    }) => TranscriptSummary(
      id: id,
      projectId: 'project-1',
      ownerKind: TranscriptOwnerKind.capture,
      attachmentId: id == 't-live' ? 'audio-2' : 'audio-1',
      audioPath: 'projects/field/audio/$id.wav',
      title: title,
      status: status,
      startedAt: DateTime.utc(2026, 10, 4),
      languageTag: 'en',
      modelId: 'tiny-q5_1',
    );
    transcripts
      ..seed(
        summary('t-done', TranscriptStatus.complete),
        lines: const <TranscriptLine>[
          TranscriptLine(
            seq: 1,
            start: Duration.zero,
            end: Duration(seconds: 1),
            text: 'valve',
          ),
          TranscriptLine(
            seq: 2,
            start: Duration(seconds: 1),
            end: Duration(seconds: 2),
            text: 'is stuck',
          ),
        ],
        edit: 'Valve 4 is stuck.',
      )
      ..seed(
        summary('t-live', TranscriptStatus.live, title: 'Still going'),
        lines: const <TranscriptLine>[
          TranscriptLine(
            seq: 1,
            start: Duration.zero,
            end: Duration(seconds: 1),
            text: 'not yet',
          ),
        ],
      );
    final DeliverableReports reports = DeliverableReports(
      db: db,
      meetings: MeetingRepositoryImpl(
        db: db,
        clock: clock,
        deviceId: 'device-test',
        ids: UuidV7Service.sequence(clock),
      ),
      quality: FakeQualityRepository(),
      transcripts: transcripts,
    );

    final DeliverableReportInputs inputs = await reports.load(
      request,
      projectName: 'Field',
      operator: '',
      createdAt: DateTime.utc(2026, 10, 4),
    );

    expect(inputs.transcripts, <TranscriptContent>[
      (
        title: '${record.templateName} ${record.number}',
        raw: 'valve is stuck',
        edited: 'Valve 4 is stuck.',
      ),
    ]);
  });

  test('minutes print an edited live meeting transcript once per labelled '
      'section and never under the raw notes', () {
    final ExportRecord record = anExportRecord();
    final MeetingRecord meeting = (
      meeting: Meeting(
        id: 'meeting-1',
        projectId: 'project-1',
        title: 'Site walk',
        startedAt: DateTime.utc(2026, 10, 4),
      ),
      originalNotes: 'Bring the ladder.',
      notes: 'Bring two ladders.',
      minutes: '',
      transcript: 'The seal is leaking.',
      transcripts: const <TranscriptVersion>[],
      attachments: const <MeetingAttachment>[],
    );

    final PdfDocument minutes = DeliverableReports.documents(
      request,
      (
        projectName: 'Field',
        cover: const <String>[],
        checklists: const <DeliverableChecklist>[],
        meetings: <DeliverableMeeting>[
          (
            number: record.number,
            minutes: DeliverableReports.minutesOf(
              meeting,
              record,
              transcripts: const <TranscriptContent>[
                (
                  title: 'Site walk',
                  raw: 'the seal is leaking',
                  edited: 'The seal is leaking.',
                ),
              ],
            ),
          ),
        ],
        transcripts: const <TranscriptContent>[],
        variance: null,
        actionRegister: const <List<String>>[],
      ),
      exportPdfEngine(),
    ).entries.singleWhere((e) => e.key.startsWith('minutes-')).value;

    final Map<String, List<String>> sections = <String, List<String>>{
      for (final PdfSection section in minutes.sections)
        section.heading: section.lines,
    };
    expect(sections['Raw notes'], <String>['Bring the ladder.']);
    expect(sections['Site walk (as heard)'], <String>['the seal is leaking']);
    expect(sections['Site walk (edited)'], <String>['The seal is leaking.']);
    expect(
      minutes.sections
          .expand((PdfSection section) => section.lines)
          .where((String line) => line.contains('The seal is leaking.')),
      hasLength(1),
    );
  });

  test('minutes keep an imported meeting transcript under the raw notes', () {
    final MeetingRecord meeting = (
      meeting: Meeting(
        id: 'meeting-1',
        projectId: 'project-1',
        title: 'Site walk',
        startedAt: DateTime.utc(2026, 10, 4),
      ),
      originalNotes: '',
      notes: 'Working notes are separate.',
      minutes: '',
      transcript: 'imported words',
      transcripts: const <TranscriptVersion>[],
      attachments: const <MeetingAttachment>[],
    );

    expect(
      DeliverableReports.minutesOf(meeting, anExportRecord()).rawNotes,
      'imported words',
    );
  });
}
