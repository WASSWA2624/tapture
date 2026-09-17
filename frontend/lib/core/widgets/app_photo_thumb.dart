import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';

part 'photo_asset.dart';

/// The one square thumbnail every photo renders through (FE-CONS-06).
///
/// Tap opens; long-press selects (FE-CONS-10). The image is the cached
/// thumb for [size], never the original (FE-PERF-04).
class AppPhotoThumb extends StatelessWidget {
  /// Creates a thumbnail. [size] is the layout edge; the image uses a 1:1
  /// ratio and [BoxFit.cover] (FE-RESP-09).
  const AppPhotoThumb({
    super.key,
    required this.photo,
    required this.size,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  /// Photo to render. Only [PhotoAsset.thumbPath] is decoded.
  final PhotoAsset photo;

  /// Layout edge of the square, in logical pixels.
  final double size;

  /// Multi-select highlight. A tick is shown as well as a border
  /// (FE-A11Y-05).
  final bool selected;

  /// Opens the viewer. Null means the thumb is not tappable.
  final VoidCallback? onTap;

  /// Starts multi-select. Null means long-press does nothing.
  final VoidCallback? onLongPress;

  bool get _interactive => onTap != null || onLongPress != null;

  bool get _missing {
    if (photo.thumbPath.isEmpty) {
      return false;
    }
    return !File(photo.thumbPath).existsSync();
  }

  String _resolvedPath() {
    if (photo.thumbPath.isNotEmpty) {
      return photo.thumbPath;
    }
    return photo.cacheKey(size.round());
  }

  String get _label {
    return Copy.photoThumbLabel(
      type: photo.photoType?.label ?? Copy.photo,
      missing: _missing,
      captioned: photo.hasCaption,
      selected: selected,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final double edge = size < Sizes.minTapTarget ? Sizes.minTapTarget : size;
    final int decodeEdge = _decodeEdge(context, edge);
    final Widget stack = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _subject(colors, decodeEdge),
        if (photo.photoType != null)
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(Space.x1),
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
        if (selected)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(Space.x1),
              child: Icon(Icons.check, color: colors.primary, size: Space.x5),
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
    return Semantics(
      button: _interactive,
      selected: selected,
      image: true,
      enabled: _interactive,
      label: _label,
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
  }

  Widget _subject(AppColors colors, int decodeEdge) {
    final String path = _resolvedPath();
    if (photo.thumbPath.isNotEmpty) {
      if (File(path).existsSync()) {
        return Image.file(
          File(path),
          fit: BoxFit.cover,
          cacheWidth: decodeEdge,
          cacheHeight: decodeEdge,
          excludeFromSemantics: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => _MissingPlaceholder(colors: colors),
        );
      }
      return _MissingPlaceholder(colors: colors);
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
                  type.badgeLabel,
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
        child: Icon(
          Icons.closed_caption,
          size: Space.x4,
          color: colors.onSurface,
        ),
      ),
    );
  }
}

class _MissingPlaceholder extends StatelessWidget {
  const _MissingPlaceholder({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colors.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(Space.x1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.broken_image_outlined,
              color: colors.onSurface,
              size: Space.x6,
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                Copy.missingPhoto,
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
