import 'dart:typed_data';

import 'feedback_entry.dart';

/// An entry just deleted, held with its screenshot so the undo that pairs
/// the delete confirm can put both back exactly (FE-CONS-05).
final class RemovedFeedback {
  /// Creates the pair.
  const RemovedFeedback({required this.entry, this.screenshot});

  /// The entry as it was stored.
  final FeedbackEntry entry;

  /// Its screenshot, when it had one.
  final Uint8List? screenshot;
}
