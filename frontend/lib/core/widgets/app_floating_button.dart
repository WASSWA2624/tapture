import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';

/// A draggable icon that sits over a [Stack]. On a pointing device the
/// label stays hidden until hover; on touch it is icon-only. There is no
/// fill, outline or tooltip.
///
/// Must be a direct child of a [Stack]: it fills the stack and only the
/// control itself receives pointer events.
class AppFloatingButton extends StatefulWidget {
  /// Creates the control. [startX] and [startY] are fractions of the free
  /// width and height (0 is the start edge, 1 is the far edge).
  const AppFloatingButton({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.onPressed,
    this.expandOnHover = false,
    this.startX = 1,
    this.startY = 1,
  });

  /// Glyph inside the control.
  final IconData icon;

  /// Visible name when expanded, and the semantic name.
  final String label;

  /// How the control behaves, for screen readers.
  final String hint;

  /// Invoked on a tap, with the control's global rectangle so a menu can
  /// anchor to it. Not invoked after a drag.
  final void Function(Rect anchor) onPressed;

  /// When true, a pointer hover reveals [label] beside the icon.
  final bool expandOnHover;

  /// Horizontal rest, as a fraction of the free width.
  final double startX;

  /// Vertical rest, as a fraction of the free height.
  final double startY;

  @override
  State<AppFloatingButton> createState() => _AppFloatingButtonState();
}

class _AppFloatingButtonState extends State<AppFloatingButton> {
  final GlobalKey _buttonKey = GlobalKey();
  late double _fx = widget.startX.clamp(0, 1);
  late double _fy = widget.startY.clamp(0, 1);
  bool _hovering = false;

  bool get _showLabel => widget.expandOnHover && _hovering;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          safe.left + Space.x3,
          safe.top + Space.x3,
          safe.right + Space.x3,
          safe.bottom + Space.x3,
        ),
        child: Align(
          alignment: Alignment(2 * _fx - 1, 2 * _fy - 1),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: widget.expandOnHover
                ? (_) => setState(() => _hovering = true)
                : null,
            onExit: widget.expandOnHover
                ? (_) => setState(() => _hovering = false)
                : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: _onPanUpdate,
              onTap: () => widget.onPressed(_anchor()),
              child: Semantics(
                button: true,
                label: widget.label,
                hint: widget.hint,
                child: UnconstrainedBox(
                  child: Stack(
                    alignment: Alignment(2 * _fx - 1, 2 * _fy - 1),
                    children: <Widget>[
                      const SizedBox(
                        width: Sizes.minTapTarget,
                        height: Sizes.minTapTarget,
                      ),
                      AnimatedSize(
                        key: _buttonKey,
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : AppConstants.motion.short,
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.all(Space.x0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                widget.icon,
                                size: Space.x6,
                                color: colors.primary,
                              ),
                              if (_showLabel) ...<Widget>[
                                const SizedBox(width: Space.x1),
                                Text(
                                  widget.label,
                                  style: AppText.label.copyWith(
                                    color: colors.primary,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final double width = box.size.width - Sizes.minTapTarget - Space.x3 * 2;
    final double height = box.size.height - Sizes.minTapTarget - Space.x3 * 2;
    if (width <= 0 || height <= 0) {
      return;
    }
    setState(() {
      _fx = (_fx + details.delta.dx / width).clamp(0, 1);
      _fy = (_fy + details.delta.dy / height).clamp(0, 1);
    });
  }

  Rect _anchor() {
    final RenderBox? box =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return Rect.zero;
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }
}
