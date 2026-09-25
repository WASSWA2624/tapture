import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
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
    // The shared radio group (FE-CONS-01). Selected photos is offered only
    // when some are selected, so no option on screen is a dead end.
    return AppRadioGroup<CaptionScope>(
      label: Copy.captionScopeLabel,
      value: scope,
      options: <Choice<CaptionScope>>[
        Choice<CaptionScope>(
          CaptionScope.thisPhoto,
          Copy.captionScopeThis(thisCount),
        ),
        if (selectedCount > 0)
          Choice<CaptionScope>(
            CaptionScope.selected,
            Copy.captionScopeSelected(selectedCount),
          ),
        Choice<CaptionScope>(CaptionScope.all, Copy.captionScopeAll(allCount)),
      ],
      onChanged: onChanged,
    );
  }
}
