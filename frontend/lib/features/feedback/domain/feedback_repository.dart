import 'dart:typed_data';

import 'package:tapture/core/errors/result.dart';

import 'feedback_category.dart';
import 'feedback_context.dart';
import 'feedback_entry.dart';
import 'removed_feedback.dart';

/// The operator's feedback on this device.
///
/// Feedback is the operator's own note about the app, not project evidence,
/// so they may delete it for good behind a confirm (FE-SEC-08 covers
/// evidence). It is never sent anywhere (FE-SEC-10).
abstract interface class FeedbackRepository {
  /// Every entry, oldest first, re-emitted after each committed change
  /// (FE-STATE-08).
  Stream<List<FeedbackEntry>> watch();

  /// Saves a new entry, numbered after every entry this device has ever
  /// numbered, with [screenshots] beside it in order. Completes once all
  /// are durable (FE-STATE-07).
  Future<Result<FeedbackEntry>> add({
    required FeedbackCategory category,
    required String message,
    required FeedbackContext context,
    String? otherCategory,
    List<Uint8List> screenshots = const <Uint8List>[],
  });

  /// Every image stored with entry [id], in the order they were attached.
  Future<Result<List<Uint8List>>> screenshots(String id);

  /// Deletes the entries in [ids] and their screenshots, and returns what was
  /// deleted so [restore] can undo it. Unknown ids are ignored.
  Future<Result<List<RemovedFeedback>>> remove(Set<String> ids);

  /// Puts entries [remove] returned back exactly as they were.
  Future<Result<void>> restore(List<RemovedFeedback> removed);
}
