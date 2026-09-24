import 'package:flutter/material.dart';
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
          height: Space.x12 * 2,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == photos.length) {
                return AppIconButton(
                  icon: Icons.add_a_photo,
                  tooltip: Copy.captureAddPhoto,
                  semanticLabel: Copy.captureAddPhoto,
                  onPressed: onAdd,
                );
              }
              final PhotoDraft photo = photos[index];
              final bool hasCaption =
                  photo.hasCaption || (captions[photo.id]?.isNotEmpty ?? false);
              final String? thumb = thumbPaths[photo.id];
              final bool missing = missingIds.contains(photo.id);
              return Padding(
                padding: const EdgeInsets.all(Space.x1),
                child: RotatedBox(
                  quarterTurns: _quarterTurns(photo.rotationDegrees),
                  child: AppPhotoThumb(
                    key: ValueKey<String>('photo-thumb-${photo.id}'),
                    photo: PhotoAsset(
                      sha256: photo.sha256,
                      thumbPath: missing ? 'missing' : (thumb ?? ''),
                      photoType: _photoType(photo.photoType),
                      hasCaption: hasCaption,
                    ),
                    size: Space.x12 * 2,
                    selected: selectedIds.contains(photo.id),
                    statusLabel: photo.processingState == 'ready'
                        ? null
                        : Copy.capturePhotoProcessing,
                    onTap: () => onTap?.call(photo),
                    onLongPress: () => onLongPress?.call(photo),
                  ),
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
