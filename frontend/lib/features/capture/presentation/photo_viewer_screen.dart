import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/photo_frame.dart';

/// Full-screen photo inspector with swipe between photos, the photo edits,
/// and the visible photo's caption to read, edit and delete (FBK0000132).
final class PhotoViewerScreen extends StatefulWidget {
  /// Creates a viewer.
  const PhotoViewerScreen({
    required this.photos,
    this.initialIndex = 0,
    this.missingIds = const <String>{},
    this.captions = const <String, String>{},
    this.onCaptionChanged,
    this.onRotate,
    this.onCrop,
    this.onType,
    this.onDraw,
    this.onRevert,
    this.images = const <String, Uint8List>{},
    this.loadBytes,
    super.key,
  });

  /// Record photos, newest version of each. The viewer follows changes, so
  /// a crop, drawing or typed copy shows at the same position.
  final ValueListenable<List<PhotoDraft>> photos;

  /// Starting index.
  final int initialIndex;

  /// Ids whose file is missing.
  final Set<String> missingIds;

  /// Caption text keyed by photo id.
  final Map<String, String> captions;

  /// Writes a photo's caption; `''` deletes it. True means it was saved.
  final Future<bool> Function(PhotoDraft photo, String text)? onCaptionChanged;

  /// Persists a quarter turn. True means the viewer may show it.
  final Future<bool> Function(PhotoDraft photo, int degrees)? onRotate;

  /// Opens crop.
  final ValueChanged<PhotoDraft>? onCrop;

  /// Types onto a derived copy of the visible photo.
  final ValueChanged<PhotoDraft>? onType;

  /// Opens freehand drawing.
  final ValueChanged<PhotoDraft>? onDraw;

  /// Walks back one derived version.
  final ValueChanged<PhotoDraft>? onRevert;

  /// Session bytes keyed by photo id, read each time a photo is drawn.
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
  final Map<String, Uint8List> _loaded = <String, Uint8List>{};
  final Set<String> _loading = <String>{};
  final Map<String, String> _captions = <String, String>{};

  @override
  void initState() {
    super.initState();
    _photos = List<PhotoDraft>.of(widget.photos.value);
    _captions.addAll(widget.captions);
    _index = widget.initialIndex.clamp(
      0,
      _photos.isEmpty ? 0 : _photos.length - 1,
    );
    _controller = PageController(initialPage: _index);
    widget.photos.addListener(_photosChanged);
    _loadMissing();
  }

  @override
  void didUpdateWidget(PhotoViewerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photos != widget.photos) {
      oldWidget.photos.removeListener(_photosChanged);
      widget.photos.addListener(_photosChanged);
      _takePhotos();
      _loadMissing();
    }
  }

  /// Takes the newest photo list, keeping the position. A new version takes
  /// its source's caption, as the capture page copies it.
  void _photosChanged() {
    setState(_takePhotos);
    _loadMissing();
  }

  void _takePhotos() {
    final List<PhotoDraft> next = List<PhotoDraft>.of(widget.photos.value);
    _photos = next;
    for (final PhotoDraft photo in next) {
      final String? source = photo.derivedFrom;
      if (source != null && !_captions.containsKey(photo.id)) {
        final String? caption = _captions[source];
        if (caption != null) {
          _captions[photo.id] = caption;
        }
      }
    }
    _index = _index.clamp(0, next.isEmpty ? 0 : next.length - 1);
  }

  Uint8List? _bytesOf(PhotoDraft photo) {
    return widget.images[photo.id] ?? _loaded[photo.id];
  }

  void _loadMissing() {
    for (final PhotoDraft photo in _photos) {
      if (_bytesOf(photo) == null && _loading.add(photo.id)) {
        unawaited(_load(photo));
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
    _loading.remove(photo.id);
    if (!mounted || bytes == null) {
      return;
    }
    setState(() => _loaded[photo.id] = bytes);
  }

  @override
  void dispose() {
    widget.photos.removeListener(_photosChanged);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(current.photoType),
        actions: <Widget>[
          _action(AppIcons.rotate, Copy.photoRotate, () => _rotate(current)),
          _action(
            AppIcons.crop,
            Copy.photoCrop,
            () => widget.onCrop?.call(current),
          ),
          _action(
            AppIcons.draw,
            Copy.photoDraw,
            () => widget.onDraw?.call(current),
          ),
          _action(
            AppIcons.typeText,
            Copy.photoTypeOn,
            () => widget.onType?.call(current),
          ),
          if (current.derivedFrom != null)
            _action(
              AppIcons.undo,
              Copy.photoRevert,
              () => widget.onRevert?.call(current),
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
      bottomNavigationBar: _captionPanel(current),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onPressed) {
    return AppIconButton(
      icon: icon,
      tooltip: label,
      semanticLabel: label,
      outlined: false,
      onPressed: onPressed,
    );
  }

  /// The visible photo's caption with Edit and Delete, in place of the old
  /// storage-path line.
  Widget _captionPanel(PhotoDraft current) {
    final String caption = _captions[current.id] ?? '';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.x4,
          Space.x2,
          Space.x4,
          Space.x2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const AppSectionHeader(
              title: Copy.captureRecordCaption,
              dense: true,
            ),
            Text(
              caption.isEmpty ? Copy.photoNoCaption : caption,
              key: const ValueKey<String>('photo-viewer-caption'),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: Space.x2),
            Wrap(
              spacing: Space.x2,
              runSpacing: Space.x1,
              children: <Widget>[
                AppButton(
                  label: Copy.photoCaptionEdit,
                  icon: AppIcons.edit,
                  variant: AppButtonVariant.text,
                  onPressed: () => unawaited(_editCaption(current)),
                ),
                if (caption.isNotEmpty)
                  AppButton(
                    label: Copy.photoCaptionDelete,
                    icon: AppIcons.delete,
                    variant: AppButtonVariant.text,
                    onPressed: () => unawaited(_deleteCaption(current)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editCaption(PhotoDraft photo) async {
    final String? text = await showAppSheet<String>(
      context,
      title: Copy.photoCaptionEdit,
      contentSized: true,
      builder: (BuildContext _) =>
          _CaptionEditor(initial: _captions[photo.id] ?? ''),
    );
    if (text == null) {
      return;
    }
    await _write(photo, text);
  }

  Future<void> _deleteCaption(PhotoDraft photo) async {
    final String previous = _captions[photo.id] ?? '';
    final bool confirmed = await showAppConfirm(
      context,
      title: Copy.photoCaptionDelete,
      message: Copy.photoCaptionDeleteMessage,
      confirmLabel: Copy.photoCaptionDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    if (!await _write(photo, '') || !mounted) {
      return;
    }
    showAppSnack(
      context,
      Copy.photoCaptionDeleted,
      undoLabel: Copy.undo,
      onUndo: () => unawaited(_write(photo, previous)),
    );
  }

  Future<bool> _write(PhotoDraft photo, String text) async {
    final Future<bool> Function(PhotoDraft photo, String text)? write =
        widget.onCaptionChanged;
    if (write == null) {
      return false;
    }
    final bool saved = await write(photo, text);
    if (saved && mounted) {
      setState(() => _captions[photo.id] = text);
    }
    return saved;
  }

  Widget _frame(PhotoDraft photo) {
    if (widget.missingIds.contains(photo.id)) {
      return const Center(child: Text(Copy.missingPhoto));
    }
    final Uint8List? bytes = _bytesOf(photo);
    if (bytes == null) {
      return const Center(child: Text(Copy.loading));
    }
    return InteractiveViewer(
      child: Center(
        child: RotatedBox(
          quarterTurns: PhotoFrame.quarterTurns(photo.rotationDegrees),
          child: Image.memory(
            bytes,
            key: ValueKey<String>('photo-viewer-image-${photo.id}'),
            fit: BoxFit.contain,
          ),
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

/// A caption text field and Save. Pops the typed text.
class _CaptionEditor extends StatefulWidget {
  const _CaptionEditor({required this.initial});

  final String initial;

  @override
  State<_CaptionEditor> createState() => _CaptionEditorState();
}

class _CaptionEditorState extends State<_CaptionEditor> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: Space.x3,
        end: Space.x3,
        bottom: Space.x3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            label: Copy.captureRecordCaption,
            controller: _text,
            minLines: 2,
            maxLines: 5,
          ),
          const SizedBox(height: Space.x3),
          AppButton(
            label: Copy.save,
            expand: true,
            onPressed: () => Navigator.of(context).pop(_text.text),
          ),
        ],
      ),
    );
  }
}
