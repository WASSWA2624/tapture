import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/context_state.dart';
import 'context_picker_sheet.dart';
import 'context_providers.dart';
import 'pinned_fields_sheet.dart';

/// Opens a project-bound overview, then the existing context editor selected.
Future<void> showContextValuesSheet({
  required BuildContext context,
  required String projectId,
}) async {
  if (projectId.isEmpty) return;
  final ProviderContainer container = ProviderScope.containerOf(
    context,
    listen: false,
  );
  final ModalRoute<Object?>? callerRoute = ModalRoute.of(context);
  // Setup is modal to the whole app, outside the shell's bounded body.
  final BuildContext modalContext = Navigator.of(
    context,
    rootNavigator: true,
  ).context;
  bool stale = false;
  final ProviderSubscription<String?> owner = container.listen(
    currentProjectProvider,
    (String? previous, String? next) {
      if (previous != next) stale = true;
    },
  );
  // Keep the same live snapshots through the overview's exit animation.
  final stateOwner = container.listen(
    projectContextProvider(projectId),
    (_, _) {},
  );
  final templatesOwner = container.listen(
    contextTemplatesProvider(projectId),
    (_, _) {},
  );
  ModalRoute<_ContextSelection>? overviewRoute;
  try {
    final _ContextSelection? selected = await showAppSheet<_ContextSelection>(
      modalContext,
      title: Copy.of(context).captureContextValues,
      builder: (BuildContext sheetContext) {
        overviewRoute = ModalRoute.of<_ContextSelection>(sheetContext);
        return _ContextValuesView(projectId: projectId);
      },
    );
    // A pop result precedes its exit animation. Wait for removal so two
    // modal surfaces never overlap and focus returns to the caller first.
    await overviewRoute?.completed;
    if (!context.mounted ||
        stale ||
        selected == null ||
        (callerRoute != null && !callerRoute.isCurrent)) {
      return;
    }
    final ContextState? state = container
        .read(projectContextProvider(projectId))
        .asData
        ?.value;
    final List<TemplateDef>? templates = container
        .read(contextTemplatesProvider(projectId))
        .asData
        ?.value;
    switch (selected.action) {
      case _ContextAction.level:
        if (state == null) return;
        for (final ContextLevel level in orderedLevels(state)) {
          if (level.fieldKey == selected.fieldKey) {
            await showContextPickerSheet(
              context: modalContext,
              projectId: projectId,
              level: level,
              currentValue: state.values[level.fieldKey] ?? '',
            );
            return;
          }
        }
      case _ContextAction.pin:
        if (state == null || templates == null) return;
        for (final FieldDef field in pinnableFields(templates, state)) {
          if (field.fieldKey == selected.fieldKey) {
            await showPinPickerSheet(
              context: modalContext,
              projectId: projectId,
              field: field,
              currentValue: state.pinned[field.fieldKey] ?? '',
            );
            return;
          }
        }
        if (state.pinned.containsKey(selected.fieldKey)) {
          await showPinnedFieldsSheet(
            context: modalContext,
            projectId: projectId,
          );
        }
      case _ContextAction.manage:
        await context.push<void>(RoutePaths.projectContext(projectId));
      case _ContextAction.presets:
        await context.push<void>(RoutePaths.projectContextPresets(projectId));
      case _ContextAction.pins:
        await showPinnedFieldsSheet(
          context: modalContext,
          projectId: projectId,
        );
    }
  } finally {
    owner.close();
    stateOwner.close();
    templatesOwner.close();
  }
}

enum _ContextAction { level, pin, manage, presets, pins }

final class _ContextSelection {
  const _ContextSelection(this.action, [this.fieldKey]);
  final _ContextAction action;
  final String? fieldKey;
}

class _ContextValuesView extends ConsumerWidget {
  const _ContextValuesView({required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy copy = Copy.of(context);
    final AsyncValue<ContextState> state = ref.watch(
      projectContextProvider(projectId),
    );
    final AsyncValue<List<TemplateDef>> templates = ref.watch(
      contextTemplatesProvider(projectId),
    );
    void select(_ContextAction action, [String? key]) =>
        Navigator.of(context).pop(_ContextSelection(action, key));
    return ListView(
      key: const ValueKey<String>('context-values-overview'),
      // Rows announce their own labels and actions, including grouped levels.
      addSemanticIndexes: false,
      children: <Widget>[
        AsyncValueView<ContextState>(
          value: state,
          onRetry: () => ref.invalidate(projectContextProvider(projectId)),
          data: (ContextState state) => AsyncValueView<List<TemplateDef>>(
            value: templates,
            onRetry: () => ref.invalidate(contextTemplatesProvider(projectId)),
            isEmpty: (List<TemplateDef> templates) =>
                state.isEmpty && pinnableFields(templates, state).isEmpty,
            empty: () => AppEmptyState(
              icon: AppIcons.context,
              headline: copy.contextHierarchyEmptyHeadline,
              message: copy.contextHierarchyEmptyMessage,
              actionLabel: copy.contextSetUp,
              onAction: () => select(_ContextAction.manage),
            ),
            data: (List<TemplateDef> templates) => Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final ContextLevel level in orderedLevels(state))
                  AppListTile(
                    key: ValueKey<String>(
                      'context-values-level-${level.fieldKey}',
                    ),
                    title: contextLevelName(level),
                    subtitle: _value(state.values[level.fieldKey], copy),
                    leading: const Icon(AppIcons.context),
                    trailing: const Icon(AppIcons.open),
                    wrapText: true,
                    onTap: () => select(_ContextAction.level, level.fieldKey),
                  ),
                for (final String key in <String>{
                  ...state.pinned.keys,
                  for (final FieldDef field in pinnableFields(templates, state))
                    field.fieldKey,
                })
                  AppListTile(
                    key: ValueKey<String>('context-values-pin-$key'),
                    title: pinnedFieldLabel(templates, key),
                    subtitle: copy.contextPinnedValue(
                      pinnedFieldLabel(templates, key),
                      _value(state.pinned[key], copy),
                    ),
                    leading: const Icon(AppIcons.pin),
                    trailing: const Icon(AppIcons.open),
                    wrapText: true,
                    onTap: () => select(_ContextAction.pin, key),
                  ),
              ],
            ),
          ),
        ),
        AppListTile(
          key: const ValueKey<String>('context-values-manage'),
          title: state.asData?.value.levels.isNotEmpty ?? false
              ? copy.contextManage
              : copy.contextSetUp,
          leading: const Icon(AppIcons.context),
          trailing: const Icon(AppIcons.open),
          wrapText: true,
          onTap: () => select(_ContextAction.manage),
        ),
        AppListTile(
          key: const ValueKey<String>('context-values-presets'),
          title: copy.contextPresetsChip,
          leading: const Icon(AppIcons.preset),
          trailing: const Icon(AppIcons.open),
          wrapText: true,
          onTap: () => select(_ContextAction.presets),
        ),
        AppListTile(
          key: const ValueKey<String>('context-values-pins'),
          title: copy.contextPinnedTitle,
          leading: const Icon(AppIcons.pin),
          trailing: const Icon(AppIcons.open),
          wrapText: true,
          onTap: () => select(_ContextAction.pins),
        ),
      ],
    );
  }
}

String _value(String? value, LocalizedCopy copy) =>
    value == null || value.isEmpty ? copy.contextValueNotSet : value;
