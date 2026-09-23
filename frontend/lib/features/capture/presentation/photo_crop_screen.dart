import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/photo_markup.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';

/// Crop UI that writes a derived file link; revert restores full frame.
final class PhotoCropScreen extends StatefulWidget {
  /// Creates a crop screen.
  const PhotoCropScreen({
    required this.photo,
    required this.onCropped,
    required this.onRevert,
    this.bytes,
    super.key,
  });

  /// Source photo (original bytes stay immutable).
  final PhotoDraft photo;

  /// Image bytes when the session still holds them.
  final Uint8List? bytes;

  /// Derived draft and, when [bytes] was set, the cropped PNG.
  final void Function(PhotoDraft draft, Uint8List? png) onCropped;

  /// Restore full frame / clear derived link.
  final ValueChanged<PhotoDraft> onRevert;

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  Rect? _fraction;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = widget.bytes;
    return Scaffold(
      appBar: AppBar(title: const Text(Copy.photo)),
      body: Column(
        children: <Widget>[
          Expanded(
            child: bytes == null
                ? Center(child: Text(widget.photo.id))
                : GestureDetector(
                    onPanUpdate: (DragUpdateDetails details) {
                      final RenderBox? box =
                          context.findRenderObject() as RenderBox?;
                      if (box == null || box.size.width == 0) {
                        return;
                      }
                      final Offset local = box.globalToLocal(
                        details.localPosition,
                      );
                      setState(() {
                        _fraction = Rect.fromLTWH(
                          0.1,
                          (local.dy / box.size.height).clamp(0.0, 0.8),
                          0.8,
                          0.2,
                        );
                      });
                    },
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              TextButton(
                onPressed: () async {
                  Uint8List? png;
                  try {
                    if (bytes != null) {
                      png = await PhotoMarkup.crop(bytes, _fraction);
                    }
                  } on Object catch (error) {
                    if (mounted) {
                      setState(() => _error = error.toString());
                    }
                    return;
                  }
                  if (!mounted) {
                    return;
                  }
                  setState(() => _error = null);
                  widget.onCropped(
                    PhotoDraft(
                      id: widget.photo.id,
                      projectId: widget.photo.projectId,
                      relativePath: '${widget.photo.relativePath}.crop',
                      sha256: widget.photo.sha256,
                      derivedFrom: widget.photo.id,
                      mimeType: 'image/png',
                    ),
                    png,
                  );
                },
                child: const Text(Copy.photoCrop),
              ),
              TextButton(
                onPressed: () => widget.onRevert(widget.photo),
                child: const Text(Copy.photoRevert),
              ),
            ],
          ),
          if (_error != null) Text(_error!),
          const SizedBox(height: Space.x2),
        ],
      ),
    );
  }
}
