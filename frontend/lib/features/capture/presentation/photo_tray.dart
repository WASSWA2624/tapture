import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_photo_thumb.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';

/// Horizontal thumbnail strip with count, add action and badges.
final class PhotoTray extends StatelessWidget {
  /// Creates a tray.
  const PhotoTray({
    required this.photos,
    required this.onAdd,
    this.showAddAction = true,
    this.onTap,
    this.onLongPress,
    this.onRemove,
    this.selectedIds = const <String>{},
    this.captions = const <String, String>{},
    this.thumbPaths = const <String, String>{},
    this.thumbBytes = const <String, Uint8List>{},
    this.missingIds = const <String>{},
    super.key,
  });

  /// Photos in tray order. Callers pass the active derived set.
  final List<PhotoDraft> photos;

  /// Add affordance. Null disables the control.
  final VoidCallback? onAdd;

  /// Hides duplicate intake controls when the composer provides the action.
  final bool showAddAction;

  /// Opens viewer / type sheet.
  final ValueChanged<PhotoDraft>? onTap;

  /// Toggles a photo in or out of the selection, from a long press and
  /// from its checkbox alike (FE-CONS-10).
  final ValueChanged<PhotoDraft>? onLongPress;

  /// Removes one draft. Separate from [onTap].
  final ValueChanged<PhotoDraft>? onRemove;

  /// Selected photo ids.
  final Set<String> selectedIds;

  /// Caption map for indicator.
  final Map<String, String> captions;

  /// Absolute cached thumbnail paths keyed by photo id.
  final Map<String, String> thumbPaths;

  /// Photo bytes keyed by photo id, drawn at thumbnail size in place of a
  /// cached file. A browser passes these; it has no thumbnail files.
  final Map<String, Uint8List> thumbBytes;

  /// Photos whose file could not be read.
  final Set<String> missingIds;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    if (photos.isEmpty) {
      // Keep the catalogue's guidance passive when intake is in the composer.
      return AppEmptyState(
        compact: true,
        icon: AppIcons.addPhoto,
        headline: localCopy.captureNoPhotosHeadline,
        message: localCopy.captureNoPhotosMessage,
        onIconTap: showAddAction ? onAdd : null,
        iconLabel: showAddAction ? localCopy.captureAddPhoto : null,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(localCopy.capturePhotoCount(photos.length)),
        SizedBox(
          height: Space.x12 * 2,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length + (showAddAction ? 1 : 0),
            itemBuilder: (BuildContext context, int index) {
              final LocalizedCopy localCopy = Copy.of(context);

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
                child: SizedBox(
                  width: edge,
                  height: edge,
                  // No type badge: the select control takes that corner and
                  // the preview names the type (D6).
                  child: AppPhotoThumb(
                    key: ValueKey<String>('photo-thumb-${photo.id}'),
                    photo: PhotoAsset(
                      sha256: photo.sha256,
                      thumbPath: missing ? 'missing' : (thumb ?? ''),
                      thumbBytes: missing ? null : thumbBytes[photo.id],
                      hasCaption: hasCaption,
                    ),
                    size: edge,
                    quarterTurns: _quarterTurns(photo.rotationDegrees),
                    selected: selectedIds.contains(photo.id),
                    statusLabel: photo.processingState == 'ready'
                        ? null
                        : localCopy.capturePhotoProcessing,
                    onTap: () => onTap?.call(photo),
                    onLongPress: () => onLongPress?.call(photo),
                    onSelectedChanged: (bool _) => onLongPress?.call(photo),
                    onRemove: onRemove == null ? null : () => onRemove!(photo),
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

class _AddPhotoTarget extends StatelessWidget {
  const _AddPhotoTarget({required this.edge, required this.onPressed});

  final double edge;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AppColors colors = context.colors;
    return Semantics(
      button: true,
      label: localCopy.captureAddPhoto,
      child: Tooltip(
        message: localCopy.captureAddPhoto,
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
                child: Icon(AppIcons.addPhoto, color: colors.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
