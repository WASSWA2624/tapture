import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

import '../domain/duplicate_choice.dart';
import '../domain/duplicate_resolution.dart';
import 'duplicate_merge_sheet.dart';
import 'duplicate_prompt.dart';
import 'duplicates_controller.dart';

/// Walks a person through one duplicate pair (task 015).
///
/// Every way of clearing a pair ends in [apply], the one repository call, so
/// history, audit rows and links are the same whether the pair is cleared
/// from the list, the comparison or a bulk choice.
abstract final class DuplicateFlow {
  /// Asks about pair [pairId] of [projectId] and carries out the answer:
  /// keeping both and discarding apply at once, a merge asks field by field
  /// first, and an update opens the comparison, where the override happens.
  /// Dismissing any step leaves the pair unresolved.
  static Future<void> open(
    BuildContext context,
    WidgetRef ref, {
    required String projectId,
    required String pairId,
  }) async {
    final DuplicateChoice? choice = await showDuplicatePrompt(context, pairId);
    if (choice == null || !context.mounted) {
      return;
    }
    switch (choice) {
      case DuplicateChoice.overrideExisting:
        await context.push<void>(
          RoutePaths.projectDuplicateCompare(projectId, pairId),
        );
      case DuplicateChoice.mergeFields:
        final DuplicateResolution? merge = await showDuplicateMergeSheet(
          context,
          pairId,
        );
        if (merge != null && context.mounted) {
          await apply(context, ref, pairId, merge);
        }
      case DuplicateChoice.keepBoth:
      case DuplicateChoice.discardNew:
        await apply(context, ref, pairId, DuplicateResolution(choice));
    }
  }

  /// Applies [resolution] to pair [pairId] and reports the outcome. True
  /// when it was applied.
  static Future<bool> apply(
    BuildContext context,
    WidgetRef ref,
    String pairId,
    DuplicateResolution resolution,
  ) async {
    final Result<void> done = await ref
        .read(duplicatesControllerProvider.notifier)
        .resolve(pairId, resolution);
    if (context.mounted) {
      switch (done) {
        case Success<void>():
          showAppSnack(
            context,
            outcome(resolution.choice),
            tone: SnackTone.success,
          );
        case FailureResult<void>(:final Failure failure):
          showAppSnack(
            context,
            failure.message,
            tone: SnackTone.error,
            localizedMessage: failure.explanation,
          );
      }
    }
    return done is Success<void>;
  }

  /// What a person is told once [choice] is applied.
  static String outcome(
    DuplicateChoice choice, {
    LocalizedCopy? localizedCopy,
  }) {
    return switch (choice) {
      DuplicateChoice.keepBoth =>
        (localizedCopy ?? Copy.english).duplicateResolvedKeepBoth,
      DuplicateChoice.discardNew =>
        (localizedCopy ?? Copy.english).duplicateResolvedDiscard,
      DuplicateChoice.overrideExisting =>
        (localizedCopy ?? Copy.english).duplicateResolvedOverride,
      DuplicateChoice.mergeFields =>
        (localizedCopy ?? Copy.english).duplicateResolvedMerge,
    };
  }

  /// How a record of a pair is named: its name, else its number.
  static String title(
    String name,
    int? number, {
    LocalizedCopy? localizedCopy,
  }) {
    return name.trim().isNotEmpty
        ? name
        : (localizedCopy ?? Copy.english).recordsUntitled(number);
  }

  /// The label [choice] carries in a list of outcomes.
  static String label(DuplicateChoice choice, {LocalizedCopy? localizedCopy}) {
    return switch (choice) {
      DuplicateChoice.keepBoth =>
        (localizedCopy ?? Copy.english).duplicateLinkBoth,
      DuplicateChoice.discardNew =>
        (localizedCopy ?? Copy.english).duplicateDiscard,
      DuplicateChoice.overrideExisting =>
        (localizedCopy ?? Copy.english).duplicateOverride,
      DuplicateChoice.mergeFields =>
        (localizedCopy ?? Copy.english).duplicateMerge,
    };
  }
}
