/// Nonsecret catalogue metadata shared by provider and settings regressions.
Map<String, Object?> aiProviderMetadata({
  String id = 'field-ai',
  String label = 'Field AI',
  String authMode = 'required',
  bool managed = true,
}) => <String, Object?>{
  'provider': id,
  'label': label,
  'protocol': 'openai-responses',
  'authMode': authMode,
  'operations': <Object?>['extract', 'refine'],
  'model': 'standard',
  'models': <Object?>['standard', 'accurate'],
  'managed': managed,
  'personalConfigured': false,
  'modelCostCeilings': <String, Object?>{'standard': 1.0, 'accurate': 3.0},
  'currency': 'configured',
};

/// Dated documentation model and synthetic ceilings, never provider pricing.
Map<String, Object?> xaiProviderMetadata() => <String, Object?>{
  ...aiProviderMetadata(id: 'xai', label: 'xAI', managed: false),
  'operations': <Object?>['ocr', 'extract', 'refine'],
  'model': 'grok-4.7',
  'models': <Object?>['grok-4.7'],
  'modelCostCeilings': <String, Object?>{'grok-4.7': 1.0},
};
