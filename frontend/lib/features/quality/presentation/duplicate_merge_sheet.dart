import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/duplicate_choice.dart';
import '../domain/duplicate_pair_view.dart';
import '../domain/duplicate_resolution.dart';
import 'duplicate_merge_controller.dart';
import 'quality_providers.dart';

/// Decides a merge field by field (task 015): the existing value, the new
/// one, or both, and whether the new record's photos move onto the record
/// that survives.
///
/// No field is decided for the person: the merge runs once every differing
/// field has a pick.
final class DuplicateMergeSheet extends ConsumerWidget {
  /// Creates the sheet for pair [pairId].
  const DuplicateMergeSheet({
    required this.pairId,
    required this.onApply,
    super.key,
  });

  /// The pair being merged.
  final String pairId;

  /// Called with the finished merge.
  final ValueChanged<DuplicateResolution> onApply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncValueView<DuplicatePairView?>(
      value: ref.watch(duplicatePairProvider(pairId)),
      onRetry: () => ref.invalidate(duplicatePairProvider(pairId)),
      isEmpty: (DuplicatePairView? pair) => pair == null,
      empty: () => AppEmptyState(
        icon: AppIcons.duplicate,
        headline: Copy.of(context).duplicatesEmptyHeadline,
        message: Copy.of(context).duplicatePairGone,
        actionLabel: Copy.of(context).close,
        onAction: () => Navigator.of(context).maybePop(),
      ),
      data: (DuplicatePairView? pair) => _form(context, ref, pair!),
    );
  }

  Widget _form(BuildContext context, WidgetRef ref, DuplicatePairView pair) {
    final DuplicateMergeDraft draft = ref.watch(
      duplicateMergeControllerProvider(pairId),
    );
    DuplicateMergeController merge() =>
        ref.read(duplicateMergeControllerProvider(pairId).notifier);
    final int photos = pair.incoming.photos.length;
    final bool decided = pair.differences.every(
      (DuplicateDifference row) => draft.picks.containsKey(row.fieldKey),
    );
    return Padding(
      padding: const EdgeInsets.all(Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final DuplicateDifference row in pair.differences) ...<Widget>[
            AppListTile(
              dense: true,
              title: row.label,
              subtitle: Copy.of(
                context,
              ).duplicateValueChange(row.existing, row.incoming),
            ),
            AppChoiceField<MergePick>(
              key: ValueKey<String>('merge-pick-${row.fieldKey}'),
              label: Copy.of(context).duplicateMergeKeep(row.label),
              value: draft.picks[row.fieldKey],
              options: <Choice<MergePick>>[
                Choice<MergePick>(
                  MergePick.theirs,
                  Copy.of(context).duplicateMergeExisting,
                ),
                Choice<MergePick>(
                  MergePick.mine,
                  Copy.of(context).duplicateMergeNew,
                ),
                Choice<MergePick>(
                  MergePick.both,
                  Copy.of(context).duplicateMergeBoth,
                ),
              ],
              onChanged: (MergePick? pick) => merge().pick(row.fieldKey, pick),
            ),
            const SizedBox(height: Space.x3),
          ],
          if (photos > 0)
            AppSwitchTile(
              key: const ValueKey<String>('merge-carry-photos'),
              title: Copy.of(context).duplicateCarryPhotos,
              description: Copy.of(context).duplicateCarryPhotosHelp(photos),
              value: draft.carryPhotos,
              onChanged: (bool value) => merge().carryPhotos(carry: value),
            ),
          const SizedBox(height: Space.x4),
          AppPrimaryAction(
            key: const ValueKey<String>('merge-apply'),
            label: Copy.of(context).duplicateMergeApply,
            caption: decided ? null : Copy.of(context).duplicateMergeChooseAll,
            onPressed: decided ? () => onApply(merge().resolution()) : null,
          ),
        ],
      ),
    );
  }
}

/// Opens the merge sheet for pair [pairId]. Returns the merge a person
/// finished, or null when the sheet is dismissed.
Future<DuplicateResolution?> showDuplicateMergeSheet(
  BuildContext context,
  String pairId,
) {
  final LocalizedCopy localCopy = Copy.of(context);

  return showAppSheet<DuplicateResolution>(
    context,
    title: localCopy.duplicateMergeTitle,
    contentSized: true,
    builder: (BuildContext sheet) {
      return DuplicateMergeSheet(
        pairId: pairId,
        onApply: (DuplicateResolution merge) => Navigator.of(sheet).pop(merge),
      );
    },
  );
}
