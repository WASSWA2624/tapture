import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/meetings.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_file_writer.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/speech/finished_utterance.dart';
import 'package:tapture/core/speech/transcript_segment.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/meetings/data/meeting_repository_impl.dart';
import 'package:tapture/features/meetings/domain/action_entry.dart';
import 'package:tapture/features/meetings/domain/agenda_entry.dart';
import 'package:tapture/features/meetings/domain/attendee.dart';
import 'package:tapture/features/meetings/domain/decision.dart';
import 'package:tapture/features/meetings/domain/meeting.dart';
import 'package:tapture/features/meetings/domain/meeting_attachment.dart';
import 'package:tapture/features/meetings/domain/meeting_repository.dart';
import 'package:tapture/features/meetings/domain/meeting_transcription.dart';
import 'package:tapture/features/meetings/domain/minutes_refinement.dart';
import 'package:tapture/features/merge/data/merge_repository_impl.dart';
import 'package:tapture/features/merge/data/merge_snapshot_store.dart';
import 'package:tapture/features/merge/data/package_files.dart';
import 'package:tapture/features/transcripts/data/transcript_repository_impl.dart';
import 'package:tapture/features/transcripts/domain/domain.dart';

import '../../../core/db/record_rows.dart';

void main() {
  late AppDatabase db;
  late MeetingRepositoryImpl store;
  final DateTime t0 = DateTime.utc(2026, 9, 27, 9);

  setUp(() {
    db = AppDatabase.memory();
    store = MeetingRepositoryImpl(
      db: db,
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: UuidV7Service.sequence(FixedClock(t0)),
      operatorName: () => 'Ada',
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('a meeting round-trips and a later transcript is kept', () async {
    final Meeting meeting = Meeting(
      id: '',
      projectId: 'p1',
      title: 'Kick-off',
      startedAt: t0,
      location: 'Site A',
      secretary: 'Ada',
      attendees: const <Attendee>[
        Attendee(id: 'a1', name: 'Ada'),
        Attendee(id: 'a2', name: 'Ben', status: AttendanceStatus.apology),
      ],
      actions: <ActionEntry>[
        ActionEntry(
          id: 'c1',
          text: 'Send the minutes',
          ownerName: 'Ada',
          ownerId: 'a1',
          due: t0,
          status: ActionStatus.open,
        ),
      ],
    );
    final MeetingRecord saved = _ok(
      await store.save(
        meeting,
        recordId: 'r1',
        transcript: 'verbatim',
        notes: 'raw',
      ),
    );
    expect(saved.meeting.attendanceCount, 1);
    expect(saved.originalNotes, 'raw');
    expect(saved.transcript, 'verbatim');
    expect(
      _ok(await listAttendeesForMeeting(db, meetingId: saved.meeting.id)),
      hasLength(2),
    );
    expect(
      _ok(
        await listMeetingActionsByMeetingAndStatus(
          db,
          meetingId: saved.meeting.id,
          status: 'open',
          offset: 0,
          limit: 10,
        ),
      ),
      hasLength(1),
    );

    final MeetingRecord again = _ok(
      await store.save(
        saved.meeting.copyWith(title: 'Later'),
        recordId: 'r1',
        transcript: 'replaced',
        minutes: 'refined',
      ),
    );
    expect(again.transcript, 'verbatim');
    expect(again.originalNotes, 'raw');
    expect(again.minutes, 'refined');
    expect(again.meeting.title, 'Later');
  });

  group('one transcript source', () {
    late TranscriptRepositoryImpl transcripts;
    const int second = 16000;

    setUp(() async {
      await seedRow(db, 'projects', <String, Object?>{
        'id': 'p1',
        'name': 'Alpha',
        'client': '',
        'status': 'active',
        'folder_name': 'alpha',
        'settings': '{}',
      });
      await seedRecord(db, 'r1');
      final FixedClock later = FixedClock(t0.add(const Duration(days: 1)));
      transcripts = TranscriptRepositoryImpl(
        db: db,
        clock: later,
        deviceId: 'device-a',
        ids: UuidV7Service.sequence(later),
      );
    });

    /// Meeting `m1` on record `r1`, with an imported [raw] transcript and
    /// online transcription [versions].
    Future<void> meeting({
      String raw = '',
      String notes = 'Raw notes',
      List<TranscriptVersion> versions = const <TranscriptVersion>[],
    }) {
      return seedRow(db, 'meetings', <String, Object?>{
        'id': 'm1',
        'record_id': 'r1',
        'title': 'Site meeting',
        'start_at': 1,
        'agenda': jsonEncode(<Object?>[
          <String, Object?>{
            'meeting': Meeting(
              id: 'm1',
              projectId: 'p1',
              title: 'Site meeting',
              startedAt: t0,
              recordId: 'r1',
            ).toJson(),
            'notes': notes,
            'minutes': '',
            'transcripts': MeetingTranscription.toJson(versions),
          },
        ]),
        'transcript_raw': raw,
      });
    }

    /// A transcript of meeting [owner] that heard [words], one per second,
    /// started at [at] and left [status].
    Future<String> heard(
      List<String> words, {
      DateTime? at,
      TranscriptStatus status = TranscriptStatus.complete,
      String owner = 'm1',
    }) async {
      final String id = _ok(
        await transcripts.begin((
          projectId: 'p1',
          ownerKind: TranscriptOwnerKind.meeting,
          ownerId: owner,
          attachmentId: null,
          audioPath: 'projects/alpha/meetings/$owner/recording.wav',
          title: '',
          languageTag: 'en',
          modelId: 'tiny-q5_1',
          startedAt: at ?? t0,
        )),
      ).id;
      for (int index = 0; index < words.length; index++) {
        _ok(
          await transcripts.appendUtterance(
            id,
            FinishedUtterance(
              utteranceId: index + 1,
              fromSample: index * second,
              toSample: (index + 1) * second,
              skipped: false,
              segments: <TranscriptSegment>[
                TranscriptSegment(
                  id: index + 1,
                  utteranceId: index + 1,
                  startSample: index * second,
                  endSample: index * second + second ~/ 2,
                  text: words[index],
                  languageTag: 'en',
                  modelId: 'tiny-q5_1',
                  confidence: 0.75,
                ),
              ],
            ),
          ),
        );
      }
      switch (status) {
        case TranscriptStatus.complete:
          _ok(
            await transcripts.complete(
              id,
              duration: Duration(seconds: words.length),
              languageTag: 'en',
            ),
          );
        case TranscriptStatus.interrupted:
          _ok(await transcripts.markInterrupted(id));
        case TranscriptStatus.live:
          break;
      }
      return id;
    }

    Future<String> transcriptOfMeeting() async =>
        _ok(await store.read('m1'))!.transcript;

    test(
      'legacy notes are preserved through repeated edits with audit',
      () async {
        const String original = '  Raw café notes\nSecond line.  ';
        await meeting(notes: original, raw: 'Verbatim words');
        MeetingRecord current = _ok(await store.read('m1'))!;
        expect(current.originalNotes, original);
        current = _ok(
          await store.save(
            current.meeting,
            recordId: 'r1',
            notes: 'Working notes',
            minutes: 'First minutes',
          ),
        );
        current = _ok(
          await store.save(
            current.meeting,
            recordId: 'r1',
            notes: 'Corrected notes',
            minutes: current.minutes,
          ),
        );
        _ok(
          await store.save(
            current.meeting,
            recordId: 'r1',
            notes: current.notes,
            minutes: current.minutes,
          ),
        );
        final MeetingRecord reopened = _ok(await store.read('m1'))!;
        expect(reopened.originalNotes, original);
        expect(reopened.notes, 'Corrected notes');
        expect(reopened.minutes, 'First minutes');
        expect(reopened.transcript, 'Verbatim words');
        final List<AuditLogData> audits = await db.select(db.auditLog).get();
        expect(audits, hasLength(3));
        expect(
          audits.every((AuditLogData row) => row.operator == 'Ada'),
          isTrue,
        );
        expect(
          audits.every((AuditLogData row) => row.device == 'device-a'),
          isTrue,
        );
        expect(
          audits.map(
            (AuditLogData row) =>
                (row.fieldKey, row.previousValue, row.newValue),
          ),
          unorderedEquals(<(String, String, String)>[
            ('notes', original, 'Working notes'),
            ('minutes', '', 'First minutes'),
            ('notes', 'Working notes', 'Corrected notes'),
          ]),
        );
      },
    );

    test(
      'audit failure rolls back edits and the first original snapshot',
      () async {
        await meeting(notes: 'Original notes');
        final MeetingRecord before = _ok(await store.read('m1'))!;
        final String agenda = (await db.select(db.meetings).getSingle()).agenda;
        await db.customStatement('''
CREATE TEMP TRIGGER reject_meeting_audit BEFORE INSERT ON audit_log
WHEN NEW.entity_type = 'meetings' AND NEW.field_key = 'minutes'
BEGIN SELECT RAISE(ABORT, 'fixture rejection'); END
''');
        expect(
          await store.save(
            before.meeting,
            recordId: 'r1',
            notes: 'Unsaved edit',
            minutes: 'Unsaved minutes',
          ),
          isA<FailureResult<MeetingRecord>>(),
        );
        expect((await db.select(db.meetings).getSingle()).agenda, agenda);
        final MeetingRecord reopened = _ok(await store.read('m1'))!;
        expect(reopened.originalNotes, before.originalNotes);
        expect(reopened.notes, before.notes);
        expect(reopened.minutes, before.minutes);
        expect(await db.select(db.auditLog).get(), isEmpty);
      },
    );

    test(
      'delayed transcriptions preserve edits, versions and source bytes',
      () async {
        await meeting(notes: 'Original notes', raw: 'Raw transcript');
        final Uint8List audio = Uint8List.fromList(<int>[1, 2, 3, 4, 5]);
        const String audioPath = 'projects/alpha/meetings/m1/take.wav';
        final Map<String, Uint8List> files = <String, Uint8List>{
          audioPath: audio,
        };
        final String sourceHash = sha256.convert(audio).toString();
        final MeetingRepositoryImpl audioStore = MeetingRepositoryImpl(
          db: db,
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: UuidV7Service.sequence(FixedClock(t0)),
          writer: BlobFileWriter(BlobStore.memory(backing: files)),
          reader: FileReader.memory(files),
          isBrowser: true,
        );
        final MeetingAttachment file = _ok(
          await audioStore.attachStored(
            'm1',
            storagePath: audioPath,
            mimeType: 'audio/wav',
            bytes: audio.length,
            sha256: sourceHash,
          ),
        );
        _ok(
          await audioStore.transcribe(
            'm1',
            file,
            transcribeChunk: (_) async =>
                const Success<String>('Earlier version'),
          ),
        );
        final List<Object?> firstDocument =
            jsonDecode((await db.select(db.meetings).getSingle()).agenda)
                as List<Object?>;
        expect(
          (firstDocument.single! as Map<String, Object?>)['originalNotes'],
          'Original notes',
        );
        final Completer<void> started = Completer<void>();
        final Completer<Result<String>> answer = Completer<Result<String>>();
        final Future<Result<List<TranscriptVersion>>> delayed = audioStore
            .transcribe(
              'm1',
              file,
              transcribeChunk: (_) {
                started.complete();
                return answer.future;
              },
            );
        await started.future;
        final MeetingRecord before = _ok(await store.read('m1'))!;
        _ok(
          await store.save(
            before.meeting,
            recordId: 'r1',
            notes: 'Edited while transcribing',
            minutes: 'Reviewed minutes',
          ),
        );
        _ok(
          await audioStore.transcribe(
            'm1',
            file,
            transcribeChunk: (_) async =>
                const Success<String>('Finished first'),
          ),
        );
        answer.complete(const Success<String>('Finished last'));
        _ok(await delayed);
        final MeetingRecord reopened = _ok(await store.read('m1'))!;
        expect(reopened.originalNotes, 'Original notes');
        expect(reopened.notes, 'Edited while transcribing');
        expect(reopened.minutes, 'Reviewed minutes');
        expect(reopened.transcript, 'Raw transcript');
        expect(reopened.transcripts.map((v) => v.text), <String>[
          'Earlier version',
          'Finished first',
          'Finished last',
        ]);
        expect(reopened.attachments.single.id, file.id);
        expect(sha256.convert(files[audioPath]!).toString(), sourceHash);
      },
    );

    test(
      'merge undo restores working notes independently of later audits',
      () async {
        await meeting(notes: 'Original notes');
        MeetingRecord current = _ok(await store.read('m1'))!;
        current = _ok(
          await store.save(
            current.meeting,
            recordId: 'r1',
            notes: 'Before merge',
            minutes: 'Before minutes',
          ),
        );
        Future<SnapshotRows>
        rows() async => <String, List<Map<String, Object?>>>{
          'meetings': <Map<String, Object?>>[
            (await db.customSelect('SELECT * FROM meetings').getSingle()).data,
          ],
        };
        final SnapshotRows before = await rows();
        _ok(
          await store.save(
            current.meeting,
            recordId: 'r1',
            notes: 'Incoming working notes',
            minutes: 'Incoming minutes',
          ),
        );
        final PackageFiles files = PackageFiles.blobs(BlobStore.memory());
        final MergeSnapshotStore snapshots = MergeSnapshotStore(db, files);
        await snapshots.publish(
          path: 'snapshot.json',
          projectId: 'p1',
          before: before,
          after: await rows(),
          importedFiles: const <String>[],
        );
        await seedRow(db, 'merge_sessions', <String, Object?>{
          'id': 'merge-1',
          'bundle_name': 'meeting.zip',
          'source_device': 'device-b',
          'imported_at': t0.millisecondsSinceEpoch ~/ 1000,
          'counts': '{"project_id":"p1"}',
          'status': 'applied',
          'undo_snapshot_path': 'snapshot.json',
        });
        _ok(
          await MergeRepositoryImpl(
            db: db,
            files: files,
            clock: FixedClock(t0),
            deviceId: 'device-a',
          ).undo('merge-1'),
        );
        final MeetingRecord restored = _ok(await store.read('m1'))!;
        expect(restored.originalNotes, 'Original notes');
        expect(restored.notes, 'Before merge');
        expect(restored.minutes, 'Before minutes');
        expect(
          (await db.select(db.auditLog).get()).where(
            (AuditLogData row) => row.entityType == 'meetings',
          ),
          hasLength(4),
        );
        expect((await db.select(db.merge).getSingle()).status, 'undone');
      },
    );

    const TranscriptVersion cloud = (
      version: 1,
      text: 'cloud words',
      failedChunks: <int>[],
    );

    test('an imported raw transcript wins over every other source', () async {
      await meeting(
        raw: 'imported words',
        versions: const <TranscriptVersion>[cloud],
      );
      await heard(<String>['live', 'words']);
      expect(await transcriptOfMeeting(), 'imported words');
    });

    test('the latest settled meeting transcript is read: its edit when one '
        'stands, never one still recording, discarded or of another '
        'meeting', () async {
      await meeting(versions: const <TranscriptVersion>[cloud]);
      await heard(<String>['older', 'talk']);
      final String newer = await heard(<String>[
        'fence',
        'the',
        'reservoir',
      ], at: t0.add(const Duration(hours: 1)));
      await heard(
        <String>['still', 'recording'],
        at: t0.add(const Duration(hours: 2)),
        status: TranscriptStatus.live,
      );
      await heard(
        <String>['another', 'meeting'],
        at: t0.add(const Duration(hours: 3)),
        owner: 'm2',
      );
      expect(await transcriptOfMeeting(), 'fence the reservoir');

      _ok(await transcripts.saveEdit(newer, 'Fence the north reservoir.'));
      expect(await transcriptOfMeeting(), 'Fence the north reservoir.');

      _ok(await transcripts.discard(newer));
      expect(await transcriptOfMeeting(), 'older talk');

      await heard(
        <String>['cut', 'short'],
        at: t0.add(const Duration(hours: 4)),
        status: TranscriptStatus.interrupted,
      );
      expect(
        await transcriptOfMeeting(),
        'cut short',
        reason: 'an interrupted transcript is settled too',
      );

      await heard(const <String>[], at: t0.add(const Duration(hours: 5)));
      expect(
        await transcriptOfMeeting(),
        'cut short',
        reason: 'a later take recorded as audio only hides no words',
      );
    });

    test('without an on-device transcript the last online run is read, and '
        'with nothing heard the transcript is empty', () async {
      await meeting(
        versions: const <TranscriptVersion>[
          cloud,
          (version: 2, text: 'second run', failedChunks: <int>[]),
        ],
      );
      await heard(<String>['still', 'live'], status: TranscriptStatus.live);
      expect(await transcriptOfMeeting(), 'second run');

      await db.customStatement('DELETE FROM meetings');
      await meeting();
      expect(await transcriptOfMeeting(), isEmpty);
    });

    test('Refine minutes receives the live transcript text, and the edited '
        'text once an edit stands', () async {
      await meeting(versions: const <TranscriptVersion>[cloud]);
      final String id = await heard(<String>[
        'we agreed',
        'to fence the reservoir',
      ]);
      const List<Decision> decisions = <Decision>[
        Decision(id: 'd1', text: 'fence the reservoir'),
        Decision(id: 'd2', text: 'by Friday'),
      ];

      MeetingRecord read = _ok(await store.read('m1'))!;
      MinutesRefinementResult refined = MinutesRefinement.refine(
        notes: read.notes,
        transcript: read.transcript,
        agenda: const <AgendaEntry>[],
        decisions: decisions,
      );
      expect(refined.transcript, 'we agreed to fence the reservoir');
      expect(refined.decisions.map((Decision d) => d.id), <String>['d1']);
      expect(refined.rejected, <String>['by Friday']);

      _ok(
        await transcripts.saveEdit(
          id,
          'We agreed to fence the reservoir by Friday.',
        ),
      );
      read = _ok(await store.read('m1'))!;
      refined = MinutesRefinement.refine(
        notes: read.notes,
        transcript: read.transcript,
        agenda: const <AgendaEntry>[],
        decisions: decisions,
      );
      expect(refined.transcript, 'We agreed to fence the reservoir by Friday.');
      expect(refined.decisions.map((Decision d) => d.id), <String>['d1', 'd2']);
    });

    test('a take filed through attachStored and linked makes the completed '
        'transcript searchable on the meeting record', () async {
      await meeting();
      final String id = await heard(<String>[
        'borehole',
        'pump rusted',
      ], status: TranscriptStatus.live);
      final String path = _ok(
        await store.storagePathFor('m1', 'recording.wav'),
      );
      final MeetingAttachment take = _ok(
        await store.attachStored(
          'm1',
          storagePath: path,
          mimeType: 'audio/wav',
          bytes: 44,
          sha256: 'take-hash',
          duration: const Duration(seconds: 2),
        ),
      );
      _ok(await transcripts.linkAttachment(id, take.id));
      expect(
        await searchRecords(db, 'borehole'),
        isEmpty,
        reason: 'a transcript still recording is not indexed',
      );

      _ok(
        await transcripts.complete(
          id,
          duration: const Duration(seconds: 2),
          languageTag: 'en',
        ),
      );
      expect(await searchRecords(db, 'borehole'), <String>['r1']);
      expect(await searchRecords(db, 'rusted'), <String>['r1']);
      expect(_ok(await store.read('m1'))!.attachments.single.id, take.id);
      expect(await transcriptOfMeeting(), 'borehole pump rusted');
    });
  });
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final failure) => fail(failure.message),
  };
}
