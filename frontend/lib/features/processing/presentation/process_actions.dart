import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';

export 'package:tapture/core/widgets/app_progress_steps.dart' show ProgressStep;
export 'process_batch_line.dart';

/// The queue's footer: Process all as the one primary action, with Process
/// selected beside it while groups are picked, or Cancel while a batch runs
/// (FE-SIMP-01, FE-A11Y-09).
class ProcessActions extends StatelessWidget {
  /// Creates the actions.
  const ProcessActions({
    super.key,
    this.running = false,
    this.onProcessAll,
    this.onProcessSelected,
    this.selectedCount = 0,
    this.onCancel,
  });

  /// Whether a batch is in progress. Process all shows busy meanwhile.
  final bool running;

  /// Starts every waiting record. Null disables it.
  final VoidCallback? onProcessAll;

  /// Starts the current selection.
  final VoidCallback? onProcessSelected;

  /// How many groups are selected. Process selected stays hidden at zero.
  final int selectedCount;

  /// Stops the batch. Work already finished is kept.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Widget primary = AppPrimaryAction(
      key: const ValueKey<String>('queue-process-all'),
      label: localCopy.queueProcessAll,
      busy: running,
      onPressed: onProcessAll,
    );
    final VoidCallback? processSelected = onProcessSelected;
    final Widget? secondary = running
        ? AppButton(
            key: const ValueKey<String>('queue-cancel'),
            label: localCopy.queueCancel,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: onCancel,
          )
        : processSelected != null && selectedCount > 0
        ? AppButton(
            key: const ValueKey<String>('queue-process-selected'),
            label: localCopy.queueProcessSelected,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: processSelected,
          )
        : null;
    if (secondary == null) {
      return primary;
    }
    // One level row at every width, as capture's saves are: the primary is
    // marked by its fill and its place at the end.
    return ResponsivePair(
      stacksOnCompact: false,
      matchesHeights: true,
      gap: Space.x2,
      start: secondary,
      end: primary,
    );
  }
}
