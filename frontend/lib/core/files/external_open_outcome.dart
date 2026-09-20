/// How a share or open attempt finished, so tests never import the plugin.
enum ExternalOpenOutcome {
  /// The operator chose an app or the handler launched.
  success,

  /// The operator dismissed the chooser.
  dismissed,

  /// The platform could not say what happened, or no handler exists.
  unavailable,
}
