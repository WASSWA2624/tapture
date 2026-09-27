import 'photo_naming.dart';
import 'renameable_photo.dart';

/// Renames provisional photo files once an identity is confirmed (task 018).
///
/// The original name stays on the photo. Every stored path that pointed at
/// the old file is updated with it, so nothing is left pointing at a missing
/// file.
final class PhotoRename {
  /// Creates a renamer over [photos].
  const PhotoRename(this.photos);

  /// Photos that may be renamed.
  final List<RenameablePhoto> photos;

  /// Renames every provisional photo of [recordId] to [identity].
  ///
  /// Returns how many files moved.
  Future<int> renameForIdentity(
    String recordId, {
    required String identity,
  }) async {
    const PhotoNaming namer = PhotoNaming('{serial}_{type}_{sequence}');
    final Set<String> taken = <String>{
      for (final RenameablePhoto photo in photos) photo.path,
    };
    var moved = 0;
    for (final RenameablePhoto photo in photos) {
      if (photo.recordId != recordId || !photo.provisional) {
        continue;
      }
      final String next = namer.nameFor((
        project: '',
        recordNumber: photo.recordId,
        photoType: photo.type,
        sequence: photo.sequence,
        context: const <String, String>{},
        serial: identity,
        asset: null,
      ), taken: taken);
      final String previous = photo.path;
      photo.originalName = photo.originalName.isEmpty
          ? previous
          : photo.originalName;
      photo.path = next;
      photo.provisional = false;
      photo.history.add(previous);
      for (final RenameablePhoto other in photos) {
        other.references.replaceRange(0, other.references.length, <String>[
          for (final String reference in other.references)
            reference == previous ? next : reference,
        ]);
      }
      moved += 1;
    }
    return moved;
  }
}

/// Contract name for [PhotoRename].
typedef PhotoRenamer = PhotoRename;
