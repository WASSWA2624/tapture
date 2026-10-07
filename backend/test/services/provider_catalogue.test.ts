import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { it } from 'node:test';
import type { AiBilling } from '../../src/domain/ai.js';
import { AppError } from '../../src/domain/errors.js';
import { Store } from '../../src/repositories/store.js';
import {
  providerCatalogue,
  aiAvailable,
  selectProvider,
} from '../../src/services/ai/provider-selection.js';
import {
  credentialStatus,
  saveCredential,
  deleteCredential,
} from '../../src/services/ai/credentials.js';
import { fakeProvider } from '../../src/services/ai/provider.js';
import { proxyAi } from '../../src/services/ai/proxy.js';
import { receiptBinding } from '../../src/services/ai/receipts.js';
import { testConfig } from '../helpers.js';
import { catalogueProvider } from '../fakes/provider_catalogue.js';

const principal = {
  userId: 'user',
  deviceId: 'device',
  organisationId: 'org',
  role: 'field_operator' as const,
  contextScope: null,
};
const failure = (code: string) => (error: unknown) =>
  error instanceof AppError && error.code === code;
function fixture(definition = catalogueProvider()) {
  const config = testConfig({
    AI_PROVIDER_CATALOGUE: JSON.stringify([definition]),
    AI_CREDENTIAL_ENCRYPTION_KEY: 'ab'.repeat(32),
  });
  const store = new Store();
  store.addProject({
    id: 'project',
    organisationId: 'org',
    name: 'Field',
    relayEnabled: false,
    neverRelay: true,
    retentionDays: 30,
  });
  store.addMember({ projectId: 'project', userId: 'user', contextScope: null });
  return { store, config };
}
function input(billing: AiBilling = { kind: 'managed', provider: 'field-ai' }) {
  const payload = Buffer.from('original evidence');
  return {
    projectId: 'project',
    model: 'default',
    payload,
    billing,
    processing: {
      version: 1 as const,
      projectRevision: 'revision',
      recordId: 'record',
      requestHash: createHash('sha256').update(payload).digest('hex'),
      idempotencyKey: 'a'.repeat(64),
    },
  };
}

it('publishes only safe metadata and performs no keyless credential lookup or request', async () => {
  const { store, config } = fixture();
  const original = store.aiCredential.bind(store);
  store.aiCredential = (user, provider) => {
    assert.notEqual(provider, 'field-ai');
    return original(user, provider);
  };
  const result = await providerCatalogue(store, config, principal);
  const row = result.providers.find((entry) => entry.provider === 'field-ai');
  assert.deepEqual(row, {
    provider: 'field-ai',
    label: 'Field AI',
    protocol: 'openai-responses',
    authMode: 'none',
    operations: ['ocr', 'extract', 'refine'],
    model: 'small',
    models: ['small', 'large'],
    modelCostCeilings: { small: 0.01, large: 0.2 },
    requestCostCeiling: 0.01,
    currency: 'configured',
    managed: true,
    personalConfigured: false,
  });
  assert.equal(JSON.stringify(result).includes('field-provider.test'), false);
  assert.equal(await aiAvailable(store, config, principal), true);
  assert.equal(
    await aiAvailable(store, config, { ...principal, role: 'reviewer' }),
    false,
  );
  for (const work of [
    () => credentialStatus(store, principal, 'field-ai', config),
    () => saveCredential(store, config, principal, 'field-ai', 'unused'),
    () => deleteCredential(store, principal, 'field-ai', config),
  ])
    await assert.rejects(work, failure('invalid_request'));
  assert.equal(store.usage().length, 0);
});

it('binds exact keyless provider, costs and permissions with no credential lookup in either transaction', async () => {
  const { store, config } = fixture();
  store.aiCredential = () => {
    throw new Error('Keyless credentials must never be read');
  };
  let calls = 0;
  const factory = (provider: string, key: string) => {
    assert.equal(provider, 'field-ai');
    assert.equal(key, '');
    const answer = async () => {
      calls++;
      return { text: 'proposed', model: 'small' };
    };
    return { extract: answer, ocr: answer, refine: answer, transcribe: answer };
  };
  const result = await proxyAi(
    store,
    config,
    fakeProvider('fail'),
    principal,
    'extract',
    input(),
    undefined,
    factory,
  );
  assert.equal(result.provider, 'field-ai');
  assert.equal(result.billingKind, 'managed');
  assert.equal(result.usage.reservedCost, 0.01);
  await assert.rejects(
    () =>
      proxyAi(
        store,
        config,
        fakeProvider('fail'),
        principal,
        'extract',
        input(),
        undefined,
        factory,
      ),
    failure('ai_result_unavailable'),
  );
  assert.equal(calls, 1);
  assert.equal(store.usage().length, 1);
  await assert.rejects(
    () =>
      proxyAi(
        store,
        config,
        fakeProvider('fail'),
        { ...principal, role: 'reviewer' },
        'extract',
        input(),
        undefined,
        factory,
      ),
    failure('not_found'),
  );
  await assert.rejects(
    () =>
      proxyAi(
        store,
        config,
        fakeProvider('fail'),
        principal,
        'transcribe',
        input(),
        undefined,
        factory,
      ),
    failure('invalid_request'),
  );
  await assert.rejects(
    () =>
      selectProvider(
        store,
        config,
        fakeProvider('fail'),
        principal,
        { ...input(), billing: { kind: 'personal', provider: 'field-ai' } },
        factory,
      ),
    failure('unavailable'),
  );
  await assert.rejects(
    () =>
      selectProvider(
        store,
        config,
        fakeProvider('fail'),
        principal,
        { ...input(), model: 'large' },
        factory,
      ),
    failure('invalid_request'),
  );
  await assert.rejects(
    () =>
      selectProvider(
        store,
        config,
        fakeProvider('fail'),
        principal,
        { ...input(), model: 'large', maxCost: 0.1 },
        factory,
      ),
    failure('quota_exceeded'),
  );
  await assert.rejects(
    () =>
      proxyAi(
        store,
        { ...config, aiProjectBudget: 0 },
        fakeProvider('fail'),
        principal,
        'extract',
        {
          ...input(),
          processing: { ...input().processing, idempotencyKey: 'b'.repeat(64) },
        },
        undefined,
        factory,
      ),
    failure('quota_exceeded'),
  );
  const signal = AbortSignal.abort();
  await assert.rejects(
    () =>
      proxyAi(
        store,
        config,
        fakeProvider('fail'),
        principal,
        'extract',
        { ...input(), signal },
        undefined,
        factory,
      ),
    failure('ai_request_uncertain'),
  );
  assert.equal(calls, 1);
});

it('new provider credentials remain encrypted and scoped to a required-auth account', async () => {
  const { store, config } = fixture(
    catalogueProvider({ authMode: 'required' }),
  );
  await saveCredential(
    store,
    config,
    principal,
    'field-ai',
    'private-fixture-value',
  );
  assert.equal(
    store
      .aiCredential('user', 'field-ai')
      ?.encryptedKey.includes('private-fixture-value'),
    false,
  );
  const selected = await selectProvider(
    store,
    config,
    fakeProvider('fail'),
    principal,
    input({ kind: 'personal', provider: 'field-ai' }),
    (id, key) => {
      assert.equal(id, 'field-ai');
      assert.equal(key, 'private-fixture-value');
      return fakeProvider('ok');
    },
  );
  assert.equal(selected.model, 'small');
  assert.equal(selected.kind, 'personal');
  await assert.rejects(
    () =>
      selectProvider(store, config, fakeProvider('fail'), principal, input()),
    failure('unavailable'),
  );
});

it('configuration changes reject reused receipt identities before another dispatch', async () => {
  const { store, config } = fixture();
  let calls = 0;
  const factory = () => {
    const answer = async (request: { model: string }) => {
      calls++;
      return { text: 'proposal', model: request.model };
    };
    return { extract: answer, ocr: answer, refine: answer, transcribe: answer };
  };
  await proxyAi(
    store,
    config,
    fakeProvider('fail'),
    principal,
    'extract',
    input(),
    undefined,
    factory,
  );
  const before = store.usage().length;
  for (const changed of [
    { baseUrl: 'https://changed.test/v1' },
    { protocol: 'gemini-generate-content' as const },
    { model: 'large' },
  ]) {
    const next = fixture(catalogueProvider(changed)).config;
    await assert.rejects(
      () =>
        proxyAi(
          store,
          next,
          fakeProvider('fail'),
          principal,
          'extract',
          input(),
          undefined,
          factory,
        ),
      failure('conflict'),
    );
  }
  assert.equal(store.usage().length, before);
  assert.equal(calls, 1);
});

it('legacy managed and personal hashes recover existing outcomes without redispatch or mutation', async () => {
  for (const kind of ['managed', 'personal'] as const)
    for (const status of ['completed', 'running', 'uncertain'] as const) {
      const { store, config } = fixture();
      if (kind === 'personal')
        await saveCredential(
          store,
          config,
          principal,
          'gemini',
          'legacy-fixture-key',
        );
      const attempt = input({ kind, provider: 'gemini' });
      const account =
        kind === 'managed'
          ? `managed:gemini:${createHash('sha256').update(config.aiProviderKey).digest('hex')}`
          : `personal:gemini:user:${store.aiCredential('user', 'gemini')?.revision}`;
      const bindingHash = receiptBinding(
        attempt.processing,
        principal,
        'extract',
        'project',
        config.aiGeminiModel,
        account,
        attempt.payload,
      );
      const receipt = {
        idempotencyKey: attempt.processing.idempotencyKey,
        bindingHash,
        userId: 'user',
        deviceId: 'device',
        projectId: 'project',
        usageId: 'old',
        status,
        createdAt: new Date().toISOString(),
      };
      store.saveAiReceipt(receipt);
      await assert.rejects(
        () =>
          proxyAi(
            store,
            config,
            fakeProvider('fail'),
            principal,
            'extract',
            attempt,
            undefined,
            () => fakeProvider('fail'),
          ),
        failure(
          status === 'completed'
            ? 'ai_result_unavailable'
            : 'ai_request_uncertain',
        ),
      );
      assert.deepEqual(store.aiReceipt(receipt.idempotencyKey), receipt);
      assert.equal(store.usage().length, 0);
    }
});
