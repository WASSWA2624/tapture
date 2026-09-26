/// Returned by the detect stage when local detection cannot decide the
/// template and someone has to choose from [shortlist].
///
/// The controller asks and applies the answer, which completes the stage. With [modelMayDecide], a model is asked about [shortlist]
/// first, behind the egress preview, and the operator only when it cannot
/// say. It never reaches the job as a failure.
final class TemplateChoiceNeeded {
  /// Creates the question for [recordId] in [projectId].
  const TemplateChoiceNeeded({
    required this.recordId,
    required this.projectId,
    required this.shortlist,
    this.pinKey,
    this.modelMayDecide = false,
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

  /// Whether local scoring narrowed the choice enough for a model to pick
  /// from [shortlist] before the operator is asked.
  final bool modelMayDecide;
}

/// The operator's answer: the chosen template and whether to pin it to the
/// current context.
typedef TemplateChoice = ({String templateId, bool pin});
