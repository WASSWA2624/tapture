import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// One unresolved pair, with the fields that differ already on the row.
typedef DuplicatePairRow = ({
  String id,
  String title,
  String subtitle,
  String group,
});

/// A project's unresolved duplicate pairs, grouped, cleared in place (task 015).
final class DuplicatesScreen extends StatelessWidget {
  /// Creates the review list.
  const DuplicatesScreen({
    required this.pairs,
    this.failure,
    this.onResolve,
    this.onResolveGroup,
    super.key,
  });

  /// Unresolved pairs. Empty is the empty state.
  final List<DuplicatePairRow> pairs;

  /// Why the list could not be read.
  final Failure? failure;

  /// Clears one pair.
  final ValueChanged<String>? onResolve;

  /// Clears every remaining pair in [group] after a confirmation.
  final void Function(String group, int count)? onResolveGroup;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    return AppPage(
      key: const ValueKey<String>('route-duplicates'),
      title: Copy.duplicatesTitle,
      body: failed != null
          ? AppErrorState(failure: failed, onRetry: () {})
          : pairs.isEmpty
          ? const AppEmptyState(
              icon: AppIcons.duplicate,
              headline: Copy.duplicatesEmptyHeadline,
              message: Copy.duplicatesEmptyMessage,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final MapEntry<String, List<DuplicatePairRow>> group
                    in _groups(pairs).entries) ...<Widget>[
                  AppSectionHeader(title: group.key),
                  for (final DuplicatePairRow pair in group.value)
                    AppListTile(
                      key: ValueKey<String>('duplicate-pair-${pair.id}'),
                      title: pair.title,
                      subtitle: pair.subtitle,
                      onTap: () => onResolve?.call(pair.id),
                    ),
                  AppButton(
                    key: ValueKey<String>('duplicate-group-${group.key}'),
                    label: Copy.duplicatesResolveGroup,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => unawaited(
                      _confirmGroup(context, group.key, group.value.length),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _confirmGroup(
    BuildContext context,
    String group,
    int count,
  ) async {
    final bool confirmed = await showAppConfirm(
      context,
      title: Copy.duplicatesBulkTitle(count, Copy.duplicateLinkBoth),
      message: Copy.duplicatesBulkMessage(count),
      confirmLabel: Copy.duplicateLinkBoth,
    );
    if (confirmed) {
      onResolveGroup?.call(group, count);
    }
  }
}

Map<String, List<DuplicatePairRow>> _groups(List<DuplicatePairRow> pairs) {
  final Map<String, List<DuplicatePairRow>> grouped =
      <String, List<DuplicatePairRow>>{};
  for (final DuplicatePairRow pair in pairs) {
    grouped.putIfAbsent(pair.group, () => <DuplicatePairRow>[]).add(pair);
  }
  return grouped;
}
