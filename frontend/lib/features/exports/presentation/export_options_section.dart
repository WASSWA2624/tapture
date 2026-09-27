import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// Column and extra choices, restored from the last export (task 018).
final class ExportOptionsSection extends StatelessWidget {
  /// Creates the section. [columns.refined] starts on.
  const ExportOptionsSection({
    required this.columns,
    this.advancedOpen = false,
    this.loading = false,
    this.empty = false,
    this.failure,
    this.onChanged,
    this.onToggleAdvanced,
    super.key,
  });

  /// The remembered column switches.
  final ExportColumns columns;

  /// Whether the advanced group is open.
  final bool advancedOpen;

  /// Whether options are still loading.
  final bool loading;

  /// Whether there is nothing to configure.
  final bool empty;

  /// Why options could not be read.
  final Failure? failure;

  /// Stores a new column choice.
  final ValueChanged<ExportColumns>? onChanged;

  /// Opens or closes the advanced group.
  final VoidCallback? onToggleAdvanced;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    if (loading) {
      return const SizedBox.shrink();
    }
    if (empty) {
      return const AppEmptyState(
        icon: AppIcons.fields,
        headline: Copy.exportEmptyHeadline,
        message: Copy.exportEmptyMessage,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSwitchTile(
          key: const ValueKey<String>('export-refined'),
          title: Copy.exportRefined,
          value: columns.refined,
          onChanged: (bool value) => onChanged?.call((
            raw: columns.raw,
            refined: value,
            confidence: columns.confidence,
            evidence: columns.evidence,
          )),
        ),
        AppSwitchTile(
          title: Copy.exportRaw,
          value: columns.raw,
          onChanged: (bool value) => onChanged?.call((
            raw: value,
            refined: columns.refined,
            confidence: columns.confidence,
            evidence: columns.evidence,
          )),
        ),
        AppButton(
          key: const ValueKey<String>('export-advanced'),
          label: Copy.exportAdvanced,
          variant: AppButtonVariant.secondary,
          onPressed: onToggleAdvanced,
        ),
        if (advancedOpen) ...<Widget>[
          AppSwitchTile(
            title: Copy.exportConfidence,
            value: columns.confidence,
            onChanged: (bool value) => onChanged?.call((
              raw: columns.raw,
              refined: columns.refined,
              confidence: value,
              evidence: columns.evidence,
            )),
          ),
          AppSwitchTile(
            title: Copy.exportEvidence,
            value: columns.evidence,
            onChanged: (bool value) => onChanged?.call((
              raw: columns.raw,
              refined: columns.refined,
              confidence: columns.confidence,
              evidence: value,
            )),
          ),
        ],
      ],
    );
  }
}
