import 'package:tapture/core/files/path_sanitizer.dart';

/// Builds a photo file name from the project's pattern (task 018).
///
/// Unresolved tokens fall back in a fixed order: serial, asset number,
/// record number, photo type, then sequence. Names are sanitised and never
/// collide with [taken].
final class PhotoNaming {
  /// Creates a namer for [pattern]. Tokens are `{name}`.
  const PhotoNaming(this.pattern);

  /// Pattern such as `{record}_{type}_{sequence}`.
  final String pattern;

  /// A sanitised name for [tokens] that is not already in [taken].
  String nameFor(PhotoNamingTokens tokens, {required Set<String> taken}) {
    final String filled = pattern.replaceAllMapped(_token, (Match match) {
      return _tokenValue(match.group(1) ?? '', tokens);
    });
    final String safe = sanitiseSegment(filled.isEmpty ? 'photo' : filled);
    var name = safe;
    var suffix = 2;
    while (taken.contains(name)) {
      name = sanitiseSegment('$safe-$suffix');
      suffix += 1;
    }
    taken.add(name);
    return name;
  }

  static final RegExp _token = RegExp(r'\{([a-zA-Z0-9_.]+)\}');

  static String _tokenValue(String token, PhotoNamingTokens tokens) {
    final String direct = switch (token) {
      'project' => tokens.project,
      'record' => tokens.recordNumber,
      'type' => tokens.photoType,
      'sequence' => '${tokens.sequence}',
      'serial' => tokens.serial ?? '',
      'asset' => tokens.asset ?? '',
      _ => tokens.context[token] ?? '',
    };
    if (direct.isNotEmpty) {
      return direct;
    }
    for (final String fallback in <String>[
      tokens.serial ?? '',
      tokens.asset ?? '',
      tokens.recordNumber,
      tokens.photoType,
      '${tokens.sequence}',
    ]) {
      if (fallback.isNotEmpty) {
        return fallback;
      }
    }
    return 'photo';
  }
}

/// Values a photo name may draw on.
typedef PhotoNamingTokens = ({
  String project,
  String recordNumber,
  String photoType,
  int sequence,
  Map<String, String> context,
  String? serial,
  String? asset,
});
