part of 'transcripts.dart';

/// One finished segment of a [Transcripts] row, written once at insert and
/// never updated (FE-SEC-08).
///
/// [seq] is the 1-based insertion order, the session's segment id. Reading
/// order is `ORDER BY start_ms, seq`, so a segment that fills a gap later
/// slots into time order.
@TableIndex(
  name: 'transcript_segments_by_transcript',
  columns: {#transcriptId, #seq},
  unique: true,
)
@DataClassName('TranscriptSegmentRow')
class TranscriptSegments extends Table with MergeColumns {
  /// The transcript this segment belongs to.
  TextColumn get transcriptId => text()();

  /// 1-based insertion order within the transcript.
  IntColumn get seq => integer()();

  /// Where the segment starts in the recording, in milliseconds.
  IntColumn get startMs => integer()();

  /// Where the segment ends in the recording, in milliseconds.
  IntColumn get endMs => integer()();

  /// The text as decoded. Written once at insert, never updated or logged.
  TextColumn get textRaw => text()();

  /// Mean word probability from 0 to 1, when the decode reported one.
  RealColumn get confidence => real().nullable()();
}

/// Inserts one segment row. The only write of its raw text.
Future<void> _insertSegment(
  AppDatabase db, {
  required String transcriptId,
  required ({int seq, int startMs, int endMs, String text, double? confidence})
  segment,
  required DateTime now,
  required String deviceId,
  required IdService ids,
}) {
  return db
      .into(db.transcriptSegments)
      .insert(
        TranscriptSegmentsCompanion.insert(
          textRaw: segment.text,
          id: Value<String>(ids.newId()),
          transcriptId: transcriptId,
          seq: segment.seq,
          startMs: segment.startMs,
          endMs: segment.endMs,
          confidence: Value<double?>(segment.confidence),
          createdAt: now,
          updatedAt: now,
          updatedByDevice: deviceId,
        ),
      );
}
