import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';

import '../context.dart' show contextRepositoryProvider;
import '../domain/context_state.dart';
import 'context_preset_save.dart';
import 'context_providers.dart';

/// Lists context presets, most recently used first; a tap applies one.
class ContextPresetList extends ConsumerWidget {
  /// Creates the list.
  const ContextPresetList({super.key, this.projectId});

  /// Owning project; the open project when null.
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final String? id = projectId ?? ref.watch(currentProjectProvider);
    if (id == null || id.isEmpty) {
      return AppPage(
        title: localCopy.contextPresetsTitle,
        showAppBar: false,
        body: AppEmptyState(
          icon: AppIcons.preset,
          headline: localCopy.contextPresetsEmptyHeadline,
          message: localCopy.contextPresetsEmptyMessage,
          actionLabel: localCopy.navProjects,
          onAction: () => context.go(RoutePaths.projects),
        ),
      );
    }
    final AsyncValue<List<ContextPreset>> presets = ref.watch(
      contextPresetsProvider(id),
    );
    final ContextState state =
        ref.watch(projectContextProvider(id)).asData?.value ??
        const ContextState();
    void save() =>
        unawaited(showContextPresetSave(context: context, projectId: id));
    final bool listed = presets.asData?.value.isNotEmpty ?? false;
    return AppPage(
      title: localCopy.contextPresetsTitle,
      showAppBar: false,
      footer: listed
          ? AppPrimaryAction(
              label: localCopy.contextPresetSave,
              onPressed: save,
            )
          : null,
      body: AsyncValueView<List<ContextPreset>>(
        value: presets,
        isEmpty: (List<ContextPreset> rows) => rows.isEmpty,
        empty: () => AppEmptyState(
          icon: AppIcons.preset,
          headline: Copy.of(context).contextPresetsEmptyHeadline,
          message: Copy.of(context).contextPresetsEmptyMessage,
          actionLabel: Copy.of(context).contextPresetSave,
          onAction: save,
        ),
        onRetry: () => ref.invalidate(contextPresetsProvider(id)),
        data: (List<ContextPreset> rows) {
          final LocalizedCopy localCopy = Copy.of(context);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final ContextPreset preset in rows)
                AppListTile(
                  key: ValueKey<String>('context-preset-${preset.id}'),
                  title: preset.name,
                  subtitle: presetSummary(
                    preset,
                    localizedCopy: Copy.of(context),
                  ),
                  current: preset.isAppliedTo(state),
                  onTap: () => unawaited(
                    applyContextPreset(
                      context,
                      ref,
                      projectId: id,
                      preset: preset,
                    ),
                  ),
                  trailing: AppOverflowMenu(
                    key: ValueKey<String>('context-preset-menu-${preset.id}'),
                    items: <AppOverflowAction>[
                      AppOverflowAction(
                        label: localCopy.contextPresetDelete,
                        icon: AppIcons.delete,
                        onTap: () => unawaited(_delete(context, ref, preset)),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ContextPreset preset,
  ) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool ok = await showAppConfirm(
      context,
      title: localCopy.contextPresetDelete,
      message: localCopy.contextPresetDeleteMessage(preset.name),
      confirmLabel: localCopy.contextPresetDelete,
      destructive: true,
    );
    if (!ok) {
      return;
    }
    final Result<void> result = await ref
        .read(contextRepositoryProvider)
        .deletePreset(preset.id, reason: localCopy.contextPresetDeleteReason);
    if (!context.mounted) {
      return;
    }
    if (result case FailureResult<void>(:final Failure failure)) {
      showAppSnack(
        context,
        failure.message,
        tone: SnackTone.error,
        localizedMessage: failure.explanation,
      );
    }
  }
}

/// A preset's values and pins in one line, the way the list shows them.
String presetSummary(ContextPreset preset, {LocalizedCopy? localizedCopy}) {
  return (localizedCopy ?? Copy.english).contextBreadcrumb(<String>[
    for (final String value in <String>[
      ...preset.values.values,
      ...preset.pinned.values,
    ])
      if (value.isNotEmpty) value,
  ]);
}

/// Applies [preset] in one write, with no cascade confirmation because the
/// operator chose the whole set, then says which preset is now in force.
Future<void> applyContextPreset(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required ContextPreset preset,
}) async {
  final LocalizedCopy localCopy = Copy.of(context);

  final Result<ContextState> result = await ref
      .read(contextRepositoryProvider)
      .applyPreset(projectId, preset);
  if (!context.mounted) {
    return;
  }
  switch (result) {
    case FailureResult<ContextState>(:final Failure failure):
      showAppSnack(
        context,
        failure.message,
        tone: SnackTone.error,
        localizedMessage: failure.explanation,
      );
    case Success<ContextState>():
      showAppSnack(
        context,
        localCopy.contextPresetApplied(preset.name),
        tone: SnackTone.success,
      );
  }
}
