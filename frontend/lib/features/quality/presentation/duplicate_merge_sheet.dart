import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// A field the merge sheet asks about.
typedef MergeField = ({
  String fieldKey,
  String label,
  String mine,
  String theirs,
});

/// Decides each field: keep mine, take theirs, or keep both as a note.
final class DuplicateMergeSheet extends StatelessWidget {
  /// Creates the sheet.
  const DuplicateMergeSheet({
    required this.fields,
    this.picks = const <String, MergePick>{},
    this.failure,
    this.onPick,
    this.onApply,
    super.key,
  });

  /// Fields that differ.
  final List<MergeField> fields;

  /// Choices already made, by field key.
  final Map<String, MergePick> picks;

  /// Why the fields could not be read.
  final Failure? failure;

  /// Records a choice for one field.
  final void Function(String fieldKey, MergePick pick)? onPick;

  /// Applies the choices, including photos carried from the other side.
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    if (fields.isEmpty) {
      return const AppEmptyState(
        icon: AppIcons.duplicate,
        headline: Copy.duplicateNoDifferenceHeadline,
        message: Copy.duplicateNoDifferenceMessage,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final MergeField field in fields) ...<Widget>[
          AppListTile(
            title: field.label,
            subtitle: '${field.mine} · ${field.theirs}',
          ),
          AppButton(
            key: ValueKey<String>('merge-mine-${field.fieldKey}'),
            label: Copy.duplicateKeepMine,
            variant: picks[field.fieldKey] == MergePick.mine
                ? AppButtonVariant.primary
                : AppButtonVariant.secondary,
            onPressed: () => onPick?.call(field.fieldKey, MergePick.mine),
          ),
          AppButton(
            key: ValueKey<String>('merge-theirs-${field.fieldKey}'),
            label: Copy.duplicateTakeTheirs,
            variant: AppButtonVariant.secondary,
            onPressed: () => onPick?.call(field.fieldKey, MergePick.theirs),
          ),
          AppButton(
            key: ValueKey<String>('merge-both-${field.fieldKey}'),
            label: Copy.duplicateKeepBothNote,
            variant: AppButtonVariant.secondary,
            onPressed: () => onPick?.call(field.fieldKey, MergePick.both),
          ),
        ],
        AppButton(
          key: const ValueKey<String>('merge-apply'),
          label: Copy.duplicateMerge,
          onPressed: onApply,
        ),
      ],
    );
  }
}

/// Opens the merge sheet.
Future<void> showDuplicateMergeSheet(
  BuildContext context, {
  required List<MergeField> fields,
  Failure? failure,
}) {
  return showAppSheet<void>(
    context,
    title: Copy.duplicateMergeTitle,
    builder: (BuildContext _) {
      return DuplicateMergeSheet(fields: fields, failure: failure);
    },
  );
}

/// One field in a merge, and which side a person kept.
enum MergePick { mine, theirs, both }
