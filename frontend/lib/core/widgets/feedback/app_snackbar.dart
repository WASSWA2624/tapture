import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';

/// Queued snack body. Features call [showAppSnack] rather than constructing
/// [SnackBar] (FE-CONS-05). Colour is never the only signal (FE-A11Y-05).
class AppSnackbar extends StatelessWidget {
  /// Creates a snack body. [onUndo] is offered only with [undoLabel].
  const AppSnackbar({
    super.key,
    required this.message,
    this.tone = SnackTone.info,
    this.undoLabel,
    this.onUndo,
  });

  /// Plain-language status. Announced when the snack appears (FE-A11Y-07).
  final String message;

  /// Visual role. Icon plus [message] carry the meaning.
  final SnackTone tone;

  /// Undo control label. Null hides the control.
  final String? undoLabel;

  /// Invoked by undo. Null hides the control.
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final String? undoLabel = this.undoLabel;
    final VoidCallback? onUndo = this.onUndo;
    return Semantics(
      liveRegion: true,
      label: message,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.minTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.x4,
            vertical: Space.x2,
          ),
          child: Row(
            children: <Widget>[
              Icon(tone.icon, color: tone.color(colors), size: Space.x6),
              const SizedBox(width: Space.x3),
              Expanded(
                child: Text(
                  message,
                  style: AppText.caption.copyWith(color: colors.onSurface),
                ),
              ),
              if (undoLabel != null && onUndo != null) ...<Widget>[
                const SizedBox(width: Space.x2),
                AppButton(
                  label: undoLabel,
                  variant: AppButtonVariant.text,
                  onPressed: onUndo,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Info, success, warning and error roles for snacks and banners.
enum SnackTone {
  /// Neutral information, not a verdict.
  info,

  /// Completed or verified.
  success,

  /// Needs attention, not yet invalid.
  warning,

  /// Failed or destructive outcome.
  error;

  /// Icon that accompanies this tone (FE-A11Y-05).
  IconData get icon {
    return switch (this) {
      SnackTone.info => AppIcons.info,
      SnackTone.success => AppIcons.success,
      SnackTone.warning => AppIcons.warning,
      SnackTone.error => AppIcons.error,
    };
  }

  /// Token colour for this tone. Never used alone.
  Color color(AppColors colors) {
    return switch (this) {
      SnackTone.info => colors.info,
      SnackTone.success => colors.success,
      SnackTone.warning => colors.warning,
      SnackTone.error => colors.danger,
    };
  }
}

/// Shows [message] through the scaffold messenger so snacks queue rather
/// than overlap. Optional undo is the pair for a destructive confirm.
void showAppSnack(
  BuildContext context,
  String message, {
  SnackTone tone = SnackTone.info,
  String? undoLabel,
  VoidCallback? onUndo,
}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final AppColors colors = context.colors;
  messenger.showSnackBar(
    SnackBar(
      duration: AppConstants.feedback.snack,
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.surface,
      elevation: 0,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: tone.color(colors), width: Space.x0 / 2),
      ),
      content: AppSnackbar(
        message: message,
        tone: tone,
        undoLabel: undoLabel,
        onUndo: onUndo == null
            ? null
            : () {
                messenger.hideCurrentSnackBar();
                onUndo();
              },
      ),
    ),
  );
}
