/// How a live transcript session records (spec §30.4.5).
enum TranscriptMode {
  /// Records and transcribes as the operator speaks.
  live,

  /// Records the audio only, because no speech model is ready. The
  /// transcript row is kept, so the audio can be transcribed later.
  audioOnly,
}
