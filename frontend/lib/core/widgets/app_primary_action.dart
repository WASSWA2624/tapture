import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';

/// The large, full-width action capture and review both compose.
///
/// Tall enough for gloves, stretched to the parent's width so it can sit in
/// an [AppPage] footer within thumb reach (FE-A11Y-09, FE-SIMP-01).
class AppPrimaryAction extends StatelessWidget {
  /// Creates the primary action. [busy] shows an inline spinner and ignores
  /// presses so a double submission cannot land.
  const AppPrimaryAction({
    super.key,
    required this.label,
    this.caption,
    this.onPressed,
    this.busy = false,
  });

  /// The action verb. The largest line on the control.
  final String label;

  /// Optional second line under [label], still inside the tap target.
  final String? caption;

  /// Invoked on a press. Null is the disabled state. Ignored while [busy].
  final VoidCallback? onPressed;

  /// When true, an inline spinner is shown and taps are swallowed.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null && !busy;
    final VoidCallback? visualPress = isDisabled
        ? null
        : () {
            if (!busy) {
              onPressed?.call();
            }
          };
    return Semantics(
      liveRegion: busy,
      child: AbsorbPointer(
        absorbing: busy,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: visualPress,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, Sizes.controlHeight),
              padding: const EdgeInsets.symmetric(
                horizontal: Space.x2,
                vertical: Space.x0,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(Radii.sm)),
              ),
              side: BorderSide(
                color: context.colors.outline,
                width: Theme.of(context).dividerTheme.thickness ?? Space.x0 / 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              disabledBackgroundColor: context.colors.surfaceVariant,
              disabledForegroundColor: context.colors.onSurface,
            ),
            child: Builder(
              builder: (BuildContext buttonContext) {
                return _child(buttonContext);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _child(BuildContext context) {
    final String semantics = <String>[
      label,
      ?caption,
      if (busy) Copy.busy,
    ].join('\n');
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (busy) ...<Widget>[
                ExcludeSemantics(
                  child: SizedBox(
                    width: Space.x5,
                    height: Space.x5,
                    child: CircularProgressIndicator(
                      strokeWidth: Space.x0,
                      color: IconTheme.of(context).color,
                      value: MediaQuery.disableAnimationsOf(context)
                          ? Space.x3 / Space.x4
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: Space.x2),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppText.bodyStrong,
                  textAlign: TextAlign.center,
                  semanticsLabel: semantics,
                ),
              ),
            ],
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: Space.x1),
            ExcludeSemantics(
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  caption!,
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
