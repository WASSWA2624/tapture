import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'photo_draft.dart';

/// Chooses the active photo in each edit chain (decision D1).
///
/// The newest derived version is active. Originals and intermediate edits
/// stay stored and are omitted from the tray, the filed record and processing.
abstract final class PhotoDerivation {
  /// Active photos in root capture order.
  ///
  /// Fails when an edit names a missing parent or the links form a cycle.
  static Result<List<PhotoDraft>> select(List<PhotoDraft> photos) {
    if (photos.isEmpty) {
      return const Success<List<PhotoDraft>>(<PhotoDraft>[]);
    }
    final Map<String, PhotoDraft> byId = <String, PhotoDraft>{};
    for (final PhotoDraft photo in photos) {
      if (byId.containsKey(photo.id)) {
        return const FailureResult<List<PhotoDraft>>(
          ValidationFailure(
            message: 'This photo appears more than once.',
            recoveryAction: 'Reload the capture and try again.',
          ),
        );
      }
      byId[photo.id] = photo;
    }
    for (final PhotoDraft photo in photos) {
      final String? parentId = photo.derivedFrom;
      if (parentId == null) {
        continue;
      }
      if (!byId.containsKey(parentId)) {
        return const FailureResult<List<PhotoDraft>>(
          ValidationFailure(
            message: 'An edited photo is missing its original.',
            recoveryAction: 'Keep this capture and restore the original photo.',
          ),
        );
      }
    }
    if (_cycles(byId)) {
      return const FailureResult<List<PhotoDraft>>(
        ValidationFailure(
          message: 'These photo edits loop back on themselves.',
          recoveryAction: 'Reload the capture and try again.',
        ),
      );
    }
    final Map<String, List<PhotoDraft>> children = <String, List<PhotoDraft>>{};
    for (final PhotoDraft photo in photos) {
      final String? parentId = photo.derivedFrom;
      if (parentId == null) {
        continue;
      }
      (children[parentId] ??= <PhotoDraft>[]).add(photo);
    }
    final List<PhotoDraft> active = <PhotoDraft>[
      for (final PhotoDraft photo in photos)
        if (photo.derivedFrom == null) _tip(photo, children),
    ];
    return Success<List<PhotoDraft>>(active);
  }

  static PhotoDraft _tip(
    PhotoDraft node,
    Map<String, List<PhotoDraft>> children,
  ) {
    final List<PhotoDraft> leaves = _leaves(node, children);
    PhotoDraft best = leaves.first;
    for (final PhotoDraft leaf in leaves.skip(1)) {
      if (_newer(leaf, best)) {
        best = leaf;
      }
    }
    return best;
  }

  static List<PhotoDraft> _leaves(
    PhotoDraft node,
    Map<String, List<PhotoDraft>> children,
  ) {
    final List<PhotoDraft> next = children[node.id] ?? const <PhotoDraft>[];
    if (next.isEmpty) {
      return <PhotoDraft>[node];
    }
    return <PhotoDraft>[
      for (final PhotoDraft child in next) ..._leaves(child, children),
    ];
  }

  static bool _newer(PhotoDraft candidate, PhotoDraft current) {
    final DateTime? left = candidate.capturedAt;
    final DateTime? right = current.capturedAt;
    if (left == null && right == null) {
      return candidate.id.compareTo(current.id) > 0;
    }
    if (left == null) {
      return false;
    }
    if (right == null) {
      return true;
    }
    final int compared = left.compareTo(right);
    if (compared != 0) {
      return compared > 0;
    }
    return candidate.id.compareTo(current.id) > 0;
  }

  static bool _cycles(Map<String, PhotoDraft> byId) {
    final Set<String> visiting = <String>{};
    final Set<String> visited = <String>{};
    for (final String id in byId.keys) {
      if (_walk(id, byId, visiting, visited)) {
        return true;
      }
    }
    return false;
  }

  static bool _walk(
    String id,
    Map<String, PhotoDraft> byId,
    Set<String> visiting,
    Set<String> visited,
  ) {
    if (visited.contains(id)) {
      return false;
    }
    if (!visiting.add(id)) {
      return true;
    }
    final String? parentId = byId[id]?.derivedFrom;
    if (parentId != null && _walk(parentId, byId, visiting, visited)) {
      return true;
    }
    visiting.remove(id);
    visited.add(id);
    return false;
  }
}
