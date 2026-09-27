import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import request from 'supertest';
import { mergeVectors } from '../../src/domain/version_vector.js';
import { appFor, makeDeps, seedUser, signIn } from '../helpers.js';

describe('relay state', () => {
  it('returns the pushed vector and deletes a fully acknowledged package', async () => {
    const deps = makeDeps();
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
    const uploaded = await request(app)
      .post('/api/v1/projects/project-1/relay/packages')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .set('idempotency-key', 'once')
      .set('content-type', 'application/octet-stream')
      .send(Buffer.from('abcd'));
    const state = await request(app)
      .get('/api/v1/projects/project-1/relay/state')
      .set('authorization', `Bearer ${tokens.accessToken}`);
    assert.deepEqual(state.body, mergeVectors({ [account.deviceId]: 1 }, {}));
    const ack = await request(app)
      .post('/api/v1/relay/ack')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .set('idempotency-key', 'ack-1')
      .send({ packageIds: [uploaded.body.id] });
    const replay = await request(app)
      .post('/api/v1/relay/ack')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .set('idempotency-key', 'ack-1')
      .send({ packageIds: [uploaded.body.id] });
    assert.equal(ack.status, 200);
    assert.deepEqual(replay.body, ack.body);
    assert.equal(deps.store.packages().length, 0);
    const afterPurge = await request(app)
      .post('/api/v1/relay/ack')
      .set('authorization', `Bearer ${tokens.accessToken}`)
      .set('idempotency-key', 'ack-2')
      .send({ packageIds: [uploaded.body.id] });
    assert.equal(afterPurge.status, 200);
  });
});
