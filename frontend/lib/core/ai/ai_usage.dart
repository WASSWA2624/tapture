/// Provider token counts and the conservative cost reserved before dispatch.
final class AiUsage {
  /// Creates attributable usage; reserved cost is a ceiling, not an invoice.
  const AiUsage({
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
    required this.reservedCost,
    required this.currency,
  });

  /// Input tokens reported by the provider, absent when not reported.
  final int? inputTokens;

  /// Output tokens reported by the provider.
  final int? outputTokens;

  /// Total tokens reported by the provider.
  final int? totalTokens;

  /// Amount reserved against the organisation's configured budget units.
  final double reservedCost;

  /// Currency or deployment-defined unit used by its spending limits.
  final String currency;

  /// Validates optional metadata without inventing unreported token counts.
  static AiUsage? fromJson(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map<String, Object?>) throw const FormatException();
    int? count(String key) {
      final Object? value = raw[key];
      if (value == null) return null;
      if (value is! int || value < 0) throw const FormatException();
      return value;
    }

    final Object? cost = raw['reservedCost'];
    final Object? currency = raw['currency'];
    if (cost is! num || !cost.isFinite || cost < 0 || currency is! String) {
      throw const FormatException();
    }
    return AiUsage(
      inputTokens: count('inputTokens'),
      outputTokens: count('outputTokens'),
      totalTokens: count('totalTokens'),
      reservedCost: cost.toDouble(),
      currency: currency,
    );
  }

  /// Metadata persisted beside the local response, never project evidence.
  Map<String, Object?> toJson() => <String, Object?>{
    'inputTokens': ?inputTokens,
    'outputTokens': ?outputTokens,
    'totalTokens': ?totalTokens,
    'reservedCost': reservedCost,
    'currency': currency,
  };
}
