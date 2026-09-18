import 'dart:typed_data';

import '../domain/feedback_category.dart';
import '../domain/feedback_context.dart';
import 'feedback_shot.dart';

/// The in-progress feedback: text, type and attachments, kept while the
/// operator moves through the app until they save or discard it.
final class FeedbackDraft {
  /// Creates the draft. [screenshot] seeds [shots] when [shots] is empty.
  factory FeedbackDraft({
    required FeedbackContext context,
    Uint8List? screenshot,
    List<FeedbackShot> shots = const <FeedbackShot>[],
    String message = '',
    String other = '',
    FeedbackCategory category = FeedbackCategory.general,
    bool attachShots = true,
    bool open = false,
    bool expanded = false,
  }) {
    final List<FeedbackShot> attached = shots.isNotEmpty
        ? shots
        : screenshot == null || screenshot.isEmpty
        ? const <FeedbackShot>[]
        : <FeedbackShot>[
            FeedbackShot(
              id: 'capture',
              bytes: screenshot,
              label: context.screen,
            ),
          ];
    return FeedbackDraft._(
      context: context,
      shots: attached,
      message: message,
      other: other,
      category: category,
      attachShots: attached.isEmpty ? false : attachShots,
      open: open,
      expanded: expanded,
    );
  }

  const FeedbackDraft._({
    required this.context,
    required this.shots,
    required this.message,
    required this.other,
    required this.category,
    required this.attachShots,
    required this.open,
    required this.expanded,
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

  /// The first attached image, when there is one.
  Uint8List? get screenshot => shots.isEmpty ? null : shots.first.bytes;

  /// A copy with the given parts replaced.
  FeedbackDraft copyWith({
    FeedbackContext? context,
    List<FeedbackShot>? shots,
    String? message,
    String? other,
    FeedbackCategory? category,
    bool? attachShots,
    bool? open,
    bool? expanded,
  }) {
    return FeedbackDraft._(
      context: context ?? this.context,
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
