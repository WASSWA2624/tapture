/// Where a speech engine is in its life, for the host and diagnostics.
enum SpeechEngineState {
  /// Nothing started yet.
  idle,

  /// Workers are starting.
  starting,

  /// Workers are serving and no model is loaded.
  ready,

  /// A model is being verified and loaded.
  loading,

  /// A model is loaded and nothing is decoding.
  loaded,

  /// A model is loaded and a decode is in flight.
  busy,

  /// The loaded model is being freed.
  unloading,

  /// The engine was disposed and refuses every call.
  disposed,

  /// A worker ended unexpectedly; the next load starts it again.
  failed,
}
