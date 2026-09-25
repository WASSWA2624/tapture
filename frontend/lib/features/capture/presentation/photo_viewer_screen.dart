import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
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
    this.onDraw,
    this.onRevert,
    this.images = const <String, Uint8List>{},
    this.loadBytes,
    super.key,
  });

  /// Record photos.
  final List<PhotoDraft> photos;

  /// Starting index.
  final int initialIndex;

  /// Ids whose file is missing.
  final Set<String> missingIds;

  /// Persists a quarter turn. True means the viewer may show it.
  final Future<bool> Function(PhotoDraft photo, int degrees)? onRotate;

  /// Opens crop.
  final ValueChanged<PhotoDraft>? onCrop;

  /// Opens the caption sheet for the visible photo.
  final ValueChanged<PhotoDraft>? onCaption;

  /// Types onto a derived copy of the visible photo.
  final ValueChanged<PhotoDraft>? onType;

  /// Opens freehand drawing.
  final ValueChanged<PhotoDraft>? onDraw;

  /// Walks back one derived version.
  final ValueChanged<PhotoDraft>? onRevert;

  /// Session bytes keyed by photo id.
  final Map<String, Uint8List> images;

  /// Loads stored bytes when [images] does not hold them.
  final Future<Uint8List?> Function(PhotoDraft photo)? loadBytes;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller;
  late List<PhotoDraft> _photos;
  late int _index;
  final Map<String, Uint8List> _images = <String, Uint8List>{};

  @override
  void initState() {
    super.initState();
    _photos = List<PhotoDraft>.of(widget.photos);
    _images.addAll(widget.images);
    _index = widget.initialIndex.clamp(
      0,
      _photos.isEmpty ? 0 : _photos.length - 1,
    );
    _controller = PageController(initialPage: _index);
    for (final PhotoDraft photo in _photos) {
      if (!_images.containsKey(photo.id)) {
        _load(photo);
      }
    }
  }

  Future<void> _load(PhotoDraft photo) async {
    final Future<Uint8List?> Function(PhotoDraft photo)? load =
        widget.loadBytes;
    if (load == null) {
      return;
    }
    final Uint8List? bytes = await load(photo);
    if (!mounted || bytes == null) {
      return;
    }
    setState(() => _images[photo.id] = bytes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text(Copy.photo)),
        body: const Center(child: Text(Copy.missingPhoto)),
      );
    }
    final PhotoDraft current = _photos[_index];
    final bool missing = widget.missingIds.contains(current.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(current.photoType),
        actions: <Widget>[
          IconButton(
            tooltip: Copy.photoRotate,
            onPressed: () => _rotate(current),
            icon: const Icon(AppIcons.rotate),
          ),
          IconButton(
            tooltip: Copy.photoCrop,
            onPressed: () => widget.onCrop?.call(current),
            icon: const Icon(AppIcons.crop),
          ),
          IconButton(
            tooltip: Copy.photoDraw,
            onPressed: () => widget.onDraw?.call(current),
            icon: const Icon(AppIcons.draw),
          ),
          IconButton(
            tooltip: Copy.capturePhotoCaption,
            onPressed: () => widget.onCaption?.call(current),
            icon: const Icon(AppIcons.caption),
          ),
          IconButton(
            tooltip: Copy.photoTypeOn,
            onPressed: () => widget.onType?.call(current),
            icon: const Icon(AppIcons.typeText),
          ),
          if (current.derivedFrom != null)
            IconButton(
              tooltip: Copy.photoRevert,
              onPressed: () => widget.onRevert?.call(current),
              icon: const Icon(AppIcons.undo),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: _photos.length,
        onPageChanged: (int i) => setState(() => _index = i),
        itemBuilder: (BuildContext context, int i) {
          final PhotoDraft photo = _photos[i];
          return _frame(photo);
        },
      ),
      bottomNavigationBar: missing
          ? const ListTile(title: Text(Copy.missingPhoto))
          : ListTile(
              title: Text(current.photoType),
              subtitle: Text(current.relativePath),
            ),
    );
  }

  Widget _frame(PhotoDraft photo) {
    if (widget.missingIds.contains(photo.id)) {
      return const Center(child: Text(Copy.missingPhoto));
    }
    final Uint8List? bytes = _images[photo.id];
    if (bytes == null) {
      return const Center(child: Text(Copy.loading));
    }
    return InteractiveViewer(
      child: Center(
        child: RotatedBox(
          quarterTurns: ((photo.rotationDegrees % 360) + 360) % 360 ~/ 90,
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Future<void> _rotate(PhotoDraft current) async {
    final Future<bool> Function(PhotoDraft photo, int degrees)? rotate =
        widget.onRotate;
    if (rotate == null) {
      return;
    }
    final bool saved = await rotate(current, 90);
    if (!saved || !mounted) {
      return;
    }
    setState(() {
      _photos[_index] = _photos[_index].copyWith(
        rotationDegrees:
            ((_photos[_index].rotationDegrees + 90) % 360 + 360) % 360,
      );
    });
  }
}
