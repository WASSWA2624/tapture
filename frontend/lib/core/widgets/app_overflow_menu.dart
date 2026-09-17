import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';

part 'app_overflow_action.dart';

/// Vertical three-dot control that opens a labelled overflow menu.
///
/// Title-bar actions outside this menu stay icon-only. Every row in the
/// sheet carries an [AppOverflowAction.label].
class AppOverflowMenu extends StatelessWidget {
  /// Creates the control. [items] is the menu; empty is a no-op icon.
  const AppOverflowMenu({
    super.key,
    required this.items,
    this.inverted = false,
  });

  /// Labelled commands shown when the control is opened.
  final List<AppOverflowAction> items;

  /// When true, the icon sits on a primary fill (status line, branded bar).
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color iconColor = inverted ? colors.onPrimary : colors.onSurface;
    return Semantics(
      button: true,
      enabled: items.isNotEmpty,
      label: Copy.overflowMenu,
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(
          width: Sizes.minTapTarget,
          height: Sizes.minTapTarget,
        ),
        child: PopupMenuButton<int>(
          tooltip: Copy.overflowMenu,
          enabled: items.isNotEmpty,
          padding: EdgeInsets.zero,
          offset: const Offset(0, Sizes.minTapTarget),
          color: colors.surface,
          elevation: 0,
          shadowColor: const Color(0x00000000),
          surfaceTintColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
            side: BorderSide(color: colors.outline, width: Space.x0 / 2),
          ),
          icon: Icon(
            Icons.more_vert,
            size: Space.x6,
            color: iconColor,
            semanticLabel: Copy.overflowMenu,
          ),
          onSelected: (int index) => items[index].onTap(),
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry<int>>[
              for (int index = 0; index < items.length; index++)
                PopupMenuItem<int>(
                  key: items[index].key,
                  value: index,
                  height: Sizes.minTapTarget,
                  child: _OverflowRow(action: items[index]),
                ),
            ];
          },
        ),
      ),
    );
  }
}

class _OverflowRow extends StatelessWidget {
  const _OverflowRow({required this.action});

  final AppOverflowAction action;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Sizes.minTapTarget),
      child: Row(
        children: <Widget>[
          if (action.icon != null) ...<Widget>[
            Icon(action.icon, size: Space.x6, color: colors.onSurface),
            const SizedBox(width: Space.x3),
          ],
          Expanded(
            child: Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body.copyWith(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
