import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/dimensions.dart';
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
    final List<AppChip> chips = <AppChip>[
      for (final ContextLevel level in ordered)
        AppChip(
          label: _label(
            level.label.isEmpty ? level.fieldKey : level.label,
            state.values[level.fieldKey] ?? '',
            narrow: narrow,
            longest: true,
          ),
          onTap: () => showContextPickerSheet(
            context: context,
            projectId: projectId,
            level: level,
            currentValue: state.values[level.fieldKey] ?? '',
          ),
        ),
      for (final MapEntry<String, String> pin in state.pinned.entries)
        AppChip(
          label: '${pin.value} · ${Copy.contextPinMarker}',
          icon: Icons.push_pin_outlined,
          onTap: () =>
              showPinnedFieldsSheet(context: context, projectId: projectId),
        ),
    ];
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 96),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.x3,
            vertical: Space.x1,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppChipRow(chips: chips, scrollable: true),
          ),
        ),
      ),
    );
  }

  String _label(
    String name,
    String value, {
    required bool narrow,
    required bool longest,
  }) {
    if (value.isEmpty) {
      return name;
    }
    if (!narrow || value.length <= 18) {
      return '$name: $value';
    }
    return '$name: ${value.substring(0, 16)}…';
  }
}
