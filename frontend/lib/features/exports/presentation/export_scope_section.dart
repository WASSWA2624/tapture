import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';

/// The five export scopes and a live record count (task 018).
///
/// [count] is computed by the parent, never inside this build.
final class ExportScopeSection extends StatelessWidget {
  /// Creates the section.
  const ExportScopeSection({
    this.selected,
    this.count,
    this.loading = false,
    this.failure,
    this.onSelect,
    super.key,
  });

  /// The scope currently chosen.
  final ExportScopeKind? selected;

  /// Records in [selected]. Null before a count exists.
  final int? count;

  /// Whether the count is still loading.
  final bool loading;

  /// Why the scopes could not be read.
  final Failure? failure;

  /// Chooses a scope. The parent recomputes [count].
  final ValueChanged<ExportScopeKind>? onSelect;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    if (loading) {
      return const SizedBox.shrink();
    }
    if (selected == null && count == null) {
      return const AppEmptyState(
        icon: AppIcons.export,
        headline: Copy.exportEmptyHeadline,
        message: Copy.exportEmptyMessage,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final ExportScopeKind kind in ExportScopeKind.values)
          AppButton(
            key: ValueKey<String>('export-scope-${kind.name}'),
            label: _label(kind),
            variant: kind == selected
                ? AppButtonVariant.primary
                : AppButtonVariant.secondary,
            onPressed: () => onSelect?.call(kind),
          ),
        if (count != null)
          Text(
            Copy.exportCount(count!),
            key: const ValueKey<String>('export-count'),
          ),
      ],
    );
  }

  static String _label(ExportScopeKind kind) {
    return switch (kind) {
      ExportScopeKind.approved => Copy.exportScopeApproved,
      ExportScopeKind.all => Copy.exportScopeAll,
      ExportScopeKind.context => Copy.exportScopeContext,
      ExportScopeKind.dateRange => Copy.exportScopeDates,
      ExportScopeKind.filter => Copy.exportScopeFilter,
    };
  }
}
