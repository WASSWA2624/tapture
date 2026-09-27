import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/features/projects/projects.dart';

import '../domain/context_state.dart';
import 'context_picker_sheet.dart';
import 'context_providers.dart';
import 'pinned_fields_sheet.dart';

/// Always-visible breadcrumb of current context values. Hidden when empty,
/// except on Capture, where [showsEmptyLevels] lists every level so the
/// first value can be set in place (FBK0000160, D10).
class ContextBar extends ConsumerWidget {
  /// Creates the bar. [showsEmptyLevels] shows every level of the open
  /// project, set or not, and a way to its context levels.
  const ContextBar({this.showsEmptyLevels = false, super.key});

  /// When true, levels with no value show as "Set" chips naming the level, and a
  /// Manage chip (or Set up context, with no levels) opens the project's
  /// context levels.
  final bool showsEmptyLevels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? projectId = ref.watch(currentProjectProvider);
    if (projectId == null || projectId.isEmpty) {
      return const SizedBox.shrink();
    }
    final AsyncValue<ContextState> async = ref.watch(
      projectContextProvider(projectId),
    );
    final ContextState? state = async.asData?.value;
    if (state != null && showsEmptyLevels) {
      return _EveryLevel(projectId: projectId, state: state);
    }
    if (state == null || state.isEmpty) {
      return const SizedBox.shrink();
    }
    final List<ContextLevel> ordered = List<ContextLevel>.of(state.levels)
      ..sort((ContextLevel a, ContextLevel b) => a.order.compareTo(b.order));
    final bool narrow = context.sizeClass == SizeClass.compact;
    final List<String> shown = _truncateMiddle(<String>[
      for (final ContextLevel level in ordered)
        state.values[level.fieldKey] ?? '',
    ], narrow: narrow);
    final double scale = MediaQuery.textScalerOf(context).scale(1);
    final double textLine =
        (AppText.label.fontSize ?? Space.x4) *
            (AppText.label.height ?? 1) *
            scale +
        Space.x2;
    final double line = textLine < Sizes.minTapTarget
        ? Sizes.minTapTarget
        : textLine;
    final double maxHeight =
        line * AppConstants.context.barLines + Space.x1 + Space.x2;
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < ordered.length; i++) {
      final ContextLevel level = ordered[i];
      final String name = level.label.isEmpty ? level.fieldKey : level.label;
      final String value = shown[i];
      if (value.isEmpty) {
        continue;
      }
      if (i > 0 && children.isNotEmpty) {
        children.add(const Icon(AppIcons.open, size: Space.x4));
      }
      children.add(
        AppChip(
          label: value.isEmpty ? name : '$name: $value',
          onTap: () => showContextPickerSheet(
            context: context,
            projectId: projectId,
            level: level,
            currentValue: state.values[level.fieldKey] ?? '',
          ),
        ),
      );
    }
    for (final MapEntry<String, String> pin in state.pinned.entries) {
      if (pin.value.isEmpty) {
        continue;
      }
      children.add(
        AppChip(
          label: '${pin.value} · ${Copy.contextPinMarker}',
          icon: AppIcons.pin,
          onTap: () =>
              showPinnedFieldsSheet(context: context, projectId: projectId),
        ),
      );
    }
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return Material(
      color: context.colors.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.x3,
            vertical: Space.x1,
          ),
          child: ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: Space.x1,
                runSpacing: Space.x1,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Every level of the open project in one scrolling line: its value, or
/// a "Set" chip naming the level when it has none, each opening the picker; the pinned
/// values; and Manage, which opens the project's context levels.
class _EveryLevel extends StatelessWidget {
  const _EveryLevel({required this.projectId, required this.state});

  final String projectId;
  final ContextState state;

  @override
  Widget build(BuildContext context) {
    final List<ContextLevel> ordered = List<ContextLevel>.of(state.levels)
      ..sort((ContextLevel a, ContextLevel b) => a.order.compareTo(b.order));
    void manage() => unawaited(
      GoRouter.of(context).push(RoutePaths.projectContext(projectId)),
    );
    final List<Widget> chips = <Widget>[
      for (final ContextLevel level in ordered)
        _chipFor(context, level, state.values[level.fieldKey] ?? ''),
      for (final MapEntry<String, String> pin in state.pinned.entries)
        if (pin.value.isNotEmpty)
          AppChip(
            label: '${pin.value} · ${Copy.contextPinMarker}',
            icon: AppIcons.pin,
            onTap: () =>
                showPinnedFieldsSheet(context: context, projectId: projectId),
          ),
      if (ordered.isEmpty)
        AppChip(
          key: const ValueKey<String>('context-bar-set-up'),
          label: Copy.contextSetUp,
          icon: AppIcons.context,
          onTap: manage,
        )
      else
        AppChip(
          key: const ValueKey<String>('context-bar-manage'),
          label: Copy.contextManage,
          icon: AppIcons.context,
          onTap: manage,
        ),
    ];
    return Material(
      key: const ValueKey<String>('context-bar-every-level'),
      color: context.colors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.x3,
          vertical: Space.x1,
        ),
        child: Row(
          children: <Widget>[
            for (int i = 0; i < chips.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: Space.x1),
              chips[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _chipFor(BuildContext context, ContextLevel level, String value) {
    final String name = level.label.isEmpty ? level.fieldKey : level.label;
    return AppChip(
      key: ValueKey<String>('context-bar-level-${level.fieldKey}'),
      label: value.isEmpty
          ? Copy.contextSetLevel(name)
          : Copy.contextLevelValue(name, value),
      onTap: () => showContextPickerSheet(
        context: context,
        projectId: projectId,
        level: level,
        currentValue: value,
      ),
    );
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
