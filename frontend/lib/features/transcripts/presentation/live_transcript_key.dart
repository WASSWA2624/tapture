/// The session keys a surface's live transcript controller is held under,
/// one per place that records.
abstract final class LiveTranscriptKey {
  /// The caption recorder of the capture session stored under [storageKey].
  static String capture(String storageKey) => 'capture:$storageKey';

  /// The recording of meeting [meetingId].
  static String meeting(String meetingId) => 'meeting:$meetingId';

  /// The Transcribe screen of project [projectId].
  static String standalone(String projectId) => 'standalone:$projectId';
}
