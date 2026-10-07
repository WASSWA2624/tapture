import 'dart:convert';
import 'dart:io' show File;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/database_provider.dart';
import 'package:tapture/core/db/tables/attachment_owners.dart';
import 'package:tapture/core/db/tables/attachments.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/meetings.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/db/tables/transcripts.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/path_sanitizer.dart';
import 'package:tapture/core/files/picked_document.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/speech/speech_text.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/action_entry.dart';
import '../domain/attendee.dart';
import '../domain/meeting.dart';
import '../domain/meeting_attachment.dart';
import '../domain/meeting_repository.dart';
import '../domain/meeting_transcription.dart';

/// Writes a meeting through the meeting, attendee, action and attachment
/// tables, and keeps its files in the project folder.
final class MeetingRepositoryImpl implements MeetingRepository {
  /// Creates a store over [db]. Files go through [writer] and [reader]
  /// under [storageRoot]; each defaults to the platform's own.
  MeetingRepositoryImpl({
    required AppDatabase db,
    required Clock clock,
    required String deviceId,
    required IdService ids,
    this._operatorName,
    StorageRoot? storageRoot,
    FileWriter? writer,
    FileReader? reader,
    bool isBrowser = kIsWeb,
  }) : _database = db,
       _time = clock,
       _device = deviceId,
       _idService = ids,
       _root = storageRoot ?? StorageRoot(),
       _writerOverride = writer,
       _readerOverride = reader,
       _browser = isBrowser;

  final AppDatabase _database;
  final Clock _time;
  final String _device;
  final IdService _idService;
  final String Function()? _operatorName;
  final StorageRoot _root;
  final FileWriter? _writerOverride;
  final FileReader? _readerOverride;
  final bool _browser;

  FileWriter get _writer => _writerOverride ?? FileWriter(storageRoot: _root);

  FileReader get _reader => _readerOverride ?? FileReader(storageRoot: _root);

  @override
  Future<Result<MeetingRecord>> save(
    Meeting meeting, {
    required String recordId,
    String? templateId,
    String notes = '',
    String transcript = '',
    String minutes = '',
  }) async {
    final Result<String> written = await runInTransaction<String>(
      _database,
      () => _write(
        meeting,
        recordId: recordId,
        templateId: templateId,
        notes: notes,
        transcript: transcript,
        minutes: minutes,
      ),
    );
    return switch (written) {
      FailureResult<String>(:final Failure failure) =>
        FailureResult<MeetingRecord>(failure),
      Success<String>(:final String value) => _required(await read(value)),
    };
  }

  Future<String> _write(
    Meeting meeting, {
    required String recordId,
    required String? templateId,
    required String notes,
    required String transcript,
    required String minutes,
  }) async {
    final MeetingRow? existing = meeting.id.isEmpty
        ? null
        : await _row(meeting.id);
    final Map<String, Object?> previous = existing == null
        ? const <String, Object?>{}
        : _documentOf(existing) ?? const <String, Object?>{};
    final String previousNotes = previous['notes'] as String? ?? '';
    final String id = meeting.id.isEmpty ? _idService.newId() : meeting.id;
    // Rows keep one id from their first save, so a later save updates them.
    final Meeting stored = meeting.copyWith(
      id: id,
      recordId: recordId,
      attendees: <Attendee>[
        for (final Attendee person in meeting.attendees)
          person.id.isEmpty
              ? Attendee.fromJson(<String, Object?>{
                  ...person.toJson(),
                  'id': _idService.newId(),
                })
              : person,
      ],
      actions: <ActionEntry>[
        for (final ActionEntry action in meeting.actions)
          action.id.isEmpty
              ? ActionEntry.fromJson(<String, Object?>{
                  ...action.toJson(),
                  'id': _idService.newId(),
                })
              : action,
      ],
    );
    if (existing == null) {
      _unwrap(
        await upsertRecord(
          _database,
          row: RecordsCompanion(
            id: Value<String>(recordId),
            projectId: Value<String>(stored.projectId),
            // A caller that installed no template keeps the shipped key.
            templateId: Value<String>(templateId ?? Meeting.templateKey),
            status: const Value<String>('needsReview'),
            processingMode: const Value<String>('manual'),
            contextJson: Value<String>(
              jsonEncode(<String, String>{'location': stored.location ?? ''}),
            ),
            identityHash: Value<String>(id),
            source: const Value<String>('capture'),
            capturedAt: Value<DateTime>(stored.startedAt.toUtc()),
            capturedBy: Value<String>(stored.secretary ?? ''),
          ),
          clock: _time,
          deviceId: _device,
          ids: _idService,
        ),
      );
    }
    _unwrap(
      await insertMeeting(
        _database,
        row: MeetingsCompanion(
          transcriptRaw: existing != null
              ? const Value<String>.absent()
              : Value<String>(transcript),
          id: Value<String>(id),
          recordId: Value<String>(recordId),
          title: Value<String>(stored.title),
          startAt: Value<DateTime>(stored.startedAt.toUtc()),
          endAt: stored.endedAt == null
              ? const Value<DateTime>.absent()
              : Value<DateTime>(stored.endedAt!.toUtc()),
          secretary: Value<String>(stored.secretary ?? ''),
          agenda: Value<String>(
            _document(
              stored,
              previous: previous,
              originalNotes: existing == null
                  ? notes
                  : previous['originalNotes'] as String? ?? previousNotes,
              notes: notes,
              minutes: minutes,
              transcripts: existing == null
                  ? const <TranscriptVersion>[]
                  : _versionsOf(existing),
            ),
          ),
          minutesRefined: Value<String>(minutes),
        ),
        clock: _time,
        deviceId: _device,
        ids: _idService,
      ),
    );
    await _auditText(
      id,
      'notes',
      existing == null ? null : previousNotes,
      notes,
    );
    await _auditText(
      id,
      'minutes',
      existing == null ? null : existing.minutesRefined ?? '',
      minutes,
    );
    await _writeAttendees(id, stored.attendees);
    await _writeActions(id, stored.actions);
    return id;
  }

  Future<void> _auditText(
    String id,
    String field,
    String? previous,
    String next,
  ) async {
    if (previous == next) {
      return;
    }
    final String operator =
        _operatorName?.call() ??
        (await _database.select(_database.deviceProfile).getSingleOrNull())
            ?.operatorName ??
        '';
    await appendAudit(
      _database,
      entityType: _meetingsEntity,
      entityId: id,
      action: previous == null ? AuditAction.created : AuditAction.updated,
      fieldKey: field,
      previousValue: previous,
      newValue: next,
      clock: _time,
      device: _device,
      operator: operator.trim(),
    );
  }

  /// Every attendee row, and a tombstone for each one removed since.
  Future<void> _writeAttendees(String meetingId, List<Attendee> people) async {
    final Set<String> kept = <String>{};
    for (final Attendee person in people) {
      final MeetingAttendee row = _unwrap(
        await upsertMeetingAttendee(
          _database,
          row: AttendeesCompanion(
            id: Value<String>(person.id),
            meetingId: Value<String>(meetingId),
            name: Value<String>(person.name),
            title: Value<String>(person.title),
            organisation: Value<String>(person.organisation),
            contact: Value<String>(person.contact),
            signaturePresent: Value<bool>(person.signaturePresent),
            matchedStaffId: Value<String?>(person.staffId),
          ),
          clock: _time,
          deviceId: _device,
          ids: _idService,
        ),
      );
      kept.add(row.id);
    }
    final List<MeetingAttendee> rows = await (_database.select(
      _database.attendees,
    )..where(($AttendeesTable tbl) => tbl.meetingId.equals(meetingId))).get();
    await _tombstone(_attendeesEntity, <String>[
      for (final MeetingAttendee row in rows)
        if (!kept.contains(row.id)) row.id,
    ]);
  }

  /// Every action on the register, dated or not, and a tombstone for each
  /// one removed since.
  Future<void> _writeActions(String meetingId, List<ActionEntry> items) async {
    final Set<String> kept = <String>{};
    for (final ActionEntry action in items) {
      final MeetingAction row = _unwrap(
        await upsertMeetingAction(
          _database,
          row: MeetingActionsCompanion(
            id: Value<String>(action.id),
            meetingId: Value<String>(meetingId),
            action: Value<String>(action.text),
            ownerName: Value<String>(action.ownerName),
            dueDate: Value<DateTime?>(action.due?.toUtc()),
            status: Value<String>(action.status.name),
          ),
          clock: _time,
          deviceId: _device,
          ids: _idService,
        ),
      );
      kept.add(row.id);
    }
    final List<MeetingAction> rows =
        await (_database.select(_database.meetingActions)..where(
              ($MeetingActionsTable tbl) => tbl.meetingId.equals(meetingId),
            ))
            .get();
    await _tombstone(_actionsEntity, <String>[
      for (final MeetingAction row in rows)
        if (!kept.contains(row.id)) row.id,
    ]);
  }

  Future<void> _tombstone(String entityType, List<String> ids) async {
    for (final String id in ids) {
      await writeTombstone(
        _database,
        entityType: entityType,
        entityId: id,
        reason: _removedReason,
        clock: _time,
        deviceId: _device,
      );
    }
  }

  /// The meeting [id]. Its transcript is the one source Refine minutes and
  /// the minutes export read: an imported raw transcript when there is
  /// one, otherwise the latest settled on-device transcript, otherwise the
  /// last online transcription run.
  @override
  Future<Result<MeetingRecord?>> read(String id) async {
    try {
      final MeetingRow? row = await _row(id);
      if (row == null) {
        return const Success<MeetingRecord?>(null);
      }
      final Map<String, Object?>? document = _documentOf(row);
      final Object? body = document?['meeting'];
      if (document == null || body is! Map) {
        return const Success<MeetingRecord?>(null);
      }
      final List<MeetingAttachment> files = await _attachments(row.recordId);
      final List<TranscriptVersion> versions = _versionsOf(row);
      final Meeting meeting = Meeting.fromJson(Map<String, Object?>.from(body))
          .copyWith(
            attachmentIds: <String>[
              for (final MeetingAttachment file in files) file.id,
            ],
          );
      return Success<MeetingRecord?>((
        meeting: meeting,
        originalNotes:
            document['originalNotes'] as String? ??
            document['notes'] as String? ??
            '',
        notes: document['notes'] as String? ?? '',
        minutes: row.minutesRefined ?? '',
        transcript: row.transcriptRaw.isNotEmpty
            ? row.transcriptRaw
            : await _heardTranscript(row.id) ??
                  (versions.isEmpty ? '' : versions.last.text),
        transcripts: versions,
        attachments: files,
      ));
    } on Failure catch (failure) {
      return FailureResult<MeetingRecord?>(failure);
    } on Object catch (error) {
      return FailureResult<MeetingRecord?>(Failure.from(error));
    }
  }

  @override
  Future<Result<String?>> meetingOfRecord(String recordId) {
    return _guard<String?>(() async {
      final MeetingRow? row =
          await (_database.select(_database.meetings)
                ..where(($MeetingsTable tbl) => tbl.recordId.equals(recordId))
                ..limit(1))
              .getSingleOrNull();
      if (row == null || await _isTombstoned(_meetingsEntity, row.id)) {
        return null;
      }
      return row.id;
    });
  }

  @override
  Future<Result<String>> storagePathFor(String meetingId, String name) {
    return _guard<String>(() async {
      final _Owner owner = await _owner(meetingId);
      return _storagePath(owner, name);
    });
  }

  @override
  Future<Result<MeetingAttachment>> attachFile(
    String meetingId, {
    required String name,
    required String mimeType,
    required Uint8List bytes,
  }) {
    return _guard<MeetingAttachment>(() async {
      final _Owner owner = await _owner(meetingId);
      final WrittenFile file = _unwrap(
        await _writer.write(
          Stream<List<int>>.value(bytes),
          _storagePath(owner, name),
        ),
      );
      return _link(
        owner,
        storagePath: file.relativePath,
        mimeType: mimeType,
        bytes: file.byteLength,
        sha256: file.sha256,
      );
    });
  }

  @override
  Future<Result<MeetingAttachment>> attachDocument(
    String meetingId,
    PickedDocument document,
  ) {
    return _guard<MeetingAttachment>(() async {
      final _Owner owner = await _owner(meetingId);
      final String path = _storagePath(owner, document.name);
      final WrittenFile file = switch (document) {
        PickedBytes(:final Uint8List bytes) => _unwrap(
          await _writer.write(Stream<List<int>>.value(bytes), path),
        ),
        PickedFile(:final File file, :final bool isCopy) => await () async {
          final Result<WrittenFile> copied = await _writer.copyIn(file, path);
          if (isCopy) {
            await discardUnpublishedFile(file);
          }
          return _unwrap(copied);
        }(),
      };
      return _link(
        owner,
        storagePath: file.relativePath,
        mimeType: _mimeOf(document.name),
        bytes: file.byteLength,
        sha256: file.sha256,
      );
    });
  }

  @override
  Future<Result<MeetingAttachment>> attachStored(
    String meetingId, {
    required String storagePath,
    required String mimeType,
    required int bytes,
    required String sha256,
    Duration? duration,
  }) {
    return _guard<MeetingAttachment>(() async {
      return _link(
        await _owner(meetingId),
        storagePath: storagePath,
        mimeType: mimeType,
        bytes: bytes,
        sha256: sha256,
        duration: duration,
      );
    });
  }

  @override
  Future<Result<Uint8List>> readFile(String meetingId, MeetingAttachment file) {
    return _guard<Uint8List>(() async {
      final _Owner owner = await _owner(meetingId);
      return _unwrap(await _reader.read(owner.pathOf(file.relativePath)));
    });
  }

  @override
  Future<Result<String>> servicePath(String meetingId, MeetingAttachment file) {
    return _guard<String>(() async {
      final _Owner owner = await _owner(meetingId);
      return _servicePath(owner.pathOf(file.relativePath));
    });
  }

  @override
  Future<Result<List<TranscriptVersion>>> transcribe(
    String meetingId,
    MeetingAttachment file, {
    required Future<Result<String>> Function(String clipPath) transcribeChunk,
    void Function(int done, int total)? onProgress,
  }) {
    return _guard<List<TranscriptVersion>>(() async {
      final _Owner owner = await _owner(meetingId);
      final Uint8List recording = _unwrap(
        await _reader.read(owner.pathOf(file.relativePath)),
      );
      final List<Uint8List> clips = MeetingTranscription.split(recording);
      final List<TranscriptChunk> chunks = <TranscriptChunk>[];
      for (int index = 0; index < clips.length; index++) {
        final Result<WrittenFile> staged = await _writer.write(
          Stream<List<int>>.value(clips[index]),
          '$_cacheFolder/$meetingId/${file.id}_$index.wav',
        );
        final Result<String> heard = switch (staged) {
          FailureResult<WrittenFile>(:final Failure failure) =>
            FailureResult<String>(failure),
          Success<WrittenFile>(:final WrittenFile value) =>
            await transcribeChunk(await _servicePath(value.relativePath)),
        };
        chunks.add(switch (heard) {
          Success<String>(:final String value) => (
            index: index,
            text: value.trim(),
            failed: false,
          ),
          FailureResult<String>() => (index: index, text: '', failed: true),
        });
        onProgress?.call(index + 1, clips.length);
      }
      return _unwrap(
        await runInTransaction<List<TranscriptVersion>>(_database, () async {
          // Transcription can finish after edits or another transcription run.
          // Patch its field against the latest document inside the final write.
          final MeetingRow? row = await _row(meetingId);
          if (row == null) {
            throw _missingFailure;
          }
          final Map<String, Object?> document =
              _documentOf(row) ?? <String, Object?>{};
          document.putIfAbsent(
            'originalNotes',
            () => document['notes'] as String? ?? '',
          );
          final List<TranscriptVersion> versions = MeetingTranscription.fold(
            existing: _versionsOf(row),
            chunks: chunks,
          );
          document[_transcriptsKey] = MeetingTranscription.toJson(versions);
          _unwrap(
            await insertMeeting(
              _database,
              row: MeetingsCompanion(
                id: Value<String>(row.id),
                agenda: Value<String>(jsonEncode(<Object?>[document])),
              ),
              clock: _time,
              deviceId: _device,
              ids: _idService,
            ),
          );
          return versions;
        }),
      );
    });
  }

  /// Hangs the file at [storagePath] on [owner]'s record. The same file
  /// attached twice is linked once.
  Future<MeetingAttachment> _link(
    _Owner owner, {
    required String storagePath,
    required String mimeType,
    required int bytes,
    required String sha256,
    Duration? duration,
  }) async {
    final String prefix = owner.pathOf('');
    if (!storagePath.startsWith(prefix)) {
      throw StorageFailure(
        localizedMessage: Copy.messages.failureThatFileIsNotInThisMeeting,
        localizedRecovery: Copy.messages.failureAddTheFileToTheMeetingAgain,
      );
    }
    final String id = _idService.newId();
    final String hash = sha256.isEmpty ? '$_unhashed$id' : sha256;
    final Attachment? same =
        await (_database.select(_database.attachments)..where(
              ($AttachmentsTable tbl) =>
                  tbl.projectId.equals(owner.projectId) &
                  tbl.sha256.equals(hash),
            ))
            .getSingleOrNull();
    final Attachment stored =
        same ??
        _unwrap(
          await upsertAttachment(
            _database,
            row: AttachmentsCompanion(
              id: Value<String>(id),
              projectId: Value<String>(owner.projectId),
              relativePath: Value<String>(storagePath.substring(prefix.length)),
              mimeType: Value<String>(mimeType),
              fileSize: Value<int>(bytes),
              sha256: Value<String>(hash),
              kind: Value<AttachmentKind>(
                mimeType.startsWith('audio/')
                    ? AttachmentKind.audio
                    : AttachmentKind.document,
              ),
              durationMs: Value<int?>(duration?.inMilliseconds),
            ),
            clock: _time,
            deviceId: _device,
            ids: _idService,
          ),
        );
    final List<AttachmentOwner> links =
        await (_database.select(_database.attachmentOwners)..where(
              ($AttachmentOwnersTable tbl) =>
                  tbl.ownerType.equalsValue(AttachmentOwnerType.record) &
                  tbl.ownerId.equals(owner.meeting.recordId),
            ))
            .get();
    if (!links.any((AttachmentOwner link) => link.attachmentId == stored.id)) {
      final DateTime now = _time.nowUtc();
      await _database
          .into(_database.attachmentOwners)
          .insert(
            AttachmentOwnersCompanion(
              id: Value<String>(_idService.newId()),
              attachmentId: Value<String>(stored.id),
              ownerType: const Value<AttachmentOwnerType>(
                AttachmentOwnerType.record,
              ),
              ownerId: Value<String>(owner.meeting.recordId),
              sortOrder: Value<int>(links.length),
              createdAt: Value<DateTime>(now),
              updatedAt: Value<DateTime>(now),
              updatedByDevice: Value<String>(_device),
              rev: const Value<int>(1),
            ),
          );
    }
    return _attachmentOf(stored);
  }

  /// The files on record [recordId], in the order they were added.
  Future<List<MeetingAttachment>> _attachments(String recordId) async {
    final List<TypedResult> rows =
        await (_database
                .select(_database.attachments)
                .join(<Join<HasResultSet, dynamic>>[
                  innerJoin(
                    _database.attachmentOwners,
                    _database.attachmentOwners.attachmentId.equalsExp(
                      _database.attachments.id,
                    ),
                  ),
                ])
              ..where(
                _database.attachmentOwners.ownerType.equalsValue(
                      AttachmentOwnerType.record,
                    ) &
                    _database.attachmentOwners.ownerId.equals(recordId),
              )
              ..orderBy(<OrderingTerm>[
                OrderingTerm.asc(_database.attachmentOwners.sortOrder),
                OrderingTerm.asc(_database.attachments.createdAt),
              ]))
            .get();
    final List<Attachment> files = <Attachment>[
      for (final TypedResult row in rows) row.readTable(_database.attachments),
    ];
    final Set<String> gone = await _tombstoned(_attachmentsEntity, <String>[
      for (final Attachment file in files) file.id,
    ]);
    return <MeetingAttachment>[
      for (final Attachment file in files)
        if (!gone.contains(file.id)) _attachmentOf(file),
    ];
  }

  MeetingAttachment _attachmentOf(Attachment row) {
    final int? duration = row.durationMs;
    return MeetingAttachment(
      id: row.id,
      relativePath: row.relativePath,
      mimeType: row.mimeType,
      bytes: row.fileSize,
      duration: duration == null ? null : AppConstants.millisecond * duration,
    );
  }

  /// The meeting [meetingId] with its project, for its files.
  Future<_Owner> _owner(String meetingId) async {
    final MeetingRow? meeting = await _row(meetingId);
    if (meeting == null) {
      throw _missingFailure;
    }
    final RecordRow? record =
        await (_database.select(_database.records)
              ..where(($RecordsTable tbl) => tbl.id.equals(meeting.recordId)))
            .getSingleOrNull();
    final Project? project = record == null
        ? null
        : await (_database.select(
                _database.projects,
              )..where(($ProjectsTable tbl) => tbl.id.equals(record.projectId)))
              .getSingleOrNull();
    if (project == null) {
      throw _missingFailure;
    }
    return _Owner(
      meeting: meeting,
      projectId: project.id,
      folder: project.folderName,
    );
  }

  String _storagePath(_Owner owner, String name) {
    return owner.pathOf(
      '$_meetingsFolder/${owner.meeting.id}/${_idService.newId()}/'
      '${sanitiseSegment(name)}',
    );
  }

  Future<String> _servicePath(String storagePath) async {
    if (_browser) {
      return storagePath;
    }
    return '${_unwrap(await _root.resolve()).path}/$storagePath';
  }

  Future<MeetingRow?> _row(String id) {
    return (_database.select(
      _database.meetings,
    )..where(($MeetingsTable tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// What the latest settled on-device transcript of meeting [meetingId]
  /// that holds words reads as: the operator's edit when one stands, else
  /// its raw segments in reading order. A take recorded without words (as
  /// audio only) never hides an earlier one that has them. Null when there
  /// is none. A transcript still recording or discarded is never read.
  Future<String?> _heardTranscript(String meetingId) async {
    final List<TranscriptRow> rows =
        await (_database.select(_database.transcripts)
              ..where(
                ($TranscriptsTable tbl) =>
                    tbl.ownerKind.equals(_meetingOwnerKind) &
                    tbl.ownerId.equals(meetingId) &
                    tbl.status.equals(transcriptLiveStatus).not(),
              )
              ..orderBy(<OrderClauseGenerator<$TranscriptsTable>>[
                ($TranscriptsTable tbl) => OrderingTerm.desc(tbl.startedAt),
                ($TranscriptsTable tbl) => OrderingTerm.desc(tbl.id),
              ]))
            .get();
    final Set<String> gone = await _tombstoned(_transcriptsEntity, <String>[
      for (final TranscriptRow row in rows) row.id,
    ]);
    for (final TranscriptRow row in rows) {
      if (gone.contains(row.id)) {
        continue;
      }
      final String text = row.textEdited ?? await _rawTranscript(row.id);
      if (text.trim().isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  /// The raw text of transcript [transcriptId]: its segments by start time,
  /// then insertion order, joined as every transcript reads them.
  Future<String> _rawTranscript(String transcriptId) async {
    final List<TranscriptSegmentRow> segments =
        await (_database.select(_database.transcriptSegments)
              ..where(
                ($TranscriptSegmentsTable tbl) =>
                    tbl.transcriptId.equals(transcriptId),
              )
              ..orderBy(<OrderClauseGenerator<$TranscriptSegmentsTable>>[
                ($TranscriptSegmentsTable tbl) => OrderingTerm.asc(tbl.startMs),
                ($TranscriptSegmentsTable tbl) => OrderingTerm.asc(tbl.seq),
              ]))
            .get();
    return SpeechText.join(
      segments.map((TranscriptSegmentRow segment) => segment.textRaw),
    );
  }

  Future<bool> _isTombstoned(String entityType, String id) async {
    return (await _tombstoned(entityType, <String>[id])).isNotEmpty;
  }

  Future<Set<String>> _tombstoned(String entityType, List<String> ids) async {
    if (ids.isEmpty) {
      return const <String>{};
    }
    final List<Tombstone> rows =
        await (_database.select(_database.tombstones)..where(
              ($TombstonesTable tbl) =>
                  tbl.entityType.equals(entityType) & tbl.entityId.isIn(ids),
            ))
            .get();
    return <String>{for (final Tombstone row in rows) row.entityId};
  }

  Map<String, Object?>? _documentOf(MeetingRow row) {
    final Object? decoded = jsonDecode(row.agenda);
    if (decoded is! List<Object?> || decoded.isEmpty) {
      return null;
    }
    final Object? first = decoded.first;
    return first is Map ? Map<String, Object?>.from(first) : null;
  }

  List<TranscriptVersion> _versionsOf(MeetingRow row) {
    return MeetingTranscription.fromJson(_documentOf(row)?[_transcriptsKey]);
  }

  String _document(
    Meeting meeting, {
    required Map<String, Object?> previous,
    required String originalNotes,
    required String notes,
    required String minutes,
    required List<TranscriptVersion> transcripts,
  }) {
    return jsonEncode(<Object?>[
      <String, Object?>{
        ...previous,
        'meeting': meeting.toJson(),
        'originalNotes': originalNotes,
        'notes': notes,
        'minutes': minutes,
        _transcriptsKey: MeetingTranscription.toJson(transcripts),
      },
    ]);
  }

  Result<MeetingRecord> _required(Result<MeetingRecord?> loaded) {
    return switch (loaded) {
      Success<MeetingRecord?>(:final MeetingRecord? value) when value != null =>
        Success<MeetingRecord>(value),
      Success<MeetingRecord?>() => FailureResult<MeetingRecord>(
        _missingFailure,
      ),
      FailureResult<MeetingRecord?>(:final Failure failure) =>
        FailureResult<MeetingRecord>(failure),
    };
  }

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Success<T>(await body());
    } on Failure catch (failure) {
      return FailureResult<T>(failure);
    } on Object catch (error) {
      return FailureResult<T>(Failure.from(error));
    }
  }
}

/// A meeting row with the project its files live under.
final class _Owner {
  const _Owner({
    required this.meeting,
    required this.projectId,
    required this.folder,
  });

  final MeetingRow meeting;
  final String projectId;
  final String folder;

  /// [relativePath] under the project folder, as a storage-root path.
  String pathOf(String relativePath) => 'projects/$folder/$relativePath';
}

/// The media type a picked file's name implies.
String _mimeOf(String name) {
  final int dot = name.lastIndexOf('.');
  final String extension = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  return switch (extension) {
    'pdf' => 'application/pdf',
    'doc' => 'application/msword',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls' => 'application/vnd.ms-excel',
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt' => 'application/vnd.ms-powerpoint',
    'pptx' =>
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'txt' => 'text/plain',
    'csv' => 'text/csv',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'm4a' => 'audio/mp4',
    'wav' => 'audio/wav',
    _ => 'application/octet-stream',
  };
}

T _unwrap<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(failure: final Failure causeFailure) => throw causeFailure,
  };
}

final StorageFailure _missingFailure = StorageFailure(
  localizedMessage: Copy.messages.failureThatMeetingIsNoLongerOnThis,
  localizedRecovery: Copy.messages.failureStartTheMeetingAgain,
);

/// Tombstone reason for an attendee or action taken off the meeting.
const String _removedReason = 'Removed from the meeting.';

const String _meetingsEntity = 'meetings';
const String _attendeesEntity = 'attendees';
const String _actionsEntity = 'meeting_actions';
const String _attachmentsEntity = 'attachments';
const String _transcriptsEntity = 'transcripts';

/// The stored owner kind of a transcript recorded for a meeting.
const String _meetingOwnerKind = 'meeting';

/// Where a meeting's files sit inside the project folder.
const String _meetingsFolder = 'meetings';

/// Where transcription clips are staged; disposable.
const String _cacheFolder = '.cache/meetings';

/// Document key of the transcription versions.
const String _transcriptsKey = 'transcripts';

/// Stands in for a hash the recorder could not give, so the file still has
/// its own row.
const String _unhashed = 'unhashed:';

/// The meeting store. Tests override it; production uses the database
/// opened in `main`.
final Provider<MeetingRepository> meetingRepositoryProvider =
    Provider<MeetingRepository>((Ref ref) {
      return MeetingRepositoryImpl(
        db: ref.watch(appDatabaseProvider),
        clock: const SystemClock(),
        deviceId: '',
        ids: UuidV7Service(const SystemClock()),
        storageRoot: ref.watch(storageRootProvider),
      );
    });
