import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/record_status.dart';

import 'deleted_record.dart';
import 'record_entry.dart';
import 'record_facets.dart';
import 'record_filter.dart';
import 'record_history_event.dart';
import 'record_sort.dart';
import 'record_summary.dart';
import 'template_change_plan.dart';

/// Persistence port for captured records (task 014). Drift rows stop at the
/// data layer; every read and write here speaks domain types.
///
/// Every implementation, the Drift one and the in-memory fake, honours the
/// same contract (`test/features/records/record_repository_contract.dart`):
/// status moves are checked with `RecordLifecycle` before anything is
/// written; a delete is a tombstone plus status deleted and a restore
/// undoes both; values are never deleted, only retired or flagged.
abstract interface class RecordRepository {
  /// The record [id], read whole, and again after every change to it.
  /// Deleted records are included; their status says so. Emits null when no
  /// record [id] is on this device.
  Stream<RecordEntry?> watchEntry(String id);

  /// The record [id] read whole once, or null when it is not on this device.
  /// Deleted records are included.
  Future<Result<RecordEntry?>> byId(String id);

  /// One page of [projectId]'s records matching [filter], ordered by [sort]
  /// with the record id as a tiebreak: [limit] rows from [offset]. Filtering,
  /// search and ordering all happen in the query. Deleted records are never
  /// listed, and archived ones only when [filter] asks for them.
  Stream<List<RecordSummary>> watchPage(
    String projectId, {
    required RecordFilter filter,
    required RecordSort sort,
    required int offset,
    required int limit,
  });

  /// How many of [projectId]'s records [filter] matches, under the same
  /// rules as [watchPage].
  Stream<int> watchCount(String projectId, RecordFilter filter);

  /// The choices [projectId]'s filter sheet offers, from its records that
  /// are not deleted.
  Future<Result<RecordFacets>> facets(String projectId);

  /// Record [id]'s history from the local audit table, oldest first: its
  /// own rows plus those of its photos and captions.
  Stream<List<RecordHistoryEvent>> watchHistory(String id);

  /// Every record in the recycle bin, across projects, newest deletion
  /// first. Records removed with their project are not listed.
  Stream<List<DeletedRecord>> watchBin();

  /// Saves a record made by hand from [draft], in status draft, and returns
  /// it. A draft without a project or template is a validation failure.
  Future<Result<RecordEntry>> save(RecordDraft draft);

  /// Moves record [id] to [to], after checking the move with
  /// `RecordLifecycle`; an illegal move fails validation and writes nothing.
  /// Moves into or out of deleted are refused here: [delete] and [restore]
  /// own them. Approving stamps the approval time and operator.
  Future<Result<void>> transition(String id, RecordStatus to, {String? reason});

  /// Writes [edits] onto record [id] as refined values, each with an audit
  /// entry whose previous value is what the field displayed. The raw value
  /// is kept; the edit supersedes an approved value, so the field displays
  /// the edit. An edited value becomes manual and verified, a field with no
  /// value gets one, and an edit that changes nothing writes nothing. An
  /// approved record goes back to needsReview in the same transaction. A
  /// deleted record must be restored first.
  Future<Result<void>> editValues(String id, List<RecordValueEdit> edits);

  /// What moving record [id] to [templateId] would map, retire, add and
  /// restore, by field key, without changing anything.
  Future<Result<TemplateChangePlan>> planTemplateChange(
    String id,
    String templateId,
  );

  /// Moves record [id] to [templateId] as [planTemplateChange] describes:
  /// values the template does not declare are kept as retired, never
  /// deleted, and retired values it declares come back. An approved record
  /// goes back to needsReview in the same transaction.
  Future<Result<void>> changeTemplate(String id, String templateId);

  /// Moves record [id] to the recycle bin: a tombstone and status deleted in
  /// one transaction, with [reason] on both. Its files stay until the purge.
  Future<Result<void>> delete(String id, {required String reason});

  /// Brings record [id] back from the recycle bin whole, to the status it had
  /// before it was deleted, and removes its tombstone.
  Future<Result<void>> restore(String id);
}

/// What a record made by hand starts with: its project, template, typed
/// field values by key, and the context snapshot in force.
typedef RecordDraft = ({
  String projectId,
  String templateId,
  Map<String, String> fields,
  Map<String, String> context,
});

/// One operator edit: the field it changes and the text it writes.
typedef RecordValueEdit = ({String fieldKey, String value});
