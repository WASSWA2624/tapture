import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/transcript_summary.dart';
import '../transcripts.dart' show transcriptRepositoryProvider;
import 'live_transcript_controller.dart';
import 'live_transcript_status.dart';

/// When a live transcript starts, for its row. Tests override it.
final Provider<Clock> transcriptClockProvider = Provider<Clock>((Ref _) {
  return const SystemClock();
});

/// The live transcript session held under a session key
/// (`LiveTranscriptKey`). Disposed with its last listener unless a running
/// session's target keeps it alive until its take is filed.
final liveTranscriptControllerProvider = NotifierProvider.autoDispose
    .family<LiveTranscriptController, LiveTranscriptStatus, String>(
      LiveTranscriptController.new,
    );

/// Transcripts heard from audio filed on a record, by record id, newest
/// first.
final recordTranscriptsProvider = StreamProvider.autoDispose
    .family<List<TranscriptSummary>, String>((Ref ref, String recordId) {
      return ref.watch(transcriptRepositoryProvider).watchRecord(recordId);
    });

/// Transcripts of a meeting, by meeting id, newest first.
final meetingTranscriptsProvider = StreamProvider.autoDispose
    .family<List<TranscriptSummary>, String>((Ref ref, String meetingId) {
      return ref.watch(transcriptRepositoryProvider).watchMeeting(meetingId);
    });
