import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';

part 'app_chip_row.dart';

/// Compact labelled value. Plain chips only display; [onTap] and
/// [onDismiss] are what make a chip interactive and 48dp (FE-A11Y-01).
///
/// Context bars, filter bars and multi-choice fields compose this instead
/// of a raw [Chip].
class AppChip extends StatelessWidget {
  /// Creates a chip. With neither callback the chip is not a tap target.
  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.onDismiss,
  });

  /// Visible text; also the semantic name of an interactive chip
  /// (FE-A11Y-02).
  final String label;

  /// Optional leading glyph. Selection still carries a tick (FE-A11Y-05).
  final IconData? icon;

  /// When true, the chip is filled and shows a tick as well as a tint.
  final bool selected;

  /// Selects or opens the thing this chip names. Null means not tappable.
  final VoidCallback? onTap;

  /// Removes the chip. Null means it cannot be dismissed.
  final VoidCallback? onDismiss;

  bool get _interactive => onTap != null || onDismiss != null;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color background = selected ? colors.primary : colors.surfaceVariant;
    final Color foreground = selected ? colors.onPrimary : colors.onSurface;
    final Widget pill = Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.pill),
        side: BorderSide(
          color: colors.outline,
          width: Space.x0 / 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: Space.x2,
          end: onDismiss == null ? Space.x2 : Space.x0,
          top: Space.x0,
          bottom: Space.x0,
        ),
        child: _labelRow(foreground),
      ),
    );
    if (!_interactive) {
      return pill;
    }
    return Semantics(
      button: onTap != null,
      selected: selected,
      enabled: onTap != null || onDismiss != null,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          excludeFromSemantics: true,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.pill),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: Sizes.minTapTarget,
              minWidth: Sizes.minTapTarget,
            ),
            child: Align(widthFactor: 1, heightFactor: 1, child: pill),
          ),
        ),
      ),
    );
  }

  Widget _labelRow(Color foreground) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool bounded = constraints.maxWidth.isFinite;
        final Widget text = Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.label.copyWith(color: foreground),
        );
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (selected) ...<Widget>[
              Icon(Icons.check, color: foreground, size: Space.x4),
              const SizedBox(width: Space.x1),
            ] else if (icon != null) ...<Widget>[
              Icon(icon, color: foreground, size: Space.x4),
              const SizedBox(width: Space.x1),
            ],
            if (bounded) Flexible(child: text) else text,
            if (onDismiss != null)
              AppIconButton(
                icon: Icons.close,
                semanticLabel: Copy.dismissChip(label),
                tooltip: Copy.dismissChip(label),
                onPressed: onDismiss,
              ),
          ],
        );
      },
    );
  }
}
