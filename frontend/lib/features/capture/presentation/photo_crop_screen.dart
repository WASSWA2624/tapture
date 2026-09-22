import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';

/// Crop UI that writes a derived file link; revert restores full frame.
final class PhotoCropScreen extends StatefulWidget {
  /// Creates a crop screen.
  const PhotoCropScreen({
    required this.photo,
    required this.onCropped,
    required this.onRevert,
    super.key,
  });

  /// Source photo (original bytes stay immutable).
  final PhotoDraft photo;

  /// Derived draft after crop.
  final ValueChanged<PhotoDraft> onCropped;

  /// Restore full frame / clear derived link.
  final ValueChanged<PhotoDraft> onRevert;

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  bool _cropped = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Copy.photo)),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: Text(
                _cropped ? 'cropped:${widget.photo.id}' : widget.photo.id,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  setState(() => _cropped = true);
                  widget.onCropped(
                    widget.photo.copyWith(
                      derivedFrom: widget.photo.derivedFrom ?? widget.photo.id,
                      relativePath: '${widget.photo.relativePath}.crop',
                    ),
                  );
                },
                child: const Text('Crop'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _cropped = false);
                  widget.onRevert(
                    widget.photo.copyWith(
                      derivedFrom: null,
                      rotationDegrees: 0,
                    ),
                  );
                },
                child: const Text('Revert'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
