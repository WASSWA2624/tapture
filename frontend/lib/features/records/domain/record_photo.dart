/// One live photo on a record, as the records screens need it.
///
/// Pure Dart, so the domain can carry photos without the Flutter-bound
/// `PhotoAsset`; presentation turns it into a thumbnail through the shared
/// thumbnail service (FE-PERF-04).
final class RecordPhoto {
  /// Creates a photo reference.
  const RecordPhoto({
    required this.id,
    required this.sha256,
    required this.storagePath,
    this.quarterTurns = 0,
    this.caption = '',
    this.sortOrder = 0,
    this.photoType = '',
  });

  /// Merge id of the photo row.
  final String id;

  /// Content hash of the original file; thumbnails are cached under it.
  final String sha256;

  /// Where the original file sits, in the form the thumbnail service takes.
  final String storagePath;

  /// Clockwise quarter turns to apply when drawing, 0 to 3.
  final int quarterTurns;

  /// The photo's live caption (refined, else raw), or empty.
  final String caption;

  /// Position among the record's photos, smallest first.
  final int sortOrder;

  /// The photo type the operator chose (front, plate…), or empty.
  final String photoType;

  /// Whether the photo carries a caption.
  bool get hasCaption => caption.trim().isNotEmpty;

  /// Returns a copy with the provided fields replaced.
  RecordPhoto copyWith({
    String? id,
    String? sha256,
    String? storagePath,
    int? quarterTurns,
    String? caption,
    int? sortOrder,
    String? photoType,
  }) {
    return RecordPhoto(
      id: id ?? this.id,
      sha256: sha256 ?? this.sha256,
      storagePath: storagePath ?? this.storagePath,
      quarterTurns: quarterTurns ?? this.quarterTurns,
      caption: caption ?? this.caption,
      sortOrder: sortOrder ?? this.sortOrder,
      photoType: photoType ?? this.photoType,
    );
  }

  @override
  int get hashCode => Object.hash(
    id,
    sha256,
    storagePath,
    quarterTurns,
    caption,
    sortOrder,
    photoType,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RecordPhoto &&
            other.id == id &&
            other.sha256 == sha256 &&
            other.storagePath == storagePath &&
            other.quarterTurns == quarterTurns &&
            other.caption == caption &&
            other.sortOrder == sortOrder &&
            other.photoType == photoType);
  }

  @override
  String toString() => 'RecordPhoto($id)';
}
