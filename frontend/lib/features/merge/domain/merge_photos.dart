/// Photos merge on content hash, never by rewriting bytes (task 019).
final class MergePhotos {
  /// One stored file per hash. Local order is kept; new incoming photos
  /// follow it. Captions from both sides are kept.
  static List<MergedPhoto> union({
    required List<PhotoSide> local,
    required List<PhotoSide> incoming,
  }) {
    final Map<String, MergedPhoto> byHash = <String, MergedPhoto>{};
    final List<String> order = <String>[];
    void take(PhotoSide photo) {
      final MergedPhoto? existing = byHash[photo.sha256];
      if (existing == null) {
        order.add(photo.sha256);
        byHash[photo.sha256] = (
          sha256: photo.sha256,
          path: photo.path,
          captions: <String>[photo.caption],
        );
        return;
      }
      if (!existing.captions.contains(photo.caption) &&
          photo.caption.isNotEmpty) {
        byHash[photo.sha256] = (
          sha256: existing.sha256,
          path: existing.path,
          captions: <String>[...existing.captions, photo.caption],
        );
      }
    }

    for (final PhotoSide photo in local) {
      take(photo);
    }
    for (final PhotoSide photo in incoming) {
      take(photo);
    }
    return <MergedPhoto>[for (final String hash in order) byHash[hash]!];
  }
}

/// One photo as a device holds it.
typedef PhotoSide = ({String sha256, String path, String caption});

/// The single stored file and every caption.
typedef MergedPhoto = ({String sha256, String path, List<String> captions});
