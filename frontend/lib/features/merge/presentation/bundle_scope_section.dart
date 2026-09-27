import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// The five bundle scopes and the estimated size (task 019).
///
/// [sizeLabel] is computed by the parent, never inside this build.
final class BundleScopeSection extends StatelessWidget {
  /// Creates the section.
  const BundleScopeSection({
    this.selected,
    this.sizeLabel,
    this.loading = false,
    this.failure,
    this.onSelect,
    super.key,
  });

  /// The scope currently chosen.
  final BundleScopeKind? selected;

  /// Estimated size for [selected].
  final String? sizeLabel;

  /// Whether the estimate is still loading.
  final bool loading;

  /// Why the scopes could not be read.
  final Failure? failure;

  /// Chooses a scope.
  final ValueChanged<BundleScopeKind>? onSelect;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    if (loading) {
      return const SizedBox.shrink();
    }
    if (selected == null && sizeLabel == null) {
      return const AppEmptyState(
        icon: AppIcons.export,
        headline: Copy.bundleScope,
        message: Copy.bundleScopeData,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final BundleScopeKind kind in BundleScopeKind.values)
          AppButton(
            key: ValueKey<String>('bundle-scope-${kind.name}'),
            label: _label(kind),
            variant: kind == selected
                ? AppButtonVariant.primary
                : AppButtonVariant.secondary,
            onPressed: () => onSelect?.call(kind),
          ),
        if (sizeLabel != null)
          Text(
            Copy.bundleSize(sizeLabel!),
            key: const ValueKey<String>('bundle-size'),
          ),
      ],
    );
  }

  static String _label(BundleScopeKind kind) {
    return switch (kind) {
      BundleScopeKind.full => Copy.bundleScopeFull,
      BundleScopeKind.dateRange => Copy.bundleScopeDates,
      BundleScopeKind.context => Copy.bundleScopeContext,
      BundleScopeKind.approved => Copy.bundleScopeApproved,
      BundleScopeKind.withoutPhotos => Copy.bundleScopeData,
    };
  }
}

/// What a bundle includes.
enum BundleScopeKind {
  /// Every row and file.
  full,

  /// Records in a date range.
  dateRange,

  /// The current context subtree.
  context,

  /// Approved records only.
  approved,

  /// Rows without photo files.
  withoutPhotos,
}
