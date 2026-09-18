import 'dart:typed_data';

import 'feedback_entry.dart';

/// An entry just deleted, held with its images so the undo that pairs the
/// delete confirm can put them all back exactly (FE-CONS-05).
final class RemovedFeedback {
  /// Creates the pair.
  const RemovedFeedback({
    required this.entry,
    this.shots = const <Uint8List>[],
  });

  /// The entry as it was stored.
  final FeedbackEntry entry;

  /// Its images, in attach order.
  final List<Uint8List> shots;
}
