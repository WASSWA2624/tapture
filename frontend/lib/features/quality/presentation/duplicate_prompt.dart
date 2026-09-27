import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// One field the two records do not share.
typedef DuplicateDifference = ({
  String label,
  String incoming,
  String existing,
});

/// The save-time question: four outcomes, and the values that differ.
///
/// Dismissing the sheet chooses nothing. Both records stay, unresolved.
final class DuplicatePrompt extends StatelessWidget {
  /// Creates the prompt.
  const DuplicatePrompt({
    required this.differences,
    this.failure,
    this.onChoose,
    super.key,
  });

  /// Fields that differ. Empty is the empty state.
  final List<DuplicateDifference> differences;

  /// Why the pair could not be read. Null when it could.
  final Failure? failure;

  /// The choice, when a button is pressed.
  final ValueChanged<DuplicateChoice>? onChoose;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    if (differences.isEmpty) {
      return const AppEmptyState(
        icon: AppIcons.duplicate,
        headline: Copy.duplicateNoDifferenceHeadline,
        message: Copy.duplicateNoDifferenceMessage,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final DuplicateDifference row in differences)
          AppListTile(
            title: row.label,
            subtitle: '${row.existing} → ${row.incoming}',
          ),
        AppButton(
          key: const ValueKey<String>('duplicate-override'),
          label: Copy.duplicateOverride,
          onPressed: () => onChoose?.call(DuplicateChoice.overrideExisting),
        ),
        AppButton(
          key: const ValueKey<String>('duplicate-keep'),
          label: Copy.duplicateLinkBoth,
          variant: AppButtonVariant.secondary,
          onPressed: () => onChoose?.call(DuplicateChoice.keepBoth),
        ),
        AppButton(
          key: const ValueKey<String>('duplicate-discard'),
          label: Copy.duplicateDiscard,
          variant: AppButtonVariant.secondary,
          onPressed: () => onChoose?.call(DuplicateChoice.discardNew),
        ),
        AppButton(
          key: const ValueKey<String>('duplicate-merge'),
          label: Copy.duplicateMerge,
          variant: AppButtonVariant.secondary,
          onPressed: () => onChoose?.call(DuplicateChoice.mergeFields),
        ),
      ],
    );
  }
}

/// Opens the prompt. Returns null when it is dismissed.
Future<DuplicateChoice?> showDuplicatePrompt(
  BuildContext context, {
  required List<DuplicateDifference> differences,
  Failure? failure,
}) {
  return showAppSheet<DuplicateChoice>(
    context,
    title: Copy.duplicatePromptTitle,
    contentSized: true,
    builder: (BuildContext sheet) {
      return DuplicatePrompt(
        differences: differences,
        failure: failure,
        onChoose: (DuplicateChoice choice) => Navigator.of(sheet).pop(choice),
      );
    },
  );
}

/// The four ways a person can answer a duplicate (task 015).
enum DuplicateChoice {
  /// Write the new values onto the existing record.
  overrideExisting,

  /// Keep both and link them.
  keepBoth,

  /// Drop the new record.
  discardNew,

  /// Decide field by field.
  mergeFields,
}
