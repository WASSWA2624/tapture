import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';

/// The one list row projects, records, templates and datasets render
/// through (FE-CONS-06). Tap opens; long-press selects (FE-CONS-10).
class AppListTile extends StatelessWidget {
  /// Creates a list row. [dense] reduces padding; the tap target stays 48dp.
  const AppListTile({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.subtitle,
    this.status,
    this.dense = false,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  /// Leading slot (avatar, thumbnail, type icon).
  final Widget? leading;

  /// Trailing slot (chevron, count, action).
  final Widget? trailing;

  /// Primary line; also the semantic name of the row (FE-A11Y-02).
  final String title;

  /// Optional supporting line under [title].
  final String? subtitle;

  /// Status pill. Always an [AppStatusPill] so colour is never mapped here
  /// (FE-CONS-06, FE-A11Y-05).
  final AppStatusPill? status;

  /// When true, vertical padding is tighter. Height still meets 48dp.
  final bool dense;

  /// Multi-select highlight. A tick is shown as well as a tint
  /// (FE-A11Y-05).
  final bool selected;

  /// Opens the row. Null means the row is not tappable.
  final VoidCallback? onTap;

  /// Selects the row. Null means long-press does nothing.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final bool interactive = onTap != null || onLongPress != null;
    final Color foreground = colors.onSurface;
    final Widget content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Sizes.minTapTarget),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Space.x4,
          vertical: dense ? Space.x1 : Space.x2,
        ),
        child: Row(
          children: <Widget>[
            if (selected) ...<Widget>[
              Icon(Icons.check, color: colors.primary, size: Space.x6),
              const SizedBox(width: Space.x3),
            ],
            if (leading != null) ...<Widget>[
              _LeadingWell(colors: colors, child: leading!),
              const SizedBox(width: Space.x3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (dense ? AppText.label : AppText.bodyStrong)
                        .copyWith(color: foreground),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: Space.x0),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(color: foreground),
                    ),
                  ],
                ],
              ),
            ),
            if (status != null) ...<Widget>[
              const SizedBox(width: Space.x2),
              status!,
            ],
            if (trailing != null) ...<Widget>[
              const SizedBox(width: Space.x2),
              trailing!,
            ],
          ],
        ),
      ),
    );
    return Semantics(
      button: onTap != null,
      selected: selected,
      enabled: interactive,
      label: title,
      hint: subtitle,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Material(
        color: selected ? colors.surfaceVariant : colors.surface,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colors.outline, width: Space.x0 / 2),
            ),
          ),
          child: interactive
              ? InkWell(onTap: onTap, onLongPress: onLongPress, child: content)
              : content,
        ),
      ),
    );
  }
}

class _LeadingWell extends StatelessWidget {
  const _LeadingWell({required this.colors, required this.child});

  final AppColors colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Sizes.minTapTarget,
      height: Sizes.minTapTarget,
      child: ClipOval(
        child: ColoredBox(
          color: colors.surfaceVariant,
          child: Center(child: child),
        ),
      ),
    );
  }
}
