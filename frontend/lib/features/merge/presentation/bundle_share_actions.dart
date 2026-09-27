import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// Share and open both go through the callbacks the platform wrapper owns.
final class BundleShareActions extends StatelessWidget {
  /// Creates the actions.
  const BundleShareActions({
    this.path,
    this.loading = false,
    this.empty = false,
    this.failure,
    this.onShare,
    this.onOpen,
    super.key,
  });

  /// The bundle to share. Opening an incoming file does not use this.
  final String? path;

  /// Whether a share sheet is opening.
  final bool loading;

  /// Whether there is no bundle yet.
  final bool empty;

  /// Why sharing failed.
  final Failure? failure;

  /// Hands [path] to the system share sheet.
  final ValueChanged<String>? onShare;

  /// Opens an incoming bundle in the import flow.
  final VoidCallback? onOpen;

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
        icon: AppIcons.export,
        headline: Copy.bundleScope,
        message: Copy.bundleScopeFull,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppButton(
          key: const ValueKey<String>('bundle-share'),
          label: Copy.bundleShare,
          onPressed: path == null ? null : () => onShare?.call(path!),
        ),
        AppButton(
          key: const ValueKey<String>('bundle-open'),
          label: Copy.bundleOpen,
          variant: AppButtonVariant.secondary,
          onPressed: onOpen,
        ),
      ],
    );
  }
}
