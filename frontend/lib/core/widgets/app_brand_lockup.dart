import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/brand_assets.dart';
import 'package:tapture/core/copy/copy.dart';

/// Wordmark used in chrome: mark plus [Copy.appName].
class AppBrandLockup extends StatelessWidget {
  /// Creates the lockup. [showName] hides the wordmark on tight app bars.
  ///
  /// [inverted] paints on a primary fill (status line, branded app bar).
  const AppBrandLockup({
    super.key,
    this.showName = true,
    this.inverted = false,
  });

  /// When false, only the mark is shown.
  final bool showName;

  /// When true, ink and the mark sit on [AppColors.primary].
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color ink = inverted ? colors.onPrimary : colors.onSurface;
    final bool lightInk = ink.computeLuminance() > 0.5;
    return Semantics(
      header: true,
      label: Copy.appName,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: Space.x8,
            height: Space.x8,
            child: Image.asset(
              lightInk ? BrandAssets.markInverse : BrandAssets.mark,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
          if (showName) ...<Widget>[
            const SizedBox(width: Space.x2),
            Text(
              Copy.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.title.copyWith(color: ink),
            ),
          ],
        ],
      ),
    );
  }
}
