import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';

/// Renders a typed [Failure] as icon, message and recovery (FE-CONS-11).
///
/// Screens do not write their own error copy. An unmapped variant is a
/// compile error: the switch has no default.
class AppErrorState extends StatelessWidget {
  /// Creates an error panel. Retry is offered only when [onRetry] is set.
  const AppErrorState({super.key, required this.failure, this.onRetry});

  /// The typed failure to explain. Message and recovery come from here.
  final Failure failure;

  /// Rebuilds or re-fetches. Null hides the retry button.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final (IconData icon, Color color) = _visual(failure, colors);
    final String? recovery = failure.recoveryAction;
    final VoidCallback? onRetry = this.onRetry;
    return Semantics(
      container: true,
      liveRegion: true,
      label: failure.message,
      child: Padding(
        padding: const EdgeInsets.all(Space.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: Space.x12, color: color),
            const SizedBox(height: Space.x4),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: AppText.title.copyWith(color: colors.onSurface),
            ),
            if (recovery != null) ...<Widget>[
              const SizedBox(height: Space.x2),
              Text(
                recovery,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: colors.onSurface),
              ),
            ],
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: Space.x6),
              AppButton(label: 'Try again', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}

/// Colour plus icon for [failure]. Text still carries the meaning
/// (FE-THEME-05, FE-A11Y-05).
(IconData, Color) _visual(Failure failure, AppColors colors) {
  return switch (failure) {
    NetworkFailure() => (Icons.cloud_off, colors.info),
    PermissionFailure() => (Icons.lock_outline, colors.warning),
    StorageFailure() => (Icons.save_outlined, colors.warning),
    ValidationFailure() => (Icons.rule, colors.warning),
    CorruptionFailure() => (Icons.broken_image_outlined, colors.danger),
    CancelledFailure() => (Icons.stop_circle_outlined, colors.secondary),
    ProviderFailure() => (Icons.error_outline, colors.danger),
  };
}
