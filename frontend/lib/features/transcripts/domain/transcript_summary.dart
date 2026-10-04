import 'transcript_gap.dart';
import 'transcript_owner_kind.dart';
import 'transcript_status.dart';

/// A transcript's header as lists show it: owner, audio, status, how far
/// the audio is accounted for, and a short preview (spec §30.4.6).
final class TranscriptSummary {
  /// Describes transcript [id].
  const TranscriptSummary({
    required this.id,
    required this.projectId,
    required this.ownerKind,
    required this.audioPath,
    required this.title,
    required this.status,
    required this.startedAt,
    required this.languageTag,
    required this.modelId,
    this.ownerId,
    this.attachmentId,
    this.endedAt,
    this.duration,
    this.coveredMs = 0,
    this.gaps = const <TranscriptGap>[],
    this.preview = '',
    this.edited = false,
  });

  /// Transcript row id.
  final String id;

  /// Project the transcript belongs to.
  final String projectId;

  /// Who owns it.
  final TranscriptOwnerKind ownerKind;

  /// The meeting id for a meeting transcript; null otherwise.
  final String? ownerId;

  /// The audio attachment it was heard from, once filed.
  final String? attachmentId;

  /// Storage-root-relative path of the recording.
  final String audioPath;

  /// Operator-facing title; empty until named.
  final String title;

  /// Where it is in its life.
  final TranscriptStatus status;

  /// When recording started.
  final DateTime startedAt;

  /// When it finished, complete or interrupted.
  final DateTime? endedAt;

  /// How much audio the recording holds, once known.
  final Duration? duration;

  /// BCP 47 tag of the language it was heard in.
  final String languageTag;

  /// Catalogue id of the model that decoded it; empty when none loaded.
  final String modelId;

  /// The highest point of the audio processed, decoded or skipped, in
  /// milliseconds.
  final int coveredMs;

  /// Stretches left untranscribed, in time order.
  final List<TranscriptGap> gaps;

  /// The start of the text it shows, edit first. Never logged.
  final String preview;

  /// Whether the operator's edit stands beside the raw text.
  final bool edited;

  /// Whether audio is left to transcribe: a gap, or recorded audio past the
  /// covered point.
  bool get remaining {
    final Duration? recorded = duration;
    return gaps.isNotEmpty ||
        (recorded != null && coveredMs < recorded.inMilliseconds);
  }

  @override
  bool operator ==(Object other) =>
      other is TranscriptSummary &&
      other.id == id &&
      other.projectId == projectId &&
      other.ownerKind == ownerKind &&
      other.ownerId == ownerId &&
      other.attachmentId == attachmentId &&
      other.audioPath == audioPath &&
      other.title == title &&
      other.status == status &&
      other.startedAt == startedAt &&
      other.endedAt == endedAt &&
      other.duration == duration &&
      other.languageTag == languageTag &&
      other.modelId == modelId &&
      other.coveredMs == coveredMs &&
      _sameGaps(other.gaps, gaps) &&
      other.preview == preview &&
      other.edited == edited;

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    ownerKind,
    ownerId,
    attachmentId,
    audioPath,
    title,
    status,
    startedAt,
    endedAt,
    duration,
    languageTag,
    modelId,
    coveredMs,
    Object.hashAll(gaps),
    preview,
    edited,
  );
}

bool _sameGaps(List<TranscriptGap> a, List<TranscriptGap> b) {
  if (a.length != b.length) {
    return false;
  }
  for (int index = 0; index < a.length; index++) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
