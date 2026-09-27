import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/bundle/bundle_manifest.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/quality/quality.dart'
    hide ConflictChoice, FieldConflict;
import 'package:tapture/features/settings/settings.dart';

import '../domain/compatibility_issue.dart';
import '../domain/compatibility_status.dart';
import '../domain/conflict_choice.dart';
import '../domain/field_conflict.dart';
import '../domain/package_import_repository.dart';
import '../domain/template_match.dart';
import 'compatibility_pill.dart';
import 'duplicate_pair_sheet.dart';
import 'merge_controller.dart';
import 'merge_labels.dart';
import 'merge_view.dart';
import 'package_import_controller.dart';

/// The merge preview (task 076, W20 to W22, specification §48.1): the
/// package, whether its templates fit, what the merge would do, and the
/// possible duplicates. Nothing is written until Merge (FE-STATE-07).
final class MergePreviewScreen extends ConsumerWidget {
  /// Creates the preview of merging the open package into [projectId].
  const MergePreviewScreen({required this.projectId, super.key});

  /// The project the package merges into.
  final String projectId;

  /// The primary action: settle conflicts, then merge.
  static const ValueKey<String> applyKey = ValueKey<String>('merge-apply');

  /// Leaves without writing anything.
  static const ValueKey<String> cancelKey = ValueKey<String>('merge-cancel');

  /// The duplicate check's switch.
  static const ValueKey<String> duplicatesKey = ValueKey<String>(
    'merge-check-duplicates',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<MergeView?> value = ref.watch(
      mergeControllerProvider(projectId),
    );
    final MergeView? view = value.asData?.value;
    return PopScope(
      canPop: !(view?.applying ?? false),
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) {
          // A page the router removes pops while it rebuilds; close the
          // package once that frame is done.
          final PackageImportController flow = ref.read(
            packageImportControllerProvider.notifier,
          );
          unawaited(Future<void>.microtask(flow.finish));
        }
      },
      child: AppPage(
        key: const ValueKey<String>('route-project-merge'),
        title: Copy.mergePackage,
        footer: view == null ? null : _footer(context, ref, view),
        body: AsyncValueView<MergeView?>(
          value: value,
          isEmpty: (MergeView? view) => view == null,
          empty: () => const AppEmptyState(
            icon: AppIcons.import,
            headline: Copy.mergeNoPackageHeadline,
            message: Copy.mergeNoPackageMessage,
          ),
          onRetry: () => ref.invalidate(mergeControllerProvider(projectId)),
          data: (MergeView? view) =>
              _Preview(projectId: projectId, view: view!),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, WidgetRef ref, MergeView view) {
    final int open = view.unsettled.length;
    final bool ready = view.report.canMerge && !view.plan.isEmpty;
    return Row(
      children: <Widget>[
        AppButton(
          key: cancelKey,
          label: Copy.cancel,
          variant: AppButtonVariant.secondary,
          onPressed: view.applying ? null : () => context.pop(),
        ),
        const SizedBox(width: Space.x3),
        Expanded(
          child: AppPrimaryAction(
            key: applyKey,
            label: open > 0 ? Copy.mergeSettleConflicts(open) : Copy.mergeApply,
            busy: view.applying,
            onPressed: !ready
                ? null
                : open > 0
                ? () => unawaited(
                    context.push(RoutePaths.projectMergeConflicts(projectId)),
                  )
                : () => unawaited(_apply(context, ref)),
          ),
        ),
      ],
    );
  }

  Future<void> _apply(BuildContext context, WidgetRef ref) async {
    final String name = ref.read(currentOperatorProvider)?.name.trim() ?? '';
    final Result<MergeOutcome> merged = await ref
        .read(mergeControllerProvider(projectId).notifier)
        .apply(chooser: name.isEmpty ? Copy.conflictThisDevice : name);
    if (!context.mounted) {
      return;
    }
    switch (merged) {
      case FailureResult<MergeOutcome>(:final Failure failure):
        showAppSnack(context, failure.message, tone: SnackTone.error);
      case Success<MergeOutcome>():
        // Leave first, then close the package, so the preview never shows
        // an empty state on its way out.
        final PackageImportController flow = ref.read(
          packageImportControllerProvider.notifier,
        );
        showAppSnack(context, Copy.mergeDone, tone: SnackTone.success);
        context.go(RoutePaths.project(projectId));
        unawaited(Future<void>.microtask(flow.finish));
    }
  }
}

class _Preview extends ConsumerWidget {
  const _Preview({required this.projectId, required this.view});

  final String projectId;
  final MergeView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BundleManifest manifest = view.bundle.manifest;
    final Set<String> expanded = ref.watch(_expandedProvider(projectId));
    void toggle(String count) =>
        ref.read(_expandedProvider(projectId).notifier).toggle(count);
    final MergeController controller = ref.read(
      mergeControllerProvider(projectId).notifier,
    );
    final ({
      int newRecords,
      int updatedRecords,
      int newPhotos,
      int photosHere,
      int deletions,
      int kept,
      int elsewhere,
    })
    counts = view.plan.counts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppListTile(
          title: manifest.projectName,
          subtitle: Copy.importFrom(
            manifest.operatorName ?? manifest.sourceDeviceId,
            manifest.exportedAt,
          ),
          leading: const Icon(AppIcons.import),
        ),
        if (view.report.templates.isNotEmpty) ...<Widget>[
          const AppSectionHeader(title: Copy.mergeTemplatesHeading),
          for (final TemplateMatch match in view.report.templates)
            _TemplateRow(match: match),
        ],
        if (view.plan.projectKept.isNotEmpty)
          AppListTile(
            key: const ValueKey<String>('merge-project-kept'),
            dense: true,
            title: Copy.mergeProjectKept(view.plan.projectKept),
          ),
        if (!view.report.canMerge)
          const _Note(text: Copy.mergeBlocked, error: true)
        else if (view.plan.isEmpty)
          const _Note(text: Copy.mergeNothing),
        const AppSectionHeader(title: Copy.mergeCountsHeading),
        _Count(
          name: 'newRecords',
          n: counts.newRecords,
          expanded: expanded.contains('newRecords'),
          onToggle: () => toggle('newRecords'),
          children: <Widget>[
            for (final String id in view.plan.insertedRecords)
              AppListTile(
                dense: true,
                title: mergeRecordLabel(view.bundle.tables, id),
              ),
          ],
        ),
        _Count(
          name: 'updatedRecords',
          n: counts.updatedRecords,
          expanded: expanded.contains('updatedRecords'),
          onToggle: () => toggle('updatedRecords'),
          children: <Widget>[
            for (final String id in view.plan.updatedRecords)
              AppListTile(dense: true, title: mergeRecordLabel(view.local, id)),
          ],
        ),
        _Count(name: 'newPhotos', n: counts.newPhotos),
        _Count(name: 'photosHere', n: counts.photosHere),
        _Count(name: 'deletions', n: counts.deletions),
        _Count(
          name: 'conflicts',
          n: view.plan.conflicts.length,
          expanded: expanded.contains('conflicts'),
          onToggle: () => toggle('conflicts'),
          children: <Widget>[
            for (final FieldConflict conflict in view.plan.conflicts)
              _ConflictRow(
                projectId: projectId,
                conflict: conflict,
                choice: view.choices[conflict.id],
              ),
          ],
        ),
        AppSwitchTile(
          key: MergePreviewScreen.duplicatesKey,
          title: Copy.mergeCheckDuplicates,
          description: Copy.mergeCheckDuplicatesHelper,
          value: view.checkDuplicates,
          enabled: !view.applying,
          onChanged: (bool on) => unawaited(controller.setCheckDuplicates(on)),
        ),
        if (view.checkDuplicates)
          _Count(
            name: 'duplicates',
            n: view.duplicates.length,
            expanded: expanded.contains('duplicates'),
            onToggle: () => toggle('duplicates'),
            children: <Widget>[
              for (final PossibleDuplicate pair in view.duplicates)
                AppListTile(
                  key: ValueKey<String>('merge-duplicate-${pair.incomingId}'),
                  dense: true,
                  title: mergeRecordLabel(view.bundle.tables, pair.incomingId),
                  subtitle: view.skipped.contains(pair.incomingId)
                      ? Copy.duplicateSkipped
                      : Copy.duplicateSignal(pair.signal.name),
                  trailing: const Icon(AppIcons.open),
                  onTap: () => unawaited(
                    showDuplicatePairSheet(
                      context,
                      projectId: projectId,
                      pair: pair,
                    ),
                  ),
                ),
            ],
          ),
        _Count(name: 'kept', n: counts.kept),
        if (counts.elsewhere > 0)
          _Count(name: 'elsewhere', n: counts.elsewhere),
      ],
    );
  }
}

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({required this.match});

  final TemplateMatch match;

  @override
  Widget build(BuildContext context) {
    final CompatibilityStatus status = match.blocks
        ? CompatibilityStatus.incompatible
        : match.issues.isEmpty
        ? CompatibilityStatus.compatible
        : CompatibilityStatus.compatibleWithDifferences;
    return AppListTile(
      key: ValueKey<String>('merge-template-${match.incomingId}'),
      title: match.name,
      subtitle: match.issues.isEmpty
          ? null
          : <String>[
              for (final ({CompatibilityIssue issue, String field}) found
                  in match.issues)
                Copy.compatibilityIssue(found.issue.name, found.field),
            ].join('\n'),
      status: compatibilityPill(status),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({
    required this.name,
    required this.n,
    this.expanded = false,
    this.onToggle,
    this.children = const <Widget>[],
  });

  final String name;
  final int n;
  final bool expanded;
  final VoidCallback? onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final String title = Copy.mergeCount(name, n);
    if (children.isEmpty) {
      return AppListTile(
        key: ValueKey<String>('merge-count-$name'),
        dense: true,
        title: title,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          key: ValueKey<String>('merge-count-$name'),
          title: title,
          dense: true,
          expanded: expanded,
          onToggle: onToggle,
        ),
        if (expanded) ...children,
      ],
    );
  }
}

class _ConflictRow extends StatelessWidget {
  const _ConflictRow({
    required this.projectId,
    required this.conflict,
    required this.choice,
  });

  final String projectId;
  final FieldConflict conflict;
  final ConflictChoice? choice;

  @override
  Widget build(BuildContext context) {
    final ConflictChoice? choice = this.choice;
    return AppListTile(
      key: ValueKey<String>('merge-conflict-${conflict.id}'),
      dense: true,
      title: Copy.mergeConflictLine(
        conflict.recordLabel.isEmpty
            ? Copy.mergeRecordUnnamed(conflict.recordId)
            : conflict.recordLabel,
        Copy.conflictKind(conflict.kind.name, conflict.fieldLabel),
      ),
      subtitle: choice == null
          ? Copy.mergeConflictOpen
          : Copy.mergeConflictChosen(incoming: choice == ConflictChoice.theirs),
      trailing: const Icon(AppIcons.open),
      onTap: () => unawaited(
        context.push(
          RoutePaths.projectMergeConflicts(projectId, conflictId: conflict.id),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            error ? AppIcons.error : AppIcons.info,
            color: error ? context.colors.danger : context.colors.onSurface,
          ),
          const SizedBox(width: Space.x2),
          Expanded(
            child: Text(text, style: AppText.body, key: ValueKey<String>(text)),
          ),
        ],
      ),
    );
  }
}

/// Which of the preview's counts are open, on this visit.
final _expandedProvider = NotifierProvider.autoDispose
    .family<_Expanded, Set<String>, String>(_Expanded.new);

final class _Expanded extends Notifier<Set<String>> {
  _Expanded(this.projectId);

  final String projectId;

  @override
  Set<String> build() => const <String>{};

  void toggle(String count) {
    state = state.contains(count)
        ? <String>{
            for (final String open in state)
              if (open != count) open,
          }
        : <String>{...state, count};
  }
}
