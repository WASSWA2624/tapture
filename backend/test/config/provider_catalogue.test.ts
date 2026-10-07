import assert from 'node:assert/strict';
import { it } from 'node:test';
import { providerDefinitions } from '../../src/services/ai/catalogue.js';
import { testConfig } from '../helpers.js';
import { catalogueProvider } from '../fakes/provider_catalogue.js';

it('retains built-ins and parses additional providers for both protocols', () => {
  for (const raw of [undefined, '', '[]']) {
    const config = testConfig(
      raw === undefined ? {} : { AI_PROVIDER_CATALOGUE: raw },
    );
    assert.deepEqual(
      providerDefinitions(config).map((row) => row.id),
      ['gemini', 'openai'],
    );
  }
  const entries = [
    catalogueProvider(),
    catalogueProvider({
      id: 'field-gemini',
      protocol: 'gemini-generate-content',
      authMode: 'required',
    }),
  ];
  const config = testConfig({ AI_PROVIDER_CATALOGUE: JSON.stringify(entries) });
  assert.deepEqual(config.aiProviderCatalogue, entries);
  assert.equal(providerDefinitions(config).length, 4);
});

it('rejects malformed catalogue entries at boot without echoing configuration', () => {
  const valid = catalogueProvider();
  const bad = [
    null,
    {},
    { ...valid, id: 'gemini' },
    { ...valid, id: 'Upper' },
    { ...valid, id: 'x'.repeat(65) },
    { ...valid, label: '' },
    { ...valid, protocol: 'chat-completions' },
    { ...valid, authMode: 'optional' },
    { ...valid, operations: ['extract', 'extract'] },
    { ...valid, operations: ['execute'] },
    { ...valid, models: [] },
    { ...valid, models: ['small', 'small'] },
    { ...valid, models: ['../small'] },
    { ...valid, model: 'missing' },
    { ...valid, currency: 'USD' },
    { ...valid, modelCostCeilings: { small: 0 } },
    { ...valid, modelCostCeilings: { small: 0.1, large: -1 } },
    { ...valid, modelCostCeilings: { small: 0.1, other: 1 } },
    { ...valid, modelCostCeilings: { small: 0.1, large: 'free' } },
    { ...valid, apiKey: 'forbidden-secret' },
    ...[
      'http://field.test',
      'https://person:forbidden-secret@field.test',
      'https://field.test?key=forbidden-secret',
      'https://field.test/#fragment',
      'https://field.test?',
    ].map((baseUrl) => ({ ...valid, baseUrl })),
  ];
  for (const entry of bad)
    assert.throws(
      () => testConfig({ AI_PROVIDER_CATALOGUE: JSON.stringify([entry]) }),
      (error: unknown) =>
        error instanceof Error && !error.message.includes('forbidden-secret'),
    );
  for (const raw of ['{}', '[', JSON.stringify([valid, valid])])
    assert.throws(() => testConfig({ AI_PROVIDER_CATALOGUE: raw }));
  for (const variable of ['AI_PROVIDER_URL', 'AI_OPENAI_URL'])
    assert.throws(() =>
      testConfig({ [variable]: 'https://person:secret@provider.test' }),
    );
});
