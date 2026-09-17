part of 'meetings.dart';

/// One person at a [Meetings] row. The captured name is kept even when a
/// staff match is accepted.
@DataClassName('MeetingAttendee')
class Attendees extends Table with MergeColumns {
  /// Meeting this person belongs to.
  TextColumn get meetingId => text()();

  /// Name as captured, stored as data. A staff match never overwrites it.
  TextColumn get name => text()();

  /// Role or job title as captured, stored as data.
  TextColumn get title => text().withDefault(const Constant(''))();

  /// Organisation as captured, stored as data.
  TextColumn get organisation => text().withDefault(const Constant(''))();

  /// Contact as captured, stored as data. Personal; never logged.
  TextColumn get contact => text().withDefault(const Constant(''))();

  /// Whether a signature was present on the sheet.
  BoolColumn get signaturePresent => boolean()();

  /// Staff dataset row the operator accepted, when they did.
  TextColumn get matchedStaffId => text().nullable()();
}

/// Inserts or updates an attendee. [MeetingAttendee.name] is stored as
/// captured; [MeetingAttendee.matchedStaffId] is an optional link beside it.
Future<Result<MeetingAttendee>> upsertMeetingAttendee(
  GeneratedDatabase db, {
  required Insertable<MeetingAttendee> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) {
  final AppDatabase database = db as AppDatabase;
  return _AttendeesDao(
    database,
    clock: clock,
    deviceId: deviceId,
    ids: ids,
  ).upsert(row);
}

/// Attendees for [meetingId], oldest first.
Future<Result<List<MeetingAttendee>>> listAttendeesForMeeting(
  GeneratedDatabase db, {
  required String meetingId,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final List<MeetingAttendee> rows =
        await (database.select(database.attendees)
              ..where(($AttendeesTable tbl) => tbl.meetingId.equals(meetingId))
              ..orderBy(<OrderClauseGenerator<$AttendeesTable>>[
                ($AttendeesTable tbl) => OrderingTerm.asc(tbl.createdAt),
                ($AttendeesTable tbl) => OrderingTerm.asc(tbl.id),
              ]))
            .get();
    return Success<List<MeetingAttendee>>(rows);
  } on Failure catch (failure) {
    return FailureResult<List<MeetingAttendee>>(failure);
  } on Object catch (error) {
    return FailureResult<List<MeetingAttendee>>(storageFailureFrom(error));
  }
}

final class _AttendeesDao extends BaseDao<Attendees, MeetingAttendee> {
  _AttendeesDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.attendees);
}
