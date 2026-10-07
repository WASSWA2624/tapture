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
