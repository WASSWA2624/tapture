/// Inserts a refined companion column beside each raw column (task 018).
final class XlsxRefinedColumns {
  /// Headers with a refined companion after each raw header.
  static List<String> headers(List<String> keys, {required bool refined}) {
    if (!refined) {
      return keys;
    }
    return <String>[
      for (final String key in keys) ...<String>[key, '$key (refined)'],
    ];
  }
}
