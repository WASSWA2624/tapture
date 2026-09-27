import 'package:tapture/core/errors/failure.dart';

/// Keeps secrets out of a bundle (task 019, FE-SEC-02).
///
/// [excluded] columns are never serialised. [assertClean] runs the same
/// patterns as `tool/secret_patterns.yaml`, passed in as that file's text
/// so there is not a second copy of the patterns.
final class BundleRedaction {
  /// Creates a checker from the shared pattern file's [yaml] text.
  BundleRedaction.parse(String yaml) : _patterns = _compile(yaml);

  /// Columns and settings keys never written into a bundle.
  static const Set<String> excluded = <String>{
    'password',
    'api_key',
    'token',
    'secret',
    'credential',
    'device_secret',
  };

  final List<RegExp> _patterns;

  /// Drops [excluded] keys from [row].
  Map<String, Object?> strip(Map<String, Object?> row) {
    return <String, Object?>{
      for (final MapEntry<String, Object?> entry in row.entries)
        if (!excluded.contains(entry.key)) entry.key: entry.value,
    };
  }

  /// Throws when [text] carries a secret-shaped value.
  void assertClean(String text) {
    for (final RegExp pattern in _patterns) {
      if (pattern.hasMatch(text)) {
        throw const ValidationFailure(
          message: 'The bundle contains a secret and was not written.',
          recoveryAction: 'Remove the secret and export the bundle again.',
        );
      }
    }
  }

  static List<RegExp> _compile(String yaml) {
    final RegExp line = RegExp(r"pattern:\s*'([^']*)'");
    return <RegExp>[
      for (final RegExpMatch match in line.allMatches(yaml))
        RegExp(match.group(1) ?? '', caseSensitive: false),
    ];
  }
}
