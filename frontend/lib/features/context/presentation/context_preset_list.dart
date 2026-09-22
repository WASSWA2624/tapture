import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';

import '../context.dart' show contextRepositoryProvider;
import '../domain/context_state.dart';
import 'context_preset_save.dart';

/// Lists context presets, most recently used first.
class ContextPresetList extends ConsumerWidget {
  /// Creates the list.
  const ContextPresetList({super.key, this.projectId, this.failure});

  /// Owning project.
  final String? projectId;

  /// Injected failure for tests.
  final Failure? failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? id = projectId ?? ref.watch(currentProjectProvider);
    if (failure != null) {
      return AppPage(
        title: Copy.contextPresetsTitle,
        showAppBar: false,
        body: AsyncValueView<void>(
          value: AsyncValue<void>.error(failure!, StackTrace.empty),
          data: (_) => const SizedBox.shrink(),
        ),
      );
    }
    if (id == null || id.isEmpty) {
      return const AppPage(
        title: Copy.contextPresetsTitle,
        showAppBar: false,
        body: AppEmptyState(
          icon: Icons.bookmark_outline,
          headline: Copy.contextPresetsEmptyHeadline,
          message: Copy.contextPresetsEmptyMessage,
        ),
      );
    }
    final AsyncValue<List<ContextPreset>> value = ref.watch(
      contextPresetsProvider(id),
    );
    return AppPage(
      title: Copy.contextPresetsTitle,
      showAppBar: false,
      scrollable: false,
      body: AsyncValueView<List<ContextPreset>>(
        value: value,
        isEmpty: (List<ContextPreset> rows) => rows.isEmpty,
        empty: () => AppEmptyState(
          icon: Icons.bookmark_outline,
          headline: Copy.contextPresetsEmptyHeadline,
          message: Copy.contextPresetsEmptyMessage,
          actionLabel: Copy.contextPresetSave,
          onAction: () => unawaited(
            showAppSheet<void>(
              context,
              title: Copy.contextPresetSave,
              builder: (BuildContext context) =>
                  ContextPresetSave(projectId: id),
            ),
          ),
        ),
        onRetry: () => ref.invalidate(contextPresetsProvider(id)),
        data: (List<ContextPreset> rows) {
          return ListView(
            children: <Widget>[
              for (final ContextPreset preset in rows)
                AppListTile(
                  title: preset.name,
                  subtitle: <String>[
                    ...preset.values.values,
                    ...preset.pinned.values,
                  ].where((String v) => v.isNotEmpty).join(' · '),
                  onTap: () => unawaited(_apply(ref, id, preset)),
                ),
              ListTile(
                title: const Text(Copy.contextPresetSave),
                leading: const Icon(Icons.add),
                onTap: () => unawaited(
                  showAppSheet<void>(
                    context,
                    title: Copy.contextPresetSave,
                    builder: (BuildContext context) =>
                        ContextPresetSave(projectId: id),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _apply(
    WidgetRef ref,
    String projectId,
    ContextPreset preset,
  ) async {
    await ref.read(contextRepositoryProvider).applyPreset(projectId, preset);
  }
}

/// Live presets for [projectId].
final contextPresetsProvider = StreamProvider.autoDispose
    .family<List<ContextPreset>, String>((Ref ref, String projectId) {
      return ref.watch(contextRepositoryProvider).watchPresets(projectId);
    }, retry: (int _, Object _) => null);
