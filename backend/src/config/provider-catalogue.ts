import type { AiOperation, ProviderDefinition } from '../domain/ai.js';

const operations: readonly AiOperation[] = [
  'ocr',
  'extract',
  'refine',
  'transcribe',
];
const fields = [
  'id',
  'label',
  'protocol',
  'baseUrl',
  'authMode',
  'models',
  'operations',
  'model',
  'currency',
  'modelCostCeilings',
];

/** Reject credentials and mutable URL parameters even in administrator configuration. */
export function providerUrl(value: string, name: string): string {
  try {
    const url = new URL(value);
    if (
      url.protocol !== 'https:' ||
      url.hostname === '' ||
      url.username !== '' ||
      url.password !== '' ||
      url.search !== '' ||
      url.hash !== '' ||
      /[\s?#]/.test(value)
    )
      throw new Error();
    return url.toString().replace(/\/$/, '');
  } catch {
    throw new Error(
      `${name} must be an HTTPS endpoint without credentials, query or fragment.`,
    );
  }
}

function object(value: unknown): Record<string, unknown> {
  if (typeof value !== 'object' || value === null || Array.isArray(value))
    throw new Error('AI_PROVIDER_CATALOGUE entries and costs must be objects.');
  // The preceding boundary check excludes null, arrays and primitives.
  return value as Record<string, unknown>;
}

function strings(value: unknown): string[] {
  if (
    !Array.isArray(value) ||
    value.length === 0 ||
    !value.every((entry: unknown) => typeof entry === 'string') ||
    new Set(value).size !== value.length
  )
    throw new Error(
      'AI_PROVIDER_CATALOGUE models and operations must be nonempty arrays of unique strings.',
    );
  // Every element passed the string check above.
  return value as string[];
}

/** Additional providers only; the retained built-in IDs cannot be shadowed. */
export function parseProviderCatalogue(
  raw: string | undefined,
): readonly ProviderDefinition[] {
  if (raw === undefined || raw.trim() === '') return [];
  let rows: unknown;
  try {
    rows = JSON.parse(raw);
  } catch {
    throw new Error('AI_PROVIDER_CATALOGUE must be a JSON array.');
  }
  if (!Array.isArray(rows))
    throw new Error('AI_PROVIDER_CATALOGUE must be a JSON array.');
  const ids = new Set(['gemini', 'openai']);
  return rows.map((value: unknown): ProviderDefinition => {
    const row = object(value);
    if (Object.keys(row).some((key) => !fields.includes(key)))
      throw new Error('AI_PROVIDER_CATALOGUE contains an unknown field.');
    const { id, label, protocol, baseUrl, authMode, model, currency } = row;
    if (
      typeof id !== 'string' ||
      !/^[a-z][a-z0-9-]{0,63}$/.test(id) ||
      ids.has(id)
    )
      throw new Error(
        'AI_PROVIDER_CATALOGUE requires unique provider IDs; gemini and openai are reserved.',
      );
    ids.add(id);
    if (typeof label !== 'string' || label.trim() === '' || label.length > 128)
      throw new Error(
        'AI_PROVIDER_CATALOGUE requires a label of at most 128 characters.',
      );
    if (
      protocol !== 'gemini-generate-content' &&
      protocol !== 'openai-responses'
    )
      throw new Error(
        'AI_PROVIDER_CATALOGUE contains an unsupported protocol.',
      );
    if (authMode !== 'required' && authMode !== 'none')
      throw new Error(
        'AI_PROVIDER_CATALOGUE authMode must be required or none.',
      );
    if (typeof baseUrl !== 'string')
      throw new Error('AI_PROVIDER_CATALOGUE requires an HTTPS endpoint.');
    const models = strings(row['models']);
    if (models.some((entry) => !/^[A-Za-z0-9._-]+$/.test(entry)))
      throw new Error(
        'AI_PROVIDER_CATALOGUE contains an invalid model identifier.',
      );
    const selectedOperations = strings(row['operations']);
    const configuredOperations = selectedOperations.filter(
      (entry): entry is AiOperation =>
        operations.some((operation) => operation === entry),
    );
    if (configuredOperations.length !== selectedOperations.length)
      throw new Error(
        'AI_PROVIDER_CATALOGUE contains an unsupported operation.',
      );
    if (typeof model !== 'string' || !models.includes(model))
      throw new Error('AI_PROVIDER_CATALOGUE base model must be in models.');
    if (models.includes('default') && model !== 'default')
      throw new Error(
        'AI_PROVIDER_CATALOGUE reserves default for the configured base model.',
      );
    if (currency !== 'configured')
      throw new Error('AI_PROVIDER_CATALOGUE currency must be configured.');
    const costs = object(row['modelCostCeilings']);
    if (Object.keys(costs).length !== models.length)
      throw new Error(
        'AI_PROVIDER_CATALOGUE requires exactly one cost ceiling per model.',
      );
    const modelCostCeilings = Object.fromEntries(
      models.map((name) => {
        const cost = costs[name];
        if (typeof cost !== 'number' || !Number.isFinite(cost) || cost <= 0)
          throw new Error(
            'AI_PROVIDER_CATALOGUE costs must be positive finite attempt ceilings.',
          );
        return [name, cost];
      }),
    );
    return {
      id,
      label,
      protocol,
      baseUrl: providerUrl(baseUrl, 'AI_PROVIDER_CATALOGUE baseUrl'),
      authMode,
      models,
      operations: configuredOperations,
      model,
      currency,
      modelCostCeilings,
    };
  });
}
