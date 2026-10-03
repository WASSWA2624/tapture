import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_page.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/async_value_view.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_loading_state.dart';

import '../domain/record_photo.dart';
import 'record_photo_providers.dart';

/// A saved record's photos, full size and read-only (task 014 step 4): the
/// one place a record's original photo is opened (FE-PERF-04). Swipe moves
/// between the photos; pinch zooms. Each photo is turned the way it was
/// saved and shows its caption underneath. Nothing here changes a photo;
/// the record page's photo edit does that.
///
/// Capture's own viewer edits a capture session's photos (rotate, crop,
/// draw, captions) and holds session bytes, so a saved record gets this
/// read-only one instead.
class RecordPhotoViewerScreen extends StatefulWidget {
  /// Creates the viewer over [photos], opened at [initialIndex].
  const RecordPhotoViewerScreen({
    required this.photos,
    this.initialIndex = 0,
    super.key,
  });

  /// The record's photos, in their sort order.
  final List<RecordPhoto> photos;

  /// The photo shown first.
  final int initialIndex;

  /// Opens the viewer over [photos] at [initialIndex], above the page that
  /// asked; back returns to it.
  static Future<void> open(
    BuildContext context, {
    required List<RecordPhoto> photos,
    int initialIndex = 0,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext _) =>
            RecordPhotoViewerScreen(photos: photos, initialIndex: initialIndex),
      ),
    );
  }

  @override
  State<RecordPhotoViewerScreen> createState() =>
      _RecordPhotoViewerScreenState();
}

class _RecordPhotoViewerScreenState extends State<RecordPhotoViewerScreen> {
  late final int _first = widget.photos.isEmpty
      ? 0
      : widget.initialIndex.clamp(0, widget.photos.length - 1);
  late final PageController _pages = PageController(initialPage: _first);

  /// The photo on screen, which names the page and picks the caption.
  late final ValueNotifier<int> _shown = ValueNotifier<int>(_first);

  @override
  void dispose() {
    _pages.dispose();
    _shown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final List<RecordPhoto> photos = widget.photos;
    if (photos.isEmpty) {
      return AppPage(
        key: const ValueKey<String>('route-record-photo'),
        title: localCopy.missingPhoto,
        body: AppEmptyState(
          icon: AppIcons.brokenFile,
          headline: localCopy.missingPhoto,
          message: localCopy.photoUnreadableRecovery,
        ),
      );
    }
    return ValueListenableBuilder<int>(
      valueListenable: _shown,
      builder: (BuildContext context, int shown, Widget? _) {
        final LocalizedCopy localCopy = Copy.of(context);

        return AppPage(
          key: const ValueKey<String>('route-record-photo'),
          title: localCopy.recordPhotoPosition(shown + 1, photos.length),
          scrollable: false,
          inset: false,
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: PageView.builder(
                      key: const ValueKey<String>('record-photo-pages'),
                      controller: _pages,
                      itemCount: photos.length,
                      onPageChanged: (int index) => _shown.value = index,
                      itemBuilder: (BuildContext _, int index) {
                        final LocalizedCopy localCopy = Copy.of(context);

                        return _PhotoPage(
                          photo: photos[index],
                          label: localCopy.recordPhotoPosition(
                            index + 1,
                            photos.length,
                          ),
                        );
                      },
                    ),
                  ),
                  // The caption never takes more than a third of the page,
                  // and scrolls within it at 200 percent text (FE-A11Y-03).
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: box.maxHeight / 3),
                    child: _Caption(photo: photos[shown]),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// One photo, full size: read from storage, then drawn turned the way it
/// was saved, zoomable. A photo still loading shows a placeholder; one that
/// cannot be read says so, with a retry.
class _PhotoPage extends ConsumerWidget {
  const _PhotoPage({required this.photo, required this.label});

  final RecordPhoto photo;

  /// What a screen reader calls the photo.
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Uint8List> bytes = ref.watch(
      recordPhotoBytesProvider(photo.storagePath),
    );
    return switch (bytes) {
      AsyncData<Uint8List>(:final Uint8List value) => InteractiveViewer(
        key: ValueKey<String>('record-photo-${photo.id}'),
        child: Center(
          child: RotatedBox(
            quarterTurns: photo.quarterTurns % 4,
            child: Image.memory(
              value,
              key: ValueKey<String>('record-photo-image-${photo.id}'),
              fit: BoxFit.contain,
              semanticLabel: label,
              gaplessPlayback: true,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stack) {
                    final LocalizedCopy localCopy = Copy.of(context);

                    return AppEmptyState(
                      icon: AppIcons.brokenFile,
                      headline: localCopy.missingPhoto,
                      message: localCopy.photoUnreadable,
                    );
                  },
            ),
          ),
        ),
      ),
      _ => SingleChildScrollView(
        key: ValueKey<String>('record-photo-state-${photo.id}'),
        padding: EdgeInsets.all(AppPage.gutter(context)),
        child: AsyncValueView<Uint8List>(
          value: bytes,
          loadingShape: SkeletonShape.card,
          loadingCount: 1,
          onRetry: () =>
              ref.invalidate(recordPhotoBytesProvider(photo.storagePath)),
          data: (Uint8List _) => const SizedBox.shrink(),
        ),
      ),
    };
  }
}

/// The shown photo's caption, read-only, under the photo.
class _Caption extends StatelessWidget {
  const _Caption({required this.photo});

  final RecordPhoto photo;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AppColors colors = context.colors;
    final double gutter = AppPage.gutter(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: const ValueKey<String>('record-photo-caption'),
        padding: EdgeInsets.fromLTRB(gutter, Space.x2, gutter, Space.x2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppSectionHeader(
              title: localCopy.captureRecordCaption,
              dense: true,
            ),
            Text(
              photo.hasCaption ? photo.caption : localCopy.photoNoCaption,
              style: AppText.body.copyWith(color: colors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
