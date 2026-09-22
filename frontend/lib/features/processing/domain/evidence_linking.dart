/// Links an applied value to the photo, block or transcript that produced it.
final class EvidenceLinking {
  /// At least one row when a photo or a snippet exists.
  ///
  /// A region is kept when the provider supplied one. Local text keeps the
  /// block. Otherwise the whole photo is the link.
  static List<EvidenceDraft> forValue({
    String? photoId,
    String? regionJson,
    String? snippet,
    double? confidence,
    bool fromLocalText = false,
  }) {
    if ((photoId == null || photoId.isEmpty) &&
        (snippet == null || snippet.isEmpty)) {
      return const <EvidenceDraft>[];
    }
    final String sourceType =
        fromLocalText && (regionJson == null || regionJson.isEmpty)
        ? 'transcript'
        : 'photo';
    return <EvidenceDraft>[
      (
        sourceType: sourceType,
        photoId: photoId,
        regionJson: regionJson,
        snippet: snippet,
        confidence: confidence,
      ),
    ];
  }
}

/// One evidence row ready to insert.
typedef EvidenceDraft = ({
  String sourceType,
  String? photoId,
  String? regionJson,
  String? snippet,
  double? confidence,
});
