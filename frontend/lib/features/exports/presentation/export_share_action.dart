import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// Shares a recorded export, or says the file is gone (task 018).
final class ExportShareAction extends StatelessWidget {
  /// Creates the action.
  const ExportShareAction({
    this.path,
    this.missing = false,
    this.loading = false,
    this.empty = false,
    this.failure,
    this.onShare,
    this.onRerun,
    super.key,
  });

  /// Recorded path. Sharing does not rebuild the file.
  final String? path;

  /// Whether [path] has been deleted.
  final bool missing;

  /// Whether the share sheet is opening.
  final bool loading;

  /// Whether there is no file to share.
  final bool empty;

  /// Why sharing failed.
  final Failure? failure;

  /// Hands [path] to the system share sheet.
  final ValueChanged<String>? onShare;

  /// Offers to run the stored request again.
  final VoidCallback? onRerun;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    if (loading) {
      return const SizedBox.shrink();
    }
    if (empty || (path == null && !missing)) {
      return const AppEmptyState(
        icon: AppIcons.export,
        headline: Copy.exportHistoryEmpty,
        message: Copy.exportHistoryEmptyMessage,
      );
    }
    if (missing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            Copy.exportMissing,
            key: ValueKey<String>('export-missing'),
          ),
          AppButton(
            key: const ValueKey<String>('export-rerun'),
            label: Copy.exportRerun,
            onPressed: onRerun,
          ),
        ],
      );
    }
    return AppButton(
      key: const ValueKey<String>('export-share'),
      label: Copy.exportShare,
      onPressed: () => onShare?.call(path!),
    );
  }
}
