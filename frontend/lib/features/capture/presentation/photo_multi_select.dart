import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';

/// Multi-select chrome: live count, select-all and clear.
final class PhotoMultiSelect extends StatelessWidget {
  /// Creates multi-select controls.
  const PhotoMultiSelect({
    required this.selectedIds,
    required this.allIds,
    required this.onChanged,
    super.key,
  });

  /// Current selection.
  final Set<String> selectedIds;

  /// Every photo id in the tray.
  final List<String> allIds;

  /// Selection update.
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return Row(
      children: <Widget>[
        Text(localCopy.captureSelectedCount(selectedIds.length)),
        const Spacer(),
        TextButton(
          onPressed: () => onChanged(allIds.toSet()),
          child: Text(localCopy.captureSelectAll),
        ),
        TextButton(
          onPressed: () => onChanged(<String>{}),
          child: Text(localCopy.captureClearSelection),
        ),
      ],
    );
  }
}
