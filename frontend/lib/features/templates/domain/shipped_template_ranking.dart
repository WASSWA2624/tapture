import 'package:tapture/core/normalise/search_text.dart';

import 'shipped_search_document.dart';

/// Orders the shipped library by how well each template answers a query,
/// which may be a name, a code, or a plain description of the work, such as
/// "count laptops in district offices" (FBK0000161, D12). On the device,
/// offline, and never sent anywhere.
abstract final class ShippedTemplateRanking {
  /// The template keys of [documents] that match [query], best first.
  ///
  /// Each query word scores the heaviest field holding a word that starts
  /// with its stem; a query that is exactly a code adds
  /// [ShippedSearchDocument.codeWeight]. A template scoring nothing drops
  /// out, and equal scores keep catalogue order. A query with no usable
  /// words matches everything, in catalogue order.
  static List<String> rank(
    String query,
    List<ShippedSearchDocument> documents,
  ) {
    final List<String> stems = <String>[
      for (final String word in searchWords(query)) searchStem(word),
    ];
    if (stems.isEmpty) {
      return <String>[
        for (final ShippedSearchDocument document in documents)
          document.templateKey,
      ];
    }
    final String whole = foldSearchText(query.trim());
    final List<({String key, int score, int order})> scored =
        <({String key, int score, int order})>[];
    for (int order = 0; order < documents.length; order++) {
      final ShippedSearchDocument document = documents[order];
      var score = whole == document.code ? ShippedSearchDocument.codeWeight : 0;
      for (final String stem in stems) {
        score += _best(stem, document);
      }
      if (score > 0) {
        scored.add((key: document.templateKey, score: score, order: order));
      }
    }
    scored.sort((
      ({String key, int score, int order}) a,
      ({String key, int score, int order}) b,
    ) {
      final int byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.order.compareTo(b.order);
    });
    return <String>[
      for (final ({String key, int score, int order}) hit in scored) hit.key,
    ];
  }

  static int _best(String stem, ShippedSearchDocument document) {
    var best = 0;
    for (final ({int weight, List<String> words}) field in document.fields) {
      if (field.weight <= best) {
        continue;
      }
      for (final String word in field.words) {
        if (word.startsWith(stem)) {
          best = field.weight;
          break;
        }
      }
    }
    return best;
  }
}
