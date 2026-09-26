/// Raised by a stage when local detection cannot decide the template and
/// the operator has to choose from [shortlist].
///
/// The controller catches it, asks, applies the answer and retries the
/// stage once. It never reaches the job as a failure.
final class TemplateChoiceNeeded implements Exception {
  /// Creates the question for [recordId] in [projectId].
  const TemplateChoiceNeeded({
    required this.recordId,
    required this.projectId,
    required this.shortlist,
    this.pinKey,
  });

  /// The record whose template is undecided.
  final String recordId;

  /// The project the record belongs to.
  final String projectId;

  /// The templates local scoring could not separate, best first.
  final List<({String templateId, String label})> shortlist;

  /// The context pin key, `'<levelKey>=<value>'`, a pinned answer is stored
  /// under. Null when the record has no context to pin to.
  final String? pinKey;
}

/// The operator's answer: the chosen template and whether to pin it to the
/// current context.
typedef TemplateChoice = ({String templateId, bool pin});
