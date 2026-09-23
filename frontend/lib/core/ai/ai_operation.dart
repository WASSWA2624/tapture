/// An AI operation that can have an independent provider/model selection.
enum AiOperation {
  /// Image text.
  readText,

  /// Field extraction.
  extractFields,

  /// Caption refinement.
  refineText,

  /// Speech.
  transcribe,
}
