import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { withinCeiling } from '../../src/services/relay/quota.js';
import { appFor, makeDeps, seedUser, signIn } from '../helpers.js';

describe('storage quota', () => {
  it('refuses an upload past the ceiling before storing it', async () => {
    assert.equal(withinCeiling(8, 4, 10), false);
    const deps = makeDeps({ STORAGE_CEILING_BYTES: '6' });
    const account = await seedUser(deps, { role: 'project_manager' });
    const app = appFor(deps);
    const tokens = await signIn(app, account);
    await request(app)
      .post('/api/v1/projects')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .send({ id: 'project-1', name: 'Field' });
    await request(app)
      .patch('/api/v1/projects/project-1')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .send({ relayEnabled: true });
    const first = await request(app)
      .post('/api/v1/projects/project-1/relay/packages')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .set('idempotency-key', 'one')
      .set('content-type', 'application/octet-stream')
      .send(Buffer.from('abcd'));
    const second = await request(app)
      .post('/api/v1/projects/project-1/relay/packages')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .set('idempotency-key', 'two')
      .set('content-type', 'application/octet-stream')
      .send(Buffer.from('abcd'));
    assert.equal(first.status, 201);
    assert.equal(second.status, 429);
    assert.equal(second.body.error.code, 'quota_exceeded');
    assert.equal(deps.store.packages().length, 1);
  });
});
