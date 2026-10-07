import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { AppError } from '../../src/domain/errors.js';
import { Store } from '../../src/repositories/store.js';
import {
  credentialStatus,
  decryptCredential,
  deleteCredential,
  saveCredential,
} from '../../src/services/ai/credentials.js';
import {
  providerCatalogue,
  selectProvider,
} from '../../src/services/ai/provider-selection.js';
import { fakeProvider } from '../../src/services/ai/provider.js';
import { testConfig } from '../helpers.js';

const principal = {
  userId: 'user',
  deviceId: 'device',
  organisationId: 'org',
  role: 'field_operator' as const,
  contextScope: null,
};
const config = () =>
  testConfig({
    AI_CREDENTIAL_ENCRYPTION_KEY: 'ab'.repeat(32),
    AI_OPENAI_MODEL: 'cheap-openai',
  });

describe('personal AI credential custody', () => {
  it('encrypts with a fresh nonce, binds custody to user/provider/revision, and exports no ciphertext or key', async () => {
    const store = new Store();
    const settings = config();
    await saveCredential(
      store,
      settings,
      principal,
      'gemini',
      'private-personal-value',
    );
    const first = store.aiCredential('user', 'gemini');
    assert.ok(first);
    assert.equal(first.encryptedKey.includes('private-personal-value'), false);
    assert.equal(decryptCredential(settings, first), 'private-personal-value');
    assert.deepEqual(
      await credentialStatus(store, principal, 'gemini', config()),
      {
        provider: 'gemini',
        configured: true,
      },
    );
    const exported = JSON.stringify(store.exportMetadata());
    assert.equal(exported.includes('private-personal-value'), false);
    assert.equal(exported.includes(first.encryptedKey), false);
    for (const row of [
      { ...first, userId: 'other' },
      { ...first, provider: 'openai' as const },
      { ...first, revision: 'altered' },
      { ...first, encryptedKey: `${first.encryptedKey}corrupt` },
    ])
      assert.throws(
        () => decryptCredential(settings, row),
        (error: unknown) =>
          error instanceof AppError && error.code === 'unavailable',
      );
    await saveCredential(
      store,
      settings,
      principal,
      'gemini',
      'private-personal-value',
    );
    assert.notEqual(
      store.aiCredential('user', 'gemini')?.encryptedKey,
      first.encryptedKey,
    );
    assert.equal(
      JSON.stringify(store.audit()).includes('private-personal-value'),
      false,
    );
  });

  it('scopes status and deletion to the authenticated user and never selects managed billing on removal', async () => {
    const store = new Store();
    const settings = config();
    await saveCredential(
      store,
      settings,
      principal,
      'openai',
      'private-openai-value',
    );
    const other = { ...principal, userId: 'other' };
    assert.equal(
      (await credentialStatus(store, other, 'openai', config())).configured,
      false,
    );
    await deleteCredential(store, other, 'openai', config());
    assert.ok(store.aiCredential('user', 'openai'));
    let selectedKey = '';
    const selected = await selectProvider(
      store,
      settings,
      fakeProvider('ok'),
      principal,
      { billing: { kind: 'personal', provider: 'openai' }, model: 'default' },
      (_provider, key) => {
        selectedKey = key;
        return fakeProvider('ok');
      },
    );
    assert.equal(selected.model, 'cheap-openai');
    assert.equal(selectedKey, 'private-openai-value');
    await deleteCredential(store, principal, 'openai', config());
    await deleteCredential(store, principal, 'openai', config());
    await assert.rejects(
      () =>
        selectProvider(store, settings, fakeProvider('ok'), principal, {
          billing: { kind: 'personal', provider: 'openai' },
          model: 'default',
        }),
      (error: unknown) =>
        error instanceof AppError && error.code === 'unavailable',
    );
    await assert.rejects(
      () =>
        selectProvider(store, settings, fakeProvider('ok'), principal, {
          billing: { kind: 'managed', provider: 'openai' },
          model: 'default',
        }),
      (error: unknown) =>
        error instanceof AppError && error.code === 'unavailable',
    );
  });

  it('refuses unconfigured encryption, disallowed roles and malformed keys before saving', async () => {
    const store = new Store();
    await assert.rejects(
      () => saveCredential(store, testConfig(), principal, 'gemini', 'key'),
      (error: unknown) =>
        error instanceof AppError && error.code === 'unavailable',
    );
    for (const key of ['', ' key', 'key\n', 'x'.repeat(4097)])
      await assert.rejects(() =>
        saveCredential(store, config(), principal, 'gemini', key),
      );
    for (const action of [
      () =>
        saveCredential(
          store,
          config(),
          { ...principal, role: 'reviewer' },
          'gemini',
          'key',
        ),
      () =>
        credentialStatus(
          store,
          { ...principal, role: 'reviewer' },
          'gemini',
          config(),
        ),
      () =>
        deleteCredential(
          store,
          { ...principal, role: 'reviewer' },
          'gemini',
          config(),
        ),
    ])
      await assert.rejects(
        action,
        (error: unknown) => error instanceof AppError && error.status === 404,
      );
    assert.equal(store.aiCredential('user', 'gemini'), undefined);
  });

  it('publishes configured base and approved escalation ceilings without any credential', async () => {
    const store = new Store();
    const settings = testConfig({
      AI_PROVIDER_KEY: 'private-managed',
      AI_CREDENTIAL_ENCRYPTION_KEY: 'ab'.repeat(32),
      AI_OPENAI_MODEL: 'cheap-openai',
      AI_MODEL_COST_CEILINGS: '{"gemini:expensive":0.5,"openai:strong":0.75}',
    });
    await saveCredential(
      store,
      settings,
      principal,
      'openai',
      'private-personal',
    );
    const catalogue = await providerCatalogue(store, settings, principal);
    assert.deepEqual(catalogue.providers[0]?.models, ['fake', 'expensive']);
    assert.deepEqual(catalogue.providers[0]?.modelCostCeilings, {
      fake: 0.01,
      expensive: 0.5,
    });
    assert.equal(catalogue.providers[0]?.managed, true);
    assert.equal(catalogue.providers[1]?.personalConfigured, true);
    assert.equal(JSON.stringify(catalogue).includes('private-'), false);
    await assert.rejects(
      () =>
        selectProvider(store, settings, fakeProvider('ok'), principal, {
          model: 'expensive',
        }),
      (error: unknown) =>
        error instanceof AppError && error.code === 'invalid_request',
    );
    await assert.rejects(
      () =>
        selectProvider(store, settings, fakeProvider('ok'), principal, {
          model: 'expensive',
          maxCost: 0.49,
        }),
      (error: unknown) =>
        error instanceof AppError && error.code === 'quota_exceeded',
    );
    assert.equal(
      (
        await selectProvider(store, settings, fakeProvider('ok'), principal, {
          model: 'expensive',
          maxCost: 0.5,
        })
      ).cost,
      0.5,
    );
  });
});
