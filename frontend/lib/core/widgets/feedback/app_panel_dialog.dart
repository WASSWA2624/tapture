import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';

/// A titled dialog that holds a whole flow — a form, a filter and its
/// results — where a desktop shows over the current screen what a phone
/// opens as a screen of its own. Features call [showAppPanelDialog] rather
/// than composing [Dialog] (FE-CONS-05).
///
/// Same surface, outline and radius as [AppDialog]; the body scrolls inside
/// the dialog, so it never grows past the window (FE-RESP-06). The title
/// bar moves the panel; the close control does not.
class AppPanelDialog extends StatefulWidget {
  /// Creates the panel. [onClose] defaults to popping the dialog.
  const AppPanelDialog({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.maxWidth = defaultMaxWidth,
  });

  /// Width a panel is capped at unless a caller asks for another.
  static const double defaultMaxWidth = 640;

  /// Heading; also the semantic name of the route (FE-A11Y-02).
  final String title;

  /// The flow. Should scroll itself when it can be taller than the window.
  final Widget child;

  /// Close action. Null pops the dialog.
  final VoidCallback? onClose;

  /// Width cap, in logical pixels.
  final double maxWidth;

  @override
  State<AppPanelDialog> createState() => _AppPanelDialogState();
}

class _AppPanelDialogState extends State<AppPanelDialog> {
  final GlobalKey _panelKey = GlobalKey();
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Transform.translate(
      offset: _offset,
      child: Dialog(
        backgroundColor: colors.surface,
        insetPadding: const EdgeInsets.all(Space.x6),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: colors.outline, width: Space.x0 / 2),
        ),
        child: Semantics(
          namesRoute: true,
          scopesRoute: true,
          label: widget.title,
          explicitChildNodes: true,
          child: ConstrainedBox(
            key: _panelKey,
            constraints: BoxConstraints(maxWidth: widget.maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.move,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: _onDrag,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              Space.x4,
                              Space.x2,
                              Space.x2,
                              Space.x2,
                            ),
                            child: Semantics(
                              header: true,
                              child: Text(
                                widget.title,
                                style: AppText.title.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        0,
                        Space.x2,
                        Space.x2,
                        Space.x2,
                      ),
                      child: AppIconButton(
                        icon: Icons.close,
                        semanticLabel: Copy.close,
                        tooltip: Copy.close,
                        onPressed:
                            widget.onClose ?? () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                Divider(
                  height: Space.x0 / 2,
                  thickness: Space.x0 / 2,
                  color: colors.outline,
                ),
                Flexible(
                  child: DefaultTextStyle(
                    style: AppText.body.copyWith(color: colors.onSurface),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onDrag(DragUpdateDetails details) {
    final RenderBox? box =
        _panelKey.currentContext?.findRenderObject() as RenderBox?;
    Offset delta = details.delta;
    if (box != null && box.hasSize) {
      final RenderBox? overlay =
          Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
      final Size screen = overlay != null && overlay.hasSize
          ? overlay.size
          : box.size;
      final Offset origin = box.localToGlobal(Offset.zero);
      const double slop = Sizes.minTapTarget;
      double dx = delta.dx;
      double dy = delta.dy;
      final double nextLeft = origin.dx + dx;
      final double nextTop = origin.dy + dy;
      final double nextRight = nextLeft + box.size.width;
      final double nextBottom = nextTop + box.size.height;
      if (nextRight < slop) {
        dx += slop - nextRight;
      } else if (nextLeft > screen.width - slop) {
        dx -= nextLeft - (screen.width - slop);
      }
      if (nextBottom < slop) {
        dy += slop - nextBottom;
      } else if (nextTop > screen.height - slop) {
        dy -= nextTop - (screen.height - slop);
      }
      delta = Offset(dx, dy);
    }
    setState(() => _offset += delta);
  }
}

/// Opens [builder] in an [AppPanelDialog] on the root navigator. A barrier
/// tap closes it only when [barrierDismissible] is true, so a half-typed
/// form is not lost to a stray click.
Future<T?> showAppPanelDialog<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  double maxWidth = AppPanelDialog.defaultMaxWidth,
}) {
  return showDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext dialogContext) {
      return AppPanelDialog(
        title: title,
        maxWidth: maxWidth,
        child: Builder(builder: builder),
      );
    },
  );
}
