import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/meetings/domain/meeting.dart';
import 'package:tapture/features/meetings/domain/meeting_repository.dart';

void main() {
  test('a save can be read back, and a later transcript is ignored', () async {
    final _Memory memory = _Memory();
    final Result<MeetingRecord> saved = await memory.save(
      Meeting(
        id: '',
        projectId: 'p1',
        title: 'Kick-off',
        startedAt: DateTime.utc(2026, 9, 27),
      ),
      recordId: 'r1',
      transcript: 'verbatim',
    );
    final MeetingRecord stored = (saved as Success<MeetingRecord>).value;
    final Result<MeetingRecord> again = await memory.save(
      stored.meeting,
      recordId: 'r1',
      transcript: 'replaced',
      minutes: 'refined',
    );
    final MeetingRecord next = (again as Success<MeetingRecord>).value;
    expect(next.transcript, 'verbatim');
    expect(next.minutes, 'refined');
    expect(
      (await memory.read('missing') as Success<MeetingRecord?>).value,
      isNull,
    );
  });
}

final class _Memory implements MeetingRepository {
  MeetingRecord? _stored;

  @override
  Future<Result<MeetingRecord>> save(
    Meeting meeting, {
    required String recordId,
    String templateId = Meeting.templateKey,
    String notes = '',
    String transcript = '',
    String minutes = '',
  }) async {
    final String id = meeting.id.isEmpty ? 'm1' : meeting.id;
    _stored = (
      meeting: meeting.copyWith(id: id, recordId: recordId),
      notes: notes,
      minutes: minutes,
      transcript: _stored?.transcript ?? transcript,
    );
    return Success<MeetingRecord>(_stored!);
  }

  @override
  Future<Result<MeetingRecord?>> read(String id) async {
    final MeetingRecord? stored = _stored;
    if (stored == null || stored.meeting.id != id) {
      return const Success<MeetingRecord?>(null);
    }
    return Success<MeetingRecord?>(stored);
  }
}
