import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';

/// The labelled commands of one row in a meeting list: moves where the row
/// can move, and a removal that is confirmed first (FE-CONS-06).
final class MeetingRowMenu extends StatelessWidget {
  /// Creates the menu. [onMoveUp] and [onMoveDown] are left out where the
  /// row cannot move that way.
  const MeetingRowMenu({
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
    super.key,
  });

  /// Takes the row off the list, once confirmed.
  final VoidCallback onRemove;

  /// Moves the row one place earlier.
  final VoidCallback? onMoveUp;

  /// Moves the row one place later.
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final VoidCallback? up = onMoveUp;
    final VoidCallback? down = onMoveDown;
    return AppOverflowMenu(
      items: <AppOverflowAction>[
        if (up != null)
          AppOverflowAction(
            label: localCopy.meetingMoveUp,
            icon: AppIcons.moveUp,
            onTap: up,
          ),
        if (down != null)
          AppOverflowAction(
            label: localCopy.meetingMoveDown,
            icon: AppIcons.moveDown,
            onTap: down,
          ),
        AppOverflowAction(
          label: localCopy.meetingRemove,
          icon: AppIcons.delete,
          onTap: () => unawaited(_remove(context)),
        ),
      ],
    );
  }

  Future<void> _remove(BuildContext context) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.meetingRemoveTitle,
      message: localCopy.meetingRemoveMessage,
      confirmLabel: localCopy.meetingRemoveConfirm,
      destructive: true,
    );
    if (confirmed) {
      onRemove();
    }
  }
}
