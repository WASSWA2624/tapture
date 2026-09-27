import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart' as sqlite;
import 'package:tapture/core/db/record_schema.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/evidence_purge.dart';
import 'package:tapture/core/widgets/record_status.dart';

import '../domain/purge_candidate.dart';
import '../domain/purge_store.dart';
import 'record_queries.dart' show RecordQueries;

/// The Drift side of the retention purge (task 014 step 7, D13): the one
/// place a record's rows are deleted for good, next to the one service that
/// deletes its files ([EvidencePurge]). Both names contain `purge`, the only
/// place a hard delete may live (FE-SEC-08).
///
/// [candidates] is the recycle bin: records in status deleted with a
/// `records` tombstone, except those removed with their project (the
/// project-delete reason, or a tombstoned project), exactly as the bin lists
/// them. Each carries its deletion time and whether a merge still needs it,
/// both read in SQL (D13): an unresolved merge conflict names the record or
/// a row it owns, or its project exchanges packages (a merge session for
/// the project, or a bundle export) and no bundle export has been made
/// since the record was deleted, so the deletion has not travelled yet.
///
/// [purge] runs in ONE transaction: it checks the record is still in the
/// bin as listed, removes its files and cached copies through
/// [EvidencePurge] (files first: a file that cannot go keeps every row), then
/// deletes every row the record owns. There are no foreign-key cascades, so
/// each child table is named:
/// - the record, first, which drops its search document by trigger;
/// - its values, their evidence, and the captions of the record and of its
///   photos;
/// - every photo filed on it, tombstoned ones included;
/// - its attachment links, and the attachments no other record, photo or
///   value still uses;
/// - its processing jobs and their results, variances, duplicate pairs that
///   name it, and meetings with their attendees and actions;
/// - the OCR text of a photo no surviving photo shares;
/// - the tombstones, version vectors, merge conflicts and audit history of
///   every row above. The audit history goes too: the purge removes the
///   record for good, and an audit row holds its values (previous and new)
///   long after the record itself is gone.
///
/// A file another surviving row still names is kept: the stored file when
/// another photo or attachment has the same path, the hash-keyed thumbnails
/// and OCR text when another photo has the same content hash. A photo
/// tombstone on a record that is not being purged is never touched (spec
/// §38: its file stays until the record is deleted).
final class RecordPurgeStore implements PurgeStore {
  /// Purges from the database `db`, removing files through `files`.
  RecordPurgeStore({required this._db, required this._files});

  final sqlite.AppDatabase _db;
  final EvidencePurge _files;

  @override
  Future<Result<List<PurgeCandidate>>> candidates() async {
    try {
      final List<QueryRow> rows = await _db
          .customSelect(_candidatesSql, variables: _binVariables)
          .get();
      return Success<List<PurgeCandidate>>(<PurgeCandidate>[
        for (final QueryRow row in rows) _candidateOf(row),
      ]);
    } on Object catch (error) {
      return FailureResult<List<PurgeCandidate>>(storageFailureFrom(error));
    }
  }

  @override
  Future<Result<int>> purge(PurgeCandidate candidate) async {
    final Result<Result<int>> outcome = await runInTransaction<Result<int>>(
      _db,
      () =>
          RecordSchema.deferIndexing(_db, () => _purgeInTransaction(candidate)),
    );
    return switch (outcome) {
      Success<Result<int>>(:final Result<int> value) => value,
      FailureResult<Result<int>>(failure: final Failure storageFailure) =>
        FailureResult<int>(storageFailure),
    };
  }

  /// The body of [purge], inside its transaction. A refusal before anything
  /// is deleted comes back as a value; a failed delete throws, so the
  /// transaction keeps every row.
  Future<Result<int>> _purgeInTransaction(PurgeCandidate candidate) async {
    final String recordId = candidate.recordId;
    final QueryRow? listed = await _db
        .customSelect(
          _oneCandidateSql,
          variables: <Variable<Object>>[
            ..._binVariables,
            Variable<String>(recordId),
          ],
        )
        .getSingleOrNull();
    if (listed == null) {
      return const FailureResult<int>(_notInBin);
    }
    final PurgeCandidate current = _candidateOf(listed);
    if (current.deletedAt.isAfter(candidate.deletedAt)) {
      // Restored and deleted again since it was listed: its window starts
      // over, so the job's decision no longer holds.
      return const FailureResult<int>(_deletedAgain);
    }
    if (current.mergeNeeded) {
      return const FailureResult<int>(_mergeStillNeeded);
    }
    final _Owned owned = await _ownedRows(recordId);

    final Result<int> photoFiles = await _files.removePhotos(owned.photos);
    final int photosRemoved;
    switch (photoFiles) {
      case FailureResult<int>(:final Failure failure):
        return FailureResult<int>(failure);
      case Success<int>(:final int value):
        photosRemoved = value;
    }
    final Result<int> otherFiles = await _files.removeFiles(owned.files);
    final int filesRemoved;
    switch (otherFiles) {
      case FailureResult<int>(:final Failure failure):
        return FailureResult<int>(failure);
      case Success<int>(:final int value):
        filesRemoved = value;
    }

    await _deleteRows(owned);
    return Success<int>(photosRemoved + filesRemoved);
  }

  /// Everything [recordId] owns, read inside the purge's transaction.
  Future<_Owned> _ownedRows(String recordId) async {
    final List<Variable<Object>> record = <Variable<Object>>[
      Variable<String>(recordId),
    ];
    final List<QueryRow> photoRows = await _db
        .customSelect(_photosSql, variables: record)
        .get();
    final List<QueryRow> attachmentRows = await _db
        .customSelect(_attachmentsSql, variables: record)
        .get();
    Future<List<String>> ids(String sql) async {
      final List<QueryRow> rows = await _db
          .customSelect(sql, variables: record)
          .get();
      return <String>[for (final QueryRow row in rows) row.read<String>('id')];
    }

    return _Owned(
      recordId: recordId,
      photos: <PurgePhoto>[
        for (final QueryRow row in photoRows)
          (
            photoId: row.read<String>('id'),
            sha256: row.read<String>('sha256'),
            storagePath: row.read<String>('storage_path'),
            keepFile: row.read<int>('keep_file') != 0,
            keepCache: row.read<int>('keep_cache') != 0,
          ),
      ],
      files: <String>[
        for (final QueryRow row in attachmentRows)
          if (row.read<int>('keep_file') == 0) row.read<String>('storage_path'),
      ],
      attachmentIds: <String>[
        for (final QueryRow row in attachmentRows) row.read<String>('id'),
      ],
      fieldIds: await ids(_fieldsSql),
      evidenceIds: await ids(_evidenceSql),
      captionIds: await ids(_captionsSql),
      ownerIds: await ids(_ownersSql),
      jobIds: await ids(_jobsSql),
      resultIds: await ids(_resultsSql),
      varianceIds: await ids(_variancesSql),
      duplicateIds: await ids(_duplicatesSql),
      meetingIds: await ids(_meetingsSql),
      attendeeIds: await ids(_attendeesSql),
      actionIds: await ids(_actionsSql),
      ocrIds: await ids(_ocrSql),
    );
  }

  /// Deletes every row in [owned], the record first, then everything that
  /// remembers those rows: tombstones, version vectors, conflicts and audit.
  Future<void> _deleteRows(_Owned owned) async {
    await _deleteIds(_db.records, <String>[owned.recordId]);
    await _deleteIds(_db.fieldEvidence, owned.evidenceIds);
    await _deleteIds(_db.recordFields, owned.fieldIds);
    await _deleteIds(_db.captions, owned.captionIds);
    await _deleteIds(_db.photos, <String>[
      for (final PurgePhoto photo in owned.photos) photo.photoId,
    ]);
    await _deleteIds(_db.attachmentOwners, owned.ownerIds);
    await _deleteIds(_db.attachments, owned.attachmentIds);
    await _deleteIds(_db.processingResults, owned.resultIds);
    await _deleteIds(_db.processing, owned.jobIds);
    await _deleteIds(_db.variances, owned.varianceIds);
    await _deleteIds(_db.duplicates, owned.duplicateIds);
    await _deleteIds(_db.attendees, owned.attendeeIds);
    await _deleteIds(_db.meetingActions, owned.actionIds);
    await _deleteIds(_db.meetings, owned.meetingIds);
    await _deleteIds(_db.ocrCacheEntries, owned.ocrIds);
    final List<String> every = owned.everyId;
    await _deleteIds(_db.tombstones, every, column: _entityColumn);
    await _deleteIds(_db.syncState, every, column: _entityColumn);
    await _deleteIds(_db.mergeConflicts, every, column: _entityColumn);
    await _deleteIds(_db.auditLog, every, column: _entityColumn);
  }

  /// Deletes the rows of [table] whose [column] is one of [ids], a bounded
  /// number of variables per statement, and tells drift's watchers.
  Future<void> _deleteIds(
    TableInfo<Table, Object?> table,
    List<String> ids, {
    String column = 'id',
  }) async {
    for (var start = 0; start < ids.length; start += _chunk) {
      final List<String> chunk = ids.sublist(
        start,
        start + _chunk < ids.length ? start + _chunk : ids.length,
      );
      await _db.customUpdate(
        'DELETE FROM ${table.actualTableName} WHERE $column IN '
        '(${List<String>.filled(chunk.length, '?').join(', ')})',
        variables: <Variable<Object>>[
          for (final String id in chunk) Variable<String>(id),
        ],
        updates: <TableInfo<Table, Object?>>{table},
        updateKind: UpdateKind.delete,
      );
    }
  }
}

/// Every row one purged record owns, by id, and the files to remove.
final class _Owned {
  _Owned({
    required this.recordId,
    required this.photos,
    required this.files,
    required this.attachmentIds,
    required this.fieldIds,
    required this.evidenceIds,
    required this.captionIds,
    required this.ownerIds,
    required this.jobIds,
    required this.resultIds,
    required this.varianceIds,
    required this.duplicateIds,
    required this.meetingIds,
    required this.attendeeIds,
    required this.actionIds,
    required this.ocrIds,
  });

  final String recordId;

  /// Every photo filed on the record, tombstoned ones included, with what
  /// another surviving row still needs of it.
  final List<PurgePhoto> photos;

  /// Stored files of the attachments that go, less any another row names.
  final List<String> files;

  final List<String> attachmentIds;
  final List<String> fieldIds;
  final List<String> evidenceIds;
  final List<String> captionIds;
  final List<String> ownerIds;
  final List<String> jobIds;
  final List<String> resultIds;
  final List<String> varianceIds;
  final List<String> duplicateIds;
  final List<String> meetingIds;
  final List<String> attendeeIds;
  final List<String> actionIds;
  final List<String> ocrIds;

  /// Every deleted row's id: what tombstones, version vectors, conflicts and
  /// audit rows are keyed by. Ids are unique across tables.
  List<String> get everyId => <String>[
    recordId,
    for (final PurgePhoto photo in photos) photo.photoId,
    ...attachmentIds,
    ...fieldIds,
    ...evidenceIds,
    ...captionIds,
    ...ownerIds,
    ...jobIds,
    ...resultIds,
    ...varianceIds,
    ...duplicateIds,
    ...meetingIds,
    ...attendeeIds,
    ...actionIds,
    ...ocrIds,
  ];
}

PurgeCandidate _candidateOf(QueryRow row) {
  return PurgeCandidate(
    recordId: row.read<String>('record_id'),
    projectId: row.read<String>('project_id'),
    deletedAt: row.read<DateTime>('deleted_at').toUtc(),
    mergeNeeded: row.read<int>('merge_needed') != 0,
  );
}

/// Ids per delete statement, well under SQLite's variable limit.
const int _chunk = 500;

/// Column that names the entity on tombstones, version vectors, merge
/// conflicts and audit rows.
const String _entityColumn = 'entity_id';

/// Binds ?1 (the deleted status) and ?2 (the project-delete reason).
final List<Variable<Object>> _binVariables = <Variable<Object>>[
  Variable<String>(RecordStatus.deleted.stored),
  const Variable<String>(RecordQueries.projectDeletedReason),
];

/// The recycle bin, on record `r` and its tombstone `t`, as the bin lists
/// it. Binds ?1 and ?2 ([_binVariables]).
const String _binWhere =
    "t.entity_type = 'records' AND r.status = ?1 AND t.reason <> ?2 "
    'AND NOT EXISTS (SELECT 1 FROM tombstones pt '
    "WHERE pt.entity_type = 'projects' AND pt.entity_id = r.project_id)";

/// SQL predicate on `x`, an `attachment_owners` or `captions` row: owned by
/// the record bound as ?1 or by one of its photos.
String _ownedByRecord(String x) =>
    "(($x.owner_type = 'record' AND $x.owner_id = ?1) OR "
    "($x.owner_type = 'photo' AND $x.owner_id IN "
    '(SELECT id FROM photos WHERE record_id = ?1)))';

/// Whether a merge still needs record `r`'s deletion (D13), 1 or 0. An
/// unresolved conflict names the record or a row it owns; or the project
/// exchanges packages and no bundle has left since tombstone `t`.
const String _mergeNeeded =
    '(EXISTS (SELECT 1 FROM merge_conflicts c WHERE c.resolution IS NULL '
    'AND (c.entity_id = r.id '
    'OR c.entity_id IN (SELECT id FROM record_fields WHERE record_id = r.id) '
    'OR c.entity_id IN (SELECT id FROM photos WHERE record_id = r.id) '
    'OR c.entity_id IN (SELECT cc.id FROM captions cc WHERE '
    "(cc.owner_type = 'record' AND cc.owner_id = r.id) OR "
    "(cc.owner_type = 'photo' AND cc.owner_id IN "
    '(SELECT id FROM photos WHERE record_id = r.id))))) '
    'OR ((EXISTS (SELECT 1 FROM merge_sessions m WHERE '
    r"CASE WHEN json_valid(m.counts) THEN json_extract(m.counts, '$.project_id') "
    'END = r.project_id) '
    'OR EXISTS (SELECT 1 FROM exports e WHERE e.project_id = r.project_id '
    '''AND instr(e.formats, '"bundle"') > 0)) '''
    'AND NOT EXISTS (SELECT 1 FROM exports e2 WHERE '
    'e2.project_id = r.project_id '
    '''AND instr(e2.formats, '"bundle"') > 0 '''
    'AND e2.created_at > t.deleted_at)))';

/// Columns [_candidateOf] reads.
const String _candidateColumns =
    'r.id AS record_id, r.project_id AS project_id, '
    't.deleted_at AS deleted_at, $_mergeNeeded AS merge_needed';

/// Every record in the bin, oldest deletion first.
const String _candidatesSql =
    'SELECT $_candidateColumns '
    'FROM tombstones t JOIN records r ON r.id = t.entity_id '
    'WHERE $_binWhere '
    'ORDER BY t.deleted_at, r.id';

/// The bin row of the record bound as ?3, if it is still in the bin.
const String _oneCandidateSql =
    'SELECT $_candidateColumns '
    'FROM tombstones t JOIN records r ON r.id = t.entity_id '
    'WHERE $_binWhere AND r.id = ?3';

/// The stored path (under the storage root) of a row `x` in project folder
/// `f`.
String _storagePath(String x, String f) =>
    "'${EvidencePurge.projectsFolder}/' || COALESCE($f.folder_name, '') || "
    "'/' || $x.relative_path";

/// Whether a photo or attachment other than row `x` (in project folder `f`)
/// that survives purging record ?1 names the same stored file.
String _pathShared(String x, String f) =>
    '(EXISTS (SELECT 1 FROM photos sp JOIN projects spp '
    'ON spp.id = sp.project_id WHERE sp.relative_path = $x.relative_path '
    'AND spp.folder_name = $f.folder_name '
    'AND (sp.record_id IS NULL OR sp.record_id <> ?1)) '
    'OR EXISTS (SELECT 1 FROM attachments sa JOIN projects sap '
    'ON sap.id = sa.project_id WHERE sa.relative_path = $x.relative_path '
    'AND sap.folder_name = $f.folder_name AND sa.id <> $x.id '
    'AND NOT ${_attachmentGoes('sa')}))';

/// Whether attachment `a` goes with record ?1: every link it has is owned
/// by the record or its photos, and no value of another record cites it.
String _attachmentGoes(String a) =>
    '(NOT EXISTS (SELECT 1 FROM attachment_owners ko '
    'WHERE ko.attachment_id = $a.id AND NOT ${_ownedByRecord('ko')}) '
    'AND NOT EXISTS (SELECT 1 FROM field_evidence kf '
    'WHERE kf.document_id = $a.id AND kf.record_field_id NOT IN '
    '(SELECT id FROM record_fields WHERE record_id = ?1)))';

/// Every photo filed on record ?1, tombstoned ones included, with its stored
/// path and whether another surviving row keeps its file or its hash.
final String _photosSql =
    'SELECT p.id AS id, p.sha256 AS sha256, '
    '${_storagePath('p', 'pr')} AS storage_path, '
    '${_pathShared('p', 'pr')} AS keep_file, '
    'EXISTS (SELECT 1 FROM photos hp WHERE hp.sha256 = p.sha256 '
    'AND hp.id <> p.id AND (hp.record_id IS NULL OR hp.record_id <> ?1)) '
    'AS keep_cache '
    'FROM photos p LEFT JOIN projects pr ON pr.id = p.project_id '
    'WHERE p.record_id = ?1 ORDER BY p.id';

/// The attachments linked to record ?1 or its photos that nothing else
/// uses, with their stored paths.
final String _attachmentsSql =
    'SELECT a.id AS id, ${_storagePath('a', 'ap')} AS storage_path, '
    '${_pathShared('a', 'ap')} AS keep_file '
    'FROM attachments a LEFT JOIN projects ap ON ap.id = a.project_id '
    'WHERE EXISTS (SELECT 1 FROM attachment_owners o '
    'WHERE o.attachment_id = a.id AND ${_ownedByRecord('o')}) '
    "AND ${_attachmentGoes('a')} ORDER BY a.id";

const String _fieldsSql = 'SELECT id FROM record_fields WHERE record_id = ?1';

const String _evidenceSql =
    'SELECT id FROM field_evidence WHERE record_field_id IN '
    '(SELECT id FROM record_fields WHERE record_id = ?1)';

final String _captionsSql =
    'SELECT c.id AS id FROM captions c WHERE ${_ownedByRecord('c')}';

final String _ownersSql =
    'SELECT o.id AS id FROM attachment_owners o WHERE ${_ownedByRecord('o')}';

const String _jobsSql = 'SELECT id FROM processing_jobs WHERE record_id = ?1';

const String _resultsSql =
    'SELECT id FROM processing_results WHERE job_id IN '
    '(SELECT id FROM processing_jobs WHERE record_id = ?1)';

const String _variancesSql = 'SELECT id FROM variances WHERE record_id = ?1';

const String _duplicatesSql =
    'SELECT id FROM duplicates '
    'WHERE left_record_id = ?1 OR right_record_id = ?1';

const String _meetingsSql = 'SELECT id FROM meetings WHERE record_id = ?1';

const String _attendeesSql =
    'SELECT id FROM attendees WHERE meeting_id IN '
    '(SELECT id FROM meetings WHERE record_id = ?1)';

const String _actionsSql =
    'SELECT id FROM meeting_actions WHERE meeting_id IN '
    '(SELECT id FROM meetings WHERE record_id = ?1)';

/// OCR text of the record's photos whose content hash no surviving photo
/// shares.
const String _ocrSql =
    'SELECT o.id AS id FROM ocr_cache o WHERE o.content_hash IN '
    '(SELECT p.sha256 FROM photos p WHERE p.record_id = ?1 '
    'AND NOT EXISTS (SELECT 1 FROM photos hp WHERE hp.sha256 = p.sha256 '
    'AND hp.id <> p.id AND (hp.record_id IS NULL OR hp.record_id <> ?1)))';

const ValidationFailure _notInBin = ValidationFailure(
  message: 'That record is no longer in the recycle bin.',
  recoveryAction: 'Nothing to remove; it was restored or already removed.',
);

const ValidationFailure _deletedAgain = ValidationFailure(
  message: 'That record was deleted again, so its retention starts over.',
  recoveryAction: 'Leave it; the purge takes it once its new window passes.',
);

const ValidationFailure _mergeStillNeeded = ValidationFailure(
  message: 'A merge still needs that deleted record.',
  recoveryAction: 'Send a bundle or settle the merge, then try again.',
);
