/// Typed paths for shipped text documents (FE-STR-12).
abstract final class DocumentAssets {
  /// Shared canonical secret patterns used by production bundle checks.
  static const String secretPatterns = 'tool/secret_patterns.yaml';

  /// Instructions an AI agent follows to turn a feedback archive into
  /// ordered implementation prompts. Shipped inside every feedback download.
  static const String feedbackPromptsGenerator =
      'assets/feedback/feedback-prompts-generator.md';
}
