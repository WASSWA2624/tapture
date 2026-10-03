import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/feedback/app_banner.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/core/widgets/record_thumb.dart';
import 'package:tapture/features/records/records.dart'
    show RecordPhoto, RecordPhotoViewerScreen;

import '../domain/review_repository.dart';

/// The photo region, document page or transcript passage a value came from
/// (task 016 step 3).
///
/// Each piece of evidence is named by its source. A photo is drawn from its
/// cached thumbnail with the region the provider supplied outlined on it;
/// with no region the whole photo is shown, never an empty highlight. The
/// OCR snippet or transcript passage sits beside it. The full photo opens
/// in the record photo viewer, not a second viewer.
final class EvidenceViewer extends StatelessWidget {
  /// Creates the viewer of [evidence], resolving photos among [photos].
  const EvidenceViewer({
    this.evidence = const <ValueEvidence>[],
    this.photos = const <RecordPhoto>[],
    this.failure,
    this.onOpenPhoto,
    super.key,
  });

  /// The value's evidence, in the order it was linked.
  final List<ValueEvidence> evidence;

  /// The record's photos, which evidence names by id.
  final List<RecordPhoto> photos;

  /// Why the evidence could not be read.
  final Failure? failure;

  /// Opens the full photo at an index of [photos]. Defaults to the record
  /// photo viewer.
  final ValueChanged<int>? onOpenPhoto;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Failure? failed = failure;
    if (failed != null) {
      return AppBanner(
        key: const ValueKey<String>('evidence-failure'),
        message: failed.message,
        icon: AppIcons.error,
        tone: SnackTone.error,
      );
    }
    if (evidence.isEmpty) {
      return AppBanner(
        key: const ValueKey<String>('evidence-empty'),
        message: localCopy.reviewEvidenceEmpty,
        icon: AppIcons.photoLibrary,
        tone: SnackTone.info,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int index = 0; index < evidence.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: Space.x4),
          _EvidenceRow(
            item: evidence[index],
            photos: photos,
            onOpenPhoto: (int at) => _open(context, at),
          ),
        ],
      ],
    );
  }

  void _open(BuildContext context, int index) {
    final ValueChanged<int>? open = onOpenPhoto;
    if (open != null) {
      open(index);
      return;
    }
    unawaited(
      RecordPhotoViewerScreen.open(
        context,
        photos: photos,
        initialIndex: index,
      ),
    );
  }
}

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({
    required this.item,
    required this.photos,
    required this.onOpenPhoto,
  });

  final ValueEvidence item;
  final List<RecordPhoto> photos;
  final ValueChanged<int> onOpenPhoto;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final AppColors colors = context.colors;
    final int at = photos.indexWhere(
      (RecordPhoto photo) => photo.id == item.photoId,
    );
    final String snippet = (item.snippet ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          _sourceLabel(item, localizedCopy: Copy.of(context)),
          key: const ValueKey<String>('evidence-source'),
          style: AppText.label.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: Space.x2),
        if (at >= 0) ...<Widget>[
          _Photo(
            photo: photos[at],
            region: _regionOf(
              item.regionJson,
              width: item.photoWidth,
              height: item.photoHeight,
            ),
            width: item.photoWidth,
            height: item.photoHeight,
            label: localCopy.recordPhotoPosition(at + 1, photos.length),
            onTap: () => onOpenPhoto(at),
          ),
          const SizedBox(height: Space.x2),
        ],
        if (snippet.isNotEmpty) ...<Widget>[
          Text(
            snippet,
            key: const ValueKey<String>('evidence-snippet'),
            style: AppText.body.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: Space.x2),
        ],
        if (at >= 0)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
              key: const ValueKey<String>('evidence-open-photo'),
              label: localCopy.reviewOpenPhoto,
              icon: AppIcons.expandPanel,
              variant: AppButtonVariant.text,
              onPressed: () => onOpenPhoto(at),
            ),
          ),
      ],
    );
  }
}

/// The photo's thumbnail, square as every thumbnail is, with [region]
/// outlined where it falls on the cropped square.
class _Photo extends StatelessWidget {
  const _Photo({
    required this.photo,
    required this.region,
    required this.width,
    required this.height,
    required this.label,
    required this.onTap,
  });

  final RecordPhoto photo;

  /// The region as fractions of the whole photo, or null for the whole
  /// photo.
  final Rect? region;
  final int? width;
  final int? height;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final LocalizedCopy localCopy = Copy.of(context);

        final double edge = math.min(constraints.maxWidth, Sizes.listPane);
        final Rect? outline = _onSquare(region, edge);
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox.square(
            key: const ValueKey<String>('evidence-photo'),
            dimension: edge,
            child: Stack(
              children: <Widget>[
                RecordThumb(
                  sha256: photo.sha256,
                  storagePath: photo.storagePath,
                  quarterTurns: photo.quarterTurns,
                  size: edge,
                  hasCaption: photo.hasCaption,
                  semanticLabel: label,
                  onTap: onTap,
                ),
                if (outline != null)
                  Positioned.fromRect(
                    rect: outline,
                    child: IgnorePointer(
                      child: Semantics(
                        label: localCopy.reviewEvidenceRegion,
                        child: DecoratedBox(
                          key: const ValueKey<String>('evidence-region'),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: colors.primary,
                              width: Space.x1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// [fraction] of the photo placed on the [edge] square the thumbnail
  /// crops it to (cover fit), clipped to the square; null when nothing of
  /// it shows.
  Rect? _onSquare(Rect? fraction, double edge) {
    if (fraction == null) {
      return null;
    }
    final double w = (width ?? 0) > 0 ? width!.toDouble() : 1;
    final double h = (height ?? 0) > 0 ? height!.toDouble() : 1;
    final double scale = edge / math.min(w, h);
    final double dx = (edge - w * scale) / 2;
    final double dy = (edge - h * scale) / 2;
    final Rect placed = Rect.fromLTRB(
      fraction.left * w * scale + dx,
      fraction.top * h * scale + dy,
      fraction.right * w * scale + dx,
      fraction.bottom * h * scale + dy,
    ).intersect(Rect.fromLTWH(0, 0, edge, edge));
    return placed.isEmpty ? null : placed;
  }
}

String _sourceLabel(ValueEvidence item, {LocalizedCopy? localizedCopy}) {
  return switch (item.kind) {
    EvidenceKind.photo => (localizedCopy ?? Copy.english).reviewEvidencePhoto,
    EvidenceKind.document =>
      (localizedCopy ?? Copy.english).reviewEvidenceDocument(item.page),
    EvidenceKind.transcript =>
      (localizedCopy ?? Copy.english).reviewEvidenceTranscript,
  };
}

/// The stored region as fractions of the whole photo: `{left, top, right,
/// bottom}` in pixels of a [width] by [height] photo, or `{x, y, width,
/// height}` as fractions. Null when there is none or it cannot be read.
Rect? _regionOf(String? json, {int? width, int? height}) {
  if (json == null || json.trim().isEmpty) {
    return null;
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) {
    return null;
  }
  final Map<Object?, Object?> region = decoded;
  double? read(String key) {
    final Object? value = region[key];
    return value is num ? value.toDouble() : null;
  }

  final double? left = read('left');
  final double? top = read('top');
  final double? right = read('right');
  final double? bottom = read('bottom');
  if (left != null && top != null && right != null && bottom != null) {
    final double w = (width ?? 0) > 0 ? width!.toDouble() : 1;
    final double h = (height ?? 0) > 0 ? height!.toDouble() : 1;
    return Rect.fromLTRB(left / w, top / h, right / w, bottom / h);
  }
  final double? x = read('x');
  final double? y = read('y');
  final double? across = read('width');
  final double? down = read('height');
  if (x != null && y != null && across != null && down != null) {
    return Rect.fromLTWH(x, y, across, down);
  }
  return null;
}
