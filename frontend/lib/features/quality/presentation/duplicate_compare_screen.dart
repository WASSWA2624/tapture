import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

import 'duplicate_prompt.dart';

/// Two records side by side, only the fields that differ (task 015).
///
/// Override is offered here, and only here.
final class DuplicateCompareScreen extends StatelessWidget {
  /// Creates the comparison.
  const DuplicateCompareScreen({
    required this.leftTitle,
    required this.rightTitle,
    required this.differences,
    this.leftDetail = '',
    this.rightDetail = '',
    this.failure,
    this.onOverride,
    super.key,
  });

  /// The existing record's name.
  final String leftTitle;

  /// The incoming record's name.
  final String rightTitle;

  /// Capture detail for the existing record: time, person, context.
  final String leftDetail;

  /// Capture detail for the incoming record.
  final String rightDetail;

  /// Fields that differ.
  final List<DuplicateDifference> differences;

  /// Why the records could not be read.
  final Failure? failure;

  /// Writes the new values onto the existing record.
  final VoidCallback? onOverride;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    return AppPage(
      key: const ValueKey<String>('route-duplicate-compare'),
      title: Copy.duplicateCompareTitle,
      body: failed != null
          ? AppErrorState(failure: failed)
          : differences.isEmpty
          ? const AppEmptyState(
              icon: AppIcons.duplicate,
              headline: Copy.duplicateNoDifferenceHeadline,
              message: Copy.duplicateNoDifferenceMessage,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppListTile(title: leftTitle, subtitle: leftDetail),
                AppListTile(title: rightTitle, subtitle: rightDetail),
                for (final DuplicateDifference row in differences)
                  AppListTile(
                    title: row.label,
                    subtitle: '${row.existing} · ${row.incoming}',
                  ),
                AppButton(
                  key: const ValueKey<String>('duplicate-compare-override'),
                  label: Copy.duplicateOverride,
                  onPressed: onOverride,
                ),
              ],
            ),
    );
  }
}
