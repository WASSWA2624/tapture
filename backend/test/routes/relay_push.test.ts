import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { appFor, makeDeps, seedUser, signIn } from '../helpers.js';

async function relayApp() {
  const deps = makeDeps({
    PACKAGE_MAX_BYTES: '8',
    STORAGE_CEILING_BYTES: '20',
  });
  const account = await seedUser(deps, { role: 'project_manager' });
  const app = appFor(deps);
  const tokens = await signIn(app, account);
  await request(app)
    .post('/api/v1/projects')
    .set('authorization', `Bearer ${tokens.accessToken}`)
    .send({ id: 'project-1', name: 'Field' });
  return { deps, app, tokens };
}

describe('relay push', () => {
  it('stores an opaque package once for one idempotency key', async () => {
    const { deps, app, tokens } = await relayApp();
    await request(app)
      .patch('/api/v1/projects/project-1')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .send({ relayEnabled: true });
    const first = await request(app)
      .post('/api/v1/projects/project-1/relay/packages')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .set('idempotency-key', 'key-1')
      .set('content-type', 'application/octet-stream')
      .send(Buffer.from('abcd'));
    const replay = await request(app)
      .post('/api/v1/projects/project-1/relay/packages')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .set('idempotency-key', 'key-1')
      .set('content-type', 'application/octet-stream')
      .send(Buffer.from('abcd'));
    assert.equal(first.status, 201);
    assert.equal(replay.body.id, first.body.id);
    assert.equal(deps.store.packages().length, 1);
    assert.equal(JSON.stringify(first.body).includes('abcd'), false);
  });

  it('refuses oversize, a disabled relay and a never-relay project', async () => {
    const { app, tokens } = await relayApp();
    const oversize = await request(app)
      .post('/api/v1/projects/project-1/relay/packages')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .set('idempotency-key', 'big')
      .set('content-type', 'application/octet-stream')
      .send(Buffer.from('0123456789'));
    assert.equal(oversize.status, 413);
    const disabled = await request(app)
      .post('/api/v1/projects/project-1/relay/packages')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .set('idempotency-key', 'off')
      .set('content-type', 'application/octet-stream')
      .send(Buffer.from('abcd'));
    assert.equal(disabled.status, 400);
    await request(app)
      .patch('/api/v1/projects/project-1')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .send({ relayEnabled: true, neverRelay: true });
    const never = await request(app)
      .post('/api/v1/projects/project-1/relay/packages')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .set('idempotency-key', 'never')
      .set('content-type', 'application/octet-stream')
      .send(Buffer.from('abcd'));
    assert.equal(never.status, 400);
  });
});
