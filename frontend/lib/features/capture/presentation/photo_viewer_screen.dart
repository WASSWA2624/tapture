import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_overflow_menu.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/feedback/app_bottom_sheet.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/fields/app_text_field.dart';
import 'package:tapture/core/widgets/state_refresh.dart';
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
    this.onRedact,
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

  /// Opens the saved masks applied to every outbound copy.
  final ValueChanged<PhotoDraft>? onRedact;

  /// Walks back one derived version.
  final ValueChanged<PhotoDraft>? onRevert;

  /// Session bytes keyed by photo id, read each time a photo is drawn.
  final Map<String, Uint8List> images;

  /// Loads stored bytes when [images] does not hold them.
  final Future<Uint8List?> Function(PhotoDraft photo)? loadBytes;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen>
    with StateRefresh {
  late final PageController _controller;
  late List<PhotoDraft> _photos;
  late int _index;
  final Map<_PhotoSource, Uint8List> _loaded = <_PhotoSource, Uint8List>{};
  final Map<_PhotoSource, Uint8List> _drawn = <_PhotoSource, Uint8List>{};
  final Set<_PhotoSource> _unreadable = <_PhotoSource>{};
  bool _loading = false;
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
    _loadWindow();
  }

  @override
  void didUpdateWidget(PhotoViewerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photos != widget.photos) {
      oldWidget.photos.removeListener(_photosChanged);
      widget.photos.addListener(_photosChanged);
      _takePhotos();
    }
    _loadWindow();
  }

  /// Takes the newest photo list, keeping the position. A new version takes
  /// its source's caption, as the capture page copies it.
  void _photosChanged() {
    refresh(_takePhotos);
    _loadWindow();
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
    return widget.images[photo.id] ?? _loaded[_sourceOf(photo)];
  }

  /// Keep full originals only for the current page and its neighbors. Reads
  /// run one at a time, prioritizing the visible page when someone swipes
  /// while a previous read is still finishing.
  List<PhotoDraft> _window() => <PhotoDraft>[
    if (_photos.isNotEmpty) _photos[_index],
    if (_index + 1 < _photos.length) _photos[_index + 1],
    if (_index > 0) _photos[_index - 1],
  ];

  void _loadWindow() {
    final List<PhotoDraft> window = _window();
    final Set<_PhotoSource> sources = window.map(_sourceOf).toSet();
    _drawn.removeWhere((_PhotoSource source, Uint8List bytes) {
      if (sources.contains(source)) {
        return false;
      }
      // Flutter's global image cache otherwise retains MemoryImage's raw
      // bytes and decoded frame after the viewer drops its own reference.
      unawaited(MemoryImage(bytes).evict());
      return true;
    });
    _loaded.removeWhere((_PhotoSource source, _) => !sources.contains(source));
    _unreadable.removeWhere((_PhotoSource source) => !sources.contains(source));
    final Future<Uint8List?> Function(PhotoDraft photo)? load =
        widget.loadBytes;
    if (_loading || load == null) {
      return;
    }
    for (final PhotoDraft photo in window) {
      if (_bytesOf(photo) == null &&
          !widget.missingIds.contains(photo.id) &&
          !_unreadable.contains(_sourceOf(photo))) {
        _loading = true;
        unawaited(_load(photo, load));
        return;
      }
    }
  }

  Future<void> _load(
    PhotoDraft photo,
    Future<Uint8List?> Function(PhotoDraft photo) load,
  ) async {
    Uint8List? bytes;
    try {
      bytes = await load(photo);
    } on Object {
      // A failing read is a missing photo, never an unhandled async error.
    }
    _loading = false;
    if (!mounted) {
      return;
    }
    final _PhotoSource source = _sourceOf(photo);
    if (_window().any((PhotoDraft next) => _sourceOf(next) == source)) {
      refresh(() {
        if (bytes case final Uint8List value) {
          _loaded[source] = value;
        } else {
          _unreadable.add(source);
        }
      });
    }
    _loadWindow();
  }

  @override
  void dispose() {
    widget.photos.removeListener(_photosChanged);
    _controller.dispose();
    for (final Uint8List bytes in _drawn.values) {
      unawaited(MemoryImage(bytes).evict());
    }
    _drawn.clear();
    _loaded.clear();
    _unreadable.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    if (_photos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(localCopy.photo)),
        body: Center(child: Text(localCopy.missingPhoto)),
      );
    }
    final PhotoDraft current = _photos[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(current.photoType),
        actions: <Widget>[
          if (widget.onRedact != null)
            AppOverflowMenu(
              items: <AppOverflowAction>[
                AppOverflowAction(
                  label: localCopy.redactionTitle,
                  icon: AppIcons.hide,
                  onTap: () => widget.onRedact?.call(current),
                ),
                AppOverflowAction(
                  label: localCopy.photoRotate,
                  icon: AppIcons.rotate,
                  onTap: () => unawaited(_rotate(current)),
                ),
              ],
            )
          else
            _action(
              AppIcons.rotate,
              localCopy.photoRotate,
              () => _rotate(current),
            ),
          _action(
            AppIcons.crop,
            localCopy.photoCrop,
            () => widget.onCrop?.call(current),
          ),
          _action(
            AppIcons.draw,
            localCopy.photoDraw,
            () => widget.onDraw?.call(current),
          ),
          _action(
            AppIcons.typeText,
            localCopy.photoTypeOn,
            () => widget.onType?.call(current),
          ),
          if (current.derivedFrom != null)
            _action(
              AppIcons.undo,
              localCopy.photoRevert,
              () => widget.onRevert?.call(current),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: _photos.length,
        onPageChanged: (int i) {
          refresh(() => _index = i);
          _loadWindow();
        },
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
    final LocalizedCopy localCopy = Copy.of(context);

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
            AppSectionHeader(
              title: localCopy.captureRecordCaption,
              dense: true,
            ),
            Text(
              caption.isEmpty ? localCopy.photoNoCaption : caption,
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
                  label: localCopy.photoCaptionEdit,
                  icon: AppIcons.edit,
                  variant: AppButtonVariant.text,
                  onPressed: () => unawaited(_editCaption(current)),
                ),
                if (caption.isNotEmpty)
                  AppButton(
                    label: localCopy.photoCaptionDelete,
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
    final LocalizedCopy localCopy = Copy.of(context);

    final String? text = await showAppSheet<String>(
      context,
      title: localCopy.photoCaptionEdit,
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
    final LocalizedCopy localCopy = Copy.of(context);

    final String previous = _captions[photo.id] ?? '';
    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.photoCaptionDelete,
      message: localCopy.photoCaptionDeleteMessage,
      confirmLabel: localCopy.photoCaptionDelete,
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
      localCopy.photoCaptionDeleted,
      undoLabel: localCopy.undo,
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
      refresh(() => _captions[photo.id] = text);
    }
    return saved;
  }

  Widget _frame(PhotoDraft photo) {
    final LocalizedCopy localCopy = Copy.of(context);

    if (widget.missingIds.contains(photo.id) ||
        _unreadable.contains(_sourceOf(photo))) {
      return Center(child: Text(localCopy.missingPhoto));
    }
    final Uint8List? bytes = _bytesOf(photo);
    if (bytes == null) {
      return Center(child: Text(localCopy.loading));
    }
    _drawn[_sourceOf(photo)] = bytes;
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
    refresh(() {
      _photos[_index] = _photos[_index].copyWith(
        rotationDegrees:
            ((_photos[_index].rotationDegrees + 90) % 360 + 360) % 360,
      );
    });
  }
}

typedef _PhotoSource = ({String id, String path, String hash});

_PhotoSource _sourceOf(PhotoDraft photo) =>
    (id: photo.id, path: photo.relativePath, hash: photo.sha256);

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
    final LocalizedCopy localCopy = Copy.of(context);

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
            label: localCopy.captureRecordCaption,
            controller: _text,
            minLines: 2,
            maxLines: 5,
          ),
          const SizedBox(height: Space.x3),
          AppButton(
            label: localCopy.save,
            expand: true,
            onPressed: () => Navigator.of(context).pop(_text.text),
          ),
        ],
      ),
    );
  }
}
