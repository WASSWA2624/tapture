import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';

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
    this.outlined = false,
  });

  /// Labelled commands shown when the control is opened.
  final List<AppOverflowAction> items;

  /// When true, the icon sits on a primary fill (status line, branded bar).
  final bool inverted;

  /// When true, the control draws the theme outline. The default is bare,
  /// on a title bar and in a list row. The widget style wins over the theme's.
  final bool outlined;

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
          shadowColor: _noShadow,
          surfaceTintColor: colors.surface,
          shape: _menuShape(colors),
          style: outlined ? null : _borderlessStyle(colors),
          icon: Icon(
            AppIcons.more,
            size: Space.x6,
            color: iconColor,
            semanticLabel: Copy.overflowMenu,
          ),
          onSelected: (int index) => items[index].onTap(),
          itemBuilder: (BuildContext context) => _menuItems(items),
        ),
      ),
    );
  }
}

/// Opens the rows [AppOverflowMenu] shows, anchored to [anchor] (a rectangle
/// in global coordinates), for a control that is not the title-bar three-dot
/// icon — a floating action, for example. Runs the chosen row's
/// [AppOverflowAction.onTap] once the menu has closed.
Future<void> showAppOverflowActions(
  BuildContext context, {
  required Rect anchor,
  required List<AppOverflowAction> items,
  bool useRootNavigator = true,
}) async {
  final AppColors colors = context.colors;
  final RenderBox overlay =
      Overlay.of(context, rootOverlay: true).context.findRenderObject()!
          as RenderBox;
  final int? chosen = await showMenu<int>(
    context: context,
    useRootNavigator: useRootNavigator,
    position: RelativeRect.fromRect(anchor, Offset.zero & overlay.size),
    color: colors.surface,
    elevation: 0,
    shadowColor: _noShadow,
    surfaceTintColor: colors.surface,
    shape: _menuShape(colors),
    items: _menuItems(items),
  );
  if (chosen != null) {
    items[chosen].onTap();
  }
}

/// Depth through tone and outline, not shadow (FE-THEME-06).
const Color _noShadow = Color(0x00000000);

ShapeBorder _menuShape(AppColors colors) {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.md),
    side: BorderSide(color: colors.outline, width: Space.x0 / 2),
  );
}

/// Bare ink at rest; a token surface on hover, focus and press, so the
/// control stays noticeable without a box (FE-THEME-01, FE-A11Y-06).
ButtonStyle _borderlessStyle(AppColors colors) {
  return IconButton.styleFrom(side: BorderSide.none).copyWith(
    backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused) ||
          states.contains(WidgetState.pressed)) {
        return colors.surfaceVariant;
      }
      return null;
    }),
  );
}

List<PopupMenuEntry<int>> _menuItems(List<AppOverflowAction> items) {
  return <PopupMenuEntry<int>>[
    for (int index = 0; index < items.length; index++)
      PopupMenuItem<int>(
        key: items[index].key,
        value: index,
        height: Sizes.minTapTarget,
        child: _OverflowRow(action: items[index]),
      ),
  ];
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
