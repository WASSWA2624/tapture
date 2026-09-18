import '../domain/feedback_category.dart';
import '../domain/feedback_context.dart';
import 'feedback_shot.dart';

/// The in-progress feedback: text, type and images, kept while the operator
/// moves through the app until they save or discard it. The one source of
/// truth for the form, the compact bar and the overlay (FE-STATE-06).
final class FeedbackDraft {
  /// Creates the draft.
  const FeedbackDraft({
    required this.context,
    this.shots = const <FeedbackShot>[],
    this.message = '',
    this.other = '',
    this.category = FeedbackCategory.general,
    this.attachShots = true,
    this.open = false,
    this.expanded = false,
  });

  /// The moment Feedback was first tapped for this draft.
  final FeedbackContext context;

  /// Attached screenshots and photos, in the order they were added.
  final List<FeedbackShot> shots;

  /// What the operator has written so far.
  final String message;

  /// The named type, when [category] is [FeedbackCategory.other].
  final String other;

  /// The kind of feedback.
  final FeedbackCategory category;

  /// Whether [shots] are stored with the entry on save.
  final bool attachShots;

  /// Whether the operator has started Give us feedback.
  final bool open;

  /// Whether the full form is showing, rather than the compact bar.
  final bool expanded;

  /// A copy with the given parts replaced.
  FeedbackDraft copyWith({
    List<FeedbackShot>? shots,
    String? message,
    String? other,
    FeedbackCategory? category,
    bool? attachShots,
    bool? open,
    bool? expanded,
  }) {
    return FeedbackDraft(
      context: context,
      shots: shots ?? this.shots,
      message: message ?? this.message,
      other: other ?? this.other,
      category: category ?? this.category,
      attachShots: attachShots ?? this.attachShots,
      open: open ?? this.open,
      expanded: expanded ?? this.expanded,
    );
  }
}
