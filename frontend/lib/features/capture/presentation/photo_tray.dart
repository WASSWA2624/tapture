import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';

/// Horizontal thumbnail strip with count, add action and badges.
final class PhotoTray extends StatelessWidget {
  /// Creates a tray.
  const PhotoTray({
    required this.photos,
    required this.onAdd,
    this.onTap,
    this.onLongPress,
    this.onRemove,
    this.onCaption,
    this.selectedIds = const <String>{},
    this.captions = const <String, String>{},
    this.thumbPaths = const <String, String>{},
    this.missingIds = const <String>{},
    super.key,
  });

  /// Photos in tray order. Callers pass the active derived set.
  final List<PhotoDraft> photos;

  /// Add affordance.
  final VoidCallback onAdd;

  /// Opens viewer / type sheet.
  final ValueChanged<PhotoDraft>? onTap;

  /// Enters multi-select.
  final ValueChanged<PhotoDraft>? onLongPress;

  /// Removes one draft. Separate from [onTap].
  final ValueChanged<PhotoDraft>? onRemove;

  /// Opens the caption for one photo. Separate from [onTap].
  final ValueChanged<PhotoDraft>? onCaption;

  /// Selected photo ids.
  final Set<String> selectedIds;

  /// Caption map for indicator.
  final Map<String, String> captions;

  /// Absolute cached thumbnail paths keyed by photo id.
  final Map<String, String> thumbPaths;

  /// Photos whose file could not be read.
  final Set<String> missingIds;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Semantics(
        label: Copy.captureNoPhotosHeadline,
        child: Column(
          children: <Widget>[
            const Text(Copy.captureNoPhotosHeadline),
            const Text(Copy.captureNoPhotosMessage),
            AppIconButton(
              icon: Icons.add_a_photo,
              tooltip: Copy.captureAddPhoto,
              semanticLabel: Copy.captureAddPhoto,
              onPressed: onAdd,
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(Copy.capturePhotoCount(photos.length)),
        SizedBox(
          height: Space.x12 * 2 + Sizes.minTapTarget,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length + 1,
            itemBuilder: (BuildContext context, int index) {
              const double edge = Space.x12 * 2;
              if (index == photos.length) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.x2),
                    child: _AddPhotoTarget(edge: edge, onPressed: onAdd),
                  ),
                );
              }
              final PhotoDraft photo = photos[index];
              final bool hasCaption =
                  photo.hasCaption || (captions[photo.id]?.isNotEmpty ?? false);
              final String? thumb = thumbPaths[photo.id];
              final bool missing = missingIds.contains(photo.id);
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: Space.x2),
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      width: edge,
                      height: edge,
                      child: Stack(
                        children: <Widget>[
                          RotatedBox(
                            quarterTurns: _quarterTurns(photo.rotationDegrees),
                            child: AppPhotoThumb(
                              key: ValueKey<String>('photo-thumb-${photo.id}'),
                              photo: PhotoAsset(
                                sha256: photo.sha256,
                                thumbPath: missing ? 'missing' : (thumb ?? ''),
                                photoType: _photoType(photo.photoType),
                                hasCaption: hasCaption,
                              ),
                              size: edge,
                              selected: selectedIds.contains(photo.id),
                              statusLabel: photo.processingState == 'ready'
                                  ? null
                                  : Copy.capturePhotoProcessing,
                              onTap: () => onTap?.call(photo),
                              onLongPress: () => onLongPress?.call(photo),
                            ),
                          ),
                          PositionedDirectional(
                            top: 0,
                            end: 0,
                            child: AppIconButton(
                              icon: Icons.close,
                              outlined: false,
                              tooltip: Copy.captureRemovePhoto,
                              semanticLabel: Copy.captureRemovePhoto,
                              onPressed: () => onRemove?.call(photo),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => onCaption?.call(photo),
                      child: const Text(Copy.captureCaptionAction),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

int _quarterTurns(int degrees) {
  return (((degrees % 360) + 360) % 360) ~/ 90;
}

PhotoType _photoType(String raw) {
  for (final PhotoType type in PhotoType.values) {
    if (type.name == raw) {
      return type;
    }
  }
  return PhotoType.other;
}

class _AddPhotoTarget extends StatelessWidget {
  const _AddPhotoTarget({required this.edge, required this.onPressed});

  final double edge;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return Semantics(
      button: true,
      label: Copy.captureAddPhoto,
      child: Tooltip(
        message: Copy.captureAddPhoto,
        child: SizedBox(
          width: edge,
          height: edge,
          child: Material(
            color: colors.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.sm),
              side: BorderSide(color: colors.outline, width: Space.x0 / 2),
            ),
            child: InkWell(
              onTap: onPressed,
              child: ExcludeSemantics(
                child: Icon(Icons.add_a_photo, color: colors.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
