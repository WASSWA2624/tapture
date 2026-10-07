import assert from 'node:assert/strict';
import { it } from 'node:test';
import { Store } from '../../src/repositories/store.js';
import { auditConfiguration } from '../../src/services/configuration.js';
import { catalogueProvider } from '../fakes/provider_catalogue.js';
import { testConfig } from '../helpers.js';

it('audits provider endpoint/configuration changes once without exposing the configured endpoint', async () => {
  const store = new Store();
  const config = testConfig({
    AI_PROVIDER_CATALOGUE: JSON.stringify([catalogueProvider()]),
  });
  await auditConfiguration(store, config);
  const next = {
    ...config,
    aiProviderCatalogue: [
      catalogueProvider({ baseUrl: 'https://changed-field.test/v1' }),
    ],
  };
  await auditConfiguration(store, next);
  await auditConfiguration(store, next);
  const changed = store
    .audit()
    .filter((row) => row.action === 'configuration_changed');
  assert.equal(changed.length, 1);
  assert.equal(changed[0]?.target, 'ai_policy');
  const metadata = JSON.stringify(store.exportMetadata());
  assert.equal(metadata.includes('field-provider.test'), false);
  assert.equal(metadata.includes('changed-field.test'), false);
  assert.equal(metadata.includes('field-ai'), true);
});
