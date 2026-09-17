import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

part 'attendees.dart';
part 'meeting_actions.dart';

/// A meeting header: times, officers, agenda, raw transcript and refined
/// minutes.
///
/// [transcriptRaw] is written once at insert. Refinement writes
/// [minutesRefined] beside it.
@DataClassName('MeetingRow')
class Meetings extends Table with MergeColumns {
  /// Record this meeting is filed on.
  TextColumn get recordId => text()();

  /// Operator-facing title, stored as data.
  TextColumn get title => text()();

  /// When the meeting started.
  DateTimeColumn get startAt => dateTime()();

  /// When the meeting ended, if it has.
  DateTimeColumn get endAt => dateTime().nullable()();

  /// Chair as captured, stored as data.
  TextColumn get chair => text().withDefault(const Constant(''))();

  /// Secretary as captured, stored as data.
  TextColumn get secretary => text().withDefault(const Constant(''))();

  /// Agenda items JSON. An array, stored as text.
  TextColumn get agenda => text()();

  /// Verbatim transcript. Written once at insert, never updated.
  TextColumn get transcriptRaw => text()();

  /// Refined minutes written beside the transcript, never over it.
  TextColumn get minutesRefined => text().nullable()();
}

/// Inserts a meeting. A later write that includes the raw transcript is
/// refused.
Future<Result<MeetingRow>> insertMeeting(
  GeneratedDatabase db, {
  required Insertable<MeetingRow> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) {
  return _writeMeeting(
    db,
    row: row,
    clock: clock,
    deviceId: deviceId,
    ids: ids,
    allowRaw: true,
  );
}

/// Writes refined minutes beside the original transcript.
Future<Result<MeetingRow>> refineMeetingMinutes(
  GeneratedDatabase db, {
  required String id,
  required String minutes,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) {
  return _writeMeeting(
    db,
    row: MeetingsCompanion(
      id: Value<String>(id),
      minutesRefined: Value<String>(minutes),
    ),
    clock: clock,
    deviceId: deviceId,
    ids: ids,
    allowRaw: false,
  );
}

/// Marks the meeting, its attendees and its actions deleted in one
/// transaction. Rows stay in place; each gets a tombstone.
Future<Result<void>> deleteMeeting(
  GeneratedDatabase db, {
  required String id,
  required String reason,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) {
  final AppDatabase database = db as AppDatabase;
  return runInTransaction(database, () async {
    final _MeetingsDao meetings = _MeetingsDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    );
    final MeetingRow? existing = (await meetings.getById(
      id,
    )).fold((Failure failure) => throw failure, (MeetingRow? value) => value);
    if (existing == null) {
      throw const StorageFailure(
        message: 'That meeting is no longer on this device.',
        recoveryAction: 'Refresh the list and try again.',
      );
    }
    final List<MeetingAttendee> people = await (database.select(
      database.attendees,
    )..where(($AttendeesTable tbl) => tbl.meetingId.equals(id))).get();
    final List<MeetingAction> items = await (database.select(
      database.meetingActions,
    )..where(($MeetingActionsTable tbl) => tbl.meetingId.equals(id))).get();
    final _AttendeesDao attendees = _AttendeesDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    );
    final _MeetingActionsDao actions = _MeetingActionsDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    );
    for (final MeetingAttendee person in people) {
      final Result<void> marked = await attendees.softDelete(
        person.id,
        reason: reason,
      );
      switch (marked) {
        case FailureResult<void>(:final Failure failure):
          throw failure;
        case Success<void>():
          break;
      }
    }
    for (final MeetingAction item in items) {
      final Result<void> marked = await actions.softDelete(
        item.id,
        reason: reason,
      );
      switch (marked) {
        case FailureResult<void>(:final Failure failure):
          throw failure;
        case Success<void>():
          break;
      }
    }
    final Result<void> marked = await meetings.softDelete(id, reason: reason);
    switch (marked) {
      case FailureResult<void>(:final Failure failure):
        throw failure;
      case Success<void>():
        return;
    }
  });
}

Future<Result<MeetingRow>> _writeMeeting(
  GeneratedDatabase db, {
  required Insertable<MeetingRow> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
  required bool allowRaw,
}) async {
  try {
    _ensureAgendaJson(row);
    final AppDatabase database = db as AppDatabase;
    final _MeetingsDao dao = _MeetingsDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    );
    final Map<String, Expression<Object>> columns =
        Map<String, Expression<Object>>.of(row.toColumns(false));
    final String? id = _idOf(row);
    final MeetingRow? existing = id == null
        ? null
        : (await dao.getById(id)).fold(
            (Failure failure) => throw failure,
            (MeetingRow? value) => value,
          );
    if (existing != null && columns.containsKey('transcript_raw')) {
      throw const StorageFailure(
        message: 'The original transcript cannot be changed.',
        recoveryAction: 'Leave the captured text and write refined minutes.',
      );
    }
    if (!allowRaw) {
      columns.remove('transcript_raw');
    }
    return dao.upsert(RawValuesInsertable<MeetingRow>(columns));
  } on Failure catch (failure) {
    return FailureResult<MeetingRow>(failure);
  } on Object catch (error) {
    return FailureResult<MeetingRow>(storageFailureFrom(error));
  }
}

void _ensureAgendaJson(Insertable<MeetingRow> row) {
  final Expression<Object>? expression = row.toColumns(false)['agenda'];
  if (expression is! Variable<String>) {
    return;
  }
  final String? raw = expression.value;
  if (raw == null) {
    return;
  }
  late final Object? decoded;
  try {
    decoded = jsonDecode(raw) as Object?;
  } on FormatException {
    throw const StorageFailure(
      message: 'A meeting agenda is not valid JSON.',
      recoveryAction: 'Fix the agenda list and save again.',
    );
  }
  if (decoded is! List) {
    throw const StorageFailure(
      message: 'A meeting agenda must be a JSON array.',
      recoveryAction: 'Fix the agenda list and save again.',
    );
  }
}

String? _idOf(Insertable<MeetingRow> row) {
  final Expression<Object>? expression = row.toColumns(false)['id'];
  if (expression is Variable<String>) {
    return expression.value;
  }
  return null;
}

final class _MeetingsDao extends BaseDao<Meetings, MeetingRow> {
  _MeetingsDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.meetings);
}
