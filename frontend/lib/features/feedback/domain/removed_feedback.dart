import 'dart:typed_data';

import 'feedback_entry.dart';

/// An entry just deleted, held with its screenshot so the undo that pairs
/// the delete confirm can put both back exactly (FE-CONS-05).
final class RemovedFeedback {
  /// Creates the pair.
  const RemovedFeedback({
    required this.entry,
    this.screenshot,
    this.extraShots = const <Uint8List>[],
  });

  /// The entry as it was stored.
  final FeedbackEntry entry;

  /// Its first screenshot, when it had one.
  final Uint8List? screenshot;

  /// Further screenshots after [screenshot], in attach order.
  final List<Uint8List> extraShots;
}
