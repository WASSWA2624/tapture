import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { describe, it } from 'node:test';
import type { ProcessingIdentity } from '../../src/domain/ai.js';
import { AppError } from '../../src/domain/errors.js';
import { Store } from '../../src/repositories/store.js';
import { proxyAi } from '../../src/services/ai/proxy.js';
import type {
  AiProvider,
  AiRequest,
  AiResult,
} from '../../src/services/ai/provider.js';
import { saveCredential } from '../../src/services/ai/credentials.js';
import { openaiProvider } from '../../src/services/ai/openai-provider.js';
import { xaiCatalogueProvider } from '../fakes/provider_catalogue.js';
import { testConfig } from '../helpers.js';

const principal = {
  userId: 'user',
  deviceId: 'device',
  organisationId: 'org',
  role: 'field_operator' as const,
  contextScope: null,
};
const settings = () => testConfig({ AI_RETRY_LIMIT: '3' });
function seeded(): Store {
  const store = new Store();
  store.addProject({
    id: 'project',
    organisationId: 'org',
    name: 'Local-first',
    relayEnabled: false,
    neverRelay: true,
    retentionDays: 30,
  });
  store.addMember({ projectId: 'project', userId: 'user', contextScope: null });
  return store;
}
function input(raw = 'original-evidence', key = 'a'.repeat(64)) {
  const payload = Buffer.from(raw);
  const processing: ProcessingIdentity = {
    version: 1,
    projectRevision: 'revision-1',
    recordId: 'record-1',
    requestHash: createHash('sha256').update(payload).digest('hex'),
    idempotencyKey: key,
  };
  return { projectId: 'project', model: 'default', payload, processing };
}
function adapter(
  answer: (request: AiRequest) => Promise<AiResult>,
): AiProvider {
  return { extract: answer, ocr: answer, transcribe: answer, refine: answer };
}
const failure = (code: string) => (error: unknown) =>
  error instanceof AppError && error.code === code;

describe('versioned processing receipts', () => {
  it('coalesces concurrent retries, reserves and bills once, and stores only durable metadata', async () => {
    const store = seeded();
    const config = settings();
    let release: () => void = () => undefined;
    let started: () => void = () => undefined;
    let replayed: () => void = () => undefined;
    const wait = new Promise<void>((resolve) => {
      release = resolve;
    });
    const start = new Promise<void>((resolve) => {
      started = resolve;
    });
    const replay = new Promise<void>((resolve) => {
      replayed = resolve;
    });
    const lookup = store.aiReceipt.bind(store);
    store.aiReceipt = (key) => {
      const row = lookup(key);
      if (row?.status === 'running') replayed();
      return row;
    };
    let calls = 0;
    const provider = adapter(async (request) => {
      calls += 1;
      started();
      await wait;
      return {
        text: 'private-generated-record',
        model: request.model,
        usage: { inputTokens: 10, outputTokens: 3, totalTokens: 13 },
      };
    });
    const attempt = { ...input(), maxCost: 0.05 };
    const first = proxyAi(
      store,
      config,
      provider,
      principal,
      'extract',
      attempt,
    );
    await start;
    await assert.rejects(
      () =>
        proxyAi(store, config, provider, principal, 'extract', {
          ...attempt,
          maxCost: 0.02,
        }),
      failure('conflict'),
    );
    const duplicate = proxyAi(
      store,
      config,
      provider,
      principal,
      'extract',
      attempt,
    );
    await replay;
    assert.equal(store.usage().length, 1);
    assert.equal(store.usage()[0]?.cost, 0.01);
    release();
    const responses = await Promise.all([first, duplicate]);
    assert.deepEqual(responses[0], responses[1]);
    assert.equal(responses[0]?.usage.totalTokens, 13);
    assert.equal(calls, 1);
    assert.equal(store.aiReceipt('a'.repeat(64))?.status, 'completed');
    const metadata = JSON.stringify(store.exportMetadata());
    assert.equal(metadata.includes('original-evidence'), false);
    assert.equal(metadata.includes('private-generated-record'), false);
    await assert.rejects(
      () => proxyAi(store, config, provider, principal, 'extract', attempt),
      failure('ai_result_unavailable'),
    );
    assert.equal(calls, 1);
    assert.equal(store.usage().length, 1);
  });

  it('rejects collisions in content, revision, actor, device, project, method, model and billing before charging', async () => {
    const store = seeded();
    const config = testConfig({
      AI_MODEL_COST_CEILINGS: '{"gemini:strong":0.5}',
      AI_OPENAI_MODEL: 'cheap-openai',
      AI_CREDENTIAL_ENCRYPTION_KEY: 'ab'.repeat(32),
    });
    let calls = 0;
    const provider = adapter(async (request) => {
      calls += 1;
      return { text: 'draft', model: request.model };
    });
    await proxyAi(store, config, provider, principal, 'extract', input());
    store.addProject({
      id: 'other-project',
      organisationId: 'org',
      name: 'Other',
      relayEnabled: false,
      neverRelay: true,
      retentionDays: 30,
    });
    store.addMember({
      projectId: 'other-project',
      userId: 'user',
      contextScope: null,
    });
    store.addMember({
      projectId: 'project',
      userId: 'other-user',
      contextScope: null,
    });
    await saveCredential(store, config, principal, 'gemini', 'personal-gemini');
    await saveCredential(store, config, principal, 'openai', 'personal-openai');
    const original = input();
    const cases = [
      { value: input('changed'), actor: principal, method: 'extract' as const },
      {
        value: {
          ...original,
          processing: { ...original.processing, projectRevision: 'changed' },
        },
        actor: principal,
        method: 'extract' as const,
      },
      {
        value: {
          ...original,
          processing: { ...original.processing, recordId: 'changed' },
        },
        actor: principal,
        method: 'extract' as const,
      },
      {
        value: original,
        actor: { ...principal, userId: 'other-user' },
        method: 'extract' as const,
      },
      {
        value: original,
        actor: { ...principal, deviceId: 'other-device' },
        method: 'extract' as const,
      },
      {
        value: { ...original, projectId: 'other-project' },
        actor: principal,
        method: 'extract' as const,
      },
      { value: original, actor: principal, method: 'refine' as const },
      {
        value: { ...original, model: 'strong', maxCost: 0.5 },
        actor: principal,
        method: 'extract' as const,
      },
      {
        value: {
          ...original,
          billing: { kind: 'personal' as const, provider: 'gemini' as const },
        },
        actor: principal,
        method: 'extract' as const,
      },
      {
        value: {
          ...original,
          billing: { kind: 'personal' as const, provider: 'openai' as const },
        },
        actor: principal,
        method: 'extract' as const,
      },
    ];
    for (const item of cases)
      await assert.rejects(
        () =>
          proxyAi(
            store,
            config,
            provider,
            item.actor,
            item.method,
            item.value,
            undefined,
            () => provider,
          ),
        failure('conflict'),
      );
    await assert.rejects(
      () =>
        proxyAi(store, config, provider, principal, 'extract', {
          ...original,
          processing: { ...original.processing, requestHash: 'b'.repeat(64) },
        }),
      failure('invalid_request'),
    );
    assert.equal(calls, 1);
    assert.equal(store.usage().length, 1);
  });

  it('does not automatically retry a failed versioned call or a replayed uncertain tombstone', async () => {
    const store = seeded();
    const config = settings();
    let calls = 0;
    const provider = adapter(async () => {
      calls += 1;
      throw new Error('network outcome unknown');
    });
    await assert.rejects(
      () => proxyAi(store, config, provider, principal, 'extract', input()),
      failure('ai_request_uncertain'),
    );
    await assert.rejects(
      () => proxyAi(store, config, provider, principal, 'extract', input()),
      failure('ai_request_uncertain'),
    );
    assert.equal(calls, 1);
    assert.equal(store.usage().length, 1);
    assert.equal(store.usage()[0]?.cost, 0.01);
    assert.equal(store.aiReceipt('a'.repeat(64))?.status, 'uncertain');
  });

  it('aborts a cancelled attempt, retains its conservative charge, and permits only an explicitly new identifier', async () => {
    const store = seeded();
    const config = settings();
    const controller = new AbortController();
    let started: () => void = () => undefined;
    const start = new Promise<void>((resolve) => {
      started = resolve;
    });
    let calls = 0;
    const provider = adapter(async (request) => {
      calls += 1;
      started();
      return new Promise((_resolve, reject) => {
        request.signal?.addEventListener(
          'abort',
          () => reject(new Error('cancelled')),
          { once: true },
        );
      });
    });
    const running = proxyAi(store, config, provider, principal, 'extract', {
      ...input(),
      signal: controller.signal,
    });
    await start;
    controller.abort();
    await assert.rejects(() => running, failure('ai_request_uncertain'));
    assert.equal(calls, 1);
    assert.equal(store.usage()[0]?.cost, 0.01);
    const healthy = adapter(async (request) => ({
      text: 'draft',
      model: request.model,
    }));
    await proxyAi(
      store,
      config,
      healthy,
      principal,
      'extract',
      input('original-evidence', 'b'.repeat(64)),
    );
    assert.equal(store.usage().length, 2);
  });

  it('does not reserve for invisible projects, exhausted budgets or unapproved escalation', async () => {
    const store = seeded();
    let calls = 0;
    const provider = adapter(async () => {
      calls += 1;
      return { text: 'draft', model: 'fake' };
    });
    await assert.rejects(
      () =>
        proxyAi(
          store,
          settings(),
          provider,
          { ...principal, userId: 'outsider' },
          'extract',
          input(),
        ),
      failure('not_found'),
    );
    await assert.rejects(
      () =>
        proxyAi(
          store,
          testConfig({ AI_PROJECT_DAILY_BUDGET: '0' }),
          provider,
          principal,
          'extract',
          input(),
        ),
      failure('quota_exceeded'),
    );
    await assert.rejects(
      () =>
        proxyAi(
          store,
          testConfig({ AI_MODEL_COST_CEILINGS: '{"gemini:strong":0.5}' }),
          provider,
          principal,
          'extract',
          { ...input(), model: 'strong' },
        ),
      failure('invalid_request'),
    );
    assert.equal(calls, 0);
    assert.equal(store.usage().length, 0);
    assert.equal(store.aiReceipt('a'.repeat(64)), undefined);
  });
  it('rejects a silent model change and preserves the original receipt without a second call', async () => {
    const store = seeded();
    const config = settings();
    const provider = adapter(async () => ({
      text: 'draft',
      model: 'downgraded-model',
    }));
    await assert.rejects(
      () => proxyAi(store, config, provider, principal, 'extract', input()),
      failure('ai_request_uncertain'),
    );
    assert.equal(store.aiReceipt('a'.repeat(64))?.status, 'uncertain');
    const receipt = store.aiReceipt('a'.repeat(64));
    assert.ok(receipt);
    assert.throws(
      () =>
        store.saveAiReceipt({
          ...receipt,
          bindingHash: 'different',
          status: 'completed',
        }),
      failure('conflict'),
    );
    assert.throws(
      () =>
        store.saveAiReceipt({
          ...receipt,
          usageId: 'different',
          status: 'completed',
        }),
      failure('conflict'),
    );
    assert.throws(
      () => store.saveAiReceipt({ ...receipt, status: 'running' }),
      failure('conflict'),
    );
  });
});

describe('configured xAI photo/text processing', () => {
  it('enforces authority, capability, exact models and approved budgets before real-protocol dispatch', async () => {
    const store = seeded();
    const definition = xaiCatalogueProvider({
      models: ['grok-4.7', 'reviewed-text'],
      modelCostCeilings: { 'grok-4.7': 0.025, 'reviewed-text': 0.2 },
    });
    const config = testConfig({
      AI_PROVIDER_CATALOGUE: JSON.stringify([definition]),
      AI_CREDENTIAL_ENCRYPTION_KEY: 'ab'.repeat(32),
    });
    await saveCredential(
      store,
      config,
      principal,
      'xai',
      'private-xai-fixture',
    );
    const raw = JSON.stringify({
      instructions: 'Use only evidence-backed fields.',
      data: { caption: 'untrusted xAI caption' },
      media: [{ mimeType: 'image/png', base64: 'AQID' }],
      responseMimeType: 'application/json',
    });
    const attempt = {
      ...input(raw),
      billing: { kind: 'personal' as const, provider: 'xai' },
    };
    let calls = 0;
    const factory = (id: string, key: string) => {
      assert.equal(id, 'xai');
      assert.equal(key, 'private-xai-fixture');
      return openaiProvider(
        config,
        key,
        async () => {
          calls++;
          return new Response(
            JSON.stringify({
              model: 'grok-4.7',
              status: 'completed',
              output: [
                {
                  type: 'message',
                  content: [
                    { type: 'output_text', text: 'private-xai-proposal' },
                  ],
                },
              ],
            }),
          );
        },
        definition,
      );
    };
    const managed = adapter(async () => {
      assert.fail('The explicitly selected xAI account must never fall back.');
    });
    for (const [actor, method, value, settings, code] of [
      [
        { ...principal, role: 'reviewer' as const },
        'extract',
        attempt,
        config,
        'not_found',
      ],
      [
        { ...principal, userId: 'outsider' },
        'extract',
        attempt,
        config,
        'not_found',
      ],
      [principal, 'transcribe', attempt, config, 'invalid_request'],
      [
        principal,
        'extract',
        { ...attempt, model: 'unapproved' },
        config,
        'invalid_request',
      ],
      [
        principal,
        'extract',
        { ...attempt, model: 'reviewed-text' },
        config,
        'invalid_request',
      ],
      [
        principal,
        'extract',
        { ...attempt, model: 'reviewed-text', maxCost: 0.1 },
        config,
        'quota_exceeded',
      ],
      [
        principal,
        'extract',
        attempt,
        { ...config, aiProjectBudget: 0 },
        'quota_exceeded',
      ],
      [
        principal,
        'extract',
        { ...attempt, billing: { kind: 'managed' as const, provider: 'xai' } },
        config,
        'unavailable',
      ],
    ] as const)
      await assert.rejects(
        () =>
          proxyAi(
            store,
            settings,
            managed,
            actor,
            method,
            value,
            undefined,
            factory,
          ),
        failure(code),
      );
    assert.equal(calls, 0);
    assert.equal(store.usage().length, 0);
    assert.equal(store.aiReceipt('a'.repeat(64)), undefined);
    for (const [index, method] of (
      ['ocr', 'extract', 'refine'] as const
    ).entries()) {
      const result = await proxyAi(
        store,
        config,
        managed,
        principal,
        method,
        {
          ...attempt,
          processing: {
            ...attempt.processing,
            idempotencyKey: String(index).repeat(64),
          },
        },
        undefined,
        factory,
      );
      assert.equal(result.provider, 'xai');
      assert.equal(result.model, 'grok-4.7');
      assert.equal(result.billingKind, 'personal');
      assert.equal(result.usage.reservedCost, 0.025);
    }
    assert.equal(calls, 3);
    const metadata = JSON.stringify(store.exportMetadata());
    for (const forbidden of [
      'untrusted xAI caption',
      'private-xai-proposal',
      'private-xai-fixture',
      'AQID',
    ])
      assert.equal(metadata.includes(forbidden), false);
  });

  it('retains one conservative charge after an xAI timeout and never retries or switches accounts', async () => {
    const store = seeded();
    const definition = xaiCatalogueProvider();
    const config = testConfig({
      AI_PROVIDER_CATALOGUE: JSON.stringify([definition]),
      AI_CREDENTIAL_ENCRYPTION_KEY: 'ab'.repeat(32),
      AI_TIMEOUT_MS: '10',
      AI_RETRY_LIMIT: '3',
    });
    await saveCredential(
      store,
      config,
      principal,
      'xai',
      'private-xai-fixture',
    );
    const attempt = {
      ...input(
        JSON.stringify({
          instructions: 'Evidence only',
          data: {},
          media: [],
          responseMimeType: 'text/plain',
        }),
      ),
      billing: { kind: 'personal' as const, provider: 'xai' },
    };
    let calls = 0;
    const factory = (_id: string, key: string) =>
      openaiProvider(
        config,
        key,
        async (_url, init) => {
          calls++;
          const signal = init?.signal;
          assert.ok(signal);
          return new Promise<Response>((_resolve, reject) => {
            signal.addEventListener('abort', () => reject(signal.reason), {
              once: true,
            });
          });
        },
        definition,
      );
    const managed = adapter(async () => assert.fail('No account fallback.'));
    for (let replay = 0; replay < 2; replay++)
      await assert.rejects(
        () =>
          proxyAi(
            store,
            config,
            managed,
            principal,
            'extract',
            attempt,
            undefined,
            factory,
          ),
        failure('ai_request_uncertain'),
      );
    assert.equal(calls, 1);
    assert.equal(store.usage().length, 1);
    assert.equal(store.usage()[0]?.cost, 0.025);
    assert.equal(
      store.aiReceipt(attempt.processing.idempotencyKey)?.status,
      'uncertain',
    );
  });
});
