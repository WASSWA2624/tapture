import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

part 'transcript_segments.dart';

/// One transcript header: who owns it, which audio it was heard from, how
/// far the audio is accounted for, and the edit written beside its raw
/// segments (spec §30.4.6).
///
/// [projectId], [ownerKind], [audioPath] and [startedAt] are written once
/// at insert; [attachmentId] is set once. [title] and [textEdited] change
/// only through [renameTranscript] and [writeTranscriptEdit], which audit
/// them. The raw text lives in [TranscriptSegments] and is never updated.
@TableIndex(name: 'transcripts_by_project', columns: {#projectId, #startedAt})
@TableIndex(name: 'transcripts_by_attachment', columns: {#attachmentId})
@TableIndex(name: 'transcripts_by_owner', columns: {#ownerKind, #ownerId})
@DataClassName('TranscriptRow')
class Transcripts extends Table with MergeColumns {
  /// Project the transcript belongs to. Written once.
  TextColumn get projectId => text()();

  /// `capture`, `meeting` or `standalone`. Written once.
  TextColumn get ownerKind => text()();

  /// The meeting id for a meeting transcript; null otherwise.
  TextColumn get ownerId => text().nullable()();

  /// The audio attachment the transcript was heard from. Set once.
  TextColumn get attachmentId => text().nullable()();

  /// Storage-root-relative path of the take's `.wav`. Written once.
  TextColumn get audioPath => text()();

  /// Operator-facing title, stored as data. Audited on rename.
  TextColumn get title => text().withDefault(const Constant(''))();

  /// BCP 47 tag: requested at begin, the one used at completion.
  TextColumn get languageTag => text()();

  /// Catalogue id of the model that decoded it; empty before one loaded.
  TextColumn get modelId => text()();

  /// `live`, `complete` or `interrupted`.
  TextColumn get status => text()();

  /// When recording started. Written once.
  DateTimeColumn get startedAt => dateTime()();

  /// When the transcript finished, complete or interrupted.
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// How much audio the recording holds, in milliseconds.
  IntColumn get durationMs => integer().nullable()();

  /// The highest point of the audio processed, decoded or skipped, in
  /// milliseconds.
  IntColumn get coveredMs => integer().withDefault(const Constant(0))();

  /// JSON `[[fromMs, toMs], …]` of utterances left untranscribed.
  TextColumn get skippedRanges => text().withDefault(const Constant('[]'))();

  /// The operator's edit, written beside the raw segments, never over them.
  TextColumn get textEdited => text().nullable()();

  /// When the edit was last written or cleared.
  DateTimeColumn get editedAt => dateTime().nullable()();
}

/// The stored [Transcripts.status] of a transcript still being recorded or
/// finished. Search and edits treat it as unsettled.
const String transcriptLiveStatus = 'live';

/// The columns [updateTranscript] never writes: the write-once header and
/// the audited columns, which have their own helpers.
const Set<String> _protectedColumns = <String>{
  'project_id',
  'owner_kind',
  'audio_path',
  'started_at',
  'created_at',
  'title',
  'text_edited',
  'edited_at',
};

/// Inserts a new transcript header. A row with the same id already stored
/// is refused, so a header is never written over.
Future<Result<TranscriptRow>> insertTranscript(
  GeneratedDatabase db, {
  required Insertable<TranscriptRow> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) {
  return _guarded(db, () async {
    final _TranscriptsDao dao = _dao(db, clock, deviceId, ids);
    final String? id = _idOf(row);
    if (id != null && await _load(dao, id) != null) {
      throw StorageFailure(
        localizedMessage:
            Copy.messages.failureARecordWithThatIdentityAlreadyExists,
        localizedRecovery:
            Copy.messages.failureOpenTheExistingRecordOrChangeThe,
      );
    }
    return dao.upsert(row).then(_unwrap);
  });
}

/// Updates transcript [row] (which names its id). The write-once header
/// and the audited title and edit are dropped from the write; an
/// attachment already linked is never replaced by a different one.
Future<Result<TranscriptRow>> updateTranscript(
  GeneratedDatabase db, {
  required Insertable<TranscriptRow> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) {
  return _guarded(db, () async {
    final _TranscriptsDao dao = _dao(db, clock, deviceId, ids);
    final TranscriptRow existing = await _required(dao, _idOf(row));
    final Map<String, Expression<Object>> columns =
        Map<String, Expression<Object>>.of(row.toColumns(false))
          ..removeWhere((String name, _) => _protectedColumns.contains(name));
    final Expression<Object>? attachment = columns['attachment_id'];
    if (attachment is Variable<Object>) {
      final Object? next = attachment.value;
      if (existing.attachmentId != null && next != existing.attachmentId) {
        throw ValidationFailure(
          localizedMessage: Copy.messages.transcriptSaveFailed,
          localizedRecovery: Copy.messages.failureRefreshTheListAndTryAgain,
        );
      }
    }
    return dao.upsert(RawValuesInsertable<TranscriptRow>(columns)).then(_unwrap);
  });
}

/// Durably appends one utterance of transcript [transcriptId], in one
/// transaction: its [segments], how far the audio is now covered, and its
/// range when it was [skipped].
///
/// Segments are insert-only and contiguous: a `seq` one past the stored
/// count is inserted; a `seq` already stored with the same text is ignored,
/// so a retried write is harmless; any other `seq`, or a different text,
/// fails with `StorageFailure` and writes nothing. A [skipped] utterance
/// adds `[fromMs, toMs]` to the skipped ranges; a transcribed utterance
/// removes a range it lies inside or covers. The covered point only moves
/// forward. Segment inserts rebuild no search document.
Future<Result<TranscriptRow>> appendTranscriptUtterance(
  GeneratedDatabase db, {
  required String transcriptId,
  required int fromMs,
  required int toMs,
  required bool skipped,
  required List<
    ({int seq, int startMs, int endMs, String text, double? confidence})
  >
  segments,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) {
  return _guarded(db, () async {
    final AppDatabase database = db as AppDatabase;
    final _TranscriptsDao dao = _dao(db, clock, deviceId, ids);
    final TranscriptRow existing = await _required(dao, transcriptId);
    if (existing.status != transcriptLiveStatus) {
      throw StorageFailure(
        localizedMessage: Copy.messages.transcriptSaveFailed,
        localizedRecovery: Copy.messages.failureRefreshTheListAndTryAgain,
      );
    }
    int count = await _segmentCount(database, transcriptId);
    for (final ({
          int seq,
          int startMs,
          int endMs,
          String text,
          double? confidence,
        })
        segment
        in segments) {
      if (segment.seq == count + 1) {
        await _insertSegment(
          database,
          transcriptId: transcriptId,
          segment: segment,
          now: clock.nowUtc(),
          deviceId: deviceId,
          ids: ids,
        );
        count = segment.seq;
        continue;
      }
      if (segment.seq < 1 ||
          segment.seq > count ||
          await _storedText(database, transcriptId, segment.seq) !=
              segment.text) {
        throw StorageFailure(
          localizedMessage: Copy.messages.transcriptSegmentOutOfOrder,
          localizedRecovery: Copy.messages.failureTryAgain,
        );
      }
    }
    final List<(int, int)> ranges = transcriptSkippedRanges(
      existing.skippedRanges,
    );
    final List<(int, int)> next = skipped
        ? _withRange(ranges, (fromMs, toMs))
        : _withoutFilled(ranges, (fromMs, toMs));
    final int covered = toMs > existing.coveredMs ? toMs : existing.coveredMs;
    final String encoded = encodeTranscriptRanges(next);
    if (covered == existing.coveredMs && encoded == existing.skippedRanges) {
      return existing;
    }
    return dao
        .upsert(
          TranscriptsCompanion(
            id: Value<String>(transcriptId),
            coveredMs: Value<int>(covered),
            skippedRanges: Value<String>(encoded),
          ),
        )
        .then(_unwrap);
  });
}

/// Writes the operator's edit of transcript [id] beside its raw segments,
/// or clears it when [text] is null, with one audit row (field
/// `transcript`). A transcript still being recorded refuses an edit with
/// `ValidationFailure`. The raw segments are never touched.
Future<Result<TranscriptRow>> writeTranscriptEdit(
  GeneratedDatabase db, {
  required String id,
  required String? text,
  required Clock clock,
  required String deviceId,
  required IdService ids,
  String? operator,
}) {
  return _guarded(db, () async {
    final _TranscriptsDao dao = _dao(db, clock, deviceId, ids);
    final TranscriptRow existing = await _required(dao, id);
    if (existing.status == transcriptLiveStatus) {
      throw ValidationFailure(
        localizedMessage: Copy.messages.transcriptStillRecording,
        localizedRecovery: Copy.messages.failureWaitAMomentThenTryTheSave,
      );
    }
    final TranscriptRow written = _unwrap(
      await dao.upsert(
        RawValuesInsertable<TranscriptRow>(<String, Expression<Object>>{
          'id': Variable<String>(id),
          'text_edited': Variable<String>(text),
          'edited_at': Variable<DateTime>(clock.nowUtc()),
        }),
      ),
    );
    await appendAudit(
      db,
      entityType: _entityType,
      entityId: id,
      action: AuditAction.updated,
      fieldKey: 'transcript',
      previousValue: existing.textEdited,
      newValue: text,
      clock: clock,
      device: deviceId,
      operator: operator,
    );
    return written;
  });
}

/// Renames transcript [id] to [title] with one audit row (field `title`).
Future<Result<TranscriptRow>> renameTranscript(
  GeneratedDatabase db, {
  required String id,
  required String title,
  required Clock clock,
  required String deviceId,
  required IdService ids,
  String? operator,
}) {
  return _guarded(db, () async {
    final _TranscriptsDao dao = _dao(db, clock, deviceId, ids);
    final TranscriptRow existing = await _required(dao, id);
    final TranscriptRow written = _unwrap(
      await dao.upsert(
        TranscriptsCompanion(id: Value<String>(id), title: Value<String>(title)),
      ),
    );
    await appendAudit(
      db,
      entityType: _entityType,
      entityId: id,
      action: AuditAction.updated,
      fieldKey: 'title',
      previousValue: existing.title,
      newValue: title,
      clock: clock,
      device: deviceId,
      operator: operator,
    );
    return written;
  });
}

/// The `[fromMs, toMs]` ranges stored in [Transcripts.skippedRanges], in
/// order. An entry that is not a pair of whole numbers is skipped.
List<(int, int)> transcriptSkippedRanges(String stored) {
  final Object? decoded;
  try {
    decoded = jsonDecode(stored);
  } on FormatException {
    return const <(int, int)>[];
  }
  if (decoded is! List<Object?>) {
    return const <(int, int)>[];
  }
  return <(int, int)>[
    for (final Object? entry in decoded)
      if (entry is List<Object?> &&
          entry.length == 2 &&
          entry[0] is int &&
          entry[1] is int)
        (entry[0]! as int, entry[1]! as int),
  ]..sort(((int, int) a, (int, int) b) => a.$1.compareTo(b.$1));
}

/// [ranges] in the stored [Transcripts.skippedRanges] form.
String encodeTranscriptRanges(List<(int, int)> ranges) => jsonEncode(<
  List<int>
>[
  for (final (int from, int to) in ranges) <int>[from, to],
]);

/// The millisecond on the session timeline that [sample] falls in.
int transcriptMillisecondOf(int sample) =>
    sample * Duration.millisecondsPerSecond ~/ AppConstants.audio.sampleRate;

const String _entityType = 'transcripts';

List<(int, int)> _withRange(List<(int, int)> ranges, (int, int) range) {
  if (range.$2 <= range.$1 || ranges.contains(range)) {
    return ranges;
  }
  return <(int, int)>[...ranges, range]
    ..sort(((int, int) a, (int, int) b) => a.$1.compareTo(b.$1));
}

List<(int, int)> _withoutFilled(List<(int, int)> ranges, (int, int) filled) {
  return <(int, int)>[
    for (final (int, int) range in ranges)
      if (!_inside(filled, range) && !_inside(range, filled)) range,
  ];
}

/// Whether [inner] lies within [outer].
bool _inside((int, int) inner, (int, int) outer) =>
    inner.$1 >= outer.$1 && inner.$2 <= outer.$2;

Future<int> _segmentCount(AppDatabase db, String transcriptId) async {
  final QueryRow row = await db
      .customSelect(
        'SELECT COALESCE(MAX(seq), 0) AS n FROM transcript_segments '
        'WHERE transcript_id = ?',
        variables: <Variable<Object>>[Variable<String>(transcriptId)],
        readsFrom: <ResultSetImplementation<dynamic, dynamic>>{
          db.transcriptSegments,
        },
      )
      .getSingle();
  return row.read<int>('n');
}

Future<String?> _storedText(AppDatabase db, String transcriptId, int seq) {
  return (db.selectOnly(db.transcriptSegments)
        ..addColumns(<Expression<Object>>[db.transcriptSegments.textRaw])
        ..where(
          db.transcriptSegments.transcriptId.equals(transcriptId) &
              db.transcriptSegments.seq.equals(seq),
        ))
      .map((TypedResult row) => row.read(db.transcriptSegments.textRaw))
      .getSingleOrNull();
}

Future<TranscriptRow?> _load(_TranscriptsDao dao, String id) async =>
    _unwrap(await dao.getById(id));

Future<TranscriptRow> _required(_TranscriptsDao dao, String? id) async {
  final TranscriptRow? row = id == null ? null : await _load(dao, id);
  if (row == null) {
    throw StorageFailure(
      localizedMessage: Copy.messages.failureThatRowIsNoLongerOnThis,
      localizedRecovery: Copy.messages.failureRefreshTheListAndTryAgain,
    );
  }
  return row;
}

/// Runs [body] in one transaction (joining the caller's). A [Failure] is
/// returned as it is; any other error becomes `transcriptSaveFailed` with
/// the recovery its cause calls for.
Future<Result<T>> _guarded<T>(
  GeneratedDatabase db,
  Future<T> Function() body,
) async {
  try {
    return Success<T>(await db.transaction(body));
  } on Failure catch (failure) {
    return FailureResult<T>(failure);
  } on Object catch (error) {
    return FailureResult<T>(
      StorageFailure(
        localizedMessage: Copy.messages.transcriptSaveFailed,
        localizedRecovery: storageFailureFrom(error).localizedRecovery,
      ),
    );
  }
}

T _unwrap<T>(Result<T> result) => result.getOrThrow();

String? _idOf(Insertable<TranscriptRow> row) {
  final Expression<Object>? expression = row.toColumns(false)['id'];
  if (expression is Variable<String>) {
    return expression.value;
  }
  return null;
}

_TranscriptsDao _dao(
  GeneratedDatabase db,
  Clock clock,
  String deviceId,
  IdService ids,
) => _TranscriptsDao(
  db as AppDatabase,
  clock: clock,
  deviceId: deviceId,
  ids: ids,
);

final class _TranscriptsDao extends BaseDao<Transcripts, TranscriptRow> {
  _TranscriptsDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.transcripts);
}
