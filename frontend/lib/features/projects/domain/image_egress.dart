/// Which image paths an extraction request may carry (§7.1).
///
/// A project that holds images back sends text only: the OCR text and the
/// caption still go, the photos never leave the device. The processing
/// stage and the project switch both read this one rule.
abstract final class ImageEgress {
  /// Image paths a request may carry. Empty when images are held back.
  static List<String> paths({
    required bool holdImages,
    required List<String> images,
  }) {
    if (holdImages) {
      return const <String>[];
    }
    return images;
  }
}
