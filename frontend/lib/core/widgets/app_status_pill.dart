import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';

import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';

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
    );
    final String label = this.label ?? styleLabel;
    final double pad = _compact ? Space.x1 : Space.x2;
    final double iconSize = _compact ? Space.x4 : Space.x5;
    final TextStyle textStyle = (_compact ? AppText.caption : AppText.label)
        .copyWith(color: colors.onSurface);
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _compact ? colors.surface : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(
            color: color,
            width: Space.x0 / 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: color, size: iconSize),
              SizedBox(width: _compact ? Space.x1 : Space.x2),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One record-lifecycle status. The set is closed; export is not a status
/// (task 162). Mapped only through [StatusStyle] and [AppStatusPill].
enum RecordStatus {
  /// Saved locally, not yet captured in the field.
  draft,

  /// Evidence is on the record; processing has not started.
  captured,

  /// Waiting for on-device or online processing.
  queued,

  /// A processing job is running.
  processing,

  /// Extraction finished; review may still be required.
  extracted,

  /// A person must look at this record.
  needsReview,

  /// A person has accepted the record.
  approved,

  /// Processing or validation failed.
  failed,

  /// Kept for history, hidden from the working list.
  archived,

  /// Marked gone; purge is a later job.
  deleted,
}
