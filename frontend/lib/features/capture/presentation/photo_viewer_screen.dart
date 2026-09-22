import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';

/// Full-screen photo inspector with swipe between photos.
final class PhotoViewerScreen extends StatefulWidget {
  /// Creates a viewer.
  const PhotoViewerScreen({
    required this.photos,
    this.initialIndex = 0,
    this.missingIds = const <String>{},
    this.onRotate,
    this.onCrop,
    this.onCaption,
    this.onType,
    this.images = const <String, Uint8List>{},
    super.key,
  });

  /// Record photos.
  final List<PhotoDraft> photos;

  /// Starting index.
  final int initialIndex;

  /// Ids whose file is missing.
  final Set<String> missingIds;

  /// Rotation request.
  final void Function(PhotoDraft photo, int degrees)? onRotate;

  /// Opens crop.
  final ValueChanged<PhotoDraft>? onCrop;

  /// Opens the caption sheet for the visible photo.
  final ValueChanged<PhotoDraft>? onCaption;

  /// Types onto a derived copy of the visible photo.
  final ValueChanged<PhotoDraft>? onType;

  /// Session bytes keyed by photo id.
  final Map<String, Uint8List> images;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(
      0,
      widget.photos.isEmpty ? 0 : widget.photos.length - 1,
    );
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text(Copy.photo)),
        body: const Center(child: Text(Copy.missingPhoto)),
      );
    }
    final PhotoDraft current = widget.photos[_index];
    final bool missing = widget.missingIds.contains(current.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(current.photoType),
        actions: <Widget>[
          IconButton(
            tooltip: Copy.captureTitle,
            onPressed: () => widget.onRotate?.call(current, 90),
            icon: const Icon(Icons.rotate_right),
          ),
          IconButton(
            tooltip: Copy.photoCrop,
            onPressed: () => widget.onCrop?.call(current),
            icon: const Icon(Icons.crop),
          ),
          IconButton(
            tooltip: Copy.capturePhotoCaption,
            onPressed: () => widget.onCaption?.call(current),
            icon: const Icon(Icons.notes),
          ),
          IconButton(
            tooltip: Copy.photoTypeOn,
            onPressed: () => widget.onType?.call(current),
            icon: const Icon(Icons.title),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        onPageChanged: (int i) => setState(() => _index = i),
        itemBuilder: (BuildContext context, int i) {
          final PhotoDraft photo = widget.photos[i];
          final bool isMissing = widget.missingIds.contains(photo.id);
          final Uint8List? bytes = widget.images[photo.id];
          return InteractiveViewer(
            child: Center(
              child: isMissing
                  ? const Text(Copy.missingPhoto)
                  : bytes == null
                  ? Text('${photo.id}\nrot=${photo.rotationDegrees}')
                  : Image.memory(bytes, fit: BoxFit.contain),
            ),
          );
        },
      ),
      bottomNavigationBar: missing
          ? null
          : ListTile(
              title: Text(current.photoType),
              subtitle: Text(current.relativePath),
            ),
    );
  }
}
