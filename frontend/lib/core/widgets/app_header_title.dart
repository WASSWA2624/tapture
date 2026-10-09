import 'package:flutter/material.dart';
import 'package:tapture/app/theme/typography.dart';

/// A naturally wrapping toolbar title with optional quieter detail.
class AppHeaderTitle extends StatelessWidget {
  /// Creates the shared toolbar title.
  const AppHeaderTitle({
    required this.title,
    this.detail,
    this.titleStyle,
    this.foregroundColor,
    super.key,
  });

  /// Primary title, kept in its original data or localized form.
  final String title;

  /// Optional secondary line; empty detail reserves no space.
  final String? detail;

  /// The owning toolbar's title typography.
  final TextStyle? titleStyle;

  /// The owning toolbar's readable ink for both lines.
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final String? detail = this.detail;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          softWrap: true,
          overflow: TextOverflow.visible,
          style: foregroundColor == null
              ? titleStyle
              : (titleStyle ?? DefaultTextStyle.of(context).style).copyWith(
                  color: foregroundColor,
                ),
        ),
        if (detail != null && detail.isNotEmpty)
          Text(
            detail,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: AppText.caption.copyWith(
              color:
                  foregroundColor ?? DefaultTextStyle.of(context).style.color,
            ),
          ),
      ],
    );
  }
}
