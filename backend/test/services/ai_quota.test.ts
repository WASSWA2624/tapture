import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { AppError } from '../../src/domain/errors.js';
import { Store } from '../../src/repositories/store.js';
import { assertQuota } from '../../src/services/ai/quota.js';
import { proxyAi } from '../../src/services/ai/proxy.js';
import {
  fakeProvider,
  type AiProvider,
} from '../../src/services/ai/provider.js';
import { testConfig } from '../helpers.js';

const principal = {
  userId: 'user-1',
  organisationId: 'org-1',
  role: 'field_operator' as const,
  deviceId: 'device-1',
  contextScope: null,
};
const now = new Date('2026-09-30T12:00:00Z');

function seedProject(
  store: Store,
  id = 'project-1',
  organisationId = 'org-1',
): void {
  store.addProject({
    id,
    organisationId,
    name: 'Field',
    relayEnabled: false,
    neverRelay: false,
    retentionDays: 30,
  });
  store.addMember({
    projectId: id,
    userId: principal.userId,
    contextScope: null,
  });
}

function seedUsage(
  store: Store,
  input: {
    projectId?: string;
    cost?: number;
    at?: string;
    userId?: string;
  } = {},
): void {
  store.addUsage({
    projectId: input.projectId ?? 'project-1',
    userId: input.userId ?? 'user-1',
    model: 'fake',
    byteSize: 1,
    durationMs: 1,
    outcome: 'ok',
    cost: input.cost ?? 0.5,
    at: input.at ?? now.toISOString(),
  });
}

const quotaFailure = (error: unknown): boolean =>
  error instanceof AppError &&
  error.code === 'quota_exceeded' &&
  !error.publicMessage.includes('storage');

describe('ai quota', () => {
  it('refuses before the call once the ceiling is reached', async () => {
    const store = new Store();
    seedProject(store);
    for (let index = 0; index < 100; index += 1) {
      store.addUsage({
        projectId: 'project-1',
        userId: 'user-1',
        model: 'fake',
        byteSize: 1,
        durationMs: 1,
        outcome: 'ok',
        cost: 0,
        at: new Date().toISOString(),
      });
    }
    await assert.rejects(
      () => assertQuota(store, testConfig(), principal, 'project-1'),
      (error: unknown) =>
        error instanceof AppError && error.code === 'quota_exceeded',
    );
  });

  for (const [name, limit] of [
    ['AI_PROJECT_REQUEST_LIMIT', 1],
    ['AI_ORGANISATION_REQUEST_LIMIT', 1],
    ['AI_PROJECT_DAILY_REQUEST_LIMIT', 1],
    ['AI_ORGANISATION_DAILY_REQUEST_LIMIT', 1],
    ['AI_PROJECT_BUDGET', 0.5],
    ['AI_ORGANISATION_BUDGET', 0.5],
    ['AI_PROJECT_DAILY_BUDGET', 0.5],
    ['AI_ORGANISATION_DAILY_BUDGET', 0.5],
  ] as const) {
    it(`enforces ${name} below, at and above its ceiling`, async () => {
      const config = testConfig({
        [name]: String(limit),
        AI_REQUEST_COST_CEILING: '0.25',
        AI_RETRY_LIMIT: '1',
      });
      const store = new Store();
      seedProject(store);
      assert.equal(
        await assertQuota(store, config, principal, 'project-1', now),
        0.5,
      );
      seedUsage(store);
      await assert.rejects(
        () => assertQuota(store, config, principal, 'project-1', now),
        quotaFailure,
      );
      seedUsage(store);
      await assert.rejects(
        () => assertQuota(store, config, principal, 'project-1', now),
        quotaFailure,
      );
    });
  }

  it('shares project limits across users and organisation limits across projects', async () => {
    const store = new Store();
    seedProject(store);
    seedProject(store, 'project-2');
    seedUsage(store, { userId: 'another-user' });
    await assert.rejects(
      () =>
        assertQuota(
          store,
          testConfig({ AI_PROJECT_DAILY_REQUEST_LIMIT: '1' }),
          principal,
          'project-1',
          now,
        ),
      quotaFailure,
    );
    await assert.rejects(
      () =>
        assertQuota(
          store,
          testConfig({ AI_ORGANISATION_DAILY_REQUEST_LIMIT: '1' }),
          principal,
          'project-2',
          now,
        ),
      quotaFailure,
    );
  });

  it('resets daily caps at midnight UTC without erasing lifetime usage', async () => {
    const store = new Store();
    seedProject(store);
    seedProject(store, 'other-project', 'other-org');
    seedUsage(store, { at: '2026-09-29T23:59:59.999Z' });
    seedUsage(store, { projectId: 'other-project', cost: 500 });
    await assertQuota(
      store,
      testConfig({ AI_PROJECT_DAILY_REQUEST_LIMIT: '1' }),
      principal,
      'project-1',
      now,
    );
    await assert.rejects(
      () =>
        assertQuota(
          store,
          testConfig({ AI_PROJECT_REQUEST_LIMIT: '1' }),
          principal,
          'project-1',
          now,
        ),
      quotaFailure,
    );
  });

  it('reserves before provider dispatch so simultaneous requests cannot bypass a ceiling', async () => {
    const store = new Store();
    seedProject(store);
    let calls = 0;
    let release: () => void = () => undefined;
    const waiting = new Promise<void>((resolve) => {
      release = resolve;
    });
    let admitted: () => void = () => undefined;
    const started = new Promise<void>((resolve) => {
      admitted = resolve;
    });
    const answer = async () => {
      calls += 1;
      admitted();
      await waiting;
      return { text: 'ok', model: 'fake' };
    };
    const provider: AiProvider = {
      extract: answer,
      ocr: answer,
      transcribe: answer,
      refine: answer,
    };
    const config = testConfig({ AI_PROJECT_DAILY_REQUEST_LIMIT: '1' });
    const input = {
      projectId: 'project-1',
      model: 'fake',
      payload: Buffer.from('private data'),
    };
    const first = proxyAi(store, config, provider, principal, 'extract', input);
    await started;
    await assert.rejects(
      () => proxyAi(store, config, provider, principal, 'extract', input),
      quotaFailure,
    );
    assert.equal(store.usage()[0]?.outcome, 'reserved');
    release();
    await first;
    assert.equal(calls, 1);
    assert.equal(store.usage().length, 1);
    assert.equal(store.usage()[0]?.outcome, 'ok');
    assert.equal(JSON.stringify(store.usage()).includes('private data'), false);
  });

  it('retains a failed call reservation because a timeout can still be billed', async () => {
    const store = new Store();
    seedProject(store);
    const config = testConfig({
      AI_RETRY_LIMIT: '0',
      AI_PROJECT_DAILY_REQUEST_LIMIT: '1',
    });
    const input = {
      projectId: 'project-1',
      model: 'fake',
      payload: Buffer.from('private data'),
    };
    await assert.rejects(() =>
      proxyAi(store, config, fakeProvider('fail'), principal, 'extract', input),
    );
    assert.equal(store.usage()[0]?.outcome, 'failed');
    assert.equal(store.usage()[0]?.cost, 0.01);
    await assert.rejects(
      () =>
        proxyAi(store, config, fakeProvider('ok'), principal, 'extract', input),
      quotaFailure,
    );
  });

  it('does not invent a zero monetary cost when the deployment has no cost bound', async () => {
    const store = new Store();
    seedProject(store);
    await assert.rejects(
      () =>
        assertQuota(
          store,
          testConfig({ AI_REQUEST_COST_CEILING: '0' }),
          principal,
          'project-1',
        ),
      (error: unknown) =>
        error instanceof AppError && error.code === 'unavailable',
    );
    assert.equal(store.usage().length, 0);
  });

  it('refuses an arbitrary model before dispatch or reservation', async () => {
    const store = new Store();
    seedProject(store);
    await assert.rejects(
      () =>
        proxyAi(store, testConfig(), fakeProvider('ok'), principal, 'extract', {
          projectId: 'project-1',
          model: 'unbounded-expensive-model',
          payload: Buffer.from('private'),
        }),
      (error: unknown) =>
        error instanceof AppError && error.code === 'invalid_request',
    );
    assert.equal(store.usage().length, 0);
  });
});
