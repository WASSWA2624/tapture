import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';

/// Persistent status under the app bar for offline and warning states.
///
/// Dismissible, announced, and excluded from focus so a field being edited
/// keeps the caret (FE-A11Y-06, FE-A11Y-07).
class AppBanner extends StatelessWidget {
  /// Creates a banner. [icon] accompanies [tone] so colour is never alone.
  const AppBanner({
    super.key,
    required this.message,
    required this.icon,
    required this.tone,
    this.onDismiss,
  });

  /// Plain-language status.
  final String message;

  /// Leading glyph (FE-A11Y-05).
  final IconData icon;

  /// Visual role shared with snacks.
  final SnackTone tone;

  /// Hides the banner. Null is not dismissible.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final Color accent = tone.color(colors);
    final VoidCallback? onDismiss = this.onDismiss;
    return ExcludeFocus(
      child: Semantics(
        liveRegion: true,
        container: true,
        label: message,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            border: Border(
              bottom: BorderSide(color: accent, width: Space.x0 / 2),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.minTapTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.x4),
              child: Row(
                children: <Widget>[
                  Icon(icon, color: accent, size: Space.x6),
                  const SizedBox(width: Space.x3),
                  Expanded(
                    child: Text(
                      message,
                      style: AppText.body.copyWith(color: colors.onSurface),
                    ),
                  ),
                  if (onDismiss != null)
                    AppIconButton(
                      icon: Icons.close,
                      semanticLabel: Copy.dismiss,
                      tooltip: Copy.dismiss,
                      onPressed: onDismiss,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
