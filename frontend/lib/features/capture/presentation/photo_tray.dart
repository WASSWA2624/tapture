import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
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
    super.key,
  });

  /// Photos in tray order.
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

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Semantics(
        label: Copy.captureNoPhotosHeadline,
        child: Column(
          children: <Widget>[
            const Text(Copy.captureNoPhotosHeadline),
            const Text(Copy.captureNoPhotosMessage),
            IconButton(
              tooltip: Copy.captureAddPhoto,
              onPressed: onAdd,
              icon: const Icon(Icons.add_a_photo),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('${photos.length}'),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == photos.length) {
                return IconButton(
                  tooltip: Copy.captureAddPhoto,
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_a_photo),
                );
              }
              final PhotoDraft photo = photos[index];
              final bool selected = selectedIds.contains(photo.id);
              final bool hasCaption =
                  photo.hasCaption || (captions[photo.id]?.isNotEmpty ?? false);
              return GestureDetector(
                onTap: () => onTap?.call(photo),
                onLongPress: () => onLongPress?.call(photo),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected ? Colors.blue : Colors.grey,
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: Stack(
                    children: <Widget>[
                      Center(child: Text(photo.photoType)),
                      Positioned(
                        top: 2,
                        left: 2,
                        child: Text(
                          photo.photoType,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      if (hasCaption)
                        const Positioned(
                          bottom: 2,
                          right: 2,
                          child: Icon(Icons.notes, size: 14),
                        ),
                      if (photo.processingState != 'ready')
                        Positioned(
                          bottom: 2,
                          left: 2,
                          child: Text(
                            photo.processingState,
                            style: const TextStyle(fontSize: 9),
                          ),
                        ),
                    ],
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
