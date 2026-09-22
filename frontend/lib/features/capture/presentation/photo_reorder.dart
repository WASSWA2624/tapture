import 'package:flutter/material.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';

/// Drag-to-reorder wrapper that reports the new id order.
final class PhotoReorder extends StatelessWidget {
  /// Creates a reorderable list.
  const PhotoReorder({
    required this.photos,
    required this.onReorder,
    super.key,
  });

  /// Current order.
  final List<PhotoDraft> photos;

  /// New ordered ids after a drop.
  final ValueChanged<List<String>> onReorder;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      itemCount: photos.length,
      onReorderItem: (int oldIndex, int newIndex) {
        final List<PhotoDraft> next = List<PhotoDraft>.of(photos);
        final PhotoDraft moved = next.removeAt(oldIndex);
        next.insert(newIndex, moved);
        onReorder(next.map((PhotoDraft p) => p.id).toList());
      },
      itemBuilder: (BuildContext context, int index) {
        final PhotoDraft photo = photos[index];
        return ListTile(
          key: ValueKey<String>(photo.id),
          title: Text(photo.photoType),
          subtitle: Text(photo.id),
        );
      },
    );
  }
}
