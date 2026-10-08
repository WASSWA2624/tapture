/// Bundled official provider artwork, addressed by stable server-provider ID.
abstract final class AiProviderAssets {
  /// Google's supplied Gemini product mark.
  static const String gemini = 'assets/ai_providers/gemini.png';

  /// OpenAI's supplied black Blossom.
  static const String openai = 'assets/ai_providers/openai.png';

  /// OpenAI's supplied white Blossom.
  static const String openaiInverse = 'assets/ai_providers/openai_inverse.png';

  /// xAI's supplied mark for light surfaces.
  static const String xai = 'assets/ai_providers/xai.png';

  /// xAI's supplied mark for dark surfaces.
  static const String xaiInverse = 'assets/ai_providers/xai_inverse.png';

  /// Resolves a supplied surface variant; unknown providers have no mark.
  static String? forProvider(String? provider, {bool inverse = false}) =>
      switch (provider) {
        'gemini' => gemini,
        'openai' => inverse ? openaiInverse : openai,
        'xai' => inverse ? xaiInverse : xai,
        _ => null,
      };
}
