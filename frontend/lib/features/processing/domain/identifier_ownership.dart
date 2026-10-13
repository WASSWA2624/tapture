import 'identifier_extraction.dart';

/// Withholds an unlabelled identifier that fits more than one field pattern.
abstract final class IdentifierOwnership {
  /// Pattern overlap is an ownership question for a person, never field order.
  static ({List<IdentifierCandidate> candidates, Set<String> ambiguousKeys})
  resolve(List<IdentifierCandidate> candidates) {
    final Map<String, Set<String>> owners = <String, Set<String>>{};
    for (final IdentifierCandidate candidate in candidates) {
      owners
          .putIfAbsent(candidate.value, () => <String>{})
          .add(candidate.fieldKey);
    }
    return (
      candidates: <IdentifierCandidate>[
        for (final IdentifierCandidate candidate in candidates)
          if (owners[candidate.value]!.length == 1) candidate,
      ],
      ambiguousKeys: <String>{
        for (final Set<String> keys in owners.values)
          if (keys.length > 1) ...keys,
      },
    );
  }
}
