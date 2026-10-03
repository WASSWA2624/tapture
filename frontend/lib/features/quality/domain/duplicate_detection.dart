import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/hash/perceptual_hash.dart';
import 'package:tapture/core/normalise/search_text.dart';
import 'package:tapture/features/records/domain/domain.dart' show RecordEntry;

import 'duplicate_candidate.dart';
import 'duplicate_signal.dart';
import 'duplicate_subject.dart';
import 'identity_hash.dart';

/// Ranks duplicate candidates over the five signals (task 015).
///
/// Nothing here merges, discards or overrides a record. Callers run it off
/// the save path, after the save has already been confirmed.
abstract interface class DuplicateDetection {
  /// The other live records of [record]'s project that may be the same
  /// thing, strongest first. Reads the stored identity hash and photo
  /// hashes; never writes.
  Future<List<DuplicateCandidate>> candidatesFor(RecordEntry record);
}

/// Ranks [others] against the record described by the arguments.
///
/// Pure: the same inputs always yield the same list, and nothing is written.
List<DuplicateCandidate> rankDuplicateCandidates({
  required String recordId,
  required String identity,
  required Set<String> photoHashes,
  required Set<String> perceptualHashes,
  required String? templateRowId,
  required Map<String, String> context,
  required String name,
  required DateTime? capturedAt,
  required List<DuplicateSubject> others,
}) {
  final List<DuplicateCandidate> ranked = <DuplicateCandidate>[];
  for (final DuplicateSubject other in others) {
    if (other.recordId == recordId) {
      continue;
    }
    final Set<DuplicateSignal> signals = <DuplicateSignal>{};
    if (identity.isNotEmpty && identity == other.identityHash) {
      signals.add(DuplicateSignal.identity);
    }
    if (photoHashes.isNotEmpty && photoHashes.any(other.photoHashes.contains)) {
      signals.add(DuplicateSignal.samePhoto);
    }
    if (_near(perceptualHashes, other.perceptualHashes)) {
      signals.add(DuplicateSignal.nearPhoto);
    }
    if (templateRowId != null &&
        templateRowId.isNotEmpty &&
        templateRowId == other.templateRowId &&
        _sameContext(context, other.context)) {
      signals.add(DuplicateSignal.predefinedRow);
    }
    if (_nameInWindow(name, capturedAt, other, context)) {
      signals.add(DuplicateSignal.nameContextTime);
    }
    if (signals.isEmpty) {
      continue;
    }
    ranked.add(DuplicateCandidate(other.recordId, _score(signals), signals));
  }
  ranked.sort(
    (DuplicateCandidate a, DuplicateCandidate b) => b.score.compareTo(a.score),
  );
  return ranked;
}

bool _near(Set<String> left, Set<String> right) {
  for (final String probe in left) {
    if (probe.isEmpty) {
      continue;
    }
    for (final String stored in right) {
      if (PerceptualHash.distance(probe, stored) <=
          AppConstants.processing.perceptualHashDistance) {
        return true;
      }
    }
  }
  return false;
}

bool _nameInWindow(
  String name,
  DateTime? capturedAt,
  DuplicateSubject other,
  Map<String, String> context,
) {
  if (name.trim().isEmpty || other.name.trim().isEmpty) {
    return false;
  }
  if (normaliseIdentity(name) != normaliseIdentity(other.name)) {
    return false;
  }
  if (!_sameContext(context, other.context)) {
    return false;
  }
  final DateTime? otherAt = other.capturedAt;
  if (capturedAt == null || otherAt == null) {
    return false;
  }
  return capturedAt.difference(otherAt).abs() <=
      AppConstants.merge.duplicateWindow;
}

bool _sameContext(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (final MapEntry<String, String> entry in left.entries) {
    if (foldSearchText(right[entry.key] ?? '') != foldSearchText(entry.value)) {
      return false;
    }
  }
  return true;
}

double _score(Set<DuplicateSignal> signals) {
  var remain = 1.0;
  for (final DuplicateSignal signal in signals) {
    remain *= 1 - _weight(signal);
  }
  final double score = 1 - remain;
  return score > 1 ? 1 : score;
}

double _weight(DuplicateSignal signal) {
  return switch (signal) {
    DuplicateSignal.identity => AppConstants.quality.identity,
    DuplicateSignal.samePhoto ||
    DuplicateSignal.photo => AppConstants.quality.samePhoto,
    DuplicateSignal.nearPhoto => AppConstants.quality.nearPhoto,
    DuplicateSignal.predefinedRow => AppConstants.quality.predefinedRow,
    DuplicateSignal.nameContextTime ||
    DuplicateSignal.caption => AppConstants.quality.nameContext,
  };
}
