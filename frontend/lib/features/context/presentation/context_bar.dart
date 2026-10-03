import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/features/projects/projects.dart';
import 'package:tapture/features/templates/templates.dart';

import '../domain/context_state.dart';
import 'context_picker_sheet.dart';
import 'context_preset_list.dart';
import 'context_providers.dart';
import 'pinned_fields_sheet.dart';

/// Always-visible breadcrumb of the current context (spec §20.1).
///
/// Levels read as a path. A wider window wraps them and puts a chevron
/// between levels. A phone keeps every chip on one scrolling line.
///
/// Levels come first, then pins, then the project's presets, each applied
/// in one tap. Elsewhere the bar shows only what is set and is hidden while
/// nothing is. On Capture, [showsEmptyLevels] also lists every unset level
/// and pinnable field so a first value can be set in place (FBK0000160, D10).
class ContextBar extends ConsumerWidget {
  /// Creates the bar.
  const ContextBar({this.showsEmptyLevels = false, super.key});

  /// When true, unset levels and pinnable fields show as "Set" chips, and
  /// Manage (or Set up context, with no levels) opens the context levels.
  final bool showsEmptyLevels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    final String? projectId = ref.watch(currentProjectProvider);
    if (projectId == null || projectId.isEmpty) {
      return const SizedBox.shrink();
    }
    final ContextState? state = ref
        .watch(projectContextProvider(projectId))
        .asData
        ?.value;
    if (state == null) {
      return const SizedBox.shrink();
    }
    final List<TemplateDef> templates =
        ref.watch(contextTemplatesProvider(projectId)).asData?.value ??
        const <TemplateDef>[];
    final List<AppChip> levels = _levelChips(context, projectId, state);
    final List<AppChip> pins = _pinChips(context, projectId, state, templates);
    if (levels.isEmpty && pins.isEmpty && !showsEmptyLevels) {
      return const SizedBox.shrink();
    }
    final List<ContextPreset> presets = state.levels.isEmpty
        ? const <ContextPreset>[]
        : ref.watch(contextPresetsProvider(projectId)).asData?.value ??
              const <ContextPreset>[];
    void open(String path) => unawaited(GoRouter.of(context).push(path));
    final bool compact = context.sizeClass == SizeClass.compact;
    final List<Widget> trail = <Widget>[
      for (int i = 0; i < levels.length; i++) ...<Widget>[
        if (i > 0 && !compact) const _ContextCrumb(),
        levels[i],
      ],
      ...pins,
      for (final ContextPreset preset in presets)
        AppChip(
          key: ValueKey<String>('context-bar-preset-${preset.id}'),
          label: preset.name,
          icon: AppIcons.preset,
          selected: preset.isAppliedTo(state),
          onTap: () => unawaited(
            applyContextPreset(
              context,
              ref,
              projectId: projectId,
              preset: preset,
            ),
          ),
        ),
      if (state.levels.isNotEmpty)
        AppChip(
          key: const ValueKey<String>('context-bar-presets'),
          label: localCopy.contextPresetsChip,
          icon: AppIcons.preset,
          onTap: () => open(RoutePaths.projectContextPresets(projectId)),
        ),
      if (showsEmptyLevels)
        AppChip(
          key: ValueKey<String>(
            state.levels.isEmpty ? 'context-bar-set-up' : 'context-bar-manage',
          ),
          label: state.levels.isEmpty
              ? localCopy.contextSetUp
              : localCopy.contextManage,
          icon: AppIcons.context,
          onTap: () => open(RoutePaths.projectContext(projectId)),
        ),
    ];
    return DecoratedBox(
      key: const ValueKey<String>('context-bar'),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(
            color: context.colors.outline,
            width: Space.x0 / 2,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.x3,
          vertical: Space.x1,
        ),
        child: _ContextTrail(scrollable: compact, children: trail),
      ),
    );
  }

  /// One chip per level from the root down: its value, or on Capture a Set
  /// chip naming it. Each opens that level's picker.
  List<AppChip> _levelChips(
    BuildContext context,
    String projectId,
    ContextState state,
  ) {
    final LocalizedCopy localCopy = Copy.of(context);

    final List<ContextLevel> levels = orderedLevels(state);
    final List<String> shown = _truncateMiddle(<String>[
      for (final ContextLevel level in levels)
        state.values[level.fieldKey] ?? '',
    ], narrow: context.sizeClass == SizeClass.compact);
    return <AppChip>[
      for (int i = 0; i < levels.length; i++)
        if (showsEmptyLevels || shown[i].isNotEmpty)
          AppChip(
            key: ValueKey<String>('context-bar-level-${levels[i].fieldKey}'),
            label: shown[i].isEmpty
                ? localCopy.contextSetLevel(contextLevelName(levels[i]))
                : localCopy.contextLevelValue(
                    contextLevelName(levels[i]),
                    shown[i],
                  ),
            selected: shown[i].isNotEmpty,
            onTap: () => unawaited(
              showContextPickerSheet(
                context: context,
                projectId: projectId,
                level: levels[i],
                currentValue: state.values[levels[i].fieldKey] ?? '',
              ),
            ),
          ),
    ];
  }

  /// Pinned values, marked with the pin glyph and named by their field; on
  /// Capture also each pinnable field not yet set. A chip opens its picker.
  List<AppChip> _pinChips(
    BuildContext context,
    String projectId,
    ContextState state,
    List<TemplateDef> templates,
  ) {
    final LocalizedCopy localCopy = Copy.of(context);

    final List<FieldDef> pinnable = pinnableFields(templates, state);
    final Set<String> keys = <String>{
      for (final MapEntry<String, String> pin in state.pinned.entries)
        if (pin.value.isNotEmpty) pin.key,
      if (showsEmptyLevels)
        for (final FieldDef field in pinnable) field.fieldKey,
    };
    FieldDef? fieldOf(String key) {
      for (final FieldDef field in pinnable) {
        if (field.fieldKey == key) {
          return field;
        }
      }
      return null;
    }

    return <AppChip>[
      for (final String key in keys)
        AppChip(
          key: ValueKey<String>('context-bar-pin-$key'),
          icon: AppIcons.pin,
          selected: (state.pinned[key] ?? '').isNotEmpty,
          label: (state.pinned[key] ?? '').isEmpty
              ? localCopy.contextSetLevel(pinnedFieldLabel(templates, key))
              : localCopy.contextPinnedValue(
                  pinnedFieldLabel(templates, key),
                  state.pinned[key]!,
                ),
          onTap: () {
            final FieldDef? field = fieldOf(key);
            unawaited(
              field == null
                  ? showPinnedFieldsSheet(
                      context: context,
                      projectId: projectId,
                    )
                  : showPinPickerSheet(
                      context: context,
                      projectId: projectId,
                      field: field,
                      currentValue: state.pinned[key] ?? '',
                    ),
            );
          },
        ),
    ];
  }
}

/// Levels, pins and actions: one scrolling line on a phone, wrapped when
/// there is room. A chevron sits between hierarchy levels only.
class _ContextTrail extends StatelessWidget {
  const _ContextTrail({required this.scrollable, required this.children});

  final bool scrollable;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < children.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: Space.x1),
              children[i],
            ],
          ],
        ),
      );
    }
    return Wrap(
      spacing: Space.x2,
      runSpacing: Space.x2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

/// The mark between two context levels, so the bar reads as a path.
class _ContextCrumb extends StatelessWidget {
  const _ContextCrumb();

  @override
  Widget build(BuildContext context) {
    final Widget mark = Icon(
      AppIcons.open,
      size: Space.x4,
      color: context.colors.onSurfaceMuted,
    );
    if (Directionality.of(context) == TextDirection.rtl) {
      return Transform.flip(flipX: true, child: mark);
    }
    return mark;
  }
}

/// Shortens the longest middle value first on a narrow window.
List<String> _truncateMiddle(List<String> values, {required bool narrow}) {
  if (!narrow || values.length < 3) {
    return values;
  }
  final List<String> next = List<String>.of(values);
  int longest = 1;
  for (int i = 2; i < next.length - 1; i++) {
    if (next[i].length > next[longest].length) {
      longest = i;
    }
  }
  final int cap = AppConstants.context.valuePreview;
  if (next[longest].length > cap) {
    next[longest] = '${next[longest].substring(0, cap - 1)}…';
  }
  return next;
}
