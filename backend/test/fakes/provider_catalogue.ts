import type { ProviderDefinition } from '../../src/domain/ai.js';

/** Non-routable configuration; transport tests inject every response. */
export function catalogueProvider(
  overrides: Partial<ProviderDefinition> = {},
): ProviderDefinition {
  return {
    id: 'field-ai',
    label: 'Field AI',
    protocol: 'openai-responses',
    baseUrl: 'https://field-provider.test/v1',
    authMode: 'none',
    model: 'small',
    models: ['small', 'large'],
    operations: ['ocr', 'extract', 'refine'],
    currency: 'configured',
    modelCostCeilings: { small: 0.01, large: 0.2 },
    ...overrides,
  };
}

/** Dated xAI model example; ceilings are synthetic test units, never pricing. */
export function xaiCatalogueProvider(
  overrides: Partial<ProviderDefinition> = {},
): ProviderDefinition {
  return catalogueProvider({
    id: 'xai',
    label: 'xAI',
    baseUrl: 'https://api.x.ai/v1',
    authMode: 'required',
    model: 'grok-4.7',
    models: ['grok-4.7'],
    modelCostCeilings: { 'grok-4.7': 0.025 },
    ...overrides,
  });
}
