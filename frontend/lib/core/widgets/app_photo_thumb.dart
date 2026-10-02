import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';

part 'photo_asset.dart';

/// The one square thumbnail every photo renders through (FE-CONS-06).
///
/// Tap opens; long-press selects (FE-CONS-10). The image is the cached
/// thumb for [size], or [PhotoAsset.thumbBytes] decoded at [size], never
/// the original at full size (FE-PERF-04). In a browser no file is ever
/// opened: a thumb without bytes shows the missing-photo placeholder.
class AppPhotoThumb extends StatelessWidget {
  /// Creates a thumbnail. [size] is the layout edge; the image uses a 1:1
  /// ratio and [BoxFit.cover] (FE-RESP-09).
  const AppPhotoThumb({
    super.key,
    required this.photo,
    required this.size,
    this.selected = false,
    this.statusLabel,
    this.onTap,
    this.onLongPress,
    this.quarterTurns = 0,
    this.onSelectedChanged,
    this.onRemove,
    this.semanticLabel,
  });

  /// Photo to render. Only its thumbnail is decoded: [PhotoAsset.thumbBytes]
  /// when set, else the file at [PhotoAsset.thumbPath]; never the original.
  final PhotoAsset photo;

  /// Layout edge of the square, in logical pixels.
  final double size;

  /// Multi-select highlight. A tick is shown as well as a border
  /// (FE-A11Y-05).
  final bool selected;

  /// Processing or other status. Null hides the badge. Text plus an icon,
  /// so the state is not colour alone (FE-A11Y-05).
  final String? statusLabel;

  /// Opens the viewer. Null means the thumb is not tappable.
  final VoidCallback? onTap;

  /// Starts multi-select. Null means long-press does nothing.
  final VoidCallback? onLongPress;

  /// Clockwise quarter turns of the saved rotation. Only the image turns;
  /// badges stay upright.
  final int quarterTurns;

  /// Toggles [selected] from a select control flush in the top-start
  /// corner, a 48dp target beside the long press. Null draws no control and
  /// marks a selected thumb with a tick instead.
  final ValueChanged<bool>? onSelectedChanged;

  /// Removes the photo from a control flush in the top-end corner, a 48dp
  /// target. Null draws no control.
  final VoidCallback? onRemove;

  /// What a screen reader calls the photo, in place of its type or "Photo".
  /// The missing, captioned, selected and status parts are still read.
  final String? semanticLabel;

  bool get _interactive => onTap != null || onLongPress != null;

  String _label(LocalizedCopy copy, bool missing) {
    final String base = copy.photoThumbLabel(
      type: semanticLabel ?? photo.photoType?.labelFor(copy) ?? copy.photo,
      missing: missing,
      captioned: photo.hasCaption,
      selected: selected,
    );
    final String? status = statusLabel;
    if (status == null || status.isEmpty) {
      return base;
    }
    return '$base, $status';
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || photo.thumbBytes != null || photo.thumbPath.isEmpty) {
      return _build(context, missing: kIsWeb && photo.thumbBytes == null);
    }
    return _ThumbnailAvailability(
      path: photo.thumbPath,
      builder: (BuildContext context, bool? exists) =>
          _build(context, missing: exists == false, ready: exists != null),
    );
  }

  Widget _build(
    BuildContext context, {
    required bool missing,
    bool ready = true,
  }) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AppColors colors = context.colors;
    final double edge = size < Sizes.minTapTarget ? Sizes.minTapTarget : size;
    final int decodeEdge = _decodeEdge(context, edge);
    final Widget stack = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (quarterTurns % 4 == 0)
          _subject(colors, decodeEdge, missing: missing, ready: ready)
        else
          RotatedBox(
            quarterTurns: quarterTurns,
            child: _subject(colors, decodeEdge, missing: missing, ready: ready),
          ),
        if (photo.photoType != null)
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              // Below the select control when it holds the corner.
              padding: EdgeInsets.fromLTRB(
                Space.x1,
                onSelectedChanged == null ? Space.x1 : Space.x7 + Space.x1,
                Space.x1,
                Space.x1,
              ),
              child: _TypeBadge(type: photo.photoType!, maxWidth: edge),
            ),
          ),
        if (photo.hasCaption)
          const Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.all(Space.x1),
              child: _CaptionMark(),
            ),
          ),
        if (selected && onSelectedChanged == null)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Space.x1,
                onRemove == null ? Space.x1 : Space.x7 + Space.x1,
                Space.x1,
                Space.x1,
              ),
              child: Icon(
                AppIcons.check,
                color: colors.primary,
                size: Space.x5,
              ),
            ),
          ),
        if (statusLabel != null)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(Space.x1),
              child: _StatusBadge(label: statusLabel!, maxWidth: edge / 2),
            ),
          ),
      ],
    );
    final Widget well = Material(
      color: colors.surfaceVariant,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        side: BorderSide(
          color: selected ? colors.primary : colors.outline,
          width: selected ? Space.x0 : Space.x0 / 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: _interactive
          ? InkWell(onTap: onTap, onLongPress: onLongPress, child: stack)
          : stack,
    );
    final Widget thumb = Semantics(
      button: _interactive,
      selected: selected,
      image: true,
      enabled: _interactive,
      label: _label(localCopy, missing),
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: Sizes.minTapTarget,
          minHeight: Sizes.minTapTarget,
        ),
        child: SizedBox(
          width: edge,
          height: edge,
          child: AspectRatio(aspectRatio: 1, child: well),
        ),
      ),
    );
    final ValueChanged<bool>? toggle = onSelectedChanged;
    final VoidCallback? remove = onRemove;
    if (toggle == null && remove == null) {
      return thumb;
    }
    // The corner controls sit outside the thumb's merged semantics so a
    // screen reader reaches each as its own control (FE-A11Y-02), and inside
    // the thumb's rounded clip so they meet its corners (FBK0000153).
    return SizedBox(
      width: edge,
      height: edge,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: thumb),
            if (toggle != null)
              PositionedDirectional(
                top: 0,
                start: 0,
                child: _CornerControl(
                  corner: AlignmentDirectional.topStart,
                  label: localCopy.photoSelect,
                  selected: selected,
                  filled: selected,
                  icon: selected ? AppIcons.check : null,
                  onPressed: () => toggle(!selected),
                ),
              ),
            if (remove != null)
              PositionedDirectional(
                top: 0,
                end: 0,
                child: _CornerControl(
                  corner: AlignmentDirectional.topEnd,
                  label: localCopy.captureRemovePhoto,
                  icon: AppIcons.close,
                  onPressed: remove,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _subject(
    AppColors colors,
    int decodeEdge, {
    required bool missing,
    required bool ready,
  }) {
    final Uint8List? bytes = photo.thumbBytes;
    if (bytes != null) {
      // Only the width is capped, so a photo keeps its shape and the cover
      // fit crops it rather than squashing it to a square.
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        cacheWidth: decodeEdge,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => _MissingPlaceholder(colors: colors),
      );
    }
    if (missing) {
      return _MissingPlaceholder(colors: colors);
    }
    if (ready && photo.thumbPath.isNotEmpty) {
      return Image.file(
        File(photo.thumbPath),
        fit: BoxFit.cover,
        cacheWidth: decodeEdge,
        cacheHeight: decodeEdge,
        excludeFromSemantics: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => _MissingPlaceholder(colors: colors),
      );
    }
    return const SizedBox.expand();
  }

  int _decodeEdge(BuildContext context, double edge) {
    final int px = (edge * MediaQuery.devicePixelRatioOf(context)).round();
    if (px < 1) {
      return 1;
    }
    final int cap = AppConstants.images.previewEdge;
    return px > cap ? cap : px;
  }
}

// A cached path is checked asynchronously once, rather than blocking every
// scrolling rebuild with two filesystem queries. A new path starts a new check.
class _ThumbnailAvailability extends StatefulWidget {
  const _ThumbnailAvailability({required this.path, required this.builder});

  final String path;
  final Widget Function(BuildContext, bool?) builder;

  @override
  State<_ThumbnailAvailability> createState() => _ThumbnailAvailabilityState();
}

class _ThumbnailAvailabilityState extends State<_ThumbnailAvailability> {
  late Future<bool> _exists;

  @override
  void initState() {
    super.initState();
    _exists = _read();
  }

  @override
  void didUpdateWidget(_ThumbnailAvailability oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _exists = _read();
    }
  }

  Future<bool> _read() async {
    try {
      return await File(widget.path).exists();
    } on FileSystemException {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    key: ValueKey<String>(widget.path),
    future: _exists,
    builder: (BuildContext context, AsyncSnapshot<bool> snapshot) =>
        widget.builder(context, snapshot.data),
  );
}

/// A thumbnail corner control: a [Space.x7] square flush in [corner], filled
/// so it reads on any photo and rounded only on its inner corner, inside a
/// 48dp target that reaches inward (FE-A11Y-01, FE-THEME-05).
class _CornerControl extends StatelessWidget {
  const _CornerControl({
    required this.corner,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = false,
    this.selected,
  });

  final AlignmentDirectional corner;
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  /// Primary fill, for a selected select control.
  final bool filled;

  /// Checked state for a toggle; null for a plain button.
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final bool start = corner == AlignmentDirectional.topStart;
    final String role = start ? 'select' : 'remove';
    const Radius inner = Radius.circular(Radii.sm);
    return Semantics(
      button: true,
      label: label,
      checked: selected,
      excludeSemantics: true,
      onTap: onPressed,
      child: Tooltip(
        message: label,
        child: SizedBox.square(
          key: ValueKey<String>('photo-corner-$role-target'),
          dimension: Sizes.minTapTarget,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onPressed,
              child: Align(
                alignment: corner,
                child: SizedBox.square(
                  key: ValueKey<String>('photo-corner-$role'),
                  dimension: Space.x7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: filled ? colors.primary : colors.surface,
                      // The ring and fill differ so one of them reaches
                      // 3:1 on a black photo and on a white one in every
                      // theme; a primary ring alone fails on black.
                      border: Border.all(
                        color: filled ? colors.surface : colors.outline,
                        width: Space.x0 / 2,
                      ),
                      borderRadius: start
                          ? const BorderRadiusDirectional.only(bottomEnd: inner)
                          : const BorderRadiusDirectional.only(
                              bottomStart: inner,
                            ),
                    ),
                    child: icon == null
                        ? null
                        : Icon(
                            icon,
                            size: Space.x5,
                            color: filled ? colors.onPrimary : colors.onSurface,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, required this.maxWidth});

  final PhotoType type;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth * 2 / 3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(
            color: colors.outline,
            width: Space.x0 / 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.x1,
            vertical: Space.x0,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(type.icon, size: Space.x4, color: colors.onSurface),
                const SizedBox(width: Space.x1),
                Text(
                  type.badgeLabelFor(Copy.of(context)),
                  maxLines: 1,
                  style: AppText.caption.copyWith(color: colors.onSurface),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.maxWidth});

  final String label;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: colors.outline, width: Space.x0 / 2),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(Space.x0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(AppIcons.waiting, size: Space.x4, color: colors.onSurface),
              const SizedBox(width: Space.x0),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(color: colors.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptionMark extends StatelessWidget {
  const _CaptionMark();

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.x0),
        child: Icon(AppIcons.caption, size: Space.x4, color: colors.onSurface),
      ),
    );
  }
}

class _MissingPlaceholder extends StatelessWidget {
  const _MissingPlaceholder({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    return ColoredBox(
      color: colors.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(Space.x1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(AppIcons.brokenFile, color: colors.onSurface, size: Space.x6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                localCopy.missingPhoto,
                maxLines: 1,
                style: AppText.caption.copyWith(color: colors.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
