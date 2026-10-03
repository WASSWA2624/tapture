import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tapture/core/concurrency/isolate_runner.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/result.dart';

/// Document mode: finds a page in a durably written photo and makes a
/// straightened, higher-contrast copy of it. The original bytes are only
/// read, never rewritten; the copy is stored beside them as a derived file
/// (FE-SEC-08).
abstract final class DocumentCorrection {
  /// The long edge the photo is reduced to while the page is looked for.
  static const int sampleEdge = 256;

  /// Smallest share of the frame a page may cover.
  static const double minPageShare = 0.25;

  /// A page with a corner this close to the frame's edge, as a share of the
  /// frame, runs out of view or already fills it: it is not straightened.
  static const double frameMargin = 0.03;

  /// Share of the page outline the bright region must fill to count as one
  /// flat page rather than scattered highlights.
  static const double minFill = 0.8;

  /// Luminance gap between page and background below which no edge is
  /// trusted.
  static const double minContrast = 40;

  /// Contrast applied to the straightened copy.
  static const double contrast = 1.25;

  /// Looks for a page in encoded [bytes] and, when one is found, returns its
  /// straightened copy as a JPEG.
  static DocumentCorrectionResult correct(Uint8List bytes) {
    final img.Image? photo = _decode(bytes);
    if (photo == null) {
      return (boundary: DocumentBoundary.correctionFailed, corrected: null);
    }
    final List<img.Point>? page = findPage(photo);
    if (page == null) {
      return (boundary: DocumentBoundary.notDetected, corrected: null);
    }
    try {
      return (
        boundary: DocumentBoundary.detected,
        corrected: Uint8List.fromList(
          img.encodeJpg(
            _straighten(photo, page),
            quality: AppConstants.images.quality,
          ),
        ),
      );
    } on Object {
      return (boundary: DocumentBoundary.correctionFailed, corrected: null);
    }
  }

  /// [correct] on the isolate runner (FE-PERF-02). A failed run keeps the
  /// original and says so.
  static Future<DocumentCorrectionResult> correctOffThread(
    Uint8List bytes,
  ) async {
    final Result<DocumentCorrectionResult> run = await runIsolate(
      correct,
      bytes,
    );
    return switch (run) {
      Success<DocumentCorrectionResult>(
        :final DocumentCorrectionResult value,
      ) =>
        value,
      FailureResult<DocumentCorrectionResult>() => (
        boundary: DocumentBoundary.correctionFailed,
        corrected: null,
      ),
    };
  }

  /// The page's corners in [photo], top-left, top-right, bottom-right,
  /// bottom-left, or null when no page stands out from its background.
  static List<img.Point>? findPage(img.Image photo) {
    final int edge = max(photo.width, photo.height);
    final double scale = edge <= sampleEdge ? 1 : edge / sampleEdge;
    final img.Image sample = scale == 1
        ? photo
        : img.copyResize(
            photo,
            width: max(1, (photo.width / scale).round()),
            height: max(1, (photo.height / scale).round()),
            interpolation: img.Interpolation.average,
          );
    final int width = sample.width;
    final int height = sample.height;
    if (width < 8 || height < 8) {
      return null;
    }
    final Uint8List luma = Uint8List(width * height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final num value = img.getLuminanceNormalized(sample.getPixel(x, y));
        luma[y * width + x] = (value * 255).round().clamp(0, 255);
      }
    }
    final int threshold = _otsu(luma);
    if (_contrastAround(luma, threshold) < minContrast) {
      return null;
    }
    final List<int> region = _largestBrightRegion(luma, width, threshold);
    if (region.isEmpty) {
      return null;
    }
    final List<img.Point> corners = _corners(region, width);
    final double area = _area(corners);
    final double frame = (width * height).toDouble();
    if (area < frame * minPageShare || region.length < area * minFill) {
      return null;
    }
    if (_touchesBorder(corners, width, height)) {
      return null;
    }
    return <img.Point>[
      for (final img.Point corner in corners)
        img.Point(corner.x * scale, corner.y * scale),
    ];
  }
}

/// Where document mode stands after a shot.
enum DocumentBoundary {
  /// A page edge was found and a straightened copy is ready.
  detected,

  /// No page edge; the photo is kept as a normal photo.
  notDetected,

  /// A page could not be straightened; the original is kept.
  correctionFailed,
}

/// What [DocumentCorrection.correct] found, with the straightened JPEG when
/// a page was found.
typedef DocumentCorrectionResult = ({
  DocumentBoundary boundary,
  Uint8List? corrected,
});

img.Image? _decode(Uint8List bytes) {
  try {
    final img.Image? decoded = img.decodeImage(bytes);
    return decoded == null ? null : img.bakeOrientation(decoded);
  } on Object {
    return null;
  }
}

/// Maps the page quad in [photo] onto an upright rectangle as long as its
/// edges and raises its contrast.
img.Image _straighten(img.Image photo, List<img.Point> page) {
  final img.Point topLeft = page[0];
  final img.Point topRight = page[1];
  final img.Point bottomRight = page[2];
  final img.Point bottomLeft = page[3];
  final int width = max(
    2,
    ((_distance(topLeft, topRight) + _distance(bottomLeft, bottomRight)) / 2)
        .round(),
  );
  final int height = max(
    2,
    ((_distance(topLeft, bottomLeft) + _distance(topRight, bottomRight)) / 2)
        .round(),
  );
  final img.Image source = photo.numChannels == 3
      ? photo
      : photo.convert(numChannels: 3);
  final img.Image straight = img.copyRectify(
    source,
    topLeft: topLeft,
    topRight: topRight,
    bottomLeft: bottomLeft,
    bottomRight: bottomRight,
    interpolation: img.Interpolation.linear,
    toImage: img.Image(width: width, height: height),
  );
  return img.adjustColor(straight, contrast: DocumentCorrection.contrast);
}

double _distance(img.Point a, img.Point b) {
  final num dx = a.x - b.x;
  final num dy = a.y - b.y;
  return sqrt(dx * dx + dy * dy);
}

/// Otsu's threshold over [luma]: the split that best separates page from
/// background.
int _otsu(Uint8List luma) {
  final List<int> histogram = List<int>.filled(256, 0);
  for (final int value in luma) {
    histogram[value]++;
  }
  final int total = luma.length;
  var sumAll = 0.0;
  for (var i = 0; i < 256; i++) {
    sumAll += i * histogram[i];
  }
  var sumBelow = 0.0;
  var weightBelow = 0;
  var best = 0.0;
  var threshold = 127;
  for (var i = 0; i < 256; i++) {
    weightBelow += histogram[i];
    if (weightBelow == 0) {
      continue;
    }
    final int weightAbove = total - weightBelow;
    if (weightAbove == 0) {
      break;
    }
    sumBelow += i * histogram[i];
    final double meanBelow = sumBelow / weightBelow;
    final double meanAbove = (sumAll - sumBelow) / weightAbove;
    final double between =
        weightBelow *
        weightAbove *
        (meanBelow - meanAbove) *
        (meanBelow - meanAbove);
    if (between > best) {
      best = between;
      threshold = i;
    }
  }
  return threshold;
}

/// Mean luminance above [threshold] minus mean luminance at or below it.
double _contrastAround(Uint8List luma, int threshold) {
  var above = 0;
  var aboveSum = 0;
  var belowSum = 0;
  for (final int value in luma) {
    if (value > threshold) {
      above++;
      aboveSum += value;
    } else {
      belowSum += value;
    }
  }
  final int below = luma.length - above;
  if (above == 0 || below == 0) {
    return 0;
  }
  return aboveSum / above - belowSum / below;
}

/// Indexes of the largest four-connected region brighter than [threshold].
List<int> _largestBrightRegion(Uint8List luma, int width, int threshold) {
  final Uint8List seen = Uint8List(luma.length);
  List<int> largest = const <int>[];
  final Queue<int> queue = Queue<int>();
  for (var start = 0; start < luma.length; start++) {
    if (seen[start] == 1 || luma[start] <= threshold) {
      continue;
    }
    final List<int> region = <int>[];
    seen[start] = 1;
    queue.add(start);
    while (queue.isNotEmpty) {
      final int at = queue.removeFirst();
      region.add(at);
      final int x = at % width;
      for (final int next in <int>[
        if (x > 0) at - 1,
        if (x < width - 1) at + 1,
        at - width,
        at + width,
      ]) {
        if (next >= 0 &&
            next < luma.length &&
            seen[next] == 0 &&
            luma[next] > threshold) {
          seen[next] = 1;
          queue.add(next);
        }
      }
    }
    if (region.length > largest.length) {
      largest = region;
    }
  }
  return largest;
}

/// The region's extreme corners: smallest and largest x + y, and largest and
/// smallest x - y, in top-left, top-right, bottom-right, bottom-left order.
List<img.Point> _corners(List<int> region, int width) {
  int? topLeft;
  int? bottomRight;
  int? topRight;
  int? bottomLeft;
  var minSum = 1 << 30;
  var maxSum = -1;
  var maxDiff = -(1 << 30);
  var minDiff = 1 << 30;
  for (final int at in region) {
    final int x = at % width;
    final int y = at ~/ width;
    if (x + y < minSum) {
      minSum = x + y;
      topLeft = at;
    }
    if (x + y > maxSum) {
      maxSum = x + y;
      bottomRight = at;
    }
    if (x - y > maxDiff) {
      maxDiff = x - y;
      topRight = at;
    }
    if (x - y < minDiff) {
      minDiff = x - y;
      bottomLeft = at;
    }
  }
  img.Point point(int at) => img.Point(at % width, at ~/ width);
  return <img.Point>[
    point(topLeft!),
    point(topRight!),
    point(bottomRight!),
    point(bottomLeft!),
  ];
}

/// Shoelace area of the quad [corners].
double _area(List<img.Point> corners) {
  var twice = 0.0;
  for (var i = 0; i < corners.length; i++) {
    final img.Point a = corners[i];
    final img.Point b = corners[(i + 1) % corners.length];
    twice += a.x * b.y - b.x * a.y;
  }
  return twice.abs() / 2;
}

/// Whether any corner sits on the frame's edge: the page runs out of view,
/// or fills the frame, so there is no whole page to straighten.
bool _touchesBorder(List<img.Point> corners, int width, int height) {
  final double dx = width * DocumentCorrection.frameMargin;
  final double dy = height * DocumentCorrection.frameMargin;
  return corners.any(
    (img.Point corner) =>
        corner.x <= dx ||
        corner.y <= dy ||
        corner.x >= width - 1 - dx ||
        corner.y >= height - 1 - dy,
  );
}
