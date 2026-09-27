import 'package:tapture/core/errors/result.dart';

import 'meeting.dart';

/// Persistence port for a meeting and the rows under it (task 017).
abstract interface class MeetingRepository {
  /// Stores [meeting] against [recordId].
  ///
  /// The first save writes [transcript]. A later save of the same id leaves
  /// that transcript in place and may replace refined [minutes].
  Future<Result<MeetingRecord>> save(
    Meeting meeting, {
    required String recordId,
    String templateId = Meeting.templateKey,
    String notes = '',
    String transcript = '',
    String minutes = '',
  });

  /// The meeting [id], or null when it is not on this device.
  Future<Result<MeetingRecord?>> read(String id);
}

/// A stored meeting plus the raw material beside it.
typedef MeetingRecord = ({
  Meeting meeting,
  String notes,
  String minutes,
  String transcript,
});
