import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_status_pill.dart';
import 'package:tapture/core/widgets/trial_report_scope.dart';

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
    this.wrapText = false,
    this.selected = false,
    this.current = false,
    this.onTap,
    this.onLongPress,
  });

  /// Key of the bar a [current] row draws on its start edge.
  static const ValueKey<String> currentMarkKey = ValueKey<String>(
    'app-list-tile-current',
  );

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

  /// Allows the title and supporting text to grow with a narrow pane.
  /// Fixed-height virtualised record rows retain their single-line contract.
  final bool wrapText;

  /// Multi-select highlight. A tick is shown as well as a tint
  /// (FE-A11Y-05).
  final bool selected;

  /// The item the page beside this list shows. Drawn with the tint, a bar
  /// on the start edge and the title in the primary colour, and announced
  /// as selected, so it never rests on colour alone (FE-A11Y-05). It is
  /// independent of [selected], which is multi-select.
  final bool current;

  /// Opens the row. Null means the row is not tappable.
  final VoidCallback? onTap;

  /// Selects the row. Null means long-press does nothing.
  final VoidCallback? onLongPress;

  /// Widest share of the row the status slot may take.
  static const double _statusShare = 0.55;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final bool interactive = onTap != null || onLongPress != null;
    final Color foreground = colors.onSurface;
    final double dividerIndent =
        Space.x4 +
        (selected ? Space.x6 + Space.x3 : 0) +
        (leading != null ? Sizes.minTapTarget + Space.x3 : 0);
    final Widget content = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: dense ? Sizes.minTapTarget : Sizes.minTapTarget + Space.x6,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Space.x4,
          vertical: dense ? Space.x1 : Space.x3,
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) => Row(
            children: <Widget>[
              if (selected) ...<Widget>[
                Icon(AppIcons.check, color: colors.primary, size: Space.x6),
                const SizedBox(width: Space.x3),
              ],
              if (leading != null) ...<Widget>[
                _LeadingWell(colors: colors, child: leading!),
                const SizedBox(width: Space.x3),
              ],
              Expanded(
                // The row already announces these lines. Keep other slots
                // outside this exclusion so their meaning and actions survive.
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: wrapText ? null : 1,
                        overflow: wrapText
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: (dense ? AppText.label : AppText.bodyStrong)
                            .copyWith(
                              color: current ? colors.primary : foreground,
                            ),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: Space.x0),
                        Text(
                          subtitle!,
                          maxLines: wrapText ? null : 1,
                          overflow: wrapText
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: AppText.caption.copyWith(color: foreground),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (status != null) ...<Widget>[
                const SizedBox(width: Space.x2),
                // The status takes its natural width, up to a share that
                // leaves the title the rest; past it the pill keeps its icon.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * _statusShare,
                  ),
                  child: status!,
                ),
              ],
              if (trailing != null) ...<Widget>[
                const SizedBox(width: Space.x2),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
    final VoidCallback? tap = onTap == null
        ? null
        : () {
            TrialReportScope.recordAction(context, title);
            onTap!();
          };
    final Widget body = interactive
        ? InkWell(
            excludeFromSemantics: true,
            onTap: tap,
            onLongPress: onLongPress,
            child: content,
          )
        : content;
    // Drawn in front, so the ink and the fill never cover the mark.
    final Widget row = current
        ? DecoratedBox(
            key: currentMarkKey,
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(color: colors.primary, width: Space.x1),
              ),
            ),
            child: body,
          )
        : body;
    return Semantics(
      button: onTap != null,
      selected: selected || current,
      enabled: interactive,
      label: title,
      hint: subtitle,
      onTap: tap,
      onLongPress: onLongPress,
      child: Material(
        color: selected || current ? colors.surfaceVariant : colors.surface,
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            row,
            Padding(
              padding: EdgeInsetsDirectional.only(start: dividerIndent),
              child: Divider(
                height: Space.x0,
                thickness: Space.x0 / 2,
                color: colors.outline,
              ),
            ),
          ],
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
