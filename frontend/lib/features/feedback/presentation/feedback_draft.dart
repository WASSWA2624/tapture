import 'dart:typed_data';

import '../domain/feedback_context.dart';

/// The screenshot and context captured when Feedback was tapped, held until
/// the operator saves or closes the form.
final class FeedbackDraft {
  /// Creates the draft.
  const FeedbackDraft({required this.context, this.screenshot});

  /// The moment Feedback was tapped.
  final FeedbackContext context;

  /// PNG of that screen, when one could be taken.
  final Uint8List? screenshot;
}
