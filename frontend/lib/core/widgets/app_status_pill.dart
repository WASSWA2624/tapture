import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';

import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/record_status.dart';

export 'record_status.dart';

part 'status_style.dart';

/// Record and job status as colour plus icon plus text (FE-THEME-05).
///
/// Screens do not map status to colour themselves. The compact [badge]
/// constructor fits [AppListTile] trailing and status slots.
class AppStatusPill extends StatelessWidget {
  /// Creates the full pill. [label] replaces the status word when the
  /// same chrome is reused for requiredness.
  const AppStatusPill({super.key, required this.status, this.label})
    : _compact = false;

  /// Creates the compact badge for list rows.
  const AppStatusPill.badge({super.key, required this.status, this.label})
    : _compact = true;

  /// Lifecycle value to render. Every value has a style.
  final RecordStatus status;

  /// Visible word when this pill is not naming a record lifecycle.
  final String? label;

  final bool _compact;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final (Color color, IconData icon, String styleLabel) = StatusStyle.of(
      status,
      colors,
      localizedCopy: Copy.of(context),
    );
    final String label = this.label ?? styleLabel;
    final double pad = _compact ? Space.x1 : Space.x2;
    final double iconSize = _compact ? Space.x4 : Space.x5;
    final TextStyle textStyle = (_compact ? AppText.caption : AppText.label)
        .copyWith(color: colors.onSurface);
    // The label already names the visible word; reading the text too would
    // announce the status twice inside a merged row.
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _compact ? colors.surface : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(
            color: color,
            width: Space.x0 / 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double gap = _compact ? Space.x1 : Space.x2;
              // A word that cannot fit is not clipped: a narrow slot at
              // large text keeps the colour and icon, and the word stays
              // in the label and the tooltip.
              if (!_fits(
                context,
                label,
                textStyle,
                constraints.maxWidth - iconSize - gap,
              )) {
                return Tooltip(
                  message: label,
                  excludeFromSemantics: true,
                  child: Icon(icon, color: color, size: iconSize),
                );
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, color: color, size: iconSize),
                  SizedBox(width: gap),
                  Text(label, maxLines: 1, style: textStyle),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static bool _fits(
    BuildContext context,
    String label,
    TextStyle style,
    double width,
  ) {
    if (!width.isFinite) return true;
    final TextPainter painter = TextPainter(
      text: TextSpan(text: label, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
    )..layout();
    final bool fits = painter.width <= width;
    painter.dispose();
    return fits;
  }
}
