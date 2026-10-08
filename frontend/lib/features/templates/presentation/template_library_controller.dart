import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../templates.dart'
    show TemplateDef, TemplateRepository, templateRepositoryProvider;

/// Saved-template commands survive the screen so snackbar Undo remains valid.
final templateLibraryControllerProvider = Provider<TemplateLibraryController>(
  (Ref ref) => TemplateLibraryController(ref.watch(templateRepositoryProvider)),
);

/// Owns durable library edits; the widget retains its draft until they succeed.
final class TemplateLibraryController {
  /// Creates commands against the owning repository.
  const TemplateLibraryController(this._repository);

  final TemplateRepository _repository;

  /// Renames the latest saved shape, preserving intervening field edits.
  Future<Result<void>> rename(String id, String name) async {
    final Result<TemplateDef?> loaded = await _repository.byId(id);
    switch (loaded) {
      case FailureResult<TemplateDef?>(:final failure):
        return FailureResult<void>(failure);
      case Success<TemplateDef?>(:final value):
        if (value == null) {
          return FailureResult<void>(
            StorageFailure(
              localizedMessage:
                  Copy.messages.failureThatTemplateIsNoLongerOnThis,
              localizedRecovery:
                  Copy.messages.failureOpenTheTemplateListAndTryAgain,
            ),
          );
        }
        return (await _repository.save(
          value.copyWith(name: name),
        )).map((TemplateDef _) {});
    }
  }

  /// Deletes a saved copy without touching its shipped or attached sources.
  Future<Result<void>> delete(String id) =>
      _repository.delete(id, reason: 'Removed from the template list.');

  /// Lifts the owning repository's exact deletion for snackbar Undo.
  Future<Result<void>> restore(String id) => _repository.restore(id);
}
