import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/capture/domain/caption_apply.dart';

/// Explicit caption target with exact counts on every option.
final class CaptionScopeSelector extends StatelessWidget {
  /// Creates a selector.
  const CaptionScopeSelector({
    required this.scope,
    required this.thisCount,
    required this.selectedCount,
    required this.allCount,
    required this.onChanged,
    super.key,
  });

  /// Current scope.
  final CaptionScope scope;

  /// This-photo count (0 or 1).
  final int thisCount;

  /// Selected count.
  final int selectedCount;

  /// All photos count.
  final int allCount;

  /// Scope change.
  final ValueChanged<CaptionScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(Copy.captionScopeThis(thisCount)),
          selected: scope == CaptionScope.thisPhoto,
          leading: Icon(
            scope == CaptionScope.thisPhoto
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
          ),
          onTap: () => onChanged(CaptionScope.thisPhoto),
        ),
        ListTile(
          title: Text(Copy.captionScopeSelected(selectedCount)),
          selected: scope == CaptionScope.selected,
          leading: Icon(
            scope == CaptionScope.selected
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
          ),
          onTap: selectedCount == 0
              ? null
              : () => onChanged(CaptionScope.selected),
        ),
        ListTile(
          title: Text(Copy.captionScopeAll(allCount)),
          selected: scope == CaptionScope.all,
          leading: Icon(
            scope == CaptionScope.all
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
          ),
          onTap: () => onChanged(CaptionScope.all),
        ),
      ],
    );
  }
}
