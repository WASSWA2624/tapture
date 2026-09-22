import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';
import 'package:tapture/features/projects/projects.dart';

import '../domain/context_state.dart';
import 'context_picker_sheet.dart';
import 'context_providers.dart';
import 'pinned_fields_sheet.dart';

/// Always-visible breadcrumb of current context values. Hidden when empty.
class ContextBar extends ConsumerWidget {
  /// Creates the bar.
  const ContextBar({super.key});

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
        children.add(const Icon(Icons.chevron_right, size: Space.x4));
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
          icon: Icons.push_pin_outlined,
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
