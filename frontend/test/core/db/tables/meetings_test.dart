import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/meetings.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  late AppDatabase db;
  late UuidV7Service ids;

  final DateTime t0 = DateTime.utc(2026, 9, 17, 8);
  final DateTime t1 = t0.add(const Duration(hours: 1));

  setUp(() {
    db = AppDatabase.memory();
    ids = UuidV7Service.sequence(FixedClock(t0));
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'a meeting with attendees and actions round-trips and deletes with tombstones',
    () async {
      final RecordRow record = _ok(
        await upsertRecord(
          db,
          row: _record(capturedAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      const String transcript = 'Chair opened. Minutes to follow.';
      final MeetingRow meeting = _ok(
        await insertMeeting(
          db,
          row: MeetingsCompanion(
            recordId: Value<String>(record.id),
            title: const Value<String>('Kick-off'),
            startAt: Value<DateTime>(t0),
            endAt: Value<DateTime>(t1),
            chair: const Value<String>('Ada'),
            secretary: const Value<String>('Ben'),
            agenda: Value<String>(jsonEncode(<String>['Welcome', 'Actions'])),
            transcriptRaw: const Value<String>(transcript),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(meeting.title, 'Kick-off');
      expect(meeting.chair, 'Ada');
      expect(jsonDecode(meeting.agenda), <String>['Welcome', 'Actions']);
      expect(meeting.transcriptRaw, transcript);

      final MeetingAttendee ada = _ok(
        await upsertMeetingAttendee(
          db,
          row: AttendeesCompanion(
            meetingId: Value<String>(meeting.id),
            name: const Value<String>('Ada Lovelace'),
            title: const Value<String>('Chair'),
            organisation: const Value<String>('Acme'),
            contact: const Value<String>('ada@example.com'),
            signaturePresent: const Value<bool>(true),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final MeetingAttendee ben = _ok(
        await upsertMeetingAttendee(
          db,
          row: AttendeesCompanion(
            meetingId: Value<String>(meeting.id),
            name: const Value<String>('Ben List'),
            signaturePresent: const Value<bool>(false),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final MeetingAction action = _ok(
        await upsertMeetingAction(
          db,
          row: MeetingActionsCompanion(
            meetingId: Value<String>(meeting.id),
            action: const Value<String>('Issue the minutes'),
            ownerName: const Value<String>('Ben List'),
            dueDate: Value<DateTime>(t1),
            status: const Value<String>('open'),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      expect(
        _ok(
          await listAttendeesForMeeting(db, meetingId: meeting.id),
        ).map((MeetingAttendee row) => row.id).toList(),
        <String>[ada.id, ben.id],
      );
      expect(
        _ok(
          await listMeetingActionsByMeetingAndStatus(
            db,
            meetingId: meeting.id,
            status: 'open',
            offset: 0,
            limit: 10,
          ),
        ).map((MeetingAction row) => row.id).toList(),
        <String>[action.id],
      );

      _ok(
        await deleteMeeting(
          db,
          id: meeting.id,
          reason: 'meeting cancelled',
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      expect(
        await (db.select(db.meetings)
              ..where(($MeetingsTable tbl) => tbl.id.equals(meeting.id)))
            .getSingleOrNull(),
        isNotNull,
      );
      expect(
        await (db.select(db.attendees)
              ..where(($AttendeesTable tbl) => tbl.id.equals(ada.id)))
            .getSingleOrNull(),
        isNotNull,
      );
      expect(
        await (db.select(db.meetingActions)
              ..where(($MeetingActionsTable tbl) => tbl.id.equals(action.id)))
            .getSingleOrNull(),
        isNotNull,
      );
      final List<Tombstone> marks = await db.select(db.tombstones).get();
      expect(
        marks
            .map((Tombstone row) => '${row.entityType}:${row.entityId}')
            .toSet(),
        <String>{
          'meetings:${meeting.id}',
          'attendees:${ada.id}',
          'attendees:${ben.id}',
          'meeting_actions:${action.id}',
        },
      );
      expect(
        marks.every((Tombstone row) => row.reason == 'meeting cancelled'),
        isTrue,
      );
    },
  );

  test('refining minutes leaves transcriptRaw byte-identical', () async {
    const String transcript = 'Raw notes.\nLine two.';
    final MeetingRow meeting = _ok(
      await insertMeeting(
        db,
        row: _meeting(transcript: transcript, startAt: t0),
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );

    final MeetingRow refined = _ok(
      await refineMeetingMinutes(
        db,
        id: meeting.id,
        minutes: 'Summary of the kick-off.',
        clock: FixedClock(t0),
        deviceId: 'device-a',
        ids: ids,
      ),
    );
    expect(refined.transcriptRaw, transcript);
    expect(refined.minutesRefined, 'Summary of the kick-off.');

    final Result<MeetingRow> overwritten = await insertMeeting(
      db,
      row: MeetingsCompanion(
        id: Value<String>(meeting.id),
        transcriptRaw: const Value<String>('changed'),
      ),
      clock: FixedClock(t0),
      deviceId: 'device-a',
      ids: ids,
    );
    expect(
      overwritten.fold((Failure failure) => failure, (_) => null),
      isA<StorageFailure>(),
    );
    expect(
      (await (db.select(db.meetings)
                ..where(($MeetingsTable tbl) => tbl.id.equals(meeting.id)))
              .getSingle())
          .transcriptRaw,
      transcript,
    );
  });

  test(
    'an attendee matched to a staff record keeps the captured name',
    () async {
      final MeetingRow meeting = _ok(
        await insertMeeting(
          db,
          row: _meeting(transcript: 'Present.', startAt: t0),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      final MeetingAttendee captured = _ok(
        await upsertMeetingAttendee(
          db,
          row: AttendeesCompanion(
            meetingId: Value<String>(meeting.id),
            name: const Value<String>('A. Lovelace'),
            signaturePresent: const Value<bool>(true),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );

      final MeetingAttendee matched = _ok(
        await upsertMeetingAttendee(
          db,
          row: AttendeesCompanion(
            id: Value<String>(captured.id),
            matchedStaffId: const Value<String>('staff-ada'),
          ),
          clock: FixedClock(t0),
          deviceId: 'device-a',
          ids: ids,
        ),
      );
      expect(matched.id, captured.id);
      expect(matched.name, 'A. Lovelace');
      expect(matched.matchedStaffId, 'staff-ada');
    },
  );

  test('version 10 creates the meeting tables with merge columns', () async {
    await db.close();
    final Directory directory = Directory.systemTemp.createTempSync(
      'tapture_meetings_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    final File seed = File('${directory.path}/tapture.sqlite');
    _seedVersion1(seed);

    final AppDatabase upgraded = AppDatabase.open(
      directoryPath: directory.path,
    );
    addTearDown(upgraded.close);
    await upgraded.customSelect('SELECT 1').get();

    expect(
      await _columns(upgraded, 'meetings'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'record_id',
        'title',
        'start_at',
        'end_at',
        'chair',
        'secretary',
        'agenda',
        'transcript_raw',
        'minutes_refined',
      ]),
    );
    expect(
      await _columns(upgraded, 'attendees'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'meeting_id',
        'name',
        'title',
        'organisation',
        'contact',
        'signature_present',
        'matched_staff_id',
      ]),
    );
    expect(
      await _columns(upgraded, 'meeting_actions'),
      containsAll(<String>[
        'id',
        'created_at',
        'updated_at',
        'updated_by_device',
        'rev',
        'meeting_id',
        'action',
        'owner_name',
        'due_date',
        'status',
      ]),
    );
  });
}

MeetingsCompanion _meeting({
  required String transcript,
  required DateTime startAt,
}) {
  return MeetingsCompanion(
    recordId: const Value<String>('r-meeting'),
    title: const Value<String>('Kick-off'),
    startAt: Value<DateTime>(startAt),
    agenda: Value<String>(jsonEncode(<String>['Welcome'])),
    transcriptRaw: Value<String>(transcript),
  );
}

RecordsCompanion _record({required DateTime capturedAt}) {
  return RecordsCompanion(
    projectId: const Value<String>('p1'),
    templateId: const Value<String>('t1'),
    status: const Value<String>('captured'),
    processingMode: const Value<String>('manual'),
    contextJson: const Value<String>('{}'),
    identityHash: const Value<String>('h-meeting'),
    source: const Value<String>('capture'),
    capturedAt: Value<DateTime>(capturedAt),
    capturedBy: const Value<String>('Ada'),
  );
}

void _seedVersion1(File file) {
  file.parent.createSync(recursive: true);
  final Database database = sqlite3.open(file.path);
  database.execute('PRAGMA user_version = 1');
  database.dispose();
}

Future<Set<String>> _columns(AppDatabase db, String table) async {
  final List<QueryRow> info = await db
      .customSelect('PRAGMA table_info("$table")')
      .get();
  return <String>{for (final QueryRow row in info) row.read<String>('name')};
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}
