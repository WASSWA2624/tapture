import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';

/// Template chooser: recent first, then name. Hidden when only one template.
final class TemplatePickerSheet extends StatelessWidget {
  /// Creates a sheet. Returns [SizedBox.shrink] when [templates] length ≤ 1.
  const TemplatePickerSheet({
    required this.templates,
    required this.onSelected,
    this.pinnedId,
    this.onPinSession,
    this.onPinContext,
    super.key,
  });

  /// (id, name, lastUsedMs) — already sorted by caller (recent then name).
  final List<({String id, String name, int lastUsedMs})> templates;

  /// Chosen template.
  final ValueChanged<String> onSelected;

  /// Currently pinned id.
  final String? pinnedId;

  /// Pin for session.
  final ValueChanged<String>? onPinSession;

  /// Pin for context level.
  final ValueChanged<String>? onPinContext;

  @override
  Widget build(BuildContext context) {
    if (templates.length <= 1) {
      return const SizedBox.shrink();
    }
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(Copy.capturePickTemplate),
        ),
        for (final t in templates)
          ListTile(
            title: Text(t.name),
            selected: t.id == pinnedId,
            onTap: () => onSelected(t.id),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  tooltip: Copy.capturePinSession,
                  onPressed: () => onPinSession?.call(t.id),
                  icon: const Icon(Icons.push_pin_outlined),
                ),
                IconButton(
                  tooltip: Copy.capturePinContext,
                  onPressed: () => onPinContext?.call(t.id),
                  icon: const Icon(Icons.pin_drop_outlined),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
