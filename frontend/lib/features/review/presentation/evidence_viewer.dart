import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';
import 'package:tapture/core/widgets/states/app_error_state.dart';
import 'package:tapture/features/records/records.dart' show RecordPhoto;

/// The photo region, document page or transcript a value came from (task 016).
///
/// A region is highlighted when the provider supplied one. Otherwise the
/// whole photo is shown. The full image opens in the record photo viewer.
final class EvidenceViewer extends StatelessWidget {
  /// Creates the viewer.
  const EvidenceViewer({
    this.photo,
    this.regionJson,
    this.snippet,
    this.sourceLabel = '',
    this.failure,
    this.onOpenPhoto,
    super.key,
  });

  /// The photo, when the evidence is a photo. Null for a transcript only.
  final RecordPhoto? photo;

  /// Bounding box JSON `{x, y, width, height}` as fractions, or null.
  final String? regionJson;

  /// OCR snippet or transcript passage.
  final String? snippet;

  /// Where the evidence came from, named beside the image.
  final String sourceLabel;

  /// Why the evidence could not be read.
  final Failure? failure;

  /// Opens the full photo. Defaults to [RecordPhotoViewerScreen.open].
  final VoidCallback? onOpenPhoto;

  @override
  Widget build(BuildContext context) {
    final Failure? failed = failure;
    if (failed != null) {
      return AppErrorState(failure: failed);
    }
    final RecordPhoto? image = photo;
    final String? passage = snippet?.trim();
    if (image == null && (passage == null || passage.isEmpty)) {
      return const AppEmptyState(
        icon: AppIcons.photoLibrary,
        headline: Copy.reviewEvidenceEmpty,
        message: Copy.reviewEvidenceEmpty,
      );
    }
    final _Region? region = _regionOf(regionJson);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (sourceLabel.isNotEmpty) Text(sourceLabel),
        if (image != null)
          SizedBox(
            key: const ValueKey<String>('evidence-photo'),
            height: 160,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const SizedBox.expand(),
                if (region != null)
                  Align(
                    alignment: Alignment(region.x * 2 - 1, region.y * 2 - 1),
                    child: FractionallySizedBox(
                      key: const ValueKey<String>('evidence-region'),
                      widthFactor: region.width,
                      heightFactor: region.height,
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            ),
          ),
        if (passage != null && passage.isNotEmpty)
          Text(passage, key: const ValueKey<String>('evidence-snippet')),
        if (image != null)
          AppButton(
            key: const ValueKey<String>('evidence-open-photo'),
            label: Copy.reviewOpenPhoto,
            onPressed: onOpenPhoto,
          ),
      ],
    );
  }
}

final class _Region {
  const _Region(this.x, this.y, this.width, this.height);

  final double x;
  final double y;
  final double width;
  final double height;
}

_Region? _regionOf(String? json) {
  if (json == null || json.trim().isEmpty) {
    return null;
  }
  try {
    final Object? decoded = jsonDecode(json);
    if (decoded is! Map) {
      return null;
    }
    final double? x = _num(decoded['x']);
    final double? y = _num(decoded['y']);
    final double? width = _num(decoded['width']);
    final double? height = _num(decoded['height']);
    if (x == null || y == null || width == null || height == null) {
      return null;
    }
    return _Region(x, y, width, height);
  } on FormatException {
    return null;
  }
}

double? _num(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return null;
}
