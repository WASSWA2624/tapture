part of 'meetings.dart';

/// One action item on a [Meetings] row.
///
/// The review list reads `WHERE meeting_id AND status`, which
/// [meeting_actions_by_meeting_status] was created to serve.
@TableIndex(
  name: 'meeting_actions_by_meeting_status',
  columns: {#meetingId, #status},
)
@DataClassName('MeetingAction')
class MeetingActions extends Table with MergeColumns {
  @override
  String get tableName => 'meeting_actions';

  /// Meeting this action belongs to.
  TextColumn get meetingId => text()();

  /// Action text as captured, stored as data.
  TextColumn get action => text()();

  /// Owner name as captured, stored as data.
  TextColumn get ownerName => text()();

  /// When the action is due.
  DateTimeColumn get dueDate => dateTime()();

  /// Lifecycle status, stored as text.
  TextColumn get status => text()();
}

/// Inserts or updates a meeting action.
Future<Result<MeetingAction>> upsertMeetingAction(
  GeneratedDatabase db, {
  required Insertable<MeetingAction> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) {
  final AppDatabase database = db as AppDatabase;
  return _MeetingActionsDao(
    database,
    clock: clock,
    deviceId: deviceId,
    ids: ids,
  ).upsert(row);
}

/// A page of actions in [meetingId] with [status], oldest first.
///
/// The `WHERE meeting_id AND status` shape is what
/// `meeting_actions_by_meeting_status` was created to serve.
Future<Result<List<MeetingAction>>> listMeetingActionsByMeetingAndStatus(
  GeneratedDatabase db, {
  required String meetingId,
  required String status,
  required int offset,
  required int limit,
}) async {
  try {
    final AppDatabase database = db as AppDatabase;
    final List<MeetingAction> rows =
        await (database.select(database.meetingActions)
              ..where(
                ($MeetingActionsTable tbl) =>
                    tbl.meetingId.equals(meetingId) & tbl.status.equals(status),
              )
              ..orderBy(<OrderClauseGenerator<$MeetingActionsTable>>[
                ($MeetingActionsTable tbl) => OrderingTerm.asc(tbl.createdAt),
                ($MeetingActionsTable tbl) => OrderingTerm.asc(tbl.id),
              ])
              ..limit(limit, offset: offset))
            .get();
    return Success<List<MeetingAction>>(rows);
  } on Failure catch (failure) {
    return FailureResult<List<MeetingAction>>(failure);
  } on Object catch (error) {
    return FailureResult<List<MeetingAction>>(storageFailureFrom(error));
  }
}

final class _MeetingActionsDao extends BaseDao<MeetingActions, MeetingAction> {
  _MeetingActionsDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.meetingActions);
}
