import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/markup_ink.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_ink_picker.dart';
import 'package:tapture/core/widgets/app_primary_action.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/markup_text.dart';
import 'package:tapture/core/widgets/photo_markup.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/photo_frame.dart';

/// Types words onto a photo with the text shown live where it will be saved,
/// in a chosen ink and size, over an optional backing, and dragged into
/// place. Saving writes a derived photo (FBK0000152, D5).
final class PhotoTypeScreen extends StatefulWidget {
  /// Creates a type-on screen.
  const PhotoTypeScreen({
    required this.photo,
    required this.bytes,
    required this.onTyped,
    this.ink = MarkupInk.red,
    this.size = 1,
    this.onStyle,
    super.key,
  });

  /// Source photo. Its bytes stay immutable.
  final PhotoDraft photo;

  /// Pixels to type on.
  final Uint8List bytes;

  /// Derived draft and PNG, ready for the caller to store.
  final void Function(PhotoDraft draft, Uint8List png) onTyped;

  /// The ink the words start in.
  final MarkupInk ink;

  /// The size index the words start at.
  final int size;

  /// Called with each new ink and size, so the caller can offer them next
  /// time.
  final void Function(MarkupInk ink, int size)? onStyle;

  @override
  State<PhotoTypeScreen> createState() => _PhotoTypeScreenState();
}

class _PhotoTypeScreenState extends State<PhotoTypeScreen> {
  late final TextEditingController _words = TextEditingController()
    ..addListener(_typed);
  late MarkupText _text = MarkupText(
    text: '',
    ink: widget.ink,
    size: widget.size,
  );
  Size? _photoSize;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_readSize());
  }

  Future<void> _readSize() async {
    final Size? size = await PhotoFrame.sizeOf(widget.bytes);
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
  void dispose() {
    _words.dispose();
    super.dispose();
  }

  void _typed() {
    if (_words.text != _text.text) {
      setState(() => _text = _text.copyWith(text: _words.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size? photoSize = _photoSize;
    final Widget controls = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          label: Copy.photoTypeOn,
          controller: _words,
          helper: Copy.markupTypeHint,
          minLines: 1,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
        ),
        const SizedBox(height: Space.x2),
        AppInkPicker(
          ink: _text.ink,
          size: _text.size,
          onInk: (MarkupInk ink) => _style(ink, _text.size),
          onSize: (int size) => _style(_text.ink, size),
        ),
        const SizedBox(height: Space.x2),
        AppSwitchTile(
          title: Copy.markupBacking,
          description: Copy.markupBackingDescription,
          value: _text.backing,
          onChanged: (bool on) {
            setState(() => _text = _text.copyWith(backing: on));
          },
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: Space.x2),
            child: Text(_error!),
          ),
        const SizedBox(height: Space.x2),
        AppPrimaryAction(
          label: Copy.save,
          busy: _busy,
          onPressed: _busy || photoSize == null
              ? null
              : () => unawaited(_save()),
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: const Text(Copy.photoTypeOn)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints limits) {
            final bool wide = limits.maxWidth > limits.maxHeight;
            final Widget canvas = photoSize == null
                ? Center(child: Text(_error == null ? Copy.loading : ''))
                : _canvas(photoSize);
            final Widget panel = SingleChildScrollView(
              key: const ValueKey<String>('type-controls'),
              padding: const EdgeInsets.all(Space.x2),
              child: controls,
            );
            // The photo takes what the controls leave; the controls scroll
            // when text is large, so the field, picker and Save stay
            // reachable.
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(child: canvas),
                      SizedBox(
                        width: limits.maxWidth * AppConstants.markup.panelShare,
                        child: panel,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(child: canvas),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              limits.maxHeight * AppConstants.markup.panelShare,
                        ),
                        child: panel,
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget _canvas(Size photoSize) {
    final int turns = PhotoFrame.quarterTurns(widget.photo.rotationDegrees);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints limits) {
        final Rect photo = PhotoFrame.fit(limits.biggest, photoSize, turns);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (DragUpdateDetails details) => _move(photo, details),
          child: Stack(
            children: <Widget>[
              Positioned.fromRect(
                rect: photo,
                child: RotatedBox(
                  quarterTurns: turns,
                  child: Image.memory(
                    widget.bytes,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: photo,
                child: ClipRect(
                  child: CustomSingleChildLayout(
                    delegate: _CentreAt(_text.centre),
                    child: _Overlay(text: _text, photoHeight: photo.height),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _move(Rect photo, DragUpdateDetails details) {
    final Offset step = PhotoFrame.fractionOf(details.delta, photo);
    final Offset next = _text.centre + step;
    setState(() {
      _text = _text.copyWith(
        centre: Offset(next.dx.clamp(0.0, 1.0), next.dy.clamp(0.0, 1.0)),
      );
    });
  }

  void _style(MarkupInk ink, int size) {
    setState(() => _text = _text.copyWith(ink: ink, size: size));
    widget.onStyle?.call(ink, size);
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final Result<Uint8List> typed = await PhotoMarkup.typeOn(
      widget.bytes,
      _text,
      rotationDegrees: widget.photo.rotationDegrees,
    );
    if (!mounted) {
      return;
    }
    switch (typed) {
      case FailureResult<Uint8List>(:final Failure failure):
        setState(() {
          _busy = false;
          _error = failure.message;
        });
      case Success<Uint8List>(:final Uint8List value):
        final String id = UuidV7Service(const SystemClock()).newId();
        widget.onTyped(
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
          value,
        );
        setState(() => _busy = false);
    }
  }
}

/// The typed words as they will be saved: each line as tall as its share of
/// the shown photo, centred, over the backing when it is on.
class _Overlay extends StatelessWidget {
  const _Overlay({required this.text, required this.photoHeight});

  final MarkupText text;
  final double photoHeight;

  @override
  Widget build(BuildContext context) {
    final String words = text.text.trim();
    if (words.isEmpty) {
      return const SizedBox.shrink();
    }
    final double line = text.lineFraction * photoHeight;
    final double pad = text.backing ? line * AppConstants.markup.backingPad : 0;
    return DecoratedBox(
      key: const ValueKey<String>('type-overlay'),
      decoration: BoxDecoration(
        color: text.backing
            ? MarkupInk.black.color.withValues(
                alpha: AppConstants.markup.backingAlpha,
              )
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Text(
          words,
          textAlign: TextAlign.center,
          softWrap: false,
          // The words are part of the photo, so they follow its size and
          // not the reading size (FE-A11Y-03 covers the controls).
          textScaler: TextScaler.noScaling,
          style: AppText.body.copyWith(
            color: text.ink.color,
            fontSize: math.max(1, line),
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Lays the overlay out centred on [centre], a fraction of the photo, and
/// keeps it inside the photo as the saved photo does.
class _CentreAt extends SingleChildLayoutDelegate {
  _CentreAt(this.centre);

  final Offset centre;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return const BoxConstraints();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double x = (centre.dx * size.width - childSize.width / 2).clamp(
      0.0,
      math.max(0.0, size.width - childSize.width),
    );
    final double y = (centre.dy * size.height - childSize.height / 2).clamp(
      0.0,
      math.max(0.0, size.height - childSize.height),
    );
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_CentreAt oldDelegate) => oldDelegate.centre != centre;
}
