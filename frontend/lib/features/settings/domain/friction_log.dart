import 'dart:typed_data';

import 'package:tapture/core/copy/domain_copy.g.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/feedback/domain/domain.dart'
    show FeedbackCategory, FeedbackContext, FeedbackEntry, FeedbackRepository;

/// Field reports use the same durable local journal and screenshot export as feedback.
final class FrictionLog {
  /// Composes the local journal port; never sends anything to a provider.
  const FrictionLog({required this._repository});

  final FeedbackRepository _repository;

  /// An optional note and screenshot accompany the captured screen context.
  Future<Result<FeedbackEntry>> logFriction({
    required FeedbackContext context,
    String? note,
    Uint8List? screenshot,
  }) => _repository.add(
    category: FeedbackCategory.error,
    message: note == null || note.trim().isEmpty
        ? DomainCopy.frictionLogAction
        : note.trim(),
    context: context,
    screenshots: <Uint8List>[?screenshot],
  );
}
