import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/photo_markup.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';

/// Crop UI that writes a derived file; revert walks back one version.
final class PhotoCropScreen extends StatefulWidget {
  /// Creates a crop screen.
  const PhotoCropScreen({
    required this.photo,
    required this.onCropped,
    required this.onRevert,
    this.bytes,
    super.key,
  });

  /// Source photo. Its bytes stay immutable.
  final PhotoDraft photo;

  /// Image bytes when they are already in memory.
  final Uint8List? bytes;

  /// Derived draft and cropped PNG. [png] is null when there are no bytes.
  final void Function(PhotoDraft draft, Uint8List? png) onCropped;

  /// Restore the preceding version.
  final ValueChanged<PhotoDraft> onRevert;

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  Rect _fraction = const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
  String? _error;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = widget.bytes;
    final AppColors colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text(Copy.photoCrop)),
      body: Column(
        children: <Widget>[
          Expanded(
            child: bytes == null
                ? Center(child: Text(widget.photo.id))
                : LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints limits) {
                      return _CropFrame(
                        bytes: bytes,
                        fraction: _fraction,
                        rotationDegrees: widget.photo.rotationDegrees,
                        color: colors.primary,
                        onChanged: (Rect next) =>
                            setState(() => _fraction = next),
                      );
                    },
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(Space.x2),
              child: Text(_error!),
            ),
          Padding(
            padding: const EdgeInsets.all(Space.x2),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: AppButton(
                    label: Copy.photoCrop,
                    busy: _busy,
                    onPressed: _busy ? null : () => unawaited(_apply()),
                  ),
                ),
                const SizedBox(width: Space.x2),
                Expanded(
                  child: AppButton(
                    label: Copy.photoRevert,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => widget.onRevert(widget.photo),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _apply() async {
    final Uint8List? bytes = widget.bytes;
    setState(() {
      _busy = true;
      _error = null;
    });
    Uint8List? png;
    if (bytes != null) {
      final Result<Uint8List> cropped = await PhotoMarkup.crop(
        bytes,
        _fraction,
        rotationDegrees: widget.photo.rotationDegrees,
      );
      if (!mounted) {
        return;
      }
      switch (cropped) {
        case FailureResult<Uint8List>(:final Failure failure):
          setState(() {
            _busy = false;
            _error = failure.message;
          });
          return;
        case Success<Uint8List>(:final Uint8List value):
          png = value;
      }
    }
    final String id = UuidV7Service(const SystemClock()).newId();
    widget.onCropped(
      widget.photo.copyWith(
        id: id,
        relativePath: 'photos/$id.png',
        storedFilename: '$id.png',
        originalFilename: '$id.png',
        mimeType: 'image/png',
        derivedFrom: widget.photo.id,
        rotationDegrees: 0,
        capturedAt: const SystemClock().nowUtc(),
      ),
      png,
    );
    if (mounted) {
      setState(() => _busy = false);
    }
  }
}

class _CropFrame extends StatelessWidget {
  const _CropFrame({
    required this.bytes,
    required this.fraction,
    required this.rotationDegrees,
    required this.color,
    required this.onChanged,
  });

  final Uint8List bytes;
  final Rect fraction;
  final int rotationDegrees;
  final Color color;
  final ValueChanged<Rect> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Center(
          child: RotatedBox(
            quarterTurns: ((rotationDegrees % 360) + 360) % 360 ~/ 90,
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints limits) {
            final Rect box = _box(limits.biggest, fraction);
            return Stack(
              children: <Widget>[
                Positioned.fromRect(
                  rect: box,
                  child: GestureDetector(
                    onPanUpdate: (DragUpdateDetails details) {
                      onChanged(_move(limits.biggest, details.delta));
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: color, width: Space.x0),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Rect _move(Size size, Offset delta) {
    if (size.width == 0 || size.height == 0) {
      return fraction;
    }
    final double left = (fraction.left + delta.dx / size.width).clamp(
      0.0,
      1 - fraction.width,
    );
    final double top = (fraction.top + delta.dy / size.height).clamp(
      0.0,
      1 - fraction.height,
    );
    return Rect.fromLTWH(left, top, fraction.width, fraction.height);
  }
}

Rect _box(Size size, Rect fraction) {
  return Rect.fromLTWH(
    fraction.left * size.width,
    fraction.top * size.height,
    fraction.width * size.width,
    fraction.height * size.height,
  );
}
