import 'package:drift/drift.dart';
import 'package:tapture/core/audio/audio_recording.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/attachments.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/db/tables/transcripts.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/evidence_purge.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/speech/finished_utterance.dart';
import 'package:tapture/core/speech/transcript_outcome.dart';
import 'package:tapture/core/speech/transcript_segment.dart';
import 'package:tapture/core/speech/transcript_sink.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/transcript.dart';
import '../domain/transcript_gap.dart';
import '../domain/transcript_line.dart';
import '../domain/transcript_owner_kind.dart';
import '../domain/transcript_repository.dart';
import '../domain/transcript_start.dart';
import '../domain/transcript_status.dart';
import '../domain/transcript_summary.dart';

/// Keeps transcripts in the `transcripts` and `transcript_segments` tables
/// through the core/db helpers, which hold every write rule (spec §30.4.6).
final class TranscriptRepositoryImpl implements TranscriptRepository {
  /// A store over [db], stamping writes with [clock], [deviceId] and [ids].
  TranscriptRepositoryImpl({
    required AppDatabase db,
    required Clock clock,
    required String deviceId,
    required IdService ids,
  }) : _database = db,
       _time = clock,
       _device = deviceId,
       _idService = ids;

  final AppDatabase _database;
  final Clock _time;
  final String _device;
  final IdService _idService;

  /// The status each transcript reopened by [reopenForRemaining] had, so
  /// its sink's finish can restore it.
  final Map<String, TranscriptStatus> _reopened = <String, TranscriptStatus>{};

  @override
  Future<Result<TranscriptSummary>> begin(TranscriptStart start) async {
    final String id = _idService.newId();
    final Result<TranscriptRow> inserted = await insertTranscript(
      _database,
      row: TranscriptsCompanion(
        id: Value<String>(id),
        projectId: Value<String>(start.projectId),
        ownerKind: Value<String>(start.ownerKind.name),
        ownerId: Value<String?>(start.ownerId),
        attachmentId: Value<String?>(start.attachmentId),
        audioPath: Value<String>(start.audioPath),
        title: Value<String>(start.title),
        languageTag: Value<String>(start.languageTag),
        modelId: Value<String>(start.modelId),
        status: Value<String>(TranscriptStatus.live.name),
        startedAt: Value<DateTime>(start.startedAt),
      ),
      clock: _time,
      deviceId: _device,
      ids: _idService,
    );
    return _then(inserted, (_) => _summary(id));
  }

  @override
  Future<Result<void>> appendUtterance(
    String transcriptId,
    FinishedUtterance utterance,
  ) async {
    final Result<TranscriptRow> appended = await appendTranscriptUtterance(
      _database,
      transcriptId: transcriptId,
      fromMs: transcriptMillisecondOf(utterance.fromSample),
      toMs: transcriptMillisecondOf(utterance.toSample),
      skipped: utterance.skipped,
      segments:
          <
            ({int seq, int startMs, int endMs, String text, double? confidence})
          >[
            for (final TranscriptSegment segment in utterance.segments)
              (
                seq: segment.id,
                startMs: transcriptMillisecondOf(segment.startSample),
                endMs: transcriptMillisecondOf(segment.endSample),
                text: segment.text,
                confidence: segment.confidence,
              ),
          ],
      clock: _time,
      deviceId: _device,
      ids: _idService,
    );
    return appended.map((_) {});
  }

  @override
  Future<Result<TranscriptSink>> sinkFor(String transcriptId) async {
    final Result<TranscriptRow> row = await _live(transcriptId);
    return row.map((_) => _RepositorySink(this, transcriptId));
  }

  @override
  Future<Result<void>> linkAttachment(String id, String attachmentId) async {
    final Result<TranscriptRow> row = await _row(id);
    if (row case Success<TranscriptRow>(
      :final TranscriptRow value,
    ) when value.attachmentId == attachmentId) {
      return const Success<void>(null);
    }
    return _then(
      row,
      (_) => _update(
        TranscriptsCompanion(
          id: Value<String>(id),
          attachmentId: Value<String?>(attachmentId),
        ),
      ),
    ).then((Result<TranscriptRow> written) => written.map((_) {}));
  }

  @override
  Future<Result<TranscriptSummary>> complete(
    String id, {
    required Duration duration,
    required String languageTag,
    String? modelId,
  }) {
    return _finish(
      id,
      complete: true,
      duration: duration,
      languageTag: languageTag,
      modelId: modelId,
    );
  }

  @override
  Future<Result<TranscriptSummary>> markInterrupted(
    String id, {
    Duration? duration,
  }) {
    return _finish(id, complete: false, duration: duration);
  }

  @override
  Future<Result<String>> fileStandaloneAudio(
    String id,
    AudioRecording audio,
  ) async {
    return _inTransaction<String>(() async {
      final TranscriptRow row = (await _row(id)).getOrThrow();
      final String? linked = row.attachmentId;
      if (linked != null && await _attachment(linked) != null) {
        return linked;
      }
      final String folder = await _projectFolder(row.projectId);
      final String prefix = '${EvidencePurge.projectsFolder}/$folder/';
      if (folder.isEmpty || !audio.relativePath.startsWith(prefix)) {
        throw StorageFailure(
          localizedMessage: Copy.messages.failureTheFilePathMustStayInsideThe,
          localizedRecovery:
              Copy.messages.failureSaveTheFileUnderTheProjectFolder,
        );
      }
      final Attachment? same =
          await (_database.select(_database.attachments)..where(
                ($AttachmentsTable tbl) =>
                    tbl.projectId.equals(row.projectId) &
                    tbl.sha256.equals(audio.sha256),
              ))
              .getSingleOrNull();
      final String attachmentId =
          same?.id ??
          (await upsertAttachment(
            _database,
            row: AttachmentsCompanion(
              id: Value<String>(linked ?? _idService.newId()),
              projectId: Value<String>(row.projectId),
              relativePath: Value<String>(
                audio.relativePath.substring(prefix.length),
              ),
              mimeType: Value<String>(audio.mimeType),
              fileSize: Value<int>(audio.byteLength),
              sha256: Value<String>(audio.sha256),
              kind: const Value<AttachmentKind>(AttachmentKind.audio),
              durationMs: Value<int?>(audio.duration.inMilliseconds),
            ),
            clock: _time,
            deviceId: _device,
            ids: _idService,
          )).getOrThrow().id;
      (await linkAttachment(id, attachmentId)).getOrThrow();
      return attachmentId;
    });
  }

  @override
  Future<Result<void>> discard(String id) async {
    final Result<void> discarded = await _inTransaction<void>(() async {
      (await _row(id)).getOrThrow();
      await writeTombstone(
        _database,
        entityType: _entityType,
        entityId: id,
        reason: _discardedReason,
        clock: _time,
        deviceId: _device,
      );
    });
    _reopened.remove(id);
    return discarded;
  }

  @override
  Future<Result<TranscriptSummary>> rename(
    String id,
    String title, {
    String? operator,
  }) async {
    final Result<TranscriptRow> renamed = await _then(
      await _row(id),
      (_) => renameTranscript(
        _database,
        id: id,
        title: title,
        clock: _time,
        deviceId: _device,
        ids: _idService,
        operator: operator,
      ),
    );
    return _then(renamed, (_) => _summary(id));
  }

  @override
  Future<Result<Transcript>> saveEdit(
    String id,
    String text, {
    String? operator,
  }) async {
    final Result<Transcript?> current = await read(id);
    return _then(current, (Transcript? transcript) {
      final String? edit = transcript != null && text == transcript.rawText
          ? null
          : text;
      return _edit(id, edit, operator);
    });
  }

  @override
  Future<Result<Transcript>> clearEdit(String id, {String? operator}) =>
      _edit(id, null, operator);

  @override
  Future<Result<void>> reopenForRemaining(String id) async {
    final Result<TranscriptRow> row = await _row(id);
    return _then(row, (TranscriptRow value) async {
      final TranscriptStatus status = _statusOf(value.status);
      if (status == TranscriptStatus.live) {
        return const Success<void>(null);
      }
      final Result<TranscriptRow> reopened = await _update(
        TranscriptsCompanion(
          id: Value<String>(id),
          status: Value<String>(TranscriptStatus.live.name),
        ),
      );
      if (reopened is Success<TranscriptRow>) {
        _reopened[id] = status;
      }
      return reopened.map((_) {});
    });
  }

  @override
  Future<Result<Transcript?>> read(String id) async {
    try {
      final List<TranscriptSummary> found = await _summaries(
        't.id = ?',
        <Variable<Object>>[Variable<String>(id)],
      ).get().then(_toSummaries);
      if (found.isEmpty) {
        return const Success<Transcript?>(null);
      }
      final TranscriptRow row = (await _row(id)).getOrThrow();
      final List<TranscriptSegmentRow> segments =
          await (_database.select(_database.transcriptSegments)
                ..where(
                  ($TranscriptSegmentsTable tbl) => tbl.transcriptId.equals(id),
                )
                ..orderBy(<OrderClauseGenerator<$TranscriptSegmentsTable>>[
                  ($TranscriptSegmentsTable tbl) =>
                      OrderingTerm.asc(tbl.startMs),
                  ($TranscriptSegmentsTable tbl) => OrderingTerm.asc(tbl.seq),
                ]))
              .get();
      return Success<Transcript?>(
        Transcript(
          summary: found.single,
          lines: <TranscriptLine>[
            for (final TranscriptSegmentRow segment in segments)
              TranscriptLine(
                seq: segment.seq,
                start: Duration(milliseconds: segment.startMs),
                end: Duration(milliseconds: segment.endMs),
                text: segment.textRaw,
                confidence: segment.confidence,
              ),
          ],
          editedText: row.textEdited,
          editedAt: row.editedAt,
        ),
      );
    } on Failure catch (failure) {
      return FailureResult<Transcript?>(failure);
    } on Object catch (error) {
      return FailureResult<Transcript?>(storageFailureFrom(error));
    }
  }

  @override
  Stream<Transcript?> watch(String id) {
    return _database
        .customSelect(
          'SELECT id FROM transcripts WHERE id = ?',
          variables: <Variable<Object>>[Variable<String>(id)],
          readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
            _database.transcripts,
            _database.transcriptSegments,
            _database.tombstones,
          },
        )
        .watch()
        .asyncMap((_) async => (await read(id)).getOrThrow());
  }

  @override
  Stream<List<TranscriptSummary>> watchProject(
    String? projectId, {
    String query = '',
    int limit = AppConstants.listPageSize,
  }) {
    final String needle = query.trim();
    final List<String> where = <String>[
      if (projectId != null) 't.project_id = ?',
      if (needle.isNotEmpty)
        r"(t.title LIKE ? ESCAPE '\' OR t.text_edited LIKE ? ESCAPE '\' "
            'OR EXISTS (SELECT 1 FROM transcript_segments s '
            r"WHERE s.transcript_id = t.id AND s.text_raw LIKE ? ESCAPE '\'))",
    ];
    final String pattern = '%${_escapeLike(needle)}%';
    return _summaries(
      where.isEmpty ? '1' : where.join(' AND '),
      <Variable<Object>>[
        if (projectId != null) Variable<String>(projectId),
        if (needle.isNotEmpty) ...<Variable<Object>>[
          Variable<String>(pattern),
          Variable<String>(pattern),
          Variable<String>(pattern),
        ],
        Variable<int>(limit),
      ],
      limit: 'LIMIT ?',
    ).watch().map(_toSummaries);
  }

  @override
  Stream<List<TranscriptSummary>> watchRecord(String recordId) {
    return _summaries(
      'o.owner_id = ? AND ${_notDiscarded('attachment_owners', 'o.id')}',
      <Variable<Object>>[Variable<String>(recordId)],
      join:
          'JOIN attachment_owners o ON o.attachment_id = t.attachment_id '
          "AND o.owner_type = 'record'",
    ).watch().map(_toSummaries);
  }

  @override
  Stream<List<TranscriptSummary>> watchMeeting(String meetingId) {
    return _summaries('t.owner_kind = ? AND t.owner_id = ?', <Variable<Object>>[
      Variable<String>(TranscriptOwnerKind.meeting.name),
      Variable<String>(meetingId),
    ]).watch().map(_toSummaries);
  }

  @override
  Future<Result<TranscriptSummary?>> completedForAttachment(
    String attachmentId,
  ) {
    return _guard(() async {
      final List<TranscriptSummary> found = await _summaries(
        't.attachment_id = ? AND t.status = ?',
        <Variable<Object>>[
          Variable<String>(attachmentId),
          Variable<String>(TranscriptStatus.complete.name),
        ],
        limit: 'LIMIT 1',
      ).get().then(_toSummaries);
      return found.isEmpty ? null : found.single;
    });
  }

  @override
  Future<Result<List<TranscriptSummary>>> stale() {
    return _guard(() {
      return _summaries('t.status = ?', <Variable<Object>>[
        Variable<String>(TranscriptStatus.live.name),
      ]).get().then(_toSummaries);
    });
  }

  /// Ends live transcript [id] as [complete] or interrupted. A reopened
  /// transcript that did not complete returns to the status it had; one
  /// already ended the same way is left as it is. [coveredMs] moves the
  /// covered point forward when the session accounted for more audio.
  Future<Result<TranscriptSummary>> _finish(
    String id, {
    required bool complete,
    Duration? duration,
    String? languageTag,
    String? modelId,
    int? coveredMs,
  }) async {
    final Result<TranscriptRow> finished = await _inTransaction<TranscriptRow>(
      () async {
        final TranscriptRow row = (await _row(id)).getOrThrow();
        final TranscriptStatus status = _statusOf(row.status);
        final TranscriptStatus target = complete
            ? TranscriptStatus.complete
            : _reopened[id] ?? TranscriptStatus.interrupted;
        if (status != TranscriptStatus.live) {
          if (status == target &&
              (duration == null || row.durationMs == duration.inMilliseconds) &&
              (languageTag == null || row.languageTag == languageTag) &&
              (modelId == null || row.modelId == modelId)) {
            return row;
          }
          throw StorageFailure(
            localizedMessage: Copy.messages.transcriptSaveFailed,
            localizedRecovery: Copy.messages.failureRefreshTheListAndTryAgain,
          );
        }
        final int? covered = coveredMs != null && coveredMs > row.coveredMs
            ? coveredMs
            : null;
        return (await _update(
          TranscriptsCompanion(
            id: Value<String>(id),
            status: Value<String>(target.name),
            endedAt: Value<DateTime?>(row.endedAt ?? _time.nowUtc()),
            durationMs: duration == null
                ? const Value<int?>.absent()
                : Value<int?>(duration.inMilliseconds),
            languageTag: languageTag == null
                ? const Value<String>.absent()
                : Value<String>(languageTag),
            modelId: modelId == null
                ? const Value<String>.absent()
                : Value<String>(modelId),
            coveredMs: covered == null
                ? const Value<int>.absent()
                : Value<int>(covered),
          ),
        )).getOrThrow();
      },
    );
    if (finished is Success<TranscriptRow>) {
      _reopened.remove(id);
    }
    return _then(finished, (_) => _summary(id));
  }

  Future<Result<Transcript>> _edit(
    String id,
    String? text,
    String? operator,
  ) async {
    final Result<TranscriptRow> written = await _then(
      await _row(id),
      (_) => writeTranscriptEdit(
        _database,
        id: id,
        text: text,
        clock: _time,
        deviceId: _device,
        ids: _idService,
        operator: operator,
      ),
    );
    return _then(written, (_) async {
      final Result<Transcript?> transcript = await read(id);
      return transcript.flatMap(
        (Transcript? value) => value == null
            ? FailureResult<Transcript>(_missingFailure())
            : Success<Transcript>(value),
      );
    });
  }

  Future<Result<TranscriptRow>> _update(TranscriptsCompanion row) {
    return updateTranscript(
      _database,
      row: row,
      clock: _time,
      deviceId: _device,
      ids: _idService,
    );
  }

  /// Transcript [id]'s row when it exists and is not discarded.
  Future<Result<TranscriptRow>> _row(String id) {
    return _guard(() async {
      final TranscriptRow? row =
          await (_database.select(_database.transcripts)..where(
                ($TranscriptsTable tbl) =>
                    tbl.id.equals(id) &
                    notExistsQuery(
                      _database.select(_database.tombstones)..where(
                        ($TombstonesTable x) =>
                            x.entityType.equals(_entityType) &
                            x.entityId.equals(id),
                      ),
                    ),
              ))
              .getSingleOrNull();
      return row ?? (throw _missingFailure());
    });
  }

  Future<Result<TranscriptRow>> _live(String id) async {
    final Result<TranscriptRow> row = await _row(id);
    if (row case Success<TranscriptRow>(
      :final TranscriptRow value,
    ) when value.status != TranscriptStatus.live.name) {
      return FailureResult<TranscriptRow>(
        StorageFailure(
          localizedMessage: Copy.messages.transcriptSaveFailed,
          localizedRecovery: Copy.messages.failureRefreshTheListAndTryAgain,
        ),
      );
    }
    return row;
  }

  Future<Result<TranscriptSummary>> _summary(String id) async {
    final Result<Transcript?> transcript = await read(id);
    return transcript.flatMap(
      (Transcript? value) => value == null
          ? FailureResult<TranscriptSummary>(_missingFailure())
          : Success<TranscriptSummary>(value.summary),
    );
  }

  Future<Attachment?> _attachment(String id) {
    return (_database.select(
      _database.attachments,
    )..where(($AttachmentsTable tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<String> _projectFolder(String projectId) async {
    final String? folder =
        await (_database.selectOnly(_database.projects)
              ..addColumns(<Expression<Object>>[_database.projects.folderName])
              ..where(_database.projects.id.equals(projectId)))
            .map((TypedResult row) => row.read(_database.projects.folderName))
            .getSingleOrNull();
    return folder?.trim() ?? '';
  }

  /// Transcript summaries matching [where] (over `transcripts t`, after
  /// [join]), newest first, discarded ones left out, each with its preview.
  Selectable<QueryRow> _summaries(
    String where,
    List<Variable<Object>> variables, {
    String join = '',
    String limit = '',
  }) {
    return _database.customSelect(
      'WITH page AS (SELECT t.* FROM transcripts t $join '
      'WHERE $where AND ${_notDiscarded(_entityType, 't.id')} '
      'ORDER BY t.started_at DESC, t.id DESC $limit) '
      'SELECT page.*, $_previewColumn AS $_previewName FROM page '
      'ORDER BY page.started_at DESC, page.id DESC',
      variables: variables,
      readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
        _database.transcripts,
        _database.transcriptSegments,
        _database.tombstones,
        if (join.isNotEmpty) _database.attachmentOwners,
      },
    );
  }

  List<TranscriptSummary> _toSummaries(List<QueryRow> rows) {
    return <TranscriptSummary>[
      for (final QueryRow row in rows)
        _summaryOf(
          _database.transcripts.map(row.data),
          row.read<String>(_previewName),
        ),
    ];
  }

  TranscriptSummary _summaryOf(TranscriptRow row, String preview) {
    final TranscriptOwnerKind? kind = TranscriptOwnerKind.values
        .asNameMap()[row.ownerKind];
    if (kind == null) {
      throw const CorruptionFailure();
    }
    final int? duration = row.durationMs;
    return TranscriptSummary(
      id: row.id,
      projectId: row.projectId,
      ownerKind: kind,
      ownerId: row.ownerId,
      attachmentId: row.attachmentId,
      audioPath: row.audioPath,
      title: row.title,
      status: _statusOf(row.status),
      startedAt: row.startedAt,
      endedAt: row.endedAt,
      duration: duration == null ? null : Duration(milliseconds: duration),
      languageTag: row.languageTag,
      modelId: row.modelId,
      coveredMs: row.coveredMs,
      gaps: <TranscriptGap>[
        for (final (int from, int to) in transcriptSkippedRanges(
          row.skippedRanges,
        ))
          TranscriptGap(
            start: Duration(milliseconds: from),
            end: Duration(milliseconds: to),
          ),
      ],
      preview: _previewOf(preview),
      edited: row.textEdited != null,
    );
  }

  /// Runs [body] in one transaction, joining the caller's.
  Future<Result<T>> _inTransaction<T>(Future<T> Function() body) async {
    final Result<T> written = await _guard(() => _database.transaction(body));
    return switch (written) {
      FailureResult<T>(:final Failure failure) => FailureResult<T>(
        transcriptWriteFailure(failure),
      ),
      Success<T>() => written,
    };
  }

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Success<T>(await body());
    } on Failure catch (failure) {
      return FailureResult<T>(failure);
    } on Object catch (error) {
      return FailureResult<T>(storageFailureFrom(error));
    }
  }
}

/// Writes a session's transcript through the repository that made it.
final class _RepositorySink implements TranscriptSink {
  _RepositorySink(this._repository, this._id);

  final TranscriptRepositoryImpl _repository;
  final String _id;

  @override
  Future<Result<void>> appendUtterance(FinishedUtterance utterance) {
    return _repository.appendUtterance(_id, utterance);
  }

  @override
  Future<Result<void>> finish(TranscriptOutcome outcome) async {
    final Result<TranscriptSummary> finished = await _repository._finish(
      _id,
      complete: outcome.complete,
      duration: outcome.captured,
      languageTag: outcome.languageTag,
      modelId: outcome.modelId,
      coveredMs: transcriptMillisecondOf(outcome.coveredToSample),
    );
    return finished.map((_) {});
  }
}

const String _entityType = 'transcripts';
const String _discardedReason = 'discarded';
const String _previewName = 'preview';

/// The edit, else the raw text of the first segments in reading order:
/// enough of them for a preview, since each holds at least one character.
final String _previewColumn =
    'COALESCE(page.text_edited, (SELECT group_concat(x.text_raw, \' \') '
    'FROM (SELECT s.text_raw FROM transcript_segments s '
    'WHERE s.transcript_id = page.id ORDER BY s.start_ms, s.seq '
    'LIMIT ${AppConstants.transcripts.previewChars}) x), \'\')';

String _notDiscarded(String entityType, String id) =>
    'NOT EXISTS (SELECT 1 FROM tombstones x '
    "WHERE x.entity_type = '$entityType' AND x.entity_id = $id)";

/// [text] on one line, cut to `AppConstants.transcripts.previewChars`.
String _previewOf(String text) {
  final String flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  final int chars = AppConstants.transcripts.previewChars;
  return flat.length <= chars ? flat : flat.substring(0, chars);
}

/// [query] with `\`, `%` and `_` escaped for `LIKE … ESCAPE '\'`.
String _escapeLike(String query) =>
    query.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

TranscriptStatus _statusOf(String stored) {
  final TranscriptStatus? status = TranscriptStatus.values.asNameMap()[stored];
  if (status == null) {
    throw const CorruptionFailure();
  }
  return status;
}

StorageFailure _missingFailure() => StorageFailure(
  localizedMessage: Copy.messages.failureThatRowIsNoLongerOnThis,
  localizedRecovery: Copy.messages.failureRefreshTheListAndTryAgain,
);

/// [first] when it failed, else what [next] makes of its value.
Future<Result<R>> _then<T, R>(
  Result<T> first,
  Future<Result<R>> Function(T value) next,
) async {
  if (first case Success<T>(:final T value)) {
    return next(value);
  }
  return FailureResult<R>((first as FailureResult<T>).failure);
}
