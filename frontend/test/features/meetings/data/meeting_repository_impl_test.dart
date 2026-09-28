import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/meetings.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/meetings/data/meeting_repository_impl.dart';
import 'package:tapture/features/meetings/domain/action_entry.dart';
import 'package:tapture/features/meetings/domain/attendee.dart';
import 'package:tapture/features/meetings/domain/meeting.dart';
import 'package:tapture/features/meetings/domain/meeting_repository.dart';

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
    expect(again.minutes, 'refined');
    expect(again.meeting.title, 'Later');
  });
}

T _ok<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final failure) => fail(failure.message),
  };
}
