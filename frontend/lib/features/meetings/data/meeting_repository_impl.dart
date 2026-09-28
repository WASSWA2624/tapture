import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/database_provider.dart';
import 'package:tapture/core/db/tables/meetings.dart';
import 'package:tapture/core/db/tables/records.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/action_entry.dart';
import '../domain/attendee.dart';
import '../domain/meeting.dart';
import '../domain/meeting_repository.dart';

/// Writes a meeting through the meeting, attendee and action tables.
final class MeetingRepositoryImpl implements MeetingRepository {
  /// Creates a store over [db].
  MeetingRepositoryImpl({
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

  @override
  Future<Result<MeetingRecord>> save(
    Meeting meeting, {
    required String recordId,
    String templateId = Meeting.templateKey,
    String notes = '',
    String transcript = '',
    String minutes = '',
  }) async {
    try {
      final bool exists = meeting.id.isNotEmpty && await _has(meeting.id);
      final String id = meeting.id.isEmpty ? _idService.newId() : meeting.id;
      final Meeting stored = meeting.copyWith(id: id, recordId: recordId);
      if (!exists) {
        final Result<RecordRow> record = await upsertRecord(
          _database,
          row: RecordsCompanion(
            id: Value<String>(recordId),
            projectId: Value<String>(stored.projectId),
            templateId: Value<String>(templateId),
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
        );
        if (record is FailureResult<RecordRow>) {
          return FailureResult<MeetingRecord>(record.failure);
        }
      }
      final Result<MeetingRow> header = await insertMeeting(
        _database,
        row: MeetingsCompanion(
          id: Value<String>(id),
          recordId: Value<String>(recordId),
          title: Value<String>(stored.title),
          startAt: Value<DateTime>(stored.startedAt.toUtc()),
          endAt: stored.endedAt == null
              ? const Value<DateTime>.absent()
              : Value<DateTime>(stored.endedAt!.toUtc()),
          secretary: Value<String>(stored.secretary ?? ''),
          agenda: Value<String>(_document(stored, notes, minutes)),
          transcriptRaw: exists
              ? const Value<String>.absent()
              : Value<String>(transcript),
          minutesRefined: Value<String>(minutes),
        ),
        clock: _time,
        deviceId: _device,
        ids: _idService,
      );
      if (header is FailureResult<MeetingRow>) {
        return FailureResult<MeetingRecord>(header.failure);
      }
      for (final Attendee person in stored.attendees) {
        final Result<MeetingAttendee> written = await upsertMeetingAttendee(
          _database,
          row: AttendeesCompanion(
            id: Value<String>(
              person.id.isEmpty ? _idService.newId() : person.id,
            ),
            meetingId: Value<String>(id),
            name: Value<String>(person.name),
            title: Value<String>(person.title),
            organisation: Value<String>(person.organisation),
            contact: Value<String>(person.contact),
            signaturePresent: Value<bool>(person.signaturePresent),
            matchedStaffId: person.staffId == null
                ? const Value<String>.absent()
                : Value<String>(person.staffId!),
          ),
          clock: _time,
          deviceId: _device,
          ids: _idService,
        );
        if (written is FailureResult<MeetingAttendee>) {
          return FailureResult<MeetingRecord>(written.failure);
        }
      }
      for (final ActionEntry action in stored.actions) {
        final DateTime? due = action.due;
        if (due == null) {
          continue;
        }
        final Result<MeetingAction> written = await upsertMeetingAction(
          _database,
          row: MeetingActionsCompanion(
            id: Value<String>(
              action.id.isEmpty ? _idService.newId() : action.id,
            ),
            meetingId: Value<String>(id),
            action: Value<String>(action.text),
            ownerName: Value<String>(action.ownerName),
            dueDate: Value<DateTime>(due.toUtc()),
            status: Value<String>(action.status.name),
          ),
          clock: _time,
          deviceId: _device,
          ids: _idService,
        );
        if (written is FailureResult<MeetingAction>) {
          return FailureResult<MeetingRecord>(written.failure);
        }
      }
      final Result<MeetingRecord?> loaded = await read(id);
      return switch (loaded) {
        Success<MeetingRecord?>(:final MeetingRecord? value)
            when value != null =>
          Success<MeetingRecord>(value),
        Success<MeetingRecord?>() => const FailureResult<MeetingRecord>(
          StorageFailure(
            message: 'That meeting is no longer on this device.',
            recoveryAction: 'Start the meeting again.',
          ),
        ),
        FailureResult<MeetingRecord?>(:final Failure failure) =>
          FailureResult<MeetingRecord>(failure),
      };
    } on Failure catch (failure) {
      return FailureResult<MeetingRecord>(failure);
    } on Object catch (error) {
      return FailureResult<MeetingRecord>(Failure.from(error));
    }
  }

  @override
  Future<Result<MeetingRecord?>> read(String id) async {
    try {
      final MeetingRow? row = await (_database.select(
        _database.meetings,
      )..where(($MeetingsTable tbl) => tbl.id.equals(id))).getSingleOrNull();
      if (row == null) {
        return const Success<MeetingRecord?>(null);
      }
      final Object? decoded = jsonDecode(row.agenda);
      if (decoded is! List<Object?> || decoded.isEmpty) {
        return const Success<MeetingRecord?>(null);
      }
      final Object? first = decoded.first;
      if (first is! Map) {
        return const Success<MeetingRecord?>(null);
      }
      final Map<String, Object?> document = Map<String, Object?>.from(first);
      final Object? body = document['meeting'];
      if (body is! Map) {
        return const Success<MeetingRecord?>(null);
      }
      return Success<MeetingRecord?>((
        meeting: Meeting.fromJson(Map<String, Object?>.from(body)),
        notes: document['notes'] as String? ?? '',
        minutes: row.minutesRefined ?? '',
        transcript: row.transcriptRaw,
      ));
    } on Failure catch (failure) {
      return FailureResult<MeetingRecord?>(failure);
    } on Object catch (error) {
      return FailureResult<MeetingRecord?>(Failure.from(error));
    }
  }

  Future<bool> _has(String id) async {
    final MeetingRow? row = await (_database.select(
      _database.meetings,
    )..where(($MeetingsTable tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row != null;
  }

  String _document(Meeting meeting, String notes, String minutes) {
    return jsonEncode(<Object?>[
      <String, Object?>{
        'meeting': meeting.toJson(),
        'notes': notes,
        'minutes': minutes,
      },
    ]);
  }
}

/// The meeting store. Tests override it; production uses the database
/// opened in `main`.
final Provider<MeetingRepository> meetingRepositoryProvider =
    Provider<MeetingRepository>((Ref ref) {
      return MeetingRepositoryImpl(
        db: ref.watch(appDatabaseProvider),
        clock: const SystemClock(),
        deviceId: '',
        ids: UuidV7Service(const SystemClock()),
      );
    });
