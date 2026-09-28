import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import type { Express } from 'express';
import request from 'supertest';
import { parseConfig } from '../../src/config/schema.js';
import { appFor, makeDeps, seedUser, signIn } from '../helpers.js';

/// Signs a field operator into a project that may call the AI proxy.
async function aiApp(
  overrides: NodeJS.ProcessEnv = {},
): Promise<{ app: Express; token: string }> {
  const deps = makeDeps(overrides);
  const account = await seedUser(deps, { role: 'field_operator' });
  deps.store.addProject({
    id: 'project-1',
    organisationId: 'org-1',
    name: 'Field',
    relayEnabled: false,
    neverRelay: false,
    retentionDays: 30,
  });
  deps.store.addMember({
    projectId: 'project-1',
    userId: 'user-1',
    contextScope: null,
  });
  const app = appFor(deps);
  const tokens = await signIn(app, account);
  return { app, token: tokens.accessToken };
}

/// An AI request whose payload decodes to [bytes] bytes.
function aiBody(bytes: number): Record<string, string> {
  return {
    projectId: 'project-1',
    model: 'fake',
    payload: Buffer.alloc(bytes, 7).toString('base64'),
  };
}

describe('body limits', () => {
  it('admits a large AI body under the default limits but refuses it elsewhere', async () => {
    const { app, token } = await aiApp();
    const body = aiBody(1_200_000);
    const ai = await request(app)
      .post('/api/v1/ai/extract')
      .set('authorization', `Bearer ${token}`)
      .send(body);
    assert.equal(ai.status, 200);
    assert.equal(ai.body.text, 'ok:1200000');
    const other = await request(app)
      .post('/api/v1/projects')
      .set('authorization', `Bearer ${token}`)
      .send(body);
    assert.equal(other.status, 413);
    assert.equal(other.body.error.code, 'payload_too_large');
  });

  it('refuses an AI body over AI_BODY_LIMIT_BYTES', async () => {
    const { app, token } = await aiApp({
      BODY_LIMIT_BYTES: '2000',
      AI_BODY_LIMIT_BYTES: '100000',
    });
    const within = await request(app)
      .post('/api/v1/ai/ocr')
      .set('authorization', `Bearer ${token}`)
      .send(aiBody(30_000));
    assert.equal(within.status, 200);
    const over = await request(app)
      .post('/api/v1/ai/ocr')
      .set('authorization', `Bearer ${token}`)
      .send(aiBody(90_000));
    assert.equal(over.status, 413);
    assert.equal(over.body.error.code, 'payload_too_large');
  });

  it('authenticates before reading an AI body', async () => {
    const { app } = await aiApp({
      BODY_LIMIT_BYTES: '2000',
      AI_BODY_LIMIT_BYTES: '100000',
    });
    const response = await request(app)
      .post('/api/v1/ai/transcribe')
      .send(aiBody(90_000));
    assert.equal(response.status, 401);
  });

  it('keeps the AI limit at or above the general limit', () => {
    const base = { DATABASE_URL: 'memory://test', TOKEN_SECRET: 'secret' };
    const config = parseConfig(base);
    assert.equal(config.bodyLimitBytes, 1_000_000);
    assert.ok(config.aiBodyLimitBytes > config.bodyLimitBytes);
    assert.throws(
      () =>
        parseConfig({
          ...base,
          BODY_LIMIT_BYTES: '2000',
          AI_BODY_LIMIT_BYTES: '1000',
        }),
      /AI_BODY_LIMIT_BYTES/,
    );
  });
});
