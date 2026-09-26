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
import 'package:tapture/features/capture/presentation/photo_frame.dart';

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
  /// The crop as fractions of the photo as shown, after its rotation.
  Rect _fraction = const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);
  Size? _photoSize;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final Uint8List? bytes = widget.bytes;
    if (bytes != null) {
      unawaited(_readSize(bytes));
    }
  }

  Future<void> _readSize(Uint8List bytes) async {
    final Size? size = await PhotoFrame.sizeOf(bytes);
    if (!mounted) {
      return;
    }
    setState(() {
      _photoSize = size;
      if (size == null) {
        _error = Copy.photoUnreadable;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = widget.bytes;
    final Size? size = _photoSize;
    final AppColors colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text(Copy.photoCrop)),
      body: Column(
        children: <Widget>[
          Expanded(
            child: bytes == null
                ? Center(child: Text(widget.photo.id))
                : size == null
                ? Center(child: Text(_error == null ? Copy.loading : ''))
                : _CropFrame(
                    bytes: bytes,
                    photoSize: size,
                    fraction: _fraction,
                    quarterTurns: PhotoFrame.quarterTurns(
                      widget.photo.rotationDegrees,
                    ),
                    color: colors.primary,
                    onChanged: (Rect next) => setState(() => _fraction = next),
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
                    onPressed: _busy || (bytes != null && size == null)
                        ? null
                        : () => unawaited(_apply()),
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

/// The photo drawn where [PhotoFrame.fit] puts it, with a frame that moves
/// inside it and resizes from four corner handles.
class _CropFrame extends StatelessWidget {
  const _CropFrame({
    required this.bytes,
    required this.photoSize,
    required this.fraction,
    required this.quarterTurns,
    required this.color,
    required this.onChanged,
  });

  final Uint8List bytes;
  final Size photoSize;
  final Rect fraction;
  final int quarterTurns;
  final Color color;
  final ValueChanged<Rect> onChanged;

  /// Half a handle's target, kept clear around the photo so corner handles
  /// at its edges stay fully touchable.
  static const double _reach = Sizes.minTapTarget / 2;

  static const List<Alignment> _corners = <Alignment>[
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints limits) {
        final Size area = limits.biggest;
        final Rect photo = PhotoFrame.fit(
          Size(
            (area.width - _reach * 2).clamp(0.0, double.infinity),
            (area.height - _reach * 2).clamp(0.0, double.infinity),
          ),
          photoSize,
          quarterTurns,
        ).shift(const Offset(_reach, _reach));
        final Rect frame = PhotoFrame.toRect(fraction, photo);
        return Stack(
          children: <Widget>[
            Positioned.fromRect(
              rect: photo,
              child: RotatedBox(
                quarterTurns: quarterTurns,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                ),
              ),
            ),
            Positioned.fromRect(
              rect: frame,
              child: Semantics(
                label: Copy.photoCropFrame,
                child: GestureDetector(
                  key: const ValueKey<String>('photo-crop-frame'),
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (DragUpdateDetails details) {
                    onChanged(
                      PhotoFrame.move(
                        fraction,
                        PhotoFrame.fractionOf(details.delta, photo),
                      ),
                    );
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: color, width: Space.x0),
                    ),
                  ),
                ),
              ),
            ),
            for (final Alignment corner in _corners)
              Positioned(
                left: (corner.x < 0 ? frame.left : frame.right) - _reach,
                top: (corner.y < 0 ? frame.top : frame.bottom) - _reach,
                width: Sizes.minTapTarget,
                height: Sizes.minTapTarget,
                child: Semantics(
                  label: Copy.photoCropCorner,
                  child: GestureDetector(
                    key: ValueKey<String>('photo-crop-corner-$corner'),
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (DragUpdateDetails details) {
                      onChanged(
                        PhotoFrame.resize(
                          fraction,
                          corner,
                          PhotoFrame.fractionOf(details.delta, photo),
                        ),
                      );
                    },
                    child: Center(
                      child: SizedBox.square(
                        dimension: Space.x4,
                        child: ColoredBox(color: color),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
