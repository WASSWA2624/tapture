/// Who holds the one microphone the app may open at a time.
enum MicrophoneOwner {
  /// Field dictation into a text field. Gives way to evidence capture.
  dictation,

  /// A live transcription session that saves its audio as evidence.
  liveTranscription,

  /// The file-mode walkthrough recorder, which saves its audio as evidence.
  fileRecorder;

  /// Whether this owner records evidence, which nothing may interrupt.
  bool get isEvidence => this != MicrophoneOwner.dictation;
}
